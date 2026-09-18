#=
Task E2 of `notes/plan_calibration_experiments.md`: the two sensitivities the
review asks for (`notes/review_calibration.md`, R1 and R14), through the
harness of `run_experiments.jl`.

    julia --project=. scripts/run_e2_sensitivity.jl [T] [--no-floor]
    julia --project=. scripts/run_e2_sensitivity.jl --only=table   # rebuild the tables from the CSVs

Every welfare number of E2 and E3 is decided by the discount rate and the
damage coefficient, and the review's disposition is to report two alternative
settings beside the calibrated one rather than refit: (a) the damage
coefficient at the Howard and Sterner damage function with the high AR6
transient response, the two readings `b5_pollution_block.csv` already carries;
(b) the DICE-2023 preference pair; (c) both.  In each setting the run solves the
planner corner of the baseline (`abar = 1`, `Rbar = 0`) at `T = 400` and reads
off it what E1 and E4 report: the state, the retained endowment, the date the
gate fee turns negative and its terminal value.  It then continues in the
policy dials to the laissez-faire corner (0,0,0,0) and the no-emission-tax
corner (1,1,0,1), the two corners E3 turns on, and in the ceiling to the
no-recycling counterfactual of E2, so that the consumption equivalents of all
three experiments are on one table under all four settings.  With the floor
switched on it also continues to `Rbar = 23.756`, the largest floor of the
calibration's grid that solves, for the survival ratio.

The baseline solve is also where the fit of the calibrated path to the century
is read (review R7): the model's own history against `series.csv` at four
dates, written as a second table.  The calibration reads its parameters one at
a time from shares and rates, so the path is a test of it and not a fit.

Rows go to `output/sensitivity/sensitivity.csv` and `fit.csv`; the tables the
note inputs are `writing/quant/Tables/Sensitivity.tex` and `Fit.tex`.
=#

include(joinpath(@__DIR__, "run_experiments.jl"))
using Printf

const POSARGS = filter(a -> !startswith(a, "--"), ARGS)
const T_REQ = isempty(POSARGS) ? 400 : parse(Int, first(POSARGS))
const WITH_FLOOR = !("--no-floor" in ARGS)
const TABLE_ONLY = "--only=table" in ARGS
const DATA = normpath(joinpath(@__DIR__, "..", "..", "data"))
const OUT = joinpath(OUTPUT_ROOT, "sensitivity")
const HOURS = 2.0

# The damage function of Howard and Sterner (2017) as DICE-2023 reports it,
# 9 percent of output at 3 degrees against its own 3.1: Barrage and Nordhaus
# (2024), section 4.6, recorded in `notes/data/pollution.md`.  The one literal
# in this file; the DICE coefficient and the transient responses are read from
# the block file.
const PI2_HOWARD_STERNER = 0.01

# DICE-2023's preference pair, Barrage and Nordhaus (2024): the review's R1.
const RHO_DICE = 0.015
const ETA_DICE = 1.45

# The floor at which the survival ratio is read: the largest of the
# calibration's grid that solves (`d1_baseline_report.md`).
floor_of(cases) = length(cases.Rbar_grid) >= 3 ? cases.Rbar_grid[3] : 0.0

"""
    kappa_multiplier() -> (mult, detail)

The factor by which the Howard and Sterner damage coefficient and the high
transient response multiply the marginal loss per gigatonne of CO2 at the
block's reference stock, on the marginal-loss formula of
`data/build/b5_pollution_block.py`, `2 pi2 tcre^2 P / (1 - pi2 (tcre P)^2)`.
The reference stock is held at the block's own, the stock the best-estimate
response puts at three degrees, which is the anchor every row of the block's
`kappa` table shares.  Everything but the Howard and Sterner coefficient is
read from the block file.
"""
function kappa_multiplier()
    c = read_csv(joinpath(DATA, "interim", "b5_pollution_block.csv"))
    val(name) = begin
        i = findfirst(==(name), c["series"])
        i === nothing && error("run_e2_sensitivity: no row `$name` in b5_pollution_block.csv")
        parse(Float64, c["value"][i])
    end
    pi2 = val("damage_pi2")
    tb, th = val("damage_tcre_best"), val("damage_tcre_high")
    P = val("kappa_reference_stock_at_3degC_under_best_tcre")
    km(a, t) = 2 * a * t^2 * P / (1 - a * (t * P)^2)
    mult = km(PI2_HOWARD_STERNER, th) / km(pi2, tb)
    return (mult, (; pi2, pi2_hs = PI2_HOWARD_STERNER, tcre_best = tb, tcre_high = th, Pref = P,
                     hs_alone = km(PI2_HOWARD_STERNER, tb) / km(pi2, tb),
                     tcre_alone = km(pi2, th) / km(pi2, tb)))
