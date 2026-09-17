#=
Task D2 of `notes/plan_calibration_experiments.md`: E2 (`experiment_circularity`)
and E4 (`experiment_gatefee`) on the calibrated baseline, through the harness of
`run_experiments.jl`.

    julia --project=. scripts/run_d2.jl                       # T = 400, both
    julia --project=. scripts/run_d2.jl --only=gatefee
    julia --project=. scripts/run_d2.jl --only=gatefeexi     # E4 at each end of xi
    julia --project=. scripts/run_d2.jl --T=60 --hours=0.2 --ghours=0.2   # smoke

E2 is run once per floor, because `experiment_circularity` takes the floor from
the parameter set rather than as a grid.  Each run writes its own live record
under `output/circularity/<tag>/`, which is the crash-resilient one -- rows are
flushed as they are produced -- and this driver copies it up to
`output/circularity/circularity_<tag>.csv`, stacks the two into
`output/circularity/circularity.csv` with the floor as the leading column, and
writes the one table the note inputs, `writing/quant/Tables/Circularity.tex`.
The per-floor tables the harness writes under the run directory are that run's
half of it and are not inputs.

E4 needs no such handling: it writes `output/gatefee/` and `Tables/GateFee.tex`
where the harness puts them.  The driver adds the readings the summary CSV does
not carry -- the gate fee at the date of its minimum and at the sign change --
by reading the per-period path back.

The grids are the calibration file's `cases`, not literals: the ceilings are
`cases.abar` plus the midpoint 0.85, the tail rates are the ends of
`cases.xi_range` around the point value of `xi`, and the floors are the first
two of `cases.Rbar_grid`.  The third and fourth are left out because D1 found
`Rbar = 47.5` unsolvable on this calibration and D2 is not the place to retry
it.
=#

include(joinpath(@__DIR__, "run_experiments.jl"))
using Printf

const ARGD = parse_args(ARGS)
const T_REQ = parse(Int, get(ARGD, "T", "400"))
const HOURS_E2 = parse(Float64, get(ARGD, "hours", "6"))
const HOURS_E4 = parse(Float64, get(ARGD, "ghours", "3"))
const ONLY = String.(split(get(ARGD, "only", "circularity,gatefee"), ','))
const DATA = normpath(joinpath(@__DIR__, "..", "..", "data", "processed"))
const ABAR_MID = 0.85
const NFLOORS = 2

"A directory-safe tag for a floor, used for the run directory and the copied CSV."
floor_tag(rb::Real) = "Rbar" * replace(@sprintf("%.4g", rb), "." => "p")

d = read_calibration(joinpath(DATA, "calibration.json"))
p, s0, cases = calibrated_params(d), calibrated_states(d), calibration_cases(d)

const ABAR_GRID = sort(unique(vcat(float.(cases.abar), ABAR_MID)); rev = true)
const XI_GRID = [cases.xi_range[1], p.xi, cases.xi_range[end]]
const RBARS = float.(cases.Rbar_grid[1:min(NFLOORS, end)])

println(repeat("=", 78))
@printf("D2 on %s, T = %d\n", joinpath(DATA, "calibration.json"), T_REQ)
@printf("  abar grid %s\n  xi grid   %s\n  floors    %s\n",
        string(ABAR_GRID), string(round.(XI_GRID; digits = 4)), string(RBARS))
println(repeat("=", 78))

# ---------------------------------------------------------------------------
# E2, once per floor, then stacked
# ---------------------------------------------------------------------------

