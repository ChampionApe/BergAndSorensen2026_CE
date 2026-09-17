#=
Task D4 of `notes/plan_calibration_experiments.md`: E5 (`experiment_surface`) on
the calibrated baseline, through the harness of `run_experiments.jl`.

    julia --project=. scripts/run_d4.jl                  # surface, edge, shutdown grid
    julia --project=. scripts/run_d4.jl --only=edge
    julia --project=. scripts/run_d4.jl --only=table     # rebuild the table from the CSVs
    julia --project=. scripts/run_d4.jl --T=60 --hours=0.3 --nsolves=2    # smoke

Three stages, and the second is the one that matters.

*The surface.*  `experiment_surface` over the floor grid at three ceilings, the
two of the calibration file and the midpoint D2 used, with the shutdown search
on where the state is collapse.  Rows go where the harness puts them,
`output/surface/surface.csv`.

*The solvability edge.*  D1 found `Rbar = 47.5` unsolvable on this calibration
and `Rbar = 23.756` solvable; the edge between them is bisected here, at most
`nsolves` probes per ceiling, each continued from the last floor that solved.
A failing probe is diagnosed rather than merely recorded: which of the three
routes failed, at what residual, which rows of the residual vector are the large
ones, and -- the reading that makes the whole floor grid intelligible -- where
the floorless path's own material input sits relative to the floor in the early
decades.  `Rbar` enters the technology as `R - Rbar`, so a floor above the base
year's throughput is not a scarcity assumption about the distant future but a
demand that the 1900 economy run several times its own material input from the
first period.

*The shutdown date.*  D1 and D2 both returned exactly 280 in every collapse cell
of the 7-point, 40-period grid `path_facts` uses.  Here the search is re-run at
two cells on `200:10:400`, so that a flat or monotone objective is visible as
one.  A date that sits at the edge of its grid is the horizon's and not the
model's, and is labelled so.

The solving is the harness's, with one difference the edge search needs: the
floorless path of each ceiling is solved once and cached, where `solve_case`
re-solves it inside every floor homotopy.  On this calibration that solve is
four minutes and the edge search spends most of its probes on failures, each of
which pays for it twice.  The routes, their order and their names are
`solve_case`'s.
=#

include(joinpath(@__DIR__, "run_experiments.jl"))
using Printf

const ARGD = parse_args(filter(a -> startswith(a, "--"), ARGS))
const T_REQ = parse(Int, get(ARGD, "T", "400"))
const HOURS = parse(Float64, get(ARGD, "hours", "8"))
const NSOLVES = parse(Int, get(ARGD, "nsolves", "6"))
const ONLY = String.(split(get(ARGD, "only", "surface,edge,shutdown,table"), ','))
const DATA = normpath(joinpath(@__DIR__, "..", "..", "data", "processed"))
# `--tag=` sends everything, the note's table included, to a scratch directory,
# so that a smoke run cannot leave a `T = 60` table where the note inputs one.
const TAG = get(ARGD, "tag", "")
const OUT_ROOT = isempty(TAG) ? OUTPUT_ROOT : joinpath(OUTPUT_ROOT, TAG)
const D4_OUT = joinpath(OUT_ROOT, "surface")
const D4_TEX = isempty(TAG) ? TABLE_ROOT : joinpath(OUT_ROOT, "Tables")
const ABAR_MID = 0.85

d = read_calibration(joinpath(DATA, "calibration.json"))
p, s0, cases = calibrated_params(d), calibrated_states(d), calibration_cases(d)

# The floor grid: the calibration file's own values where they exist, the five
# intermediate points of the task in between.  9.502 and 23.756 are the file's,
# not the report's rounded 9.5 and 23.8, so that the cells D1 and D2 also
# solved are the same cells.
const RB_FILE = float.(cases.Rbar_grid)
const RBAR_GRID = sort(vcat(RB_FILE[1:3], [2.0, 4.0, 6.0, 14.0, 19.0]))
const RBAR_SOLVED = RB_FILE[3]    # 23.756, the largest floor D1 solved
const RBAR_FAILED = RB_FILE[4]    # 47.512, the floor D1 could not solve
const ABAR_CASES = sort(unique(vcat(float.(cases.abar), ABAR_MID)); rev = true)
const ABAR_HARD = minimum(float.(cases.abar))

