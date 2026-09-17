#=
The experiments of `writing/quant/quant_calibration.tex`, Section "Experiments".

One function per experiment, E1 to E5.  Each writes a CSV under
`model/output/<experiment>/` -- the row-level record, one row per grid point,
which is what a later run reads back -- and a `%% GENERATED` table under
`writing/quant/Tables/`, which is what the note inputs.  Neither file is ever
hand-edited; `writing/overleaf.py` refuses to overwrite the second.

    julia --project=. scripts/run_experiments.jl                    # all five
    julia --project=. scripts/run_experiments.jl --only=taxonomy,gatefee
    julia --project=. scripts/run_experiments.jl --calibration=../data/processed/calibration.json

Three conventions hold across all five.

*The budget.*  Every experiment takes `hours`, checked before each solve.  A
solve that has begun is never interrupted: Newton cannot be resumed and a
half-solved path is not a result.  So the budget bounds the *start* of the last
solve, the rows already finished are on disk -- each row is flushed as it is
produced -- and the table records that the run was cut short.

*Continuation.*  A grid point is solved from the previous grid point's solution
by `continuate`, which walks every parameter linearly from one to the other.
Only when that fails does the point get a cold `solve_long`.  For a positive
floor the cold route is itself a homotopy, from `Rbar = 0`, because the floor
makes the residual discontinuous and Newton cannot cross it by backtracking.

*Horizon.*  `solve_long` returns the longest horizon it reached rather than
failing, so every row carries `T_reached` beside `T_requested` and, where the
experiment asks for it, the movement of the window of interest between the two
horizons -- the diagnostic of `quant_solution.tex`, Section "Horizon".
=#

isdefined(Main, :CircularEconomy) ||
    include(joinpath(@__DIR__, "..", "src", "CircularEconomy.jl"))
using .CircularEconomy
using Printf

const OUTPUT_ROOT = normpath(joinpath(@__DIR__, "..", "output"))
const TABLE_ROOT = normpath(joinpath(@__DIR__, "..", "..", "writing", "quant", "Tables"))

# The no-recycling counterfactual of E2.  Not zero: at abar = 0 the recycling
# block degenerates and the corner conditions on varpi and KR are trivially
# slack, which is a different model rather than the same model without
# recycling.  0.01 keeps the margin alive and puts it at its corner.
const ABAR_NORECYCLING = 0.01

# ---------------------------------------------------------------------------
# the hours budget
# ---------------------------------------------------------------------------

"""
    Budget(hours)

Wall-clock budget of one experiment.  `over!` is called before each solve and
latches: once an experiment has stopped it does not restart on a later, cheaper
grid point, so the grid that was completed is a prefix of the grid that was
asked for and can be reported as one.
"""
mutable struct Budget
    started::Float64
    seconds::Float64
    stopped::Bool
end
Budget(hours::Real) = Budget(time(), 3600 * float(hours), false)

elapsed(b::Budget) = time() - b.started
remaining(b::Budget) = b.seconds - elapsed(b)
function over!(b::Budget)
    b.stopped = b.stopped || remaining(b) <= 0
    return b.stopped
end

# ---------------------------------------------------------------------------
# CSV
# ---------------------------------------------------------------------------

struct CsvFile
    io::IO
    cols::Vector{Symbol}
    path::String
end

function open_csv(path::AbstractString, cols)
    mkpath(dirname(path))
    io = open(path, "w")
    println(io, join(cols, ","))
    flush(io)
    return CsvFile(io, collect(cols), String(path))
end

csv_quote(s::AbstractString) =
    (occursin(',', s) || occursin('"', s) || occursin('\n', s)) ?
        "\"" * replace(s, "\"" => "\"\"") * "\"" : String(s)

csv_field(v::Bool) = v ? "true" : "false"
csv_field(v::Integer) = string(v)
csv_field(v::AbstractFloat) = isfinite(v) ? @sprintf("%.10g", v) : string(v)
csv_field(::Nothing) = ""
csv_field(v) = csv_quote(string(v))

"""
    write_row!(f, row)

Append one row and flush it.  The flush is the point: an overnight run that is
killed leaves every row it finished, and a row is only written once its solve
has returned.
"""
function write_row!(f::CsvFile, row::NamedTuple)
    vals = map(f.cols) do c
        haskey(row, c) || error("run_experiments: the row has no column `$c`")
        csv_field(getfield(row, c))
    end
    println(f.io, join(vals, ","))
    flush(f.io)
    return nothing
end

close_csv(f::CsvFile) = close(f.io)

# ---------------------------------------------------------------------------
# generated tex
# ---------------------------------------------------------------------------

"Escape the characters a generated label may carry into LaTeX text."
function tex_escape(s::AbstractString)
    # One pass over the characters, not a sequence of `replace` calls: a
    # sequence escapes the backslashes its own earlier rules introduced.
    buf = IOBuffer()
    for c in s
        if c == '\\'
            print(buf, "\\textbackslash{}")
        elseif c == '~'
            print(buf, "\\textasciitilde{}")
        elseif c == '^'
            print(buf, "\\textasciicircum{}")
        elseif c in ('&', '%', '$', '#', '_', '{', '}')
            print(buf, '\\', c)
        else
            print(buf, c)
        end
    end
    return String(take!(buf))
end

"""
A number for a table cell.  An infinite survival ratio is the floorless case and
prints as such; not-a-number is a quantity the row does not have and prints as a
dash, and the two must not be confused in a table about survival.
"""
function tex_num(v; digits::Int = 3)
    v === nothing && return "--"
    x = float(v)
    isnan(x) && return "--"
    isinf(x) && return x > 0 ? "\$\\infty\$" : "\$-\\infty\$"
    return string(round(x; digits = digits))
end

"A date column: `-1` means the event did not occur within the horizon."
tex_date(d::Integer) = d < 0 ? "--" : string(d)