end

"A gigatonne total for a table cell: rounded to the tonne, without a decimal point."
tex_int(v) = isfinite(float(v)) ? string(round(Int, float(v))) : tex_num(v)

const SENS_COLS = (:setting, :point, :kappa, :rho, :eta, :phiW, :phiz, :phiP, :phiX,
                   :abar, :Rbar, :T_requested, :T_reached, :converged, :resid, :method,
                   :state, :Minf, :residence, :survival_ratio, :closes, :leak_sum,
                   :welfare, :ce_vs_planner, :ce_gain, :gatefee_sign_change, :tauW_0,
                   :tauW_end, :cum_Xi, :tvc_capital_factor, :wellposed_fail, :seconds)

"The names `wellposed_report` gives the conditions that fail at the circular rate."
function wellposed_failures(p::Params)
    out = wellposed_report(p; verbose = false)
    return join([w.name for w in out if !w.holds], "; ")
end

"""
    point_row(setting, point, pc, r; W_planner, cf) -> NamedTuple

One solved path as a row: E1's facts, the gate fee at both ends, and the
consumption equivalent against the setting's planner corner (`W_planner`) or,
for the planner corner itself, against its no-recycling counterfactual (`cf`).
"""
function point_row(setting::AbstractString, point::AbstractString, pc::Params, r;
                   W_planner = NaN, cf = nothing)
    f = path_facts(pc, s0, r; shutdown_search = false, horizon_check = false)
    t0, tT, Xi, ce, gain = NaN, NaN, NaN, NaN, NaN
    if r.ok
        sol = unpack(r.mo, r.x)
        tauW = pseries(sol, :tauW)
        t0, tT = tauW[1], tauW[end]
        Xi = cumulative_Xi(r.mo, r.x)
        isfinite(W_planner) &&
            (ce = consumption_equivalent(pc, W_planner, welfare_parts(r.mo, r.x)))
        cf === nothing || (gain = consumption_equivalent(pc, f.welfare, cf))
    end
    return (; setting, point, kappa = pc.kappa, rho = pc.rho, eta = pc.eta,
             phiW = pc.phiW, phiz = pc.phiz, phiP = pc.phiP, phiX = pc.phiX,
             abar = pc.abar, Rbar = pc.Rbar, T_requested = T_REQ, T_reached = r.mo.T,
             converged = r.ok, resid = r.nrm, method = r.method, state = f.state,
             Minf = f.Minf, residence = f.residence, survival_ratio = f.survival_ratio,
             closes = f.closes, leak_sum = f.leak_sum, welfare = f.welfare,
             ce_vs_planner = ce, ce_gain = gain, gatefee_sign_change = f.gatefee_sign_change,
             tauW_0 = t0, tauW_end = tT, cum_Xi = Xi,
             tvc_capital_factor = f.tvc_capital_factor,
             wellposed_fail = wellposed_failures(pc), seconds = r.seconds)
end

"""
    solve_point(pk, routes; T) -> NamedTuple

Continuation along each `(prev, steps, name)` route in turn, then the harness's
cold route.  A corner that the short walk from its own setting's planner corner
does not reach is usually reached by a longer walk, or from the same corner of
the calibrated setting, walking the damage coefficient or the preferences with
the dials held; the cold route is last because on this calibration it is the
slowest and the least likely to arrive.
"""
function solve_point(pk::Params, routes; T::Int)
    t0 = time()
    for (prev, steps, name) in routes
        (prev === nothing || !prev.ok) && continue
        mo = Model(pk; T = prev.mo.T, s0 = s0)
        x, ok, nrm = continuate(prev.mo, mo, prev.x; steps = steps)
        ok && return (; mo, x, ok, nrm, method = name, seconds = time() - t0)
    end
    return solve_case(pk, s0; T = T)
end

