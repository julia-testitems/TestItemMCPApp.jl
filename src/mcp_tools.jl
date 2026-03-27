# mcp_tools.jl — MCP tool definitions with JSON Schema

function tool_definitions()
    return [
        Dict{String,Any}(
            "name" => "set_workspace_folders",
            "description" => "Set the workspace folders for test item detection. Call this first to configure which Julia packages/projects to scan for @testitem and @testsetup macros. Replaces any previous workspace configuration.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "folders" => Dict{String,Any}(
                        "type" => "array",
                        "items" => Dict{String,Any}("type" => "string"),
                        "description" => "Absolute paths to workspace folders to scan for test items.",
                    ),
                ),
                "required" => ["folders"],
            ),
        ),
        Dict{String,Any}(
            "name" => "update_file",
            "description" => "Notify the server that a file has changed on disk. Call this after editing source or test files so that test item detection is refreshed.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "path" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Absolute file path that was changed.",
                    ),
                ),
                "required" => ["path"],
            ),
        ),
        Dict{String,Any}(
            "name" => "list_testitems",
            "description" => "List all detected test items, optionally filtered by tags, name pattern, file pattern, or package name.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "tags" => Dict{String,Any}(
                        "type" => "array",
                        "items" => Dict{String,Any}("type" => "string"),
                        "description" => "Filter to items containing at least one of these tags.",
                    ),
                    "name_pattern" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Regex pattern to match against test item names (case-insensitive).",
                    ),
                    "file_pattern" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Regex pattern to match against file URIs (case-insensitive).",
                    ),
                    "package" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Filter to items in this package only.",
                    ),
                ),
            ),
        ),
        Dict{String,Any}(
            "name" => "run_testitems",
            "description" => "Run test items. Blocks until all tests complete and returns full results. If no items or filter specified, runs all detected test items. Test processes are reused across runs with Revise-based hot-reload for fast iteration.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "items" => Dict{String,Any}(
                        "type" => "array",
                        "items" => Dict{String,Any}("type" => "string"),
                        "description" => "Specific test item IDs to run. If omitted, runs all (or filtered) items.",
                    ),
                    "tags" => Dict{String,Any}(
                        "type" => "array",
                        "items" => Dict{String,Any}("type" => "string"),
                        "description" => "Filter to items containing at least one of these tags.",
                    ),
                    "name_pattern" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Regex pattern to match against test item names.",
                    ),
                    "file_pattern" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Regex pattern to match against file URIs.",
                    ),
                    "package" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Filter to items in this package only.",
                    ),
                    "julia_cmd" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Julia command to use (default: \"julia\").",
                    ),
                    "julia_args" => Dict{String,Any}(
                        "type" => "array",
                        "items" => Dict{String,Any}("type" => "string"),
                        "description" => "Extra command-line arguments for Julia.",
                    ),
                    "julia_num_threads" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "Thread count (e.g. \"auto\", \"4\").",
                    ),
                    "max_workers" => Dict{String,Any}(
                        "type" => "integer",
                        "description" => "Maximum number of parallel test processes (default: min(CPU_THREADS, 8)).",
                    ),
                    "mode" => Dict{String,Any}(
                        "type" => "string",
                        "enum" => ["Run", "Coverage"],
                        "description" => "Execution mode (default: \"Run\").",
                    ),
                    "timeout" => Dict{String,Any}(
                        "type" => "number",
                        "description" => "Per-test-item timeout in seconds.",
                    ),
                    "coverage_root_uris" => Dict{String,Any}(
                        "type" => "array",
                        "items" => Dict{String,Any}("type" => "string"),
                        "description" => "Root URIs for coverage collection (Coverage mode only).",
                    ),
                ),
            ),
        ),
        Dict{String,Any}(
            "name" => "rerun_failed",
            "description" => "Re-run only the failed and errored test items from a previous test run.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "testrun_id" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "ID of the previous test run whose failures to re-run.",
                    ),
                    "julia_cmd" => Dict{String,Any}("type" => "string", "description" => "Julia command override."),
                    "julia_args" => Dict{String,Any}("type" => "array", "items" => Dict{String,Any}("type" => "string"), "description" => "Julia args override."),
                    "max_workers" => Dict{String,Any}("type" => "integer", "description" => "Max workers override."),
                    "timeout" => Dict{String,Any}("type" => "number", "description" => "Per-item timeout override."),
                ),
                "required" => ["testrun_id"],
            ),
        ),
        Dict{String,Any}(
            "name" => "cancel_testrun",
            "description" => "Cancel an active test run.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "testrun_id" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "ID of the test run to cancel.",
                    ),
                ),
                "required" => ["testrun_id"],
            ),
        ),
        Dict{String,Any}(
            "name" => "get_testrun_results",
            "description" => "Get results for a completed or in-progress test run.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "testrun_id" => Dict{String,Any}(
                        "type" => "string",
                        "description" => "ID of the test run.",
                    ),
                    "include_output" => Dict{String,Any}(
                        "type" => "boolean",
                        "description" => "Include captured stdout/stderr per test item (default: false).",
                    ),
                    "include_passing" => Dict{String,Any}(
                        "type" => "boolean",
                        "description" => "Include passing test items in results (default: false).",
                    ),
                ),
                "required" => ["testrun_id"],
            ),
        ),
        Dict{String,Any}(
            "name" => "get_testitem_detail",
            "description" => "Get detailed result for a specific test item in a run, including failure messages, stack traces, and captured output.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "testrun_id" => Dict{String,Any}("type" => "string", "description" => "Test run ID."),
                    "testitem_id" => Dict{String,Any}("type" => "string", "description" => "Test item ID."),
                ),
                "required" => ["testrun_id", "testitem_id"],
            ),
        ),
        Dict{String,Any}(
            "name" => "list_testruns",
            "description" => "List all test runs with their status summaries.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(),
            ),
        ),
        Dict{String,Any}(
            "name" => "list_test_processes",
            "description" => "List active test worker processes managed by the controller.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(),
            ),
        ),
        Dict{String,Any}(
            "name" => "terminate_test_process",
            "description" => "Terminate a specific test worker process.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "process_id" => Dict{String,Any}("type" => "string", "description" => "Process ID to terminate."),
                ),
                "required" => ["process_id"],
            ),
        ),
        Dict{String,Any}(
            "name" => "get_coverage_results",
            "description" => "Get line-level coverage results from a Coverage-mode test run.",
            "inputSchema" => Dict{String,Any}(
                "type" => "object",
                "properties" => Dict{String,Any}(
                    "testrun_id" => Dict{String,Any}("type" => "string", "description" => "Test run ID (must have been run with mode=\"Coverage\")."),
                ),
                "required" => ["testrun_id"],
            ),
        ),
    ]
end