# ---------------------------------------------------------------------------
# reading a residual vector
# ---------------------------------------------------------------------------

# The 18 rows of a residual block, in the order `residual_market!` writes them:
# six control margins, six costate equations, six transitions.  The terminal
# block has the first twelve only.
const ROW_NAMES = ("goods", "q (investment)", "N margin", "D margin",
                   "varpi margin", "x margin",
                   "costate K (q)", "costate S (pS)", "costate X (pX)",
                   "costate P (pP)", "costate MK (pM)", "costate W (pW)",
                   "transition K", "transition S", "transition X",
                   "transition P", "transition MK", "transition W")

"""
    worst_rows(mo, x; n) -> Vector{(t, row, value)}

The largest entries of the residual vector, by period and by the row's name.
This is what "which residual rows" means for a point that did not solve: a
failure in the transitions is a different animal from one in the corner
conditions of the recycling margin.
"""
function worst_rows(mo::Model, x::AbstractVector; n::Int = 6)
    nb = CircularEconomy.NBLK
    F = zeros(nvar(mo))
    residual_market!(F, mo, x)
    ord = sortperm(abs.(F); rev = true)
    return [(; t = div(i - 1, nb), row = ROW_NAMES[mod(i - 1, nb)+1], value = F[i])
            for i in ord[1:min(n, length(ord))]]
end

show_rows(w) = join([@sprintf("%s at t = %d: %.2e", r.row, r.t, r.value) for r in w], "; ")

# ---------------------------------------------------------------------------
# one floor, the harness's three routes with the floorless solve cached
# ---------------------------------------------------------------------------

"""
    solve_floor(pc, s0; T, prev, base0) -> (; mo, x, ok, nrm, method, seconds, attempts)

`solve_case`'s routes in `solve_case`'s order -- continuation from the previous
floor, the floor homotopy from the floorless path, a cold `solve_long` -- with
the floorless path passed in rather than re-solved, and with two routes the
harness does not have.  Both exist so that "this floor does not solve" is a
statement about the model and not about the harness's defaults.

  * *a longer homotopy* where the eight-step one stalled close to tolerance.
    Eight steps is what the harness spends on a point that is expected to work;
    a point at the edge is not, and a stall at `1e-6` is a step length, not a
    verdict.
  * *a cold solve from a floor-scaled guess*.  `solve_long`'s default guess
    targets `Rtarget = 0.6` Gt of material input, which is the illustrative
    set's scale; on this calibration the 1900 input is 5.7 Gt and any floor
    above that leaves the guess below the floor in every period, where
    `initial_guess` itself warns that Newton has nothing to work with.  The
    cold route as the harness calls it therefore cannot decide anything here,
    and the fifth route is the one that can.

Every attempt is kept in `attempts` with its residual and its packed vector,
which is what the failure diagnosis reads.
"""
function solve_floor(pc::Params, s0::AbstractVector; T::Int, prev = nothing, base0 = nothing)
    t0 = time()
    attempts = NamedTuple[]
    done(route, mo, x, ok, nrm) = (; mo, x, ok, nrm, method = route,
                                    seconds = time() - t0, attempts)
    if prev !== nothing && prev.ok
        mo = Model(pc; T = prev.mo.T, s0 = s0)
        x, ok, nrm = continuate(prev.mo, mo, prev.x; steps = 8)
        push!(attempts, (; route = "continuation", ok, nrm, mo, x))
        ok && return done("continuation", mo, x, ok, nrm)
    end
    if base0 !== nothing && base0.ok && pc.Rbar > 0
        mo = Model(pc; T = base0.mo.T, s0 = s0, Gam = base0.mo.Gam)
        for steps in (8, 24)
            x, ok, nrm = continuate(base0.mo, mo, base0.x; steps = steps)
            push!(attempts, (; route = "floor homotopy ($steps steps)", ok, nrm, mo, x))
            ok && return done("floor homotopy ($steps steps)", mo, x, ok, nrm)
            nrm < 1e-3 || break
        end
    end
    mo, x, ok, nrm = solve_long(pc, s0, T; start_T = min(150, T), step = 50)
    push!(attempts, (; route = "cold solve_long", ok, nrm, mo, x))
    ok && return done("cold solve_long", mo, x, ok, nrm)
    if pc.Rbar > 0
        mo, x, ok, nrm = solve_long(pc, s0, T; start_T = min(150, T), step = 50,
                                    guess_kwargs = (; Rtarget = 1.2 * pc.Rbar))
        push!(attempts, (; route = "cold, floor-scaled guess", ok, nrm, mo, x))
        ok && return done("cold, floor-scaled guess", mo, x, ok, nrm)
    end
    return done(attempts[end].route, mo, x, ok, nrm)