"""
    write_table(path; caption, label, colspec, header, rows, notes)

The generated-table format of `docs_style.md` section 2: `threeparttable`, notes
in `\\footnotesize` opening "Note:", and the `%% GENERATED` banner on the first
line, which is what `writing/overleaf.py` looks for before it refuses to
overwrite the file.
"""
function write_table(path::AbstractString; caption::AbstractString,
                     label::AbstractString, colspec::AbstractString,
                     header::AbstractString, rows::Vector{String},
                     notes::Vector{String} = String[])
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "%% GENERATED by model/scripts/run_experiments.jl on ",
                Libc.strftime("%Y-%m-%d", time()))
        println(io, "%% Do not edit by hand: the file is rewritten by the next run.")
        println(io, "\\begin{table}[!htb]")
        println(io, "\\centering")
        println(io, "\\begin{threeparttable}")
        println(io, "\\caption{", caption, "}\\label{", label, "}")
        println(io, "\\begin{tabular}{", colspec, "}")
        println(io, "\\toprule")
        println(io, header, " \\\\")
        println(io, "\\midrule")
        for r in rows
            println(io, r, " \\\\")
        end
        println(io, "\\bottomrule")
        println(io, "\\end{tabular}")
        if !isempty(notes)
            println(io, "\\begin{tablenotes}[flushleft]")
            println(io, "\\footnotesize")
            println(io, "\\item[] \\textit{Note:} ", join(notes, " "))
            println(io, "\\end{tablenotes}")
        end
        println(io, "\\end{threeparttable}")
        println(io, "\\end{table}")
    end
    return path
end

"The sentence a truncated run adds to its table note."
budget_note(b::Budget, done::Int, asked::Int) =
    b.stopped ? ["The run stopped on its time budget after $done of $asked grid points."] :
                String[]

# ---------------------------------------------------------------------------
# solving one grid point
# ---------------------------------------------------------------------------

"""
    solve_case(p, s0; T, start_T, step, prev, steps) -> NamedTuple

One grid point, by continuation from `prev` where there is one.  Returns
`(mo, x, ok, nrm, method, seconds)`; `ok = false` rows are written to the CSV
like any other, because a grid point that does not solve is a result about the
calibration and not a reason to abandon the grid.
"""
function solve_case(p::Params, s0::AbstractVector; T::Int, start_T::Int = 150,
                    step::Int = 50, prev = nothing, steps::Int = 6)
    t0 = time()
    sT = min(start_T, T)
    if prev !== nothing && prev.ok
        mo = Model(p; T = prev.mo.T, s0 = s0)
        x, ok, nrm = continuate(prev.mo, mo, prev.x; steps = steps)
        ok && return (; mo, x, ok, nrm, method = "continuation", seconds = time() - t0)
    end
    if p.Rbar > 0
        # The floor is the discontinuity: solve without it and raise it.
        p0 = with(p; Rbar = 0.0)
        mo0, x0, ok0, _ = solve_long(p0, s0, T; start_T = sT, step = step)
        if ok0 || mo0.T >= sT
            mo = Model(p; T = mo0.T, s0 = s0, Gam = mo0.Gam)
            x, ok, nrm = continuate(mo0, mo, x0; steps = max(steps, 8))
            ok && return (; mo, x, ok, nrm, method = "floor homotopy",
                            seconds = time() - t0)
        end
    end
    mo, x, ok, nrm = solve_long(p, s0, T; start_T = sT, step = step)
    return (; mo, x, ok, nrm, method = "solve_long", seconds = time() - t0)
end

"Index of the first period satisfying `pred`, as a date `t`; `-1` if there is none."
function first_date(pred, v)
    i = findfirst(pred, v)
    return i === nothing ? -1 : i - 1
end

"""
    horizon_movement(p, s0, r; T_short, window) -> (T_short, dY, dC)

The first diagnostic of `quant_solution.tex`, Section "Horizon": how much the
window of interest moves when the horizon is extended.  Solves the same problem
at a shorter horizon and compares `Y` and `C` over the first `window` periods.
"""
function horizon_movement(p::Params, s0::AbstractVector, r; T_short::Int, window::Int = 101)
    T_short < 20 && return (T_short, NaN, NaN)
    mo2, x2, ok2, _ = solve_long(p, s0, T_short; start_T = min(T_short, 100), step = 50)
    ok2 || return (mo2.T, NaN, NaN)
    n = min(window, mo2.T + 1, r.mo.T + 1)
    sa, sb = unpack(mo2, x2), unpack(r.mo, r.x)
    mv(f) = begin
        a, b = series(sa, f)[1:n], series(sb, f)[1:n]
        maximum(abs.(a .- b) ./ max.(abs.(b), eps()))
    end
    return (mo2.T, mv(:Y), mv(:C))
end

"""
    shutdown_date(p, s0, r; dates, kwargs...) -> (date, status)

The optimal shutdown date on a collapse path, by the scalar grid search of
`solve_with_shutdown`.  The branch is the fragile one of `model/README.md`,
*Known limitations*, so every failure is recorded in the row rather than thrown:
a search that does not converge must not take the rest of the grid with it.
"""
function shutdown_date(p::Params, s0::AbstractVector; dates)
    try
        res = solve_with_shutdown(p, s0, dates)
        res.best === nothing && return (-1, "no candidate date converged")
        return (res.best.Td, "ok")
    catch err
        return (-1, "solve_with_shutdown failed: " * first(split(string(err), '\n')))
    end
end

"""
    welfare_parts(mo, x) -> (Uc, Vp, total, tail_ok)

Discounted utility of consumption and disutility of pollution, separately, on
exactly the convention of `welfare`: the tail beyond `T` continues consumption
at the terminal growth factor, and is dropped when it diverges.  They are needed
apart because a consumption equivalent scales one and not the other.
"""
function welfare_parts(mo::Model, x::AbstractVector)
    p, T = mo.p, mo.T
    bet = discount(p)
    sol = unpack(mo, x)
    Uc, Vp = 0.0, 0.0
    for t in 0:T
        b = sol.blocks[t+1]
        Uc += bet^t * util(p, b.C)
        Vp += bet^t * disutil(p, b.Pst)
    end
    gfac = bet * mo.Gam^(1 - p.eta)
    tail_ok = gfac < 1
    tail_ok && (Uc += bet^(T + 1) * util(p, sol.blocks[end].C * mo.Gam) / (1 - gfac))
    return (; Uc, Vp, total = Uc - Vp, tail_ok)
