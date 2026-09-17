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

@testset "the experiment harness" begin
    # The script defines the five experiment functions and runs nothing when it
    # is included rather than executed, which is what makes it testable.
    include(joinpath(@__DIR__, "..", "scripts", "run_experiments.jl"))

    # --- the pieces that need no solve -------------------------------------
    @test tex_escape("mu_N & 10% {x}") == "mu\\_N \\& 10\\% \\{x\\}"
    @test tex_num(NaN) == "--"
    @test tex_num(Inf) == "\$\\infty\$"          # a floorless survival ratio
    @test tex_num(1.23456; digits = 2) == "1.23"
    @test tex_date(-1) == "--" && tex_date(7) == "7"
    @test first_date(<(0), [1.0, 2.0, -1.0]) == 2      # dates count from zero
    @test first_date(<(0), [1.0, 2.0]) == -1
    @test csv_quote("a,b") == "\"a,b\"" && csv_quote("ab") == "ab"
    @test csv_field(true) == "true" && csv_field(-1) == "-1"

    # The consumption equivalent must inverta proportional change in
    # consumption exactly, in both branches of the utility function.
    let pp = baseline_params(), cf = (; Uc = -1000.0, Vp = 3.0, total = -1003.0)
        @test isapprox(consumption_equivalent(pp, cf.Uc * 1.1^(1 - pp.eta) - cf.Vp, cf),
                       0.1; rtol = 1e-9)
        @test isapprox(consumption_equivalent(pp, cf.total, cf), 0.0; atol = 1e-12)
    end
    let pl = baseline_params(eta = 1.0, rho = 0.06), cf = (; Uc = 10.0, Vp = 1.0, total = 9.0)
        @test isapprox(consumption_equivalent(pl, cf.total + log(1.1) / (1 - discount(pl)), cf),
                       0.1; rtol = 1e-9)
    end

    # --- the budget stops before the first solve ---------------------------
    mktempdir() do dir
        r = experiment_taxonomy(baseline_params(), baseline_states();
                                cases = [(; name = "a"), (; name = "b")], T = 40,
                                start_T = 40, hours = 0.0, outdir = dir,
                                texdir = joinpath(dir, "Tables"),
                                shutdown_search = false, horizon_check = false,
                                verbose = false)
        @test r.stopped && isempty(r.rows)
        # both files still appear: the header, and a table saying what happened
        @test readlines(r.csv) == [join(TAXONOMY_COLS, ",")]
        @test occursin("stopped on its time budget after 0 of 2", read(r.tex, String))
    end

    # --- the five experiments, on tiny grids at T = 40 ---------------------
    p, s0, T = baseline_params(), baseline_states(), 40
    banner = "%% GENERATED by model/scripts/run_experiments.jl on "
    "First line of the CSV, split into column names."
    header(path) = split(first(readlines(path)), ',')
    ndata(path) = length(readlines(path)) - 1

    mktempdir() do dir
        tex = joinpath(dir, "Tables")
        common = (; T = T, start_T = T, outdir = dir, texdir = tex, verbose = false)

        r1 = experiment_taxonomy(p, s0; cases = [(; name = "baseline"),
                                                 (; name = "hard ceiling", abar = 0.7)],
                                 hours = 0.5, shutdown_search = false,
                                 horizon_check = false, common...)
        @test !r1.stopped && length(r1.rows) == 2
        @test header(r1.csv) == string.(collect(TAXONOMY_COLS))
        @test ndata(r1.csv) == 2
        @test basename(dirname(r1.csv)) == "taxonomy"
        @test startswith(first(readlines(r1.tex)), banner)
        @test occursin("threeparttable", read(r1.tex, String))
        # the illustrative set is state C, and the hard ceiling cannot close the
        # loop, so it is state B: the classification is the experiment's output
        @test r1.rows[1].state == "C" && r1.rows[2].state == "B"
        @test all(r -> r.converged, r1.rows)

        r2 = experiment_circularity(p, s0; abar_grid = [1.0], xi_grid = [3.0],
                                    hours = 0.5, shutdown_search = false, common...)
        @test header(r2.csv) == string.(collect(CIRCULARITY_COLS))
        @test ndata(r2.csv) == 1
        # recycling is worth something against the no-recycling counterfactual
        @test r2.rows[1].ce_gain > 0
        @test r2.rows[1].cum_Xi < r2.rows[1].cum_Xi_norecycling
        @test startswith(first(readlines(r2.tex)), banner)

        r3 = experiment_instruments(p, s0; corners = [(1.0, 1.0, 1.0, 1.0),
                                                      (0.0, 0.0, 0.0, 0.0)],
                                    dials = (:phiW,), dial_steps = 0.5,
                                    hours = 0.5, common...)
        @test header(r3.csv) == string.(collect(INSTRUMENT_COLS))
        @test ndata(r3.csv) == 5                      # two corners, one dial path
        @test count(r -> r.kind == "corner", r3.rows) == 2
        # the planner corner is the reference point, so its equivalent is zero
        @test isapprox(r3.rows[1].ce_vs_planner, 0.0; atol = 1e-9)
        @test startswith(first(readlines(r3.tex)), banner)

        r4 = experiment_gatefee(p, s0; hours = 0.5, common...)
        @test header(r4.csv) == string.(collect(GATEFEE_COLS))
        @test header(r4.paths) == string.(collect(GATEFEE_PATH_COLS))
        @test ndata(r4.csv) == 2
        @test ndata(r4.paths) == 2 * (T + 1)
        # the gate fee turns negative at the planner corner: waste becomes a
        # resource, which is the date the experiment exists to report
        @test r4.rows[1].sign_change >= 0
        @test startswith(first(readlines(r4.tex)), banner)

        r5 = experiment_surface(p, s0; Rbar_grid = [0.0, 0.2], abar_cases = [1.0],
                                hours = 0.5, common...)
        @test header(r5.csv) == string.(collect(SURFACE_COLS))
        @test ndata(r5.csv) == 2
        # the floor is slack at Rbar = 0 and binding above it
        @test isinf(r5.rows[1].survival_ratio) && isfinite(r5.rows[2].survival_ratio)
        @test startswith(first(readlines(r5.tex)), banner)

        # every table the harness generates carries the banner and nothing else
        # was written into the table directory
        @test sort(readdir(tex)) == ["Circularity.tex", "GateFee.tex", "Instruments.tex",
                                     "Surface.tex", "Taxonomy.tex"]
    end

    # --- the shutdown branch is fenced, not trusted -------------------------
    # `solve_with_shutdown` is the fragile branch of model/README.md; the
    # harness must record a failure in the row rather than take the grid down
    # with it, so what is asserted here is the contract and not convergence.
    let d, st
        d, st = shutdown_date(baseline_params(Rbar = 0.35, abar = 0.7), baseline_states();
                              dates = [20])
        @test d isa Integer && st isa AbstractString
        @test d == 20 || d == -1
    end
