# state.jl — Application state

mutable struct AppState
    workspace::Union{Nothing,JuliaWorkspaces.JuliaWorkspace}
    controller::Union{Nothing,TestItemControllers.TestItemController}
    reactor_task::Union{Nothing,Task}
    runs::Dict{String,TestRunRecord}
    processes::Dict{String,ProcessInfo}
    process_outputs::Dict{String,Vector{String}}
    endpoint::JSONRPC.JSONRPCEndpoint
    subscriptions::Set{String}
    log_level::Symbol  # MCP log level: :debug, :info, :notice, :warning, :error, :critical, :alert, :emergency
    cancellation_sources::Dict{String,CancellationTokens.CancellationTokenSource}  # testrun_id → cts
    lock::ReentrantLock
end

function AppState(endpoint::JSONRPC.JSONRPCEndpoint)
    return AppState(
        nothing,
        nothing,
        nothing,
        Dict{String,TestRunRecord}(),
        Dict{String,ProcessInfo}(),
        Dict{String,Vector{String}}(),
        endpoint,
        Set{String}(),
        :info,
        Dict{String,CancellationTokens.CancellationTokenSource}(),
        ReentrantLock(),
    )
end
