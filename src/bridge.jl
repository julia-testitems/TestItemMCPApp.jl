# bridge.jl — Map between JuliaWorkspaces and TestItemControllers types

function resolve_testitems(state::AppState; filter=nothing)
    jw = state.workspace
    jw === nothing && error("Workspace not configured. Call set_workspace_folders first.")

    items = TestItemControllers.TestItemDetail[]
    setups = TestItemControllers.TestSetupDetail[]

    for (uri, file_info) in pairs(JuliaWorkspaces.get_test_items(jw))
        env = JuliaWorkspaces.get_test_env(jw, uri)
        textfile = JuliaWorkspaces.get_text_file(jw, uri)

        for item in file_info.testitems
            # Apply filter if provided
            if filter !== nothing && !passes_filter(item, env, uri, filter)
                continue
            end

            push!(items, TestItemControllers.TestItemDetail(
                item.id,
                string(item.uri),
                item.name,
                env.package_name,
                env.package_uri === nothing ? nothing : string(env.package_uri),
                env.project_uri === nothing ? nothing : string(env.project_uri),
                env.env_content_hash === nothing ? nothing : string(env.env_content_hash),
                item.option_default_imports,
                string.(item.option_setup),
                JuliaWorkspaces.position_at(textfile.content, item.code_range.start)[1],
                JuliaWorkspaces.position_at(textfile.content, item.code_range.start)[2],
                textfile.content.content[item.code_range],
                JuliaWorkspaces.position_at(textfile.content, item.code_range.stop)[1],
                JuliaWorkspaces.position_at(textfile.content, item.code_range.stop)[2],
                get(filter, :timeout, nothing),
            ))
        end

        for setup in file_info.testsetups
            env.package_uri === nothing && continue
            push!(setups, TestItemControllers.TestSetupDetail(
                string(env.package_uri),
                string(setup.name),
                string(setup.kind),
                string(uri),
                JuliaWorkspaces.position_at(textfile.content, setup.code_range.start)[1],
                JuliaWorkspaces.position_at(textfile.content, setup.code_range.start)[2],
                textfile.content.content[setup.code_range],
            ))
        end
    end

    return items, setups
end

function passes_filter(item, env, uri, filter::Dict)
    if haskey(filter, :tags) && !isempty(filter[:tags])
        item_tags = Set(string.(item.option_tags))
        if !any(t -> t in item_tags, filter[:tags])
            return false
        end
    end
    if haskey(filter, :name_pattern) && filter[:name_pattern] !== nothing
        if !occursin(Regex(filter[:name_pattern], "i"), item.name)
            return false
        end
    end
    if haskey(filter, :file_pattern) && filter[:file_pattern] !== nothing
        if !occursin(Regex(filter[:file_pattern], "i"), string(uri))
            return false
        end
    end
    if haskey(filter, :package) && filter[:package] !== nothing
        if env.package_name != filter[:package]
            return false
        end
    end
    if haskey(filter, :ids) && !isempty(filter[:ids])
        if !(item.id in filter[:ids])
            return false
        end
    end
    return true
end

function build_profile(params::Dict{String,Any})
    id = string(UUIDs.uuid4())
    return TestItemControllers.TestProfile(
        id,
        "MCP Profile",
        get(params, "julia_cmd", "julia")::String,
        convert(Vector{String}, get(params, "julia_args", String[])),
        let v = get(params, "julia_num_threads", missing)
            v === nothing ? missing : v isa String ? v : missing
        end,
        Dict{String,Union{String,Nothing}}(),
        get(params, "max_workers", min(Sys.CPU_THREADS, 8))::Int,
        get(params, "mode", "Run")::String,
        let v = get(params, "coverage_root_uris", nothing)
            v === nothing ? nothing : convert(Vector{String}, v)
        end,
        :Info,
    )
end

function collect_detection_errors(state::AppState)
    jw = state.workspace
    jw === nothing && return Any[]
    errors = Any[]
    for (uri, file_info) in pairs(JuliaWorkspaces.get_test_items(jw))
        for e in file_info.testerrors
            push!(errors, Dict{String,Any}(
                "uri" => string(e.uri),
                "id" => e.id,
                "name" => e.name,
                "message" => e.message,
                "range" => Dict("start" => e.range.start, "stop" => e.range.stop),
            ))
        end
    end
    return errors
end

function collect_testitems_list(state::AppState; filter=nothing)
    jw = state.workspace
    jw === nothing && return Any[]
    result = Any[]
    for (uri, file_info) in pairs(JuliaWorkspaces.get_test_items(jw))
        env = JuliaWorkspaces.get_test_env(jw, uri)
        for item in file_info.testitems
            if filter !== nothing && !passes_filter(item, env, uri, filter)
                continue
            end
            push!(result, Dict{String,Any}(
                "id" => item.id,
                "name" => item.name,
                "uri" => string(item.uri),
                "package_name" => env.package_name,
                "tags" => string.(item.option_tags),
                "line" => item.range.start,
                "setup_names" => string.(item.option_setup),
            ))
        end
    end
    return result
end