end

@testset "the no-treatment corner" begin
    # The calibrated set as phase C left it, at municipal handling charges on
    # the whole handled flow: no tonne is worth treating, so varpi = 0 and
    # KR = 0 in every period.  That is a legitimate solution -- the lower
    # corner of the treatment margin -- and the solver must reach it to
    # tolerance.  Written in KR the recycling-capital row is a 0/0 there
    # (KR and T vanish together at a fixed ratio) and Newton stalled at
    # |F| ~ 1e-4 on the last smoothing steps (data/processed/c8_smoke.txt);
    # written in the intensity x = KR/T it converges.  The fixture is frozen
    # because task D0b refits the charges and the live file no longer sits at
    # this corner.
    fixture = joinpath(@__DIR__, "fixtures", "calibration_notreatment.json")
    p = calibrated_params(fixture; check = false)
    s0 = calibrated_states(fixture)
    mo = Model(p; T = 40, s0 = s0)
    x, ok, nrm = solve_path(mo, initial_guess(mo; Rtarget = 7.562, warn = false))
    @test ok
    @test nrm < 1e-9
    sol = unpack(mo, x)
    @test all(b -> abs(b.vw) < 1e-9 && abs(b.KR) < 1e-9, sol.blocks)
    for t in (1, 21, 41)
        b = sol.blocks[t]; pr = sol.prices[t]
        # the intensity is interior and on its margin, a'(x)(pR + dW tauP) = rK,
        # even though no capital is employed ...
        @test b.x > 0
        @test abs(b.ap * (pr.pR + p.dW * pr.tauP) - pr.rK) < 1e-9
        # ... and at that intensity the marginal treated tonne does not pay,
        # which is what puts the treatment margin at its corner
        gV = b.alpha * pr.pR + pr.tauP * ((1 - p.dW) + p.dW * b.alpha) -
             (1 + pr.zz * b.Omega * p.omW) * b.mcW
        @test gV < 0
    end
    @test compare_residuals(mo, x) < 1e-10
    @test check_path(mo, x; verbose = false).ledger_rel_error < 1e-7
    # and solve_long, the route the harness takes, reaches the same corner
    mo2, x2, ok2, nrm2 = solve_long(p, s0, 60; start_T = 60, guess_kwargs = (; Rtarget = 7.562))
    @test ok2 && nrm2 < 1e-9
    @test all(b -> abs(b.vw) < 1e-9, unpack(mo2, x2).blocks)
end