"""
    write_circularity_table(rows; stopped, asked) -> path

The one table the note inputs, from the stacked rows of both floors.  Split out
of the run so that `--only=table` can rebuild it from the CSV without solving
anything: the formatting of a column is not worth eighteen cold solves.  The
consumption equivalents are printed to four decimals of a percent because on
this calibration they are hundredths of a percent, and two decimals would round
every row to zero.

Three columns of the first version are in the CSV and not here.  `Era ends' and
the shutdown date go for `duration_note`'s reason: the first is empty in every
row, no path reaching the floor within the horizon, and the second is the last
date the shutdown branch solves rather than an optimum.  The Hotelling
deviation goes because the rule it measures is about the relaxed problem, and
`hotelling_deviation` reports it only where exploration has ceased and the
reserve carries no stock effect, which no cell of this calibration reaches.
"""
function write_circularity_table(rows; stopped::Bool = false, asked::Int = 0)
    texrows = String[]
    for row in rows
        push!(texrows, join((tex_num(row.Rbar; digits = 1), tex_num(row.abar; digits = 3),
                             tex_num(row.xi; digits = 2), row.state,
                             tex_num(100 * row.ce_gain; digits = 4),
                             tex_num(row.cum_Xi; digits = 1),
                             tex_num(row.Xi_avoided; digits = 1),
                             tex_num(row.Minf; digits = 1),
                             tex_num(row.survival_ratio; digits = 1)), " & "))
    end
    return write_table(joinpath(TABLE_ROOT, "Circularity.tex");
        caption = "What circularity buys, by floor, ceiling and tail rate",
        label = "tab:q:res:circularity", colspec = "rrrcrrrrr",
        header = "\$\\bar R\$ & \$\\bar a\$ & \$\\xi\$ & State & CE gain (\\%) & " *
                 "\$\\sum\\Xi\$ & \$\\Xi\$ avoided & " *
                 "\$\\mathcal M_\\infty\$ & \$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$",
        rows = texrows,
        notes = vcat(["The no-recycling counterfactual sets \$\\bar a = " *
                      string(ABAR_NORECYCLING) * "\$, so the recycling margin is at its " *
                      "corner rather than absent from the problem, and is solved at the " *
                      "same \$\\xi\$ and the same floor. The consumption-equivalent gain " *
                      "is the proportional consumption supplement that would make the " *
                      "counterfactual as good as the cell. " *
                      "Emissions are cumulative over the horizon, in gigatonnes of " *
                      "material. The survival ratio is infinite without a floor, and under " *
                      "a hard ceiling it is reported but is not what decides the state: " *
                      "the loop cannot close, so a floor puts the cell in state A whatever " *
                      "the ratio."],
                     duration_note(p, s0, [(r.abar, r.Rbar) for r in rows if r.state == "A"]),
                     stopped ? ["The run stopped on its time budget after " *
                                "$(length(rows)) of $asked grid points."] : String[]))
end

function run_circularity()
    t0 = time()
    runs = Any[]
    for rb in RBARS
        tag = floor_tag(rb)
        outdir = joinpath(OUTPUT_ROOT, "circularity", tag)
        println("\n", repeat("-", 78), "\nE2 at Rbar = ", rb, " -> ", outdir, "\n",
                repeat("-", 78))
        res = experiment_circularity(with(p; Rbar = rb), s0; abar_grid = ABAR_GRID,
                                     xi_grid = XI_GRID, T = T_REQ, hours = HOURS_E2,
                                     outdir = outdir, texdir = joinpath(outdir, "Tables"),
                                     shutdown_search = true)
        dest = joinpath(OUTPUT_ROOT, "circularity", "circularity_" * tag * ".csv")
        cp(res.csv, dest; force = true)
        push!(runs, (; Rbar = rb, res, csv = dest))
        @printf("E2 Rbar = %.4g: %d rows, stopped on budget: %s\n",
                rb, length(res.rows), res.stopped)
    end

    # the stacked record: the two runs' rows with the floor as the leading column
    stacked = open_csv(joinpath(OUTPUT_ROOT, "circularity", "circularity.csv"),
                       (:Rbar, CIRCULARITY_COLS...))
    try
        for r in runs, row in r.res.rows
            write_row!(stacked, (; Rbar = r.Rbar, row...))
        end
    finally
        close_csv(stacked)
    end

    asked = length(ABAR_GRID) * length(XI_GRID) * length(RBARS)
    done = sum(length(r.res.rows) for r in runs; init = 0)
    stopped = any(r -> r.res.stopped, runs)
    tex = write_circularity_table([(; Rbar = r.Rbar, row...) for r in runs
                                   for row in r.res.rows]; stopped = stopped, asked = asked)
    @printf("\nE2: %d of %d grid points in %.1f min; table %s\n",
            done, asked, (time() - t0) / 60, tex)
    for r in runs
        println("  rows: ", r.csv)
    end
    println("  stacked: ", joinpath(OUTPUT_ROOT, "circularity", "circularity.csv"))
    return runs
end

# ---------------------------------------------------------------------------
# E4
# ---------------------------------------------------------------------------