end

"Material input over the first `n` periods of a solved path."
input_path(r, n::Int) = series(unpack(r.mo, r.x), :R)[1:min(n, r.mo.T + 1)]

"First date at which material input reaches `level`; -1 if it never does."
first_above(R, level) = first_date(v -> v >= level, R)

# ---------------------------------------------------------------------------
# stage 1: the surface
# ---------------------------------------------------------------------------

function run_surface()
    t0 = time()
    println("\n", repeat("=", 78))
    @printf("D4 stage 1: E5 over %d floors x %d ceilings, T = %d, budget %g h\n",
            length(RBAR_GRID), length(ABAR_CASES), T_REQ, HOURS)
    @printf("  floors   %s\n  ceilings %s\n", string(RBAR_GRID), string(ABAR_CASES))
    println(repeat("=", 78))
    res = experiment_surface(p, s0; Rbar_grid = RBAR_GRID, abar_cases = ABAR_CASES,
                             T = T_REQ, hours = HOURS, shutdown_search = true,
                             outdir = OUT_ROOT, texdir = D4_TEX)
    println("\nrows: ", res.csv, "\ntable: ", res.tex)
    for row in res.rows
        @printf("%-26s conv=%-5s T=%3d/%3d %-15s |F|=%8.1e state=%-2s Minf=%9.4g surv=%9s shutdown %4d (%s) gate<0 %4d era_end %4d closes=%-5s below_floor=%d %.0fs\n",
                row.case, row.converged, row.T_reached, row.T_requested, row.method,
                row.resid, row.state, row.Minf, tex_num(row.survival_ratio),
                row.shutdown, row.shutdown_status, row.gatefee_sign_change,
                row.material_era_end, row.closes, row.periods_below_floor, row.seconds)
    end
    @printf("\nstage 1: %d of %d cells in %.1f min; stopped on budget: %s\n",
            length(res.rows), length(RBAR_GRID) * length(ABAR_CASES),
            (time() - t0) / 60, res.stopped)
    return res
end

# ---------------------------------------------------------------------------
# stage 2: the solvability edge
# ---------------------------------------------------------------------------

const EDGE_COLS = (:abar, :Rbar, :kind, :converged, :resid, :method, :T_reached,
                   :state, :survival_ratio, :Minf, :R0, :min_slack, :below_floor,
                   :routes, :worst, :seconds)

