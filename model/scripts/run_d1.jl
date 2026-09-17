#=
Task D1 of `notes/plan_calibration_experiments.md`: E1 on the calibrated
baseline and on the metals bound, through the harness of `run_experiments.jl`.

    julia --project=. scripts/run_d1.jl [T]
    julia --project=. scripts/run_d1.jl --only=table   # rebuild the table from the CSV

The baseline's rows go where `run_experiments.jl --only=taxonomy` would put
them, `output/taxonomy/` and `writing/quant/Tables/Taxonomy.tex`; the metals
bound's stay under `output/metals/`, rows and table both.  The metals table is
not a note input: at `mu_N = 0` the bound's reserve goes negative and its rows
are infeasible (`model/README.md`, *Known limitations*), and a second table
under the baseline's own label is a duplicate label in the note.  What the bound
says is said in prose until its `mu_N` is refitted.

Beyond the harness's own columns, the run prints the diagnostics the task asks
for row by row: the reserve relative to its initial level at the horizon reached
and the date it falls to two percent, the market-planner gap, the transversality
and well-posedness reports in full, and the movement of the 1900-2000 window
between the horizon reached and half of it.
=#

include(joinpath(@__DIR__, "run_experiments.jl"))
using Printf

const HORIZONS = filter(a -> !startswith(a, "--"), ARGS)
const T_REQ = isempty(HORIZONS) ? 400 : parse(Int, first(HORIZONS))
const DATA = normpath(joinpath(@__DIR__, "..", "..", "data", "processed"))

function full_diagnostics(p, s0, rows)
    for row in rows
        row.converged || (println("  $(row.case): not converged, |F| = $(row.resid)"); continue)
        pc = with(p; abar = row.abar, Rbar = row.Rbar)
        r = solve_case(pc, s0; T = row.T_reached, start_T = min(150, row.T_reached), step = 50)
        r.ok || (println("  $(row.case): re-solve at T = $(row.T_reached) failed"); continue)
        sol = unpack(r.mo, r.x)
        S = series(sol, :S)
        i2 = findfirst(v -> v <= 0.02 * s0[IS], S)
        @printf("\n== %s: T reached %d, S_T/S_0 = %.4f, min S = %.4g, S at 2%% of S0: %s\n",
                row.case, r.mo.T, S[end] / s0[IS], minimum(S),
                i2 === nothing ? "not within T" : "t = $(i2 - 1) (year $(1900 + i2 - 1))")
        b = sol.blocks[end]
        @printf("   at T: Y = %.4g C = %.4g R = %.4g N = %.4g RR = %.4g varpi = %.4f x = %.4f (Sref/S)^muN = %.3g\n",
                b.Y, b.C, b.R, b.N, b.RR, b.vw, b.x, (pc.Sref / max(b.S, 1e-12))^pc.mu_N)
        vw = series(sol, :vw)
        @printf("   treated share: 1900 %.4f, 2015 %.4f, 2100 %.4f; leaves 0 at t = %d, reaches 1 at t = %d\n",
                vw[1], vw[min(116, end)], vw[min(201, end)],
                first_date(>(1e-9), vw), first_date(v -> v >= 1 - 1e-9, vw))
        println("   check_path:")
        check_path(r.mo, r.x)
        println("   classify_longrun: ", classify_longrun(r.mo, r.x))
        @printf("   market-planner gap: %.3e\n", compare_residuals(r.mo, r.x))
        println("   tvc_report:")
        tvc_report(r.mo, r.x)
        println("   wellposed_report at the circular rate:")
        wellposed_report(pc)
    end
end

"""
Rebuild `Tables/Taxonomy.tex` from the baseline's CSV, solving nothing.  The CSV
is the record; the table is a rendering of it, and a change to a column should
not cost eight cold solves at `T = 400`.
"""
function rebuild_table()
    path = joinpath(OUTPUT_ROOT, "taxonomy", "taxonomy.csv")
    c = read_csv(path)
    n = length(c["case"])
    num(col, i) = parse(Float64, c[col][i])
    d = read_calibration(joinpath(DATA, "calibration.json"))
    rows = [(; case = c["case"][i], abar = num("abar", i), Rbar = num("Rbar", i),
              state = c["state"][i], Minf = num("Minf", i),
              residence = num("residence", i),
              survival_ratio = num("survival_ratio", i),
              gatefee_sign_change = parse(Int, c["gatefee_sign_change"][i]),
              T_reached = parse(Int, c["T_reached"][i])) for i in 1:n]
    tex = write_taxonomy_table(calibrated_params(d), calibrated_states(d), rows)
    println("rebuilt ", tex, " from ", path, ", ", n, " rows")
end

if "--only=table" in ARGS
    rebuild_table()
    exit()
end

for (label, file, outdir, texdir) in (
        ("baseline", "calibration.json", OUTPUT_ROOT, TABLE_ROOT),
        ("metals bound", "calibration_metals.json", joinpath(OUTPUT_ROOT, "metals"),
         joinpath(OUTPUT_ROOT, "metals", "Tables")))
    println("\n", repeat("=", 78), "\n", label, ": ", file, "\n", repeat("=", 78))
    d = read_calibration(joinpath(DATA, file))
    p, s0, cases = calibrated_params(d), calibrated_states(d), calibration_cases(d)
    res = experiment_taxonomy(p, s0; cases = taxonomy_cases(cases), T = T_REQ,
                              hours = 6.0, outdir = outdir, texdir = texdir)
    println("rows: ", res.csv, "\ntable: ", res.tex)
    for row in res.rows
        @printf("%-22s conv=%s T=%d/%d state=%s Minf=%.4g Tres=%.4g surv=%s closes=%s gate<0 at %d era_end %d shutdown %d (%s) gap=%.1e tvc=%.4f wp=[%s] horizon: T_short=%d dY=%.2e dC=%.2e cumN/bound=%.3f leak/B=%.3f below_floor=%d %s %.0fs\n",
                row.case, row.converged, row.T_reached, row.T_requested, row.state, row.Minf,
                row.residence, tex_num(row.survival_ratio), row.closes, row.gatefee_sign_change,
                row.material_era_end, row.shutdown, row.shutdown_status, row.market_planner_gap,
                row.tvc_capital_factor, row.wellposed_fail, row.horizon_T_short, row.horizon_dY,
                row.horizon_dC, row.cumN_over_bound, row.cum_leak_over_budget,
                row.periods_below_floor, row.method, row.seconds)
    end
    full_diagnostics(p, s0, res.rows)
end
