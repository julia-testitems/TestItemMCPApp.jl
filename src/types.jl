# types.jl — Shared data types for test run tracking

const MCP_PROTOCOL_VERSION = "2025-03-26"

mutable struct TestItemResult
    testitem_id::String
    label::String
    uri::String
    status::Symbol  # :pending, :running, :passed, :failed, :errored, :skipped
    duration::Union{Nothing,Float64}
    messages::Vector{Any}  # TestMessage-like dicts
    output::Vector{String}
end

mutable struct TestRunRecord
    const id::String
    status::Symbol  # :running, :completed, :cancelled
    const profile_params::Dict{String,Any}
    const items::Dict{String,TestItemResult}  # testitem_id → result
    coverage::Union{Nothing,Vector{Any}}      # FileCoverage-like dicts
    const started_at::Dates.DateTime
    completed_at::Union{Nothing,Dates.DateTime}
end

mutable struct ProcessInfo
    id::String
    package_name::String
    status::String
    package_uri::String
    project_uri::String
end

function run_summary(run::TestRunRecord)
    total = length(run.items)
    passed = count(v -> v.status == :passed, values(run.items))
    failed = count(v -> v.status == :failed, values(run.items))
    errored = count(v -> v.status == :errored, values(run.items))
    skipped = count(v -> v.status == :skipped, values(run.items))
    running = count(v -> v.status == :running, values(run.items))
    pending = count(v -> v.status == :pending, values(run.items))
    total_duration = sum((v.duration for v in values(run.items) if v.duration !== nothing), init=0.0)
    return Dict{String,Any}(
        "total" => total,
        "passed" => passed,
        "failed" => failed,
        "errored" => errored,
        "skipped" => skipped,
        "running" => running,
        "pending" => pending,
        "duration" => total_duration,
        "status" => string(run.status),
        "testrun_id" => run.id,
        "started_at" => string(run.started_at),
        "completed_at" => run.completed_at === nothing ? nothing : string(run.completed_at),
    )
end

function testmessage_to_dict(msg)
    d = Dict{String,Any}("message" => msg.message)
    if msg.expected_output !== nothing
        d["expected_output"] = msg.expected_output
    end
    if msg.actual_output !== nothing
        d["actual_output"] = msg.actual_output
    end
    if msg.uri !== nothing
        d["uri"] = msg.uri
    end
    if msg.line !== nothing
        d["line"] = msg.line
    end
    if msg.column !== nothing
        d["column"] = msg.column
    end
    if msg.stack_trace !== nothing
        d["stack_trace"] = [
            Dict{String,Any}(
                "label" => f.label,
                "uri" => f.uri,
                "line" => f.line,
                "column" => f.column,
            ) for f in msg.stack_trace
        ]
    end
    return d
end