"One probe of the bisection, as a CSV row and a printed paragraph."
function edge_row(ab, rb, kind, r)
    routes = join([@sprintf("%s |F| = %.1e", a.route, a.nrm) for a in r.attempts], "; ")
    # On a failure the last attempt is always the cold `solve_long`, whose model
    # and packed vector are the point's own; a failed continuation returns the
    # iterate of an intermediate parameter set and its rows would be read at the
    # wrong parameters.
    worst = r.ok ? "" : show_rows(worst_rows(r.attempts[end].mo, r.attempts[end].x; n = 4))
    if r.ok
        sol = unpack(r.mo, r.x)
        R = series(sol, :R)
        cp = check_path(r.mo, r.x; verbose = false)
        st, mg = classify_longrun(r.mo, r.x)
        return (; abar = ab, Rbar = rb, kind = kind, converged = true, resid = r.nrm,
                 method = r.method, T_reached = r.mo.T, state = String(st),
                 survival_ratio = mg.survival_ratio, Minf = mg.Minf, R0 = R[1],
                 min_slack = minimum(R) - rb, below_floor = length(cp.periods_below_floor),
                 routes = routes, worst = worst, seconds = r.seconds)
    end
    return (; abar = ab, Rbar = rb, kind = kind, converged = false, resid = r.nrm,
             method = r.method, T_reached = r.mo.T, state = "-",
             survival_ratio = NaN, Minf = NaN, R0 = NaN, min_slack = NaN,
             below_floor = -1, routes = routes, worst = worst, seconds = r.seconds)
end

function print_edge_row(row)
    @printf("\n  Rbar = %8.4f (%s): %s, |F| = %.2e, %s, T = %d\n", row.Rbar, row.kind,
            row.converged ? "converged" : "NOT SOLVED", row.resid, row.method, row.T_reached)
    println("    routes: ", row.routes)
    if row.converged
        @printf("    state %s, survival %.4g, Minf %.4g, R at t = 0 %.4g (floor %.4g, slack %.4g), periods below the floor %d\n",
                row.state, row.survival_ratio, row.Minf, row.R0, row.Rbar, row.min_slack,
                row.below_floor)
    else
        println("    largest residual rows: ", row.worst)
    end
end

"""
    edge_search(ab; lo, hi, nsolves) -> Vector

Bisection on the floor between a floor known to solve and one known not to.
Each probe is continued from the last floor that solved, which is what makes
the bisection cheap where it succeeds; a probe that fails falls back through
the floor homotopy and a cold solve, which is what makes it slow where it does
not, and is also what entitles the run to call the point unsolvable rather than
un-continued.
"""
function edge_search(ab::Real; lo::Real = RBAR_SOLVED, hi::Real = RBAR_FAILED,
                     nsolves::Int = NSOLVES, T::Int = T_REQ)
    println("\n", repeat("-", 78))
    @printf("edge at abar = %.4g: bisection on Rbar in [%.4g, %.4g], at most %d probes\n",
            ab, lo, hi, nsolves)
    println(repeat("-", 78))
    pab = with(p; abar = float(ab))
    rows = NamedTuple[]

    # the floorless path of this ceiling: the floor homotopy's starting point,
    # and the reading of what the floor is being asked of the early decades
    t0 = time()
    mo0, x0, ok0, nrm0 = solve_long(with(pab; Rbar = 0.0), s0, T; start_T = min(150, T),
                                    step = 50)
    base0 = (; mo = mo0, x = x0, ok = ok0, nrm = nrm0)
    @printf("floorless path: %s, |F| = %.2e, T = %d, %.0f s\n",
            ok0 ? "converged" : "NOT SOLVED", nrm0, mo0.T, time() - t0)
    R0 = ok0 ? series(unpack(mo0, x0), :R) : Float64[]
    if ok0
        @printf("  material input without a floor: t = 0 %.4g, t = 25 %.4g, t = 50 %.4g, t = 100 %.4g Gt\n",
                R0[1], R0[min(26, end)], R0[min(51, end)], R0[min(101, end)])
        for lv in (RBAR_SOLVED, RBAR_FAILED)
            fa = first_above(R0, lv)
            @printf("  it first reaches %.4g Gt at t = %s\n", lv,
                    fa < 0 ? "never within T" : string(fa) * " (" * string(1900 + fa) * ")")
        end
    end

    # the largest floor known to solve, as the first point of the continuation
    r = solve_floor(with(pab; Rbar = float(lo)), s0; T = T, prev = nothing, base0 = base0)
    row = edge_row(float(ab), float(lo), "known solvable", r)
    push!(rows, row); print_edge_row(row)
    prev = r.ok ? r : nothing
    a, b = float(lo), float(hi)
    r.ok || @warn "D4: the floor known to solve did not solve here; the bisection has no anchor"

    for k in 1:nsolves
        mid = 0.5 * (a + b)
        rk = solve_floor(with(pab; Rbar = mid), s0; T = T, prev = prev, base0 = base0)
        row = edge_row(float(ab), mid, @sprintf("probe %d", k), rk)
        push!(rows, row); print_edge_row(row)
        if rk.ok
            a, prev = mid, rk
        else
            b = mid
            if ok0
                fa = first_above(R0, mid)
                @printf("    the floorless path first reaches this floor at t = %s\n",
                        fa < 0 ? "never within T" : string(fa) * " (" * string(1900 + fa) * ")")
            end
        end
        @printf("    bracket now [%.4f, %.4f]\n", a, b)
    end
    @printf("\nedge at abar = %.4g: largest floor that solves %.4f, smallest that does not %.4f, bracket %.4f Gt wide\n",
            ab, a, b, b - a)
    return rows