end

"""
    consumption_equivalent(p, target, cf) -> Float64

The proportional consumption supplement that would make the path summarised by
`cf = welfare_parts(...)` as good as welfare `target`.  Positive means the
target path is better.  The pollution disutility is additive and does not scale,
which is why `welfare_parts` splits it off.
"""
function consumption_equivalent(p::Params, target::Real, cf)
    bet = discount(p)
    if p.eta == 1
        # log utility: scaling C by s adds log(s) times the sum of the weights,
        # which is 1/(1-beta) including the tail.
        return exp((target - cf.total) * (1 - bet)) - 1
    end
    num = target + cf.Vp
    (num / cf.Uc) > 0 || return NaN
    return (num / cf.Uc)^(1 / (1 - p.eta)) - 1
end

"""
    hotelling_deviation(p, mo, x) -> (max, mean)

`Psi_{t+1}/Psi_t` against `1 + r_{t+1}`, relative.  `Psi` is the planner's
shorthand of `planner_prices` -- the marginal social value of a tonne of
material input -- and `1 + r_{t+1} = Lam_t / (beta Lam_{t+1})` is read off the
path's own marginal utility rather than assumed.  On a collapse path the theory
says the material price path is a Hotelling path, and this is that statement
measured.
"""
function hotelling_deviation(p::Params, mo::Model, x::AbstractVector)
    sol = unpack(mo, x)
    Lam = pseries(sol, :Lam)
    bet = discount(p)
    Psi = [CircularEconomy.planner_prices(p, sol.blocks[t], view(sol.costates, t, :)).Psi
           for t in 1:mo.T+1]
    devs = Float64[]
    for t in 1:mo.T
        (Psi[t] > 0 && Psi[t+1] > 0 && Lam[t+1] > 0) || continue
        Rf = Lam[t] / (bet * Lam[t+1])
        Rf > 0 || continue
        push!(devs, abs(Psi[t+1] / Psi[t] - Rf) / Rf)
    end
    isempty(devs) && return (NaN, NaN)
    return (maximum(devs), sum(devs) / length(devs))
end

"""
    path_facts(p, s0, r; shutdown_search, horizon_check, window) -> NamedTuple

Everything E1 reports about one solved path, and everything E5 reports as a
surface: the classification and its margins, the accounting checks, the
transversality and well-posedness reports, the dates, and the horizon
diagnostics.  Each of the underlying functions is the one `run_baseline.jl` and
`run_sufficiency.jl` use; nothing is recomputed here.
"""
function path_facts(p::Params, s0::AbstractVector, r;
                    shutdown_search::Bool = false, horizon_check::Bool = false,
                    window::Int = 101)
    if !r.ok
        return (; state = "-", Minf = NaN, residence = NaN, survival_ratio = NaN,
                 closes = false, leak_sum = NaN, welfare = NaN,
                 ledger_rel_error = NaN, cumN_over_bound = NaN,
                 cum_leak_over_budget = NaN, periods_below_floor = -1,
                 market_planner_gap = NaN, tvc_capital_factor = NaN, tvc_g = NaN,
                 tvc_nu_path = NaN, wellposed_fail = "not solved",
                 gatefee_sign_change = -1, material_era_end = -1,
                 extraction_end = -1, shutdown = -1, shutdown_status = "not solved",
                 horizon_T_short = -1, horizon_dY = NaN, horizon_dC = NaN)
    end
    mo, x = r.mo, r.x
    sol = unpack(mo, x)
    cp = check_path(mo, x; verbose = false)
    st, mg = classify_longrun(mo, x)
    tv = tvc_report(mo, x; verbose = false)
    bad = [w.name for w in tv.wellposed if !w.holds]

    R, N = series(sol, :R), series(sol, :N)
    tauW = pseries(sol, :tauW)
    N0 = max(N[1], 1.0)
    sd, sdstat = -1, "not a collapse path"
    if shutdown_search && st === :A
        dates = unique(round.(Int, range(max(10, div(mo.T, 5)), div(4 * mo.T, 5); length = 7)))
        sd, sdstat = shutdown_date(p, s0; dates = dates)
    elseif shutdown_search
        sdstat = "not a collapse path"
    else
        sdstat = "not searched"
    end
    hT, hY, hC = horizon_check ?
        horizon_movement(p, s0, r; T_short = div(mo.T, 2), window = window) :
        (-1, NaN, NaN)

    return (; state = String(st), Minf = mg.Minf, residence = mg.residence,
             survival_ratio = mg.survival_ratio, closes = mg.closes,
             leak_sum = mg.leak_sum, welfare = welfare(mo, x),
             ledger_rel_error = cp.ledger_rel_error,
             cumN_over_bound = cp.cumulative_N / cp.cumulative_N_bound,
             cum_leak_over_budget = cp.cumulative_leakage / cp.material_budget,
             periods_below_floor = length(cp.periods_below_floor),
             market_planner_gap = compare_residuals(mo, x),
             tvc_capital_factor = tv.capital_tvc_factor, tvc_g = tv.g,
             tvc_nu_path = tv.nu_path,
             wellposed_fail = isempty(bad) ? "" : join(bad, "; "),
             gatefee_sign_change = first_date(<(0), tauW),
             material_era_end = first_date(v -> v <= p.Rbar + 1e-9, R),
             extraction_end = first_date(v -> v <= 1e-8 * N0, N),
             shutdown = sd, shutdown_status = sdstat,
             horizon_T_short = hT, horizon_dY = hY, horizon_dC = hC)
end

# ---------------------------------------------------------------------------
# E1: where is the economy in the taxonomy?
# ---------------------------------------------------------------------------

