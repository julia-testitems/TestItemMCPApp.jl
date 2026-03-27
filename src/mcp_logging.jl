# mcp_logging.jl — MCP logging subsystem

# MCP severity levels in order (lowest → highest)
const MCP_LOG_LEVELS = Dict{Symbol,Int}(
    :debug => 0,
    :info => 1,
    :notice => 2,
    :warning => 3,
    :error => 4,
    :critical => 5,
    :alert => 6,
    :emergency => 7,
)

function mcp_log(state::AppState, level::Symbol, logger::String, data)
    level_rank = get(MCP_LOG_LEVELS, level, 1)
    min_rank = get(MCP_LOG_LEVELS, state.log_level, 1)
    level_rank < min_rank && return

    # Also log to stderr as fallback
    @debug "[$level] $logger: $data"

    try
        JSONRPC.send_notification(state.endpoint, "notifications/message", Dict{String,Any}(
            "level" => string(level),
            "logger" => logger,
            "data" => data,
        ))
    catch
        # Endpoint may be closed
    end
end

mcp_debug(state::AppState, logger::String, data) = mcp_log(state, :debug, logger, data)
mcp_info(state::AppState, logger::String, data) = mcp_log(state, :info, logger, data)
mcp_notice(state::AppState, logger::String, data) = mcp_log(state, :notice, logger, data)
mcp_warn(state::AppState, logger::String, data) = mcp_log(state, :warning, logger, data)
mcp_error(state::AppState, logger::String, data) = mcp_log(state, :error, logger, data)

function set_log_level!(state::AppState, level::String)
    sym = Symbol(level)
    if !haskey(MCP_LOG_LEVELS, sym)
        error("Invalid log level: $level")
    end
    state.log_level = sym
end