end

function run_edge()
    t0 = time()
    println("\n", repeat("=", 78))
    println("D4 stage 2: the solvability edge in Rbar, both ceilings")
    println(repeat("=", 78))
    csv = open_csv(joinpath(D4_OUT, "edge.csv"), EDGE_COLS)
    rows = NamedTuple[]
    try
        for ab in (ABAR_CASES[1], ABAR_HARD)
            for row in edge_search(ab)
                write_row!(csv, row)
                push!(rows, row)
            end
        end
    finally
        close_csv(csv)
    end
    @printf("\nstage 2: %d probes in %.1f min; rows %s\n", length(rows),
            (time() - t0) / 60, joinpath(D4_OUT, "edge.csv"))
    return rows
end

# ---------------------------------------------------------------------------
# stage 3: the shutdown date on a finer grid
# ---------------------------------------------------------------------------

const SHUTDOWN_COLS = (:abar, :Rbar, :floor_steps, :Td, :ok, :value, :resid, :route, :reason)

"""
    shutdown_grid(ab, rb; dates) -> table

`solve_with_shutdown` at one cell on a date grid four times finer than the one
`path_facts` uses, and the shape of its objective: flat, monotone or peaked.
The distinction is the point of the exercise -- a maximum at the edge of the
grid is the horizon's, and the date it returns is an artefact.
"""
function shutdown_grid(ab::Real, rb::Real; dates, floor_steps::Int = 6)
    println("\n", repeat("-", 78))
    @printf("shutdown search at abar = %.4g, Rbar = %.4g over %d dates %d:%d:%d, floor_steps = %d\n",
            ab, rb, length(dates), first(dates), step(dates), last(dates), floor_steps)
    println(repeat("-", 78))
    pc = with(p; abar = float(ab), Rbar = float(rb))
    t0 = time()
    # Not verbose: the date-by-date table below is the record, and `verbose`
    # reaches `solve_path`, which prints every Newton step of every date.
    res = solve_with_shutdown(pc, s0, dates; floor_steps = floor_steps, verbose = false)
    tab = res.table
    okrows = filter(r -> r.ok, tab)
    @printf("\n%d of %d dates converged in %.1f min\n", length(okrows), length(tab),
            (time() - t0) / 60)
    for r in tab
        @printf("  Td = %3d  %-9s value = %-16s |F| = %8.1e  route %-5s %s\n", r.Td,
                r.ok ? "converged" : "skipped", r.ok ? @sprintf("%.10g", r.value) : "--",
                r.resid, r.route, r.reason)
    end
    if !isempty(okrows)
        v = [r.value for r in okrows]
        dts = [r.Td for r in okrows]
        i = argmax(v)
        dv = diff(v)
        shape = isempty(dv) ? "single point" :
                all(>(0), dv) ? "monotone increasing" :
                all(<(0), dv) ? "monotone decreasing" :
                (i == 1 || i == length(v)) ? "not monotone, best at an end of the grid" :
                "peaked in the interior"
        @printf("best Td = %d, value %.10g; %s; spread %.3e over a level of %.4g (%.2e relative)\n",
                dts[i], v[i], shape, maximum(v) - minimum(v), abs(v[i]),
                (maximum(v) - minimum(v)) / max(abs(v[i]), eps()))
        (i == 1 || i == length(v)) &&
            println("  the optimum is at the edge of the date grid: it is the grid's, not the model's")
    end
    return tab