function run_gatefee()
    t0 = time()
    println("\n", repeat("-", 78), "\nE4 on the baseline\n", repeat("-", 78))
    res = experiment_gatefee(p, s0; T = T_REQ, hours = HOURS_E4)
    @printf("\nE4: %d settings in %.1f min; table %s\n", length(res.rows),
            (time() - t0) / 60, res.tex)
    println("  summary: ", res.csv, "\n  paths:   ", res.paths)

    # the readings the summary CSV does not carry: where the minimum is, and the
    # gate fee on either side of the sign change
    paths = read_csv(res.paths)
    for row in res.rows
        idx = findall(==(row.setting), paths["setting"])
        isempty(idx) && continue
        t = parse.(Int, paths["t"][idx])
        tw = parse.(Float64, paths["tauW"][idx])
        imin = argmin(tw)
        @printf("\n== %s (%g,%g,%g,%g): T reached %d, converged %s, |F| = %.2e, %s\n",
                row.setting, row.phiW, row.phiz, row.phiP, row.phiX, row.T_reached,
                row.converged, row.resid, row.method)
        @printf("   tauW: t = 0 (1900) %.6g; minimum %.6g at t = %d (year %d); T = %d %.6g\n",
                tw[1], tw[imin], t[imin], 1900 + t[imin], t[end], tw[end])
        if row.sign_change >= 0
            i = row.sign_change + 1
            @printf("   sign change at t = %d (year %d): tauW = %.6g, previous %.6g\n",
                    t[i], 1900 + t[i], tw[i], i > 1 ? tw[i-1] : NaN)
        else
            println("   no sign change within the horizon reached")
        end
        for tt in (0, 50, 100, 115, 139, 150, 200, 300, 400)
            tt <= t[end] || continue
            @printf("   t = %3d (year %4d): tauW = %12.6g  Wst = %10.4g  R = %9.4g  a = %.4f  varpi = %.4f\n",
                    tt, 1900 + tt, tw[tt+1], parse(Float64, paths["Wst"][idx[tt+1]]),
                    parse(Float64, paths["R"][idx[tt+1]]),
                    parse(Float64, paths["a"][idx[tt+1]]),
                    parse(Float64, paths["varpi"][idx[tt+1]]))
        end
    end
    return res
end

# ---------------------------------------------------------------------------
# E4 over the tail rate: does the sign-change date move with xi?
# ---------------------------------------------------------------------------

"""
E4 again at each end of `cases.xi_range`, into its own directory so that the
table the note inputs stays the baseline's.  E2's row schema carries no
sign-change column, so this is the only place the question D2 is asked -- does
the date waste becomes a resource move plausibly with the tail rate? -- can be
answered from a solved path.
"""
function run_gatefee_xi()
    for xi in (XI_GRID[1], XI_GRID[end])
        tag = "xi" * replace(@sprintf("%.4g", xi), "." => "p")
        outdir = joinpath(OUTPUT_ROOT, "gatefee", tag)
        println("\n", repeat("-", 78), "\nE4 at xi = ", xi, " -> ", outdir, "\n",
                repeat("-", 78))
        res = experiment_gatefee(with(p; xi = xi), s0; T = T_REQ, hours = HOURS_E4,
                                 outdir = outdir, texdir = joinpath(outdir, "Tables"))
        for row in res.rows
            @printf("   xi = %.4g  %-22s sign change %s, tauW_0 = %.6g, tauW_T = %.6g, min %.6g, T = %d, %s\n",
                    xi, row.setting, tex_date(row.sign_change), row.tauW_0, row.tauW_end,
                    row.tauW_min, row.T_reached, row.method)
        end
    end
end

"""
Rebuild the two tables the note inputs from the CSVs of an earlier run, solving
nothing.  The CSV is the record; the table is a rendering of it, and a change to
a column's format should not cost eighteen cold solves.
"""
function rebuild_table()
    path = joinpath(OUTPUT_ROOT, "circularity", "circularity.csv")
    c = read_csv(path)
    n = length(c["Rbar"])
    num(col, i) = parse(Float64, c[col][i])
    rows = [(; Rbar = num("Rbar", i), abar = num("abar", i), xi = num("xi", i),
              state = c["state"][i], ce_gain = num("ce_gain", i),
              cum_Xi = num("cum_Xi", i), Xi_avoided = num("Xi_avoided", i),
              Minf = num("Minf", i), survival_ratio = num("survival_ratio", i))
            for i in 1:n]
    println("rebuilt ", write_circularity_table(rows), " from ", path, ", ", n, " rows")

    gpath = joinpath(OUTPUT_ROOT, "gatefee", "gatefee_summary.csv")
    if isfile(gpath)
        g = read_csv(gpath)
        m = length(g["setting"])
        gnum(col, i) = parse(Float64, g[col][i])
        grows = [(; setting = g["setting"][i], phiW = gnum("phiW", i),
                   phiz = gnum("phiz", i), phiP = gnum("phiP", i), phiX = gnum("phiX", i),
                   tauW_0 = gnum("tauW_0", i), tauW_end = gnum("tauW_end", i),
                   sign_change = parse(Int, g["sign_change"][i]),
                   T_reached = parse(Int, g["T_reached"][i])) for i in 1:m]
        println("rebuilt ", write_gatefee_table(grows), " from ", gpath, ", ", m, " rows")
    end
end

"circularity" in ONLY && run_circularity()
"table" in ONLY && rebuild_table()
"gatefee" in ONLY && run_gatefee()
"gatefeexi" in ONLY && run_gatefee_xi()