const TAXONOMY_COLS = (:case, :abar, :Rbar, :T_requested, :T_reached, :converged,
                       :resid, :method, :state, :Minf, :residence, :survival_ratio,
                       :closes, :leak_sum, :shutdown, :shutdown_status,
                       :gatefee_sign_change, :material_era_end, :extraction_end,
                       :welfare, :ledger_rel_error, :cumN_over_bound,
                       :cum_leak_over_budget, :periods_below_floor,
                       :market_planner_gap, :tvc_capital_factor, :tvc_g,
                       :tvc_nu_path, :wellposed_fail, :horizon_T_short,
                       :horizon_dY, :horizon_dC, :seconds)

"The name of a case, and the parameter overrides it carries."
case_name(c::NamedTuple, i::Int) = haskey(c, :name) ? String(c.name) : "case $i"
case_overrides(c::NamedTuple) = Base.structdiff(c, NamedTuple{(:name,)})

"""
    taxonomy_cases(cases) -> Vector{NamedTuple}

The grid of `cases` in the calibration file, as the case list E1 runs: the
ceiling cases crossed with the floor grid, which are the two axes the taxonomy
turns on (`quant_calibration.tex`, Section "The two parameters that history
cannot identify").
"""
function taxonomy_cases(cases)
    abars = isempty(cases.abar) ? [1.0] : cases.abar
    Rbars = isempty(cases.Rbar_grid) ? [0.0] : cases.Rbar_grid
    out = NamedTuple[]
    for ab in abars, rb in Rbars
        push!(out, (; name = @sprintf("abar %.3g, Rbar %.3g", ab, rb), abar = ab, Rbar = rb))
    end
    return out
end

"""
    experiment_taxonomy(p, s0; cases, T, hours, ...) -> NamedTuple

E1.  One row per case: the long-run state, the retained endowment, the residence
time, the survival ratio, the shutdown date where the state is collapse, the
date the gate fee changes sign, and the horizon diagnostics.
"""
function experiment_taxonomy(p::Params, s0::AbstractVector;
                             cases = [(; name = "baseline")],
                             T::Int = 300, start_T::Int = 150, step::Int = 50,
                             hours::Real = 3.0,
                             outdir::AbstractString = OUTPUT_ROOT,
                             texdir::AbstractString = TABLE_ROOT,
                             shutdown_search::Bool = true,
                             horizon_check::Bool = true, window::Int = 101,
                             verbose::Bool = true)
    b = Budget(hours)
    csv = open_csv(joinpath(outdir, "taxonomy", "taxonomy.csv"), TAXONOMY_COLS)
    rows = NamedTuple[]
    texrows = String[]
    prev = nothing
    try
        for (i, c) in enumerate(cases)
            over!(b) && break
            nm = case_name(c, i)
            pc = with(p; case_overrides(c)...)
            r = solve_case(pc, s0; T = T, start_T = start_T, step = step, prev = prev)
            f = path_facts(pc, s0, r; shutdown_search = shutdown_search,
                           horizon_check = horizon_check, window = window)
            row = (; case = nm, abar = pc.abar, Rbar = pc.Rbar, T_requested = T,
                    T_reached = r.mo.T, converged = r.ok, resid = r.nrm,
                    method = r.method, seconds = r.seconds, f...)
            write_row!(csv, row)
            push!(rows, row)
            r.ok && (prev = r)
            verbose && @printf("E1 %-28s %-3s  T = %3d  surv = %7s  %s\n", nm, f.state,
                               r.mo.T, tex_num(f.survival_ratio), r.method)
            push!(texrows, join((tex_escape(nm), f.state, tex_num(f.Minf; digits = 2),
                                 tex_num(f.residence; digits = 1),
                                 tex_num(f.survival_ratio; digits = 2),
                                 tex_date(f.shutdown), tex_date(f.gatefee_sign_change),
                                 string(r.mo.T)), " & "))
        end
    finally
        close_csv(csv)
    end
    tex = write_table(joinpath(texdir, "Taxonomy.tex");
        caption = "Where the economy lands in the taxonomy",
        label = "tab:q:res:taxonomy", colspec = "lcrrrrrr",
        header = "Case & State & \$\\mathcal M_\\infty\$ & \$\\mathcal T\$ & " *
                 "\$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$ & \$T^{\\dagger}\$ & " *
                 "Gate fee \$<0\$ & \$T\$ reached",
        rows = texrows,
        notes = vcat(["States are those of the theory note's taxonomy: A collapse, " *
                      "B balanced dematerialization, C perpetual circular growth. " *
                      "\$\\mathcal T\$ is the residence time \$1/\\mu+\\sigma_\\infty/\\delta\$ " *
                      "and the survival ratio is infinite without a floor. " *
                      "\$T^{\\dagger}\$ is the optimal shutdown date, searched only where the " *
                      "state is collapse. Dates are periods since the base year; a dash is an " *
                      "event that does not occur within the horizon reached."],
                     budget_note(b, length(rows), length(cases))))
    return (; rows, csv = csv.path, tex, stopped = b.stopped)
end

# ---------------------------------------------------------------------------
# E2: how much does circularity buy?
# ---------------------------------------------------------------------------

const CIRCULARITY_COLS = (:abar, :xi, :T_reached, :converged, :resid, :method,
                          :state, :welfare, :welfare_norecycling, :ce_gain,
                          :era_length, :era_length_shutdown, :shutdown_status,
                          :cum_Xi, :cum_Xi_norecycling, :Xi_avoided, :Minf,
                          :survival_ratio, :hotelling_max_dev, :hotelling_mean_dev,
                          :seconds)

"Cumulative emissions along a solved path."
cumulative_Xi(mo, x) = sum(b.Xi for b in unpack(mo, x).blocks)