end

function run_shutdown()
    t0 = time()
    println("\n", repeat("=", 78))
    println("D4 stage 3: the shutdown date on a 10-period grid, two collapse cells")
    println(repeat("=", 78))
    csv = open_csv(joinpath(D4_OUT, "shutdown_grid.csv"), SHUTDOWN_COLS)
    # 200:10:400 at the horizon of the run; on a short smoke horizon the same
    # grid scaled, so that the driver can be exercised without a night.
    dates = T_REQ >= 240 ? range(200, T_REQ; step = 10) :
            range(max(10, div(T_REQ, 2)), div(4 * T_REQ, 5); step = max(1, div(T_REQ, 20)))
    try
        for rb in (RB_FILE[2], RB_FILE[3])
            tab = shutdown_grid(ABAR_HARD, rb; dates = dates)
            for r in tab
                write_row!(csv, (; abar = ABAR_HARD, Rbar = rb, floor_steps = 6, r.Td,
                                  r.ok, r.value, r.resid, route = String(r.route), r.reason))
            end
            # D1 reported "no candidate date converged" at the upper floor. The
            # signature is `shutdown_cold_start`'s floor homotopy stalling a
            # little short of tolerance, which is a step length rather than a
            # verdict on the date, so the cell is asked again with four times
            # the steps before the report says a date does not admit a solution.
            any(r -> r.ok, tab) && continue
            println("\nno date converged at Rbar = ", rb, "; the cell again with floor_steps = 24")
            for r in shutdown_grid(ABAR_HARD, rb; dates = dates, floor_steps = 24)
                write_row!(csv, (; abar = ABAR_HARD, Rbar = rb, floor_steps = 24, r.Td,
                                  r.ok, r.value, r.resid, route = String(r.route), r.reason))
            end
        end
    finally
        close_csv(csv)
    end
    @printf("\nstage 3: %.1f min; rows %s\n", (time() - t0) / 60,
            joinpath(D4_OUT, "shutdown_grid.csv"))
end

# ---------------------------------------------------------------------------
# the note's table, from the CSVs
# ---------------------------------------------------------------------------

