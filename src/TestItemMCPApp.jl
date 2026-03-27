module TestItemMCPApp

import JSON, JSONRPC, JuliaWorkspaces, TestItemControllers, CancellationTokens
import UUIDs, Dates, Logging

include("types.jl")
include("state.jl")
include("mcp_logging.jl")
include("mcp_protocol.jl")
include("bridge.jl")
include("callbacks.jl")
include("mcp_tools.jl")
include("mcp_resources.jl")
include("tool_handlers.jl")
include("mcp_server.jl")

function (@main)(ARGS)
    # All logging goes to stderr — stdout is exclusively for MCP messages
    debuglogger = Logging.ConsoleLogger(stderr, Logging.Debug)
    Logging.with_logger(debuglogger) do
        run_server(stdin, stdout)
    end
end

end # module TestItemMCPApp