"""
    experiment_circularity(p, s0; abar_grid, xi_grid, ...) -> NamedTuple

E2.  For each ceiling and tail rate: the welfare gain over the no-recycling
counterfactual in consumption equivalents, the length of the material era where
it ends, and cumulative emissions.  Where the cell collapses, the era length is
also taken from the shutdown-date search, and the Hotelling check is reported.
"""
function experiment_circularity(p::Params, s0::AbstractVector;
                                abar_grid = [1.0, 0.85], xi_grid = [1.5, 3.0, 6.0],
                                T::Int = 300, start_T::Int = 150, step::Int = 50,
                                hours::Real = 6.0,
                                outdir::AbstractString = OUTPUT_ROOT,
                                texdir::AbstractString = TABLE_ROOT,
                                shutdown_search::Bool = true, verbose::Bool = true)
    b = Budget(hours)
    csv = open_csv(joinpath(outdir, "circularity", "circularity.csv"), CIRCULARITY_COLS)
    rows = NamedTuple[]
    grid = [(ab, xi) for ab in abar_grid for xi in xi_grid]
    # The counterfactual depends on the tail rate only, the ceiling being
    # replaced, so it is solved once per xi and reused down the ceiling column.
    cf_cache = Dict{Float64,Any}()
    prev = nothing
    try
        for (ab, xi) in grid
            over!(b) && break
            pc = with(p; abar = ab, xi = xi)
            r = solve_case(pc, s0; T = T, start_T = start_T, step = step, prev = prev)
            r.ok && (prev = r)
            cf = get!(cf_cache, float(xi)) do
                pcf = with(pc; abar = ABAR_NORECYCLING)
                rc = solve_case(pcf, s0; T = T, start_T = start_T, step = step,
                                prev = r.ok ? r : nothing, steps = 8)
                rc.ok ? (; r = rc, parts = welfare_parts(rc.mo, rc.x),
                          Xi = cumulative_Xi(rc.mo, rc.x)) : nothing
            end
            st = r.ok ? String(classify_longrun(r.mo, r.x)[1]) : "-"
            W = r.ok ? welfare(r.mo, r.x) : NaN
            ce = (r.ok && cf !== nothing) ?
                 consumption_equivalent(pc, W, cf.parts) : NaN
            era = r.ok ? first_date(v -> v <= pc.Rbar + 1e-9, series(unpack(r.mo, r.x), :R)) : -1
            esd, estat = -1, r.ok ? "not searched" : "not solved"
            if r.ok && shutdown_search && st == "A" && !over!(b)
                dates = unique(round.(Int, range(max(10, div(r.mo.T, 5)),
                                                 div(4 * r.mo.T, 5); length = 7)))
                esd, estat = shutdown_date(pc, s0; dates = dates)
            elseif r.ok && shutdown_search
                estat = "not a collapse path"
            end
            hmax, hmean = r.ok ? hotelling_deviation(pc, r.mo, r.x) : (NaN, NaN)
            Xi = r.ok ? cumulative_Xi(r.mo, r.x) : NaN
            mg = r.ok ? classify_longrun(r.mo, r.x)[2] : nothing
            row = (; abar = ab, xi = xi, T_reached = r.mo.T, converged = r.ok,
                    resid = r.nrm, method = r.method, state = st, welfare = W,
                    welfare_norecycling = cf === nothing ? NaN : cf.parts.total,
                    ce_gain = ce, era_length = era, era_length_shutdown = esd,
                    shutdown_status = estat, cum_Xi = Xi,
                    cum_Xi_norecycling = cf === nothing ? NaN : cf.Xi,
                    Xi_avoided = cf === nothing ? NaN : cf.Xi - Xi,
                    Minf = mg === nothing ? NaN : mg.Minf,
                    survival_ratio = mg === nothing ? NaN : mg.survival_ratio,
                    hotelling_max_dev = hmax, hotelling_mean_dev = hmean,
                    seconds = r.seconds)
            write_row!(csv, row)
            push!(rows, row)
            verbose && @printf("E2 abar = %.3g, xi = %.3g  %-2s  CE = %8s  Xi avoided = %8s\n",
                               ab, xi, st, tex_num(ce; digits = 4),
                               tex_num(row.Xi_avoided; digits = 3))
        end
    finally
        close_csv(csv)
    end
    texrows = [join((tex_num(r.abar; digits = 2), tex_num(r.xi; digits = 2), r.state,
                     tex_num(100 * r.ce_gain; digits = 2),
                     tex_date(r.era_length), tex_date(r.era_length_shutdown),
                     tex_num(r.cum_Xi; digits = 2), tex_num(r.Xi_avoided; digits = 2),
                     tex_num(r.hotelling_max_dev; digits = 4)), " & ") for r in rows]
    tex = write_table(joinpath(texdir, "Circularity.tex");
        caption = "What circularity buys, by ceiling and tail rate",
        label = "tab:q:res:circularity", colspec = "rrcrrrrrr",
        header = "\$\\bar a\$ & \$\\xi\$ & State & CE gain (\\%) & Era ends & " *
                 "\$T^{\\dagger}\$ & \$\\sum\\Xi\$ & \$\\Xi\$ avoided & Hotelling dev.",
        rows = texrows,
        notes = vcat(["The no-recycling counterfactual sets \$\\bar a = " *
                      string(ABAR_NORECYCLING) * "\$, so the recycling margin is at its " *
                      "corner rather than absent from the problem, and is solved at the " *
                      "same \$\\xi\$. The consumption-equivalent gain is the proportional " *
                      "consumption supplement that would make the counterfactual as good " *
                      "as the cell. `Era ends' is the first date at which material input " *
                      "reaches the floor; \$T^{\\dagger}\$ is the optimal shutdown date, " *
                      "searched only in the collapse cells. The Hotelling deviation is the " *
                      "largest relative gap between \$\\Psi_{t+1}/\\Psi_t\$ and \$1+r_{t+1}\$ " *
                      "along the path."],
                     budget_note(b, length(rows), length(grid))))
    return (; rows, csv = csv.path, tex, stopped = b.stopped)
end

# ---------------------------------------------------------------------------
# E3: the cost of the missing instruments
# ---------------------------------------------------------------------------