"""
    truncate_path(r, Tnew) -> NamedTuple

A solved path cut to a shorter horizon and re-solved there.  The unknown vector
is period blocks of controls, costates and next states, then a terminal block
of controls and costates, so the first `Tnew` blocks and the head of block
`Tnew` are a warm start for the shorter problem; only the terminal closure
differs.  Used when a corner's cold route stalls short of the requested
horizon: the comparison is then made at the horizon the corner reached, with
the planner corner re-solved there rather than read at a longer one.
"""
function truncate_path(r, Tnew::Int)
    t0 = time()
    NB, NE = CircularEconomy.NBLK, CircularEconomy.NEND
    mo = Model(r.mo.p; T = Tnew, s0 = r.mo.s0, Gam = r.mo.Gam)
    x0 = vcat(r.x[1:NB*Tnew], r.x[NB*Tnew+1:NB*Tnew+NE])
    x, ok, nrm = solve_path(mo, x0)
    ok && return (; mo, x, ok, nrm, method = "truncated to T = $Tnew", seconds = time() - t0)
    # the terminal closure at Tnew is not the one the longer path carries there,
    # and the warm start does not always survive it; then the cold route
    r2 = solve_case(r.mo.p, r.mo.s0; T = Tnew)
    return (; r2.mo, r2.x, r2.ok, r2.nrm, method = "re-solved at T = $Tnew", seconds = time() - t0)
end

# A corner whose cold route converged at a shorter horizon is compared there if
# the horizon is at least this long; below it the welfare tail decides the
# comparison (`experiment_instruments`' docstring) and the row stays unsolved.
const T_SHORT_MIN = 300

# ---------------------------------------------------------------------------
# the fit of the baseline path to the century
# ---------------------------------------------------------------------------

const FIT_YEARS = (1900, 1950, 2000, 2015)
const FIT_ROWS = (("Y", :Y, "\$Y\$, output", "trillion \\\$"),
                  ("K", :K, "\$K\$, capital", "trillion \\\$"),
                  ("R", :R, "\$R\$, material input", "Gt"),
                  ("N", :N, "\$N\$, extraction", "Gt"),
                  ("RR", :RR, "\$R^R\$, secondary input", "Gt"),
                  ("W", :W, "\$W\$, waste flow", "Gt"),
                  ("P", :Pst, "\$P\$, pollution stock", "Gt"))
const FIT_COLS = (:series, :year, :model, :data)

"The observed series of `series.csv` at one year, or NaN where the file has no row."
function observed(c, name::AbstractString, year::Int)
    for i in eachindex(c["series"])
        c["series"][i] == name && parse(Int, c["year"][i]) == year &&
            return parse(Float64, c["value"][i])
    end
    return NaN
end

"The model's path against the data at the four dates, as rows."
function fit_rows(r)
    c = read_csv(joinpath(DATA, "processed", "series.csv"))
    sol = unpack(r.mo, r.x)
    rows = NamedTuple[]
    for (name, fld, _, _) in FIT_ROWS, yr in FIT_YEARS
        t = yr - 1900
        m = t <= r.mo.T ? getfield(sol.blocks[t+1], fld) : NaN
        push!(rows, (; series = name, year = yr, model = m, data = observed(c, name, yr)))
    end
    return rows
end

function write_fit_table(rows; texdir::AbstractString = TABLE_ROOT)
    texrows = String[]
    for (name, _, label, unit) in FIT_ROWS
        cells = String[label, unit]
        for yr in FIT_YEARS
            i = findfirst(x -> x.series == name && x.year == yr, rows)
            m = i === nothing ? NaN : rows[i].model
            d = i === nothing ? NaN : rows[i].data
            push!(cells, tex_num(m; digits = 1), tex_num(d; digits = 1))
        end
        push!(texrows, join(cells, " & "))
    end
    head = "Series & Unit" * join([@sprintf(" & \\multicolumn{2}{c}{%d}", yr) for yr in FIT_YEARS])
    sub = " & " * join(fill(" & Model & Data", length(FIT_YEARS)))
    return write_table(joinpath(texdir, "Fit.tex");
        caption = "The calibrated path against the century it was calibrated on",
        label = "tab:q:res:fit", colspec = "ll" * repeat("rr", length(FIT_YEARS)),
        header = head * " \\\\\n" * sub,
        rows = texrows,
        notes = ["The model column is the planner corner of the calibrated baseline " *
                 "solved from 1900 at \$T = " * string(T_REQ) * "\$; the data column is " *
                 "the model-facing series of the data appendix. Goods are in trillions of " *
                 "2011 international dollars, material in gigatonnes. The pollution stock " *
                 "is in gigatonnes of material at the bridge composition of the data " *
                 "appendix, which for the data column is the 2000 to 2015 composition at " *
                 "every date, while the model's initial stock is converted at the 1900 " *
                 "composition; the two 1900 entries differ by that conversion alone. " *
                 "The capital stock before 1950 is a perpetual inventory and the material " *
                 "series are the material flow accounts, whose outflow the data column's " *
                 "waste flow is; the model's waste flow also carries unused extraction, " *
                 "which the accounts do not count. Nothing in this table was fitted: " *
                 "every parameter is read from a share, a rate or a single year, and the " *
                 "path is what those parameters imply."])
