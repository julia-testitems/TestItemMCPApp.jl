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
    if !ismissing(msg.expectedOutput)
        d["expectedOutput"] = msg.expectedOutput
    end
    if !ismissing(msg.actualOutput)
        d["actualOutput"] = msg.actualOutput
    end
    if !ismissing(msg.uri)
        d["uri"] = msg.uri
    end
    if !ismissing(msg.line)
        d["line"] = msg.line
    end
    if !ismissing(msg.column)
        d["column"] = msg.column
    end
    if !ismissing(msg.stackTrace)
        d["stackTrace"] = [
            Dict{String,Any}(
                "label" => f.label,
                "uri" => ismissing(f.uri) ? nothing : f.uri,
                "line" => ismissing(f.line) ? nothing : f.line,
                "column" => ismissing(f.column) ? nothing : f.column,
            ) for f in msg.stackTrace
        ]
    end
    return d
end