const INSTRUMENT_COLS = (:kind, :label, :phiW, :phiz, :phiP, :phiX, :T_reached,
                         :converged, :resid, :method, :welfare, :ce_vs_planner,
                         :state, :Minf, :residence, :survival_ratio,
                         :gatefee_sign_change, :cum_leak, :seconds)

"""
    instrument_corners() -> Vector{NTuple{4,Float64}}

The 16 corners of the policy space, planner first and then in order of how many
instruments are missing, so that continuation from the planner corner is walking
the shortest distance it can at each step.
"""
function instrument_corners()
    all16 = [(w, z, pp, xx) for w in (1.0, 0.0), z in (1.0, 0.0),
                                pp in (1.0, 0.0), xx in (1.0, 0.0)]
    return sort(vec(all16); by = c -> (count(iszero, c), c))
end

"""
    experiment_instruments(p, s0; corners, dial_steps, ...) -> NamedTuple

E3.  The 16 corners of `(phiW, phiz, phiP, phiX)` and the four single-dial paths
from the planner corner, each in consumption equivalents against the planner and
each classified.  A corner whose state differs from the planner's is the result
the experiment exists for: a policy failure that moves the economy across the
survival margin rather than costing a few percent of consumption.
"""
function experiment_instruments(p::Params, s0::AbstractVector;
                                corners = instrument_corners(), dial_steps::Real = 0.25,
                                dials = (:phiW, :phiz, :phiP, :phiX),
                                T::Int = 300, start_T::Int = 150, step::Int = 50,
                                hours::Real = 6.0,
                                outdir::AbstractString = OUTPUT_ROOT,
                                texdir::AbstractString = TABLE_ROOT,
                                verbose::Bool = true)
    dial_steps > 0 || error("experiment_instruments: dial_steps must be positive")
    b = Budget(hours)
    csv = open_csv(joinpath(outdir, "instruments", "instruments.csv"), INSTRUMENT_COLS)
    rows = NamedTuple[]
    dialvals = collect(1.0:-float(dial_steps):0.0)
    points = Any[]
    for c in corners
        push!(points, ("corner", @sprintf("(%g,%g,%g,%g)", c[1], c[2], c[3], c[4]), c))
    end
    order = (:phiW, :phiz, :phiP, :phiX)
    for d in dials, v in dialvals
        i = findfirst(==(Symbol(d)), order)
        i === nothing && error("experiment_instruments: `$d` is not a policy dial")
        c = ntuple(j -> j == i ? float(v) : 1.0, 4)
        push!(points, (String(d), @sprintf("%s = %.2f", d, v), c))
    end

    # The planner corner is the anchor: it is the best-conditioned point of the
    # policy space, every other point is continued from it, and the consumption
    # equivalents are measured against it.
    base = solve_case(with(p; phiW = 1.0, phiz = 1.0, phiP = 1.0, phiX = 1.0), s0;
                      T = T, start_T = start_T, step = step)
    base.ok || @warn "experiment_instruments: the planner corner did not solve; " *
                     "every point is solved cold and the equivalents are missing"
    try
        for (kind, label, c) in points
            over!(b) && break
            pc = with(p; phiW = c[1], phiz = c[2], phiP = c[3], phiX = c[4])
            r = (kind == "corner" && c == (1.0, 1.0, 1.0, 1.0) && base.ok) ? base :
                solve_case(pc, s0; T = T, start_T = start_T, step = step,
                           prev = base.ok ? base : nothing)
            st, mg = r.ok ? classify_longrun(r.mo, r.x) : (:-, nothing)
            W = r.ok ? welfare(r.mo, r.x) : NaN
            ce = (r.ok && base.ok) ?
                 consumption_equivalent(pc, welfare(base.mo, base.x),
                                        welfare_parts(r.mo, r.x)) : NaN
            sol = r.ok ? unpack(r.mo, r.x) : nothing
            row = (; kind, label, phiW = c[1], phiz = c[2], phiP = c[3], phiX = c[4],
                    T_reached = r.mo.T, converged = r.ok, resid = r.nrm,
                    method = r.method, welfare = W, ce_vs_planner = ce,
                    state = String(st), Minf = mg === nothing ? NaN : mg.Minf,
                    residence = mg === nothing ? NaN : mg.residence,
                    survival_ratio = mg === nothing ? NaN : mg.survival_ratio,
                    gatefee_sign_change = sol === nothing ? -1 :
                        first_date(<(0), pseries(sol, :tauW)),
                    cum_leak = sol === nothing ? NaN :
                        sum((1 - bb.a * bb.vw) * bb.H for bb in sol.blocks),
                    seconds = r.seconds)
            write_row!(csv, row)
            push!(rows, row)
            verbose && @printf("E3 %-8s %-18s %-2s  CE = %9s\n", kind, label,
                               row.state, tex_num(100 * ce; digits = 3))
        end
    finally
        close_csv(csv)
    end
    cr = filter(r -> r.kind == "corner", rows)
    texrows = [join((tex_escape(r.label), r.state, tex_num(100 * r.ce_vs_planner; digits = 3),
                     tex_num(r.survival_ratio; digits = 2), tex_num(r.Minf; digits = 2),
                     tex_date(r.gatefee_sign_change)), " & ") for r in cr]
    tex = write_table(joinpath(texdir, "Instruments.tex");
        caption = "The cost of the missing instruments, at the corners of the policy space",
        label = "tab:q:res:instruments", colspec = "lcrrrr",
        header = "\$(\\phi^W,\\phi^z,\\phi^P,\\phi^X)\$ & State & CE cost (\\%) & " *
                 "\$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$ & \$\\mathcal M_\\infty\$ & " *
                 "Gate fee \$<0\$",
        rows = texrows,
        notes = vcat(["Each corner sets its dial to one, the Pigouvian level, or to zero. " *
                      "The consumption-equivalent cost is the proportional consumption " *
                      "supplement that would make the corner as good as the planner corner " *
                      "\$(1,1,1,1)\$, which is therefore zero by construction. The four " *
                      "single-dial paths between the corners are in the run's CSV and not " *
                      "here."],
                     budget_note(b, length(rows), length(points))))
    return (; rows, csv = csv.path, tex, stopped = b.stopped)