end

# ---------------------------------------------------------------------------
# the sensitivity table
# ---------------------------------------------------------------------------

"""
    write_sensitivity_table(rows, settings, mult, detail, Rbar_floor; texdir)

One column per setting, one row per quantity: the three parameters, the
per-period weight the objective puts on the future, E1's facts at the planner
corner, E4's gate fee, and the three consumption equivalents.  Transposed
relative to the other generated tables because the settings are four and the
quantities twelve.
"""
function write_sensitivity_table(rows, settings, mult, detail, Rbar_floor;
                                 texdir::AbstractString = TABLE_ROOT)
    find_row(setting, point) = begin
        i = findfirst(r -> r.setting == setting && r.point == point, rows)
        i === nothing ? nothing : rows[i]
    end
    keys_ = [s.key for s in settings]
    planners = [find_row(k, "planner") for k in keys_]
    cell(f) = join([r === nothing ? "--" : f(r) for r in planners], " & ")
    ccell(point, f) = join([begin
                                r = find_row(k, point)
                                r === nothing ? "--" : f(r)
                            end for k in keys_], " & ")
    span = "\\multicolumn{" * string(length(settings) + 1) * "}{l}{\\textit{"
    # the collapse ranking condition at the preference pair, read off the run
    # rather than asserted: the note says what the report found
    pref = find_row("preferences", "planner")
    ranking_fails = pref !== nothing && occursin("cake-eating", pref.wellposed_fail)
    # the gate fee's sign date, with the harness's reading of a fee that is
    # numerically zero at the base year (`write_gatefee_table`)
    gdate(r) = (r.phiW != 0 && isfinite(r.tauW_0) && isfinite(r.tauW_end) &&
                abs(r.tauW_0) <= ZERO_TOL * max(abs(r.tauW_end), 1.0)) ? "--" :
               tex_date(r.gatefee_sign_change)
    texrows = String[
        span * "The setting}}",
        "\$\\kappa\$, per Gt & " * cell(r -> tex_sci(r.kappa; digits = 2)),
        "\$\\rho\$ & " * cell(r -> tex_num(r.rho; digits = 4)),
        "\$\\eta\$ & " * cell(r -> tex_num(r.eta; digits = 3)),
        "\$\\beta e^{(1-\\eta)g}\$, weight per period & " *
            cell(r -> tex_num(r.tvc_capital_factor; digits = 4)),
        "well-posedness condition failing & " *
            cell(r -> isempty(r.wellposed_fail) ? "none" : tex_escape(r.wellposed_fail)),
        "\\addlinespace\n" * span * "The planner corner, \$\\bar a = 1\$, \$\\bar R = 0\$}}",
        "State & " * cell(r -> r.state),
        "\$\\mathcal M_\\infty\$, Gt & " * cell(r -> tex_int(r.Minf)),
        "\$\\sum\\Xi\$, Gt & " * cell(r -> tex_int(r.cum_Xi)),
        "Gate fee \$<0\$ from & " * cell(gdate),
        "\$\\tau^{\\mathcal W}_T\$ & " * cell(r -> tex_num(r.tauW_end; digits = 2)),
    ]
    if WITH_FLOOR
        push!(texrows, "\$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$ at \$\\bar R = " *
                       tex_num(Rbar_floor; digits = 3) * "\$ & " *
                       ccell("floor", r -> tex_num(r.survival_ratio; digits = 1)))
    end
    append!(texrows, [
        "\\addlinespace\n" * span * "Consumption equivalents, percent}}",
        "gain of recycling over \$\\bar a = " * string(ABAR_NORECYCLING) * "\$ & " *
            cell(r -> tex_sci(100 * r.ce_gain; digits = 2)),
        "cost of laissez-faire \$(0,0,0,0)\$ & " *
            ccell("laissez-faire", r -> tex_sci(100 * r.ce_vs_planner; digits = 2)),
        "cost of the missing emission tax \$(1,1,0,1)\$ & " *
            ccell("no emission tax", r -> tex_sci(100 * r.ce_vs_planner; digits = 2)),
        "\$\\sum\\Xi\$ under laissez-faire, Gt & " *
            ccell("laissez-faire", r -> tex_int(r.cum_Xi)),
        "\$T\$ of the laissez-faire comparison & " *
            ccell("laissez-faire", r -> r.converged ? string(r.T_reached) : "--"),
    ])
    short = [k for k in keys_ if (rr = find_row(k, "laissez-faire")) !== nothing &&
                                 rr.converged && rr.T_reached < T_REQ]
    header = "Quantity" * join([" & " * s.label for s in settings])
    return write_table(joinpath(texdir, "Sensitivity.tex");
        caption = "The welfare numbers under the alternative damage and preference settings",
        label = "tab:q:res:sensitivity", colspec = "l" * repeat("r", length(settings)),
        header = header,
        rows = texrows,
        notes = ["The calibrated column is the baseline of the data appendix. The damage " *
                 "column multiplies \$\\kappa\$ by " * tex_num(mult; digits = 2) * ", the " *
                 "factor by which the damage function of Howard and Sterner (2017), " *
                 "\$\\pi_2 = " * string(PI2_HOWARD_STERNER) * "\$ as DICE-2023 reports it, " *
                 "and the high end of the AR6 transient response, " *
                 tex_num(detail.tcre_high; digits = 5) * " against " *
                 tex_num(detail.tcre_best; digits = 5) * " degrees per GtCO\$_2\$, together " *
                 "raise the marginal loss per gigatonne at the reference stock of the data " *
                 "appendix (" * tex_num(detail.hs_alone; digits = 2) * " from the damage " *
                 "function alone, " * tex_num(detail.tcre_alone; digits = 2) * " from the " *
                 "response alone). The preference column is the DICE-2023 pair of Barrage " *
                 "and Nordhaus (2024), \$\\rho = " * string(RHO_DICE) * "\$ and \$\\eta = " *
                 string(ETA_DICE) * "\$" *
                 (ranking_fails ?
                  "; at that pair the collapse ranking condition " *
                  "\$(1-\\delta)^{1-\\eta} < 1+\\rho\$ fails at the calibrated depreciation " *
                  "rate, so a shutdown path has no finite value there and collapse cells " *
                  "could not be ranked; the paths on this table are state C and do not " *
                  "use it. " : ". ") *
                 "The weight per period is the asymptotic factor of the transversality " *
                 "report at the circular growth rate. Every path is the planner corner of " *
                 "the baseline continued in the parameter, the dials or the ceiling, at " *
                 "\$T = " * string(T_REQ) * "\$; \$\\mathcal M_\\infty\$ is read at the " *
                 "horizon reached. The consumption equivalents are the proportional " *
                 "consumption supplements of the E2 and E3 tables, measured within each " *
                 "column against that column's own planner corner, which is why a " *
                 "column and not a row is the comparison the table is built for. " *
                 (isempty(short) ? "" :
                  "The laissez-faire corner does not solve to the requested horizon at the " *
                  "larger damage coefficient: continuation in \$\\kappa\$ from the calibrated " *
                  "corner stalls in the treated-share complementarity rows between six and " *
                  "six and a half times the calibrated value, and the cold route converges " *
                  "at the shorter horizon the last row gives; in those columns the corner " *
                  "and the planner corner are compared at that horizon, the planner corner " *
                  "re-solved there, and the cost is read at a horizon at which the welfare " *
                  "tail is a little larger. ") *
                 "The gate fee is in trillions of dollars per gigatonne, which is " *
                 "thousands of dollars per tonne."])
