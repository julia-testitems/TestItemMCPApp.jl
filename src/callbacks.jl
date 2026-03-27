# callbacks.jl — TestItemController callback implementations

function create_controller_callbacks(state::AppState)
    return TestItemControllers.ControllerCallbacks(
        on_testitem_started = (testrun_id, testitem_id) -> begin
            lock(state.lock) do
                run = get(state.runs, testrun_id, nothing)
                run === nothing && return
                item = get(run.items, testitem_id, nothing)
                item === nothing && return
                item.status = :running
            end
            mcp_info(state, "testitem", "Started: $(get_item_label(state, testrun_id, testitem_id))")
            notify_resource_updated(state, "testrun://$testrun_id/summary")
        end,

        on_testitem_passed = (testrun_id, testitem_id, duration) -> begin
            lock(state.lock) do
                run = get(state.runs, testrun_id, nothing)
                run === nothing && return
                item = get(run.items, testitem_id, nothing)
                item === nothing && return
                item.status = :passed
                item.duration = duration
            end
            mcp_info(state, "testitem", "Passed: $(get_item_label(state, testrun_id, testitem_id)) ($(round(duration, digits=2))s)")
            notify_resource_updated(state, "testrun://$testrun_id/summary")
            notify_resource_updated(state, "testrun://$testrun_id/failures")
        end,

        on_testitem_failed = (testrun_id, testitem_id, messages, duration) -> begin
            lock(state.lock) do
                run = get(state.runs, testrun_id, nothing)
                run === nothing && return
                item = get(run.items, testitem_id, nothing)
                item === nothing && return
                item.status = :failed
                item.duration = duration
                item.messages = [testmessage_to_dict(m) for m in messages]
            end
            label = get_item_label(state, testrun_id, testitem_id)
            msg_summary = isempty(messages) ? "" : ": $(first(messages).message)"
            mcp_warn(state, "testitem", "Failed: $label ($(round(duration, digits=2))s)$msg_summary")
            notify_resource_updated(state, "testrun://$testrun_id/summary")
            notify_resource_updated(state, "testrun://$testrun_id/failures")
        end,

        on_testitem_errored = (testrun_id, testitem_id, messages, duration) -> begin
            lock(state.lock) do
                run = get(state.runs, testrun_id, nothing)
                run === nothing && return
                item = get(run.items, testitem_id, nothing)
                item === nothing && return
                item.status = :errored
                item.duration = duration
                item.messages = [testmessage_to_dict(m) for m in messages]
            end
            label = get_item_label(state, testrun_id, testitem_id)
            msg_summary = isempty(messages) ? "" : ": $(first(messages).message)"
            mcp_error(state, "testitem", "Errored: $label ($(round(duration, digits=2))s)$msg_summary")
            notify_resource_updated(state, "testrun://$testrun_id/summary")
            notify_resource_updated(state, "testrun://$testrun_id/failures")
        end,

        on_testitem_skipped = (testrun_id, testitem_id) -> begin
            lock(state.lock) do
                run = get(state.runs, testrun_id, nothing)
                run === nothing && return
                item = get(run.items, testitem_id, nothing)
                item === nothing && return
                item.status = :skipped
            end
            mcp_info(state, "testitem", "Skipped: $(get_item_label(state, testrun_id, testitem_id))")
            notify_resource_updated(state, "testrun://$testrun_id/summary")
        end,

        on_append_output = (testrun_id, testitem_id, output) -> begin
            lock(state.lock) do
                run = get(state.runs, testrun_id, nothing)
                run === nothing && return
                item = get(run.items, testitem_id, nothing)
                item === nothing && return
                push!(item.output, output)
            end
            notify_resource_updated(state, "testrun://$testrun_id/items/$testitem_id/output")
        end,

        on_attach_debugger = (testrun_id, debug_pipe_name) -> begin
            # Debugging is excluded from MCP server
        end,

        on_process_created = (id, package_name, package_uri, project_uri, coverage, env) -> begin
            lock(state.lock) do
                state.processes[id] = ProcessInfo(id, package_name, "Created", package_uri, project_uri)
                state.process_outputs[id] = String[]
            end
            mcp_notice(state, "controller", "Process created for $package_name (id=$id)")
            notify_resource_list_changed(state)
        end,

        on_process_terminated = (id,) -> begin
            pkg_name = lock(state.lock) do
                p = get(state.processes, id, nothing)
                name = p === nothing ? id : p.package_name
                delete!(state.processes, id)
                delete!(state.process_outputs, id)
                name
            end
            mcp_notice(state, "controller", "Process terminated: $pkg_name (id=$id)")
            notify_resource_list_changed(state)
        end,

        on_process_status_changed = (id, status) -> begin
            lock(state.lock) do
                p = get(state.processes, id, nothing)
                p === nothing && return
                p.status = status
            end
            mcp_debug(state, "controller", "Process $id: $status")
        end,

        on_process_output = (id, output) -> begin
            lock(state.lock) do
                buf = get(state.process_outputs, id, nothing)
                buf === nothing && return
                push!(buf, output)
            end
            mcp_debug(state, "controller", output)
        end,
    )
end

function get_item_label(state::AppState, testrun_id::String, testitem_id::String)
    lock(state.lock) do
        run = get(state.runs, testrun_id, nothing)
        run === nothing && return testitem_id
        item = get(run.items, testitem_id, nothing)
        item === nothing && return testitem_id
        return item.label
    end
end

function init_controller!(state::AppState)
    if state.controller !== nothing
        return  # Already initialized
    end
    callbacks = create_controller_callbacks(state)
    state.controller = TestItemControllers.TestItemController(callbacks; log_level=:Info)
    state.reactor_task = @async Base.run(state.controller)
    mcp_notice(state, "transport", "TestItemController initialized")
end

function shutdown_controller!(state::AppState)
    state.controller === nothing && return
    TestItemControllers.shutdown(state.controller)
    if state.reactor_task !== nothing
        TestItemControllers.wait_for_shutdown(state.controller, state.reactor_task)
    end
    state.controller = nothing
    state.reactor_task = nothing
end