end

# ---------------------------------------------------------------------------
# E4: property rights over the waste stock
# ---------------------------------------------------------------------------

const GATEFEE_PATH_COLS = (:setting, :t, :tauW, :z, :zz, :zeta_star, :pWst, :Wst,
                           :R, :a, :varpi, :Xi)
const GATEFEE_COLS = (:setting, :phiW, :phiz, :phiP, :phiX, :T_reached, :converged,
                      :resid, :method, :sign_change, :tauW_0, :tauW_end,
                      :tauW_min, :seconds)

"""
    experiment_gatefee(p, s0; ...) -> NamedTuple

E4.  The gate fee path under `phiW = 1`, at the planner corner and with the
other three dials at laissez-faire, and the date it changes sign: the model's
prediction of when waste stops being a disposal problem and becomes a resource.
Two CSVs, the per-period path and the summary.
"""
function experiment_gatefee(p::Params, s0::AbstractVector;
                            T::Int = 300, start_T::Int = 150, step::Int = 50,
                            hours::Real = 2.0,
                            outdir::AbstractString = OUTPUT_ROOT,
                            texdir::AbstractString = TABLE_ROOT,
                            verbose::Bool = true)
    b = Budget(hours)
    settings = (("planner corner", (1.0, 1.0, 1.0, 1.0)),
                ("property rights only", (1.0, 0.0, 0.0, 0.0)))
    pcsv = open_csv(joinpath(outdir, "gatefee", "gatefee_paths.csv"), GATEFEE_PATH_COLS)
    scsv = open_csv(joinpath(outdir, "gatefee", "gatefee_summary.csv"), GATEFEE_COLS)
    rows = NamedTuple[]
    base = nothing
    try
        for (nm, c) in settings
            over!(b) && break
            pc = with(p; phiW = c[1], phiz = c[2], phiP = c[3], phiX = c[4])
            r = solve_case(pc, s0; T = T, start_T = start_T, step = step, prev = base)
            r.ok && base === nothing && (base = r)
            sgn, t0, tend, tmin = -1, NaN, NaN, NaN
            if r.ok
                sol = unpack(r.mo, r.x)
                tauW = pseries(sol, :tauW)
                for t in 0:r.mo.T
                    pr, bb = sol.prices[t+1], sol.blocks[t+1]
                    write_row!(pcsv, (; setting = nm, t = t, tauW = pr.tauW, z = pr.z,
                                       zz = pr.zz, zeta_star = pr.zeta_star,
                                       pWst = sol.costates[t+1, IPW], Wst = bb.Wst,
                                       R = bb.R, a = bb.a, varpi = bb.vw, Xi = bb.Xi))
                end
                sgn, t0, tend, tmin = first_date(<(0), tauW), tauW[1], tauW[end],
                                      minimum(tauW)
            end
            row = (; setting = nm, phiW = c[1], phiz = c[2], phiP = c[3], phiX = c[4],
                    T_reached = r.mo.T, converged = r.ok, resid = r.nrm,
                    method = r.method, sign_change = sgn, tauW_0 = t0,
                    tauW_end = tend, tauW_min = tmin, seconds = r.seconds)
            write_row!(scsv, row)
            push!(rows, row)
            verbose && @printf("E4 %-22s sign change at %s, tauW: %s -> %s\n", nm,
                               tex_date(sgn), tex_num(t0; digits = 4),
                               tex_num(tend; digits = 4))
        end
    finally
        close_csv(pcsv)
        close_csv(scsv)
    end
    texrows = [join((tex_escape(r.setting),
                     @sprintf("(%g,%g,%g,%g)", r.phiW, r.phiz, r.phiP, r.phiX),
                     tex_num(r.tauW_0; digits = 4), tex_num(r.tauW_end; digits = 4),
                     tex_date(r.sign_change), string(r.T_reached)), " & ") for r in rows]
    tex = write_table(joinpath(texdir, "GateFee.tex");
        caption = "The gate fee and the date waste becomes a resource",
        label = "tab:q:res:gatefee", colspec = "llrrrr",
        header = "Setting & \$(\\phi^W,\\phi^z,\\phi^P,\\phi^X)\$ & \$\\tau^{\\mathcal W}_0\$ & " *
                 "\$\\tau^{\\mathcal W}_T\$ & Sign change & \$T\$ reached",
        rows = texrows,
        notes = vcat(["The gate fee is \$\\tau^{\\mathcal W} = -\\phi^W p^{\\mathcal W}\$, a " *
                      "price and not a tax rate: at \$\\phi^W = 1\$ it is the market in which " *
                      "the waste stock is priced at all. The sign change is the first date " *
                      "at which it turns negative, so that holding waste is worth paying for. " *
                      "The per-period paths are in the run's CSV."],
                     budget_note(b, length(rows), length(settings))))
    return (; rows, csv = scsv.path, paths = pcsv.path, tex, stopped = b.stopped)
end

# ---------------------------------------------------------------------------
# E5: the surface over the two parameters history cannot pin down
# ---------------------------------------------------------------------------

const SURFACE_COLS = TAXONOMY_COLS