end

# ---------------------------------------------------------------------------
# the run
# ---------------------------------------------------------------------------

d = read_calibration(joinpath(DATA, "processed", "calibration.json"))
p0, s0, cases = calibrated_params(d), calibrated_states(d), calibration_cases(d)
mult, detail = kappa_multiplier()
Rbar_floor = floor_of(cases)

settings = [(key = "calibrated", label = "Calibrated", kappa = p0.kappa, rho = p0.rho, eta = p0.eta),
            (key = "damages", label = "Damages \$\\times$(round(mult; digits = 2))\$",
             kappa = mult * p0.kappa, rho = p0.rho, eta = p0.eta),
            (key = "preferences", label = "DICE-2023 preferences",
             kappa = p0.kappa, rho = RHO_DICE, eta = ETA_DICE),
            (key = "both", label = "Both", kappa = mult * p0.kappa, rho = RHO_DICE, eta = ETA_DICE)]

@printf("kappa multiplier %.4f (Howard-Sterner alone %.3f, high TCRE alone %.3f); pi2 %.6g -> %.3g, TCRE %.5g -> %.5g at P_ref = %.1f GtCO2\n",
        mult, detail.hs_alone, detail.tcre_alone, detail.pi2, detail.pi2_hs,
        detail.tcre_best, detail.tcre_high, detail.Pref)