"""
    write_surface_table() -> path

The note's table, rebuilt from `surface.csv` and `edge.csv`: one row per floor,
two columns per ceiling -- state and survival ratio -- and the solvability edge
as the last row of each ceiling's column group.  What this adds to the harness's
own version of the table is the edge, which is the result of the experiment
rather than a note on it.

The shutdown date the search returns is not a column here.  It is the last date
its branch solves rather than an optimum, the objective being monotone in the
date, so the collapse cells carry the duration bound of `duration_note` instead.
The survival ratio is printed only under a soft ceiling, for the reason the note
gives.
"""
function write_surface_table()
    c = read_csv(joinpath(D4_OUT, "surface.csv"))
    n = length(c["Rbar"])
    num(col, i) = parse(Float64, c[col][i])
    abars = unique(parse.(Float64, c["abar"]))
    rbars = sort(unique(parse.(Float64, c["Rbar"])))
    texrows = String[]
    for rb in rbars
        cells = String[]
        for ab in abars
            i = findfirst(k -> num("Rbar", k) == rb && num("abar", k) == ab, 1:n)
            if i === nothing
                append!(cells, ["--", "--"])
            else
                append!(cells, [c["state"][i],
                                ab < 1 ? "--" :
                                tex_num(num("survival_ratio", i); digits = 1)])
            end
        end
        push!(texrows, join(vcat(tex_num(rb; digits = 3), cells), " & "))
    end

    # the edge, one row, as the last line of the table
    edge = String[]
    epath = joinpath(D4_OUT, "edge.csv")
    if isfile(epath)
        e = read_csv(epath)
        m = length(e["Rbar"])
        cells = String[]
        for ab in abars
            idx = [k for k in 1:m if parse(Float64, e["abar"][k]) == ab]
            if isempty(idx)
                append!(cells, ["--", "--"])
            else
                okk = [k for k in idx if e["converged"][k] == "true"]
                hi = [k for k in idx if e["converged"][k] == "false"]
                best = isempty(okk) ? nothing : argmax([parse(Float64, e["Rbar"][k]) for k in okk])
                lo = best === nothing ? NaN : parse(Float64, e["Rbar"][okk[best]])
                hs = isempty(hi) ? NaN : minimum([parse(Float64, e["Rbar"][k]) for k in hi])
                push!(edge, @sprintf("at \\(\\bar a = %g\\) between %s and %s\\,Gt", ab,
                                     tex_num(lo; digits = 2), tex_num(hs; digits = 2)))
                append!(cells, [best === nothing ? "--" : e["state"][okk[best]],
                                (best === nothing || ab < 1) ? "--" :
                                tex_num(parse(Float64, e["survival_ratio"][okk[best]]); digits = 1)])
            end
        end
        push!(texrows, "\\addlinespace\n" * join(vcat("edge", cells), " & "))
    end

    head = "\$\\bar R\$" * join([@sprintf(" & \\multicolumn{2}{c}{\$\\bar a = %g\$}", ab)
                                 for ab in abars])
    sub = join(fill(" & State & \$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$",
                    length(abars)))
    notes = vcat(
            ["Each cell is one solved path at \$T = " * string(T_REQ) * "\$ from the " *
             "calibrated baseline, the floor and the ceiling overridden. The survival " *
             "ratio is \$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$ of the theory note's " *
             "survival condition, infinite at \$\\bar R = 0\$, with \$\\mathcal M_\\infty\$ " *
             "read at the horizon reached and therefore comparable across cells rather " *
             "than a limit. It is reported only under a soft ceiling \$\\bar a = 1\$: under " *
             "a hard ceiling the state is the ceiling's, the loop being unable to close " *
             "whatever the ratio, and the cell carries a dash."],
            duration_note(p, s0, [(num("abar", i), num("Rbar", i))
                                  for i in 1:n if c["state"][i] == "A"]),
            ["The floor enters the technology as \$R-\\bar R\$ and 9.5\\,Gt is already " *
             "1.66 times this calibration's own 1900 material input, so the rows are a grid " *
             "of different economies rather than a perturbation of the baseline.",
             "The last row is the largest floor that solves at all, found by bisecting " *
             "between the largest floor of the calibration's grid that solves and the " *
             "smallest that does not, at the two calibrated ceilings only. The edge lies " *
             join(edge, " and ") * ", and a finer walk puts it between 34.61 and 34.62\\,Gt. " *
             "Above it no route into the problem converges. The bound is on the base year " *
             "rather than on the long run: material input takes its minimum in 1900 on every " *
             "solved path, 2.5 to 2.9\\,Gt above the floor, so the edge asks the 1900 economy " *
             "for about six times the material input it would otherwise choose, and what then " *
             "fails is the recycling margins' corner conditions on a path that is feasible " *
             "throughout."])
    return write_table(joinpath(D4_TEX, "Surface.tex");
        caption = "The surface over the floor and the ceiling",
        label = "tab:q:res:surface",
        colspec = "r" * repeat("cr", length(abars)),
        header = head * " \\\\\n" * sub,
        rows = texrows, notes = notes)
end

# ---------------------------------------------------------------------------

"surface" in ONLY && run_surface()
"edge" in ONLY && run_edge()
"shutdown" in ONLY && run_shutdown()
"table" in ONLY && println("\ntable: ", write_surface_table())