"""
    experiment_surface(p, s0; Rbar_grid, abar_cases, ...) -> NamedTuple

E5.  E1's headline numbers over the floor grid, once per ceiling case.  The
floor grid is walked from its smallest value upward, each point continued from
the last, because the floor is the parameter that makes the problem hard and
the continuation in it is the only reliable route into a binding one.
"""
function experiment_surface(p::Params, s0::AbstractVector;
                            Rbar_grid = [0.0, 0.1, 0.2, 0.3, 0.4],
                            abar_cases = [1.0, 0.85],
                            T::Int = 300, start_T::Int = 150, step::Int = 50,
                            hours::Real = 8.0,
                            outdir::AbstractString = OUTPUT_ROOT,
                            texdir::AbstractString = TABLE_ROOT,
                            shutdown_search::Bool = false, verbose::Bool = true)
    b = Budget(hours)
    csv = open_csv(joinpath(outdir, "surface", "surface.csv"), SURFACE_COLS)
    rows = NamedTuple[]
    grid = sort(collect(float.(Rbar_grid)))
    npoints = length(grid) * length(abar_cases)
    try
        for ab in abar_cases
            prev = nothing
            for rb in grid
                over!(b) && break
                pc = with(p; abar = float(ab), Rbar = rb)
                r = solve_case(pc, s0; T = T, start_T = start_T, step = step, prev = prev)
                f = path_facts(pc, s0, r; shutdown_search = shutdown_search,
                               horizon_check = false)
                row = (; case = @sprintf("abar %.3g, Rbar %.3g", ab, rb), abar = pc.abar,
                        Rbar = pc.Rbar, T_requested = T, T_reached = r.mo.T,
                        converged = r.ok, resid = r.nrm, method = r.method,
                        seconds = r.seconds, f...)
                write_row!(csv, row)
                push!(rows, row)
                r.ok && (prev = r)
                verbose && @printf("E5 abar = %.3g, Rbar = %.3g  %-2s  surv = %8s\n",
                                   ab, rb, f.state, tex_num(f.survival_ratio))
            end
            b.stopped && break
        end
    finally
        close_csv(csv)
    end
    # The table is the surface: one row per floor, one column pair per ceiling.
    texrows = String[]
    for rb in grid
        cells = String[]
        for ab in abar_cases
            i = findfirst(r -> r.Rbar == rb && r.abar == float(ab), rows)
            if i === nothing
                push!(cells, "--", "--")
            else
                push!(cells, rows[i].state, tex_num(rows[i].survival_ratio; digits = 2))
            end
        end
        push!(texrows, join(vcat(tex_num(rb; digits = 3), cells), " & "))
    end
    head = "\$\\bar R\$" * join([@sprintf(" & \\multicolumn{2}{c}{\$\\bar a = %g\$}", ab)
                                 for ab in abar_cases])
    sub = join(fill(" & State & \$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$",
                    length(abar_cases)))
    tex = write_table(joinpath(texdir, "Surface.tex");
        caption = "The surface over the floor and the ceiling",
        label = "tab:q:res:surface",
        colspec = "r" * repeat("cr", length(abar_cases)),
        header = head * " \\\\\n" * sub,
        rows = texrows,
        notes = vcat(["Each cell is one solved path. The survival ratio is " *
                      "\$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$ of the theory note's " *
                      "survival condition, infinite at \$\\bar R = 0\$, and the state is " *
                      "the taxonomy's. A dash is a grid point the run did not reach."],
                     budget_note(b, length(rows), npoints)))
    return (; rows, csv = csv.path, tex, stopped = b.stopped)
end

# ---------------------------------------------------------------------------
# the driver
# ---------------------------------------------------------------------------

"Command-line arguments as a dictionary of `--key=value`."
function parse_args(args)
    d = Dict{String,String}()
    for a in args
        m = match(r"^--([A-Za-z_]+)=(.*)$", a)
        m === nothing && error("run_experiments: cannot read the argument `$a`; " *
                               "arguments are --key=value")
        d[m.captures[1]] = String(m.captures[2])
    end
    return d
end

"""
    run_all(; calibration, only, T, hours) -> Dict

Runs the experiments named in `only` (all five by default).  `hours` is the
budget for the whole run and is split equally across the experiments selected,
so that a night that is too short returns part of every experiment rather than
all of the first one.
"""
function run_all(; calibration = nothing, only = ["taxonomy", "circularity",
                                                  "instruments", "gatefee", "surface"],
                 T::Int = 300, hours::Real = 12.0, verbose::Bool = true)
    if calibration === nothing
        @warn "run_experiments: no calibration file given, so the illustrative set of " *
              "src/calibration.jl is used. Nothing from this run is a result."
        p, s0 = baseline_params(), baseline_states()
        cases = (; abar = Float64[], Rbar_grid = Float64[], xi_range = Float64[],
                  muN_range = Float64[])
    else
        d = read_calibration(calibration)
        p, s0, cases = calibrated_params(d), calibrated_states(d), calibration_cases(d)
    end
    each = hours / max(length(only), 1)
    abars = isempty(cases.abar) ? [1.0, 0.85] : cases.abar
    xis = isempty(cases.xi_range) ? [p.xi] : collect(range(cases.xi_range[1],
                                                          cases.xi_range[end]; length = 3))
    rbars = isempty(cases.Rbar_grid) ? [0.0, 0.1, 0.2, 0.3, 0.4] : cases.Rbar_grid
    out = Dict{String,Any}()
    for name in only
        if name == "taxonomy"
            out[name] = experiment_taxonomy(p, s0; cases = taxonomy_cases(cases),
                                            T = T, hours = each, verbose = verbose)
        elseif name == "circularity"
            out[name] = experiment_circularity(p, s0; abar_grid = abars, xi_grid = xis,
                                               T = T, hours = each, verbose = verbose)
        elseif name == "instruments"
            out[name] = experiment_instruments(p, s0; T = T, hours = each, verbose = verbose)
        elseif name == "gatefee"
            out[name] = experiment_gatefee(p, s0; T = T, hours = each, verbose = verbose)
        elseif name == "surface"
            out[name] = experiment_surface(p, s0; Rbar_grid = rbars, abar_cases = abars,
                                           T = T, hours = each, verbose = verbose)
        else
            error("run_experiments: there is no experiment called `$name`")
        end
    end
    return out
end

if abspath(PROGRAM_FILE) == @__FILE__
    a = parse_args(ARGS)
    run_all(; calibration = get(a, "calibration", nothing),
            only = split(get(a, "only", "taxonomy,circularity,instruments,gatefee,surface"), ','),
            T = parse(Int, get(a, "T", "300")),
            hours = parse(Float64, get(a, "hours", "12")))
end