if TABLE_ONLY
    c = read_csv(joinpath(OUT, "sensitivity.csv"))
    n = length(c["setting"])
    num(col, i) = parse(Float64, c[col][i])
    rows = [(; setting = c["setting"][i], point = c["point"][i], kappa = num("kappa", i),
              rho = num("rho", i), eta = num("eta", i), phiW = num("phiW", i),
              converged = c["converged"][i] == "true",
              T_reached = parse(Int, c["T_reached"][i]),
              state = c["state"][i], Minf = num("Minf", i),
              survival_ratio = num("survival_ratio", i), cum_Xi = num("cum_Xi", i),
              ce_vs_planner = num("ce_vs_planner", i), ce_gain = num("ce_gain", i),
              gatefee_sign_change = parse(Int, c["gatefee_sign_change"][i]),
              tauW_0 = num("tauW_0", i), tauW_end = num("tauW_end", i),
              tvc_capital_factor = num("tvc_capital_factor", i),
              wellposed_fail = c["wellposed_fail"][i]) for i in 1:n]
    println("rebuilt ", write_sensitivity_table(rows, settings, mult, detail, Rbar_floor))
    cf = read_csv(joinpath(OUT, "fit.csv"))
    frows = [(; series = cf["series"][i], year = parse(Int, cf["year"][i]),
               model = parse(Float64, cf["model"][i]), data = parse(Float64, cf["data"][i]))
             for i in eachindex(cf["series"])]
    println("rebuilt ", write_fit_table(frows))
    exit()
end

