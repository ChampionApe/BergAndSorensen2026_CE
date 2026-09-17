# The calibration interface and the experiment harness.
#
# Two concerns, kept in one file because they are one pipeline: the JSON the
# data work writes, and the experiments run from it.  `runtests.jl` registers
# this file with a single include.

@testset "JSON reader" begin
    J = CircularEconomy
    @test J.json_parse("{}") == Dict{String,Any}()
    @test J.json_parse("[]") == Any[]
    # integers stay integers, everything with a point or an exponent is a float
    @test J.json_parse("[1, -2, 3.5, 1e3, -1.5E-2]") == Any[1, -2, 3.5, 1000.0, -0.015]
    @test J.json_parse("[1]")[1] isa Int64
    @test J.json_parse("[1.0]")[1] isa Float64
    @test J.json_parse("{\"a\": {\"b\": [true, false, null]}}")["a"]["b"] ==
          Any[true, false, nothing]
    # escapes, including the one a Windows path would carry
    @test J.json_parse("[\"a\\\\b\\tc\\\"d\"]")[1] == "a\\b\tc\"d"
    @test J.json_parse("[\"\\u0041\"]")[1] == "A"
    # whitespace anywhere between tokens
    @test J.json_parse("  {\n \"x\" : [ 1 , 2 ]\n}  ")["x"] == Any[1, 2]

    # and the failures report a position rather than a MethodError
    for bad in ("{", "{\"a\" 1}", "[1,]", "{\"a\":1,}", "1 2", "[\"x\"", "{\"a\":1,\"a\":2}")
        @test_throws ErrorException J.json_parse(bad)
    end
    @test_throws ErrorException J.json_parse_file(joinpath(@__DIR__, "no_such_file.json"))
end

@testset "the calibration interface" begin
    fixture = joinpath(@__DIR__, "fixtures", "calibration_example.json")
    d = read_calibration(fixture)
    p = calibrated_params(fixture)
    s0 = calibrated_states(fixture)

    # every entry of the file reaches the Params field of the same name, in
    # both the bare-number and the {"value": ...} spelling
    for (k, v) in d["params"]
        f = Symbol(k)
        want = v isa AbstractDict ? v["value"] : v
        got = getfield(p, f)
        got isa Symbol ? (@test got === Symbol(want)) : (@test got == want)
    end
    @test s0 == [3.0, 20.0, 25.0, 0.5, 2.0, 1.0]
    @test length(s0) == NS
    # the fixture is the illustrative set written in the pipeline's schema, so
    # it must reproduce it field for field
    for f in fieldnames(Params)
        @test getfield(p, f) === getfield(baseline_params(), f)
    end

    # a file naming only some fields leaves the rest at their Params defaults
    part = Dict{String,Any}("params" => Dict{String,Any}("rho" => 0.03, "tail" => ":power"),
                            "states" => d["states"])
    # check = false: the fixture's psi_a = 2 with a power tail is the S-shaped
    # case check_params warns about, and this test is not about that warning
    pp = calibrated_params(part; check = false)
    @test pp.rho == 0.03
    @test pp.tail === :power
    @test pp.delta === Params().delta
    # keyword arguments override the file, as in baseline_params
    @test calibrated_params(part; check = false, rho = 0.04).rho == 0.04

    # meta, cases, sources and bounds
    @test calibration_meta(fixture)["base_year"] == 1900
    cs = calibration_cases(fixture)
    @test cs.abar == [1.0, 0.85]
    @test cs.Rbar_grid == [0.0, 0.2, 0.35]
    @test cs.xi_range == [1.5, 6.0] && cs.muN_range == [1.1, 2.0]
    @test calibration_sources(fixture)[:mu_N] == "notes/data/resources.md"
    @test !haskey(calibration_sources(fixture), :psi_v)     # a bare number has no source
    b = calibration_bounds(fixture)
    @test b[:mu_N] == (value = 1.5, low = 1.1, high = 2.0)
    @test b[:delta] == (value = 0.05, low = 0.05, high = 0.05)   # a point
    @test !haskey(b, :tail)                                      # not a number

    # a typo in the pipeline is an error, not a silently ignored entry
    @test_throws ErrorException calibrated_params(
        Dict{String,Any}("params" => Dict{String,Any}("mu" => 0.02)))
    @test_throws ErrorException calibrated_states(
        Dict{String,Any}("states" => Dict{String,Any}("K0" => 1.0)))
    @test_throws ErrorException calibrated_states(
        Dict{String,Any}("states" => merge(d["states"], Dict("Q0" => 1.0))))
    @test_throws ErrorException calibrated_params(Dict{String,Any}("states" => d["states"]))

    # round trip: write the parameters out in the schema, read them back, and
    # require every field and every state to survive the crossing
    mktempdir() do dir
        path = joinpath(dir, "roundtrip.json")
        open(path, "w") do io
            println(io, "{\"params\": {")
            ent = String[]
            for f in fieldnames(Params)
                v = getfield(p, f)
                push!(ent, v isa Symbol ? "  \"$f\": \"$v\"" :
                           "  \"$f\": {\"value\": $(repr(v)), \"source\": \"round trip\"}")
            end
            println(io, join(ent, ",\n"))
            println(io, "}, \"states\": {")
            println(io, join(["  \"$k\": $(repr(s0[i]))"
                              for (i, k) in enumerate(CircularEconomy.STATE_KEYS)], ",\n"))
            println(io, "}}")
        end
        p2 = calibrated_params(path)
        for f in fieldnames(Params)
            @test getfield(p2, f) === getfield(p, f)
        end
        @test calibrated_states(path) == s0
    end
end