b = Budget(HOURS)
csv = open_csv(joinpath(OUT, "sensitivity.csv"), SENS_COLS)
rows = NamedTuple[]
base = nothing
# the calibrated setting's paths by point, the second route into every other setting
ref = Dict{String,Any}()
try
    for s in settings
        over!(b) && (println("budget exhausted before ", s.key); break)
        println("\n", repeat("=", 78), "\n", s.key, ": kappa = ", s.kappa, ", rho = ", s.rho,
                ", eta = ", s.eta, "\n", repeat("=", 78))
        pc = with(p0; kappa = s.kappa, rho = s.rho, eta = s.eta, abar = 1.0, Rbar = 0.0,
                  phiW = 1.0, phiz = 1.0, phiP = 1.0, phiX = 1.0)
        println("wellposed at the circular rate:")
        wellposed_report(pc)
        r = base === nothing ? solve_case(pc, s0; T = T_REQ) :
            solve_point(pc, [(base, 6, "continuation"), (base, 24, "continuation, 24 steps")];
                        T = T_REQ)
        @printf("planner corner: %s, |F| = %.2e, T = %d, %.0f s\n", r.method, r.nrm, r.mo.T,
                r.seconds)
        if !r.ok
            row = point_row(s.key, "planner", pc, r)
            write_row!(csv, row); push!(rows, row)
            continue
        end
        base === nothing && (global base = r)
        s.key == "calibrated" && (ref["planner"] = r)
        Wp = welfare(r.mo, r.x)

        # E2: the no-recycling counterfactual at the setting
        pcf = with(pc; abar = ABAR_NORECYCLING)
        rc = solve_point(pcf, [(r, 8, "continuation"),
                               (get(ref, "no recycling", nothing), 12,
                                "continuation from the calibrated counterfactual"),
                               (r, 24, "continuation, 24 steps")]; T = T_REQ)
        s.key == "calibrated" && (ref["no recycling"] = rc)
        @printf("no-recycling counterfactual: %s, |F| = %.2e, %.0f s\n", rc.method, rc.nrm,
                rc.seconds)
        cf = rc.ok ? welfare_parts(rc.mo, rc.x) : nothing
        row = point_row(s.key, "planner", pc, r; cf = cf)
        write_row!(csv, row); push!(rows, row)
        @printf("  state %s  Minf %.5g  gate fee < 0 from %d  tauW %.3e -> %.4f  tvc factor %.4f  CE gain of recycling %.3e%%  wellposed fails: [%s]\n",
                row.state, row.Minf, row.gatefee_sign_change, row.tauW_0, row.tauW_end,
                row.tvc_capital_factor, 100 * row.ce_gain, row.wellposed_fail)
        if rc.ok
            rowc = point_row(s.key, "no recycling", pcf, rc; W_planner = Wp)
            write_row!(csv, rowc); push!(rows, rowc)
        end

        # E3: the two corners, continued in the dials from the planner corner
        for (nm, c) in (("laissez-faire", (0.0, 0.0, 0.0, 0.0)),
                        ("no emission tax", (1.0, 1.0, 0.0, 1.0)))
            over!(b) && break
            pk = with(pc; phiW = c[1], phiz = c[2], phiP = c[3], phiX = c[4])
            rk = solve_point(pk, [(r, 6, "continuation"),
                                  (get(ref, nm, nothing), 12,
                                   "continuation from the calibrated corner"),
                                  (r, 24, "continuation, 24 steps")]; T = T_REQ)
            s.key == "calibrated" && (ref[nm] = rk)
            Wk = Wp
            if !rk.ok && rk.nrm < 1e-8 && T_SHORT_MIN <= rk.mo.T < T_REQ
                # the cold route converged at a shorter horizon: compare there
                rp = truncate_path(r, rk.mo.T)
                @printf("  %-16s reached T = %d only; planner corner re-solved there: %s, |F| = %.2e, %.0f s\n",
                        nm, rk.mo.T, rp.ok, rp.nrm, rp.seconds)
                if rp.ok
                    Wk = welfare(rp.mo, rp.x)
                    rk = (; rk.mo, rk.x, ok = true, rk.nrm,
                           method = "solve_long, compared at T = $(rk.mo.T)",
                           seconds = rk.seconds + rp.seconds)
                end
            end
            rowk = point_row(s.key, nm, pk, rk; W_planner = Wk)
            write_row!(csv, rowk); push!(rows, rowk)
            @printf("  %-16s %s |F| = %.2e  state %s  Minf %.5g  CE cost %.3e%%  sum Xi %.5g  gate fee < 0 from %d  %.0f s\n", nm, rk.method, rk.nrm,
                    rowk.state, rowk.Minf, 100 * rowk.ce_vs_planner, rowk.cum_Xi,
                    rowk.gatefee_sign_change, rk.seconds)
        end

        # E5: the survival ratio at the largest floor that solves
        if WITH_FLOOR && Rbar_floor > 0 && !over!(b)
            pf = with(pc; Rbar = Rbar_floor)
            rf = solve_point(pf, [(r, 12, "continuation"),
                                  (get(ref, "floor", nothing), 12,
                                   "continuation from the calibrated floor"),
                                  (r, 24, "continuation, 24 steps")]; T = T_REQ)
            s.key == "calibrated" && (ref["floor"] = rf)
            rowf = point_row(s.key, "floor", pf, rf)
            write_row!(csv, rowf); push!(rows, rowf)
            @printf("  floor %g: %s |F| = %.2e  state %s  survival %.4g  gate fee < 0 from %d  %.0f s\n",
                    Rbar_floor, rf.method, rf.nrm, rowf.state, rowf.survival_ratio,
                    rowf.gatefee_sign_change, rf.seconds)
        end
    end
finally
    close_csv(csv)
end
println("\nrows: ", csv.path)
println("table: ", write_sensitivity_table(rows, settings, mult, detail, Rbar_floor))

if base !== nothing
    frows = fit_rows(base)
    fcsv = open_csv(joinpath(OUT, "fit.csv"), FIT_COLS)
    for fr in frows
        write_row!(fcsv, fr)
    end
    close_csv(fcsv)
    println("fit rows: ", fcsv.path)
    println("fit table: ", write_fit_table(frows))
    for fr in frows
        @printf("  %-3s %d  model %10.4g  data %10.4g\n", fr.series, fr.year, fr.model, fr.data)
    end
end
b.stopped && println("the run stopped on its budget after ", length(rows), " rows")
