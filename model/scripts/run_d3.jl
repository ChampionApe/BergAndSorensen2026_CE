#=
Task D3 of `notes/plan_calibration_experiments.md`: E3
(`experiment_instruments`) on the calibrated baseline, through the harness of
`run_experiments.jl`.

    julia --project=. scripts/run_d3.jl [T]
    julia --project=. scripts/run_d3.jl --table-only   # rebuild the table from the CSVs

E3 is run twice, once without a floor and once at the largest floor of the
calibration file's grid that D1 could solve.  The reason is the question E3
exists to ask.  The theory note's Section "Laissez-faire and the survival
margin" says the instruments can change the long-run *state* only in the
soft-ceiling cell with a floor, where the destination is decided by
`M_inf > Rbar * T` rather than by a primitive; without a floor the survival
ratio is infinite by construction and no missing instrument can cross it.  So
the floorless run measures the cost of the three failures in consumption, and
the floor run is the only one in which the headline of the theory can appear at
all.

Each run's rows go to `output/instruments/instruments_<floor>.csv` and its own
generated table to `output/instruments/Instruments_<floor>.tex`; the table the
note inputs, `writing/quant/Tables/Instruments.tex`, is written here from both
runs as two panels, because one table that the reader can compare across the
floor is the point.

Beyond the harness's columns the run reports two things the CSV cannot hold.
*The headline.*  For every corner whose long-run state differs from the
planner's at the same floor, and for the laissez-faire corner whether it differs
or not, the path is re-solved and classified period by period -- the classifier
applied to the path truncated at `t`, which is exactly how `classify_longrun`
reads a path -- so that the date the corner leaves the planner's state is a date
and not an inference from the endpoint.  Laissez-faire is probed either way
because "the missing instruments do not move this economy across the survival
margin" is a claim about every date, and the negative result is worth the same
evidence the positive one would need.
*The ordering check.*  The planner corner is the maximum of the problem, so a
negative consumption-equivalent cost is a horizon or solver diagnostic and never
a result (the warning in `experiment_instruments`' docstring).  Any point that
shows one is re-solved and its residual, horizon, terminal growth factor and
welfare tail are printed, which is where such a number comes from.
=#

include(joinpath(@__DIR__, "run_experiments.jl"))
using Printf

const POSARGS = filter(a -> !startswith(a, "--"), ARGS)
const T_REQ = length(POSARGS) >= 1 ? parse(Int, POSARGS[1]) : 400
# Rebuild the note's table from the CSVs of an earlier run, which is what the
# harness means by the CSV being the row-level record a later run reads back:
# the wording of a table note is not worth twenty-five minutes of Newton.
const TABLE_ONLY = "--table-only" in ARGS
const HOURS = 6.0
const DATA = normpath(joinpath(@__DIR__, "..", "..", "data", "processed"))
const D3_OUT = joinpath(OUTPUT_ROOT, "instruments")
const D3_TMP = joinpath(OUTPUT_ROOT, "d3tmp")

# A corner is worse than the planner by construction; anything below this is
# treated as a diagnostic rather than as a number.  It is loose on purpose: the
# consumption equivalents are quoted to 1e-5 and the solves that produce them
# converge to |F| ~ 1e-10, so a violation worth reporting is larger than this.
const CE_TOL = 1e-9

"Move a file the harness wrote under its own name to the name D3 keeps it under."
function relocate(src::AbstractString, dst::AbstractString)
    mkpath(dirname(dst))
    isfile(dst) && rm(dst)
    mv(src, dst)
    return dst
end

"A floor as a file-name tag: `Rbar0`, `Rbar23p756`."
floor_tag(rb::Real) = "Rbar" * replace(@sprintf("%g", rb), "." => "p")

# ---------------------------------------------------------------------------
# the classification, period by period
# ---------------------------------------------------------------------------

"""
    state_path(p, mo, x) -> (states, ratios)

The long-run classification evaluated at every date: `classify_longrun` applied
to the path truncated at `t`, which is the same reading of a path the endpoint
version makes (`Minf = M^K + W`, `sigma` and `A = a'(x)` from the block).  It is
a diagnostic of where the path's own margins stand at `t`, not a forecast made
at `t`; the date the sequence changes value for good is the date the path leaves
the state its endpoint is not going to reach.
"""
function state_path(p::Params, mo::Model, x::AbstractVector)
    sol = unpack(mo, x)
    st, ratio = String[], Float64[]
    for t in 0:mo.T
        b = sol.blocks[t+1]
        Minf = sol.states[t+1, IMK] + sol.states[t+1, IWS]
        s, m = classify_longrun(p; Minf = Minf, sigma = b.sigma, A = b.ap)
        push!(st, String(s))
        push!(ratio, m.survival_ratio)
    end
    return (st, ratio)
end

"""
    divergence_date(a, b) -> Int

The first date of the final run of dates on which the two classification
sequences differ; `-1` if they end in agreement.  Taken from the end rather than
the start deliberately: an early period in which the two differ and then agree
again is the transition, not the destination.
"""
function divergence_date(a::Vector{String}, b::Vector{String})
    n = min(length(a), length(b))
    d = -1
    for t in n-1:-1:0
        a[t+1] == b[t+1] && break
        d = t
    end
    return d
end

"""
    settle_date(v, pred) -> Int

The first date from which `pred` holds at every later date: the date the path
reaches the reading it keeps.  Applied to the classification it is the date the
economy enters the state it ends in, and applied to the survival ratio the date
`M_inf > Rbar * T` starts holding -- the margin of eq. (sp:lr:little) crossed,
which is the event the experiment is looking for.
"""
function settle_date(v, pred)
    n = length(v)
    n == 0 && return -1
    d = n - 1
    for i in n-1:-1:1
        pred(v[i]) || break
        d = i - 1
    end
    return pred(v[end]) ? d : -1
end

"The dials that are off at a corner, as the theory note's names for them."
const DIAL_NAMES = ("phiW, property rights over the waste stock",
                    "phiz, the material-content charge",
                    "phiP, the emission tax",
                    "phiX, the discovery tax")
dials_off(c) = [DIAL_NAMES[i] for i in 1:4 if c[i] == 0.0]

"""
    inspect_point(p, s0, base, sp_base, c, label; T)

Everything a headline corner or an ordering violation has to be reported with:
the route and residual of its own solve, the horizon reached, the terminal
growth factor and whether the welfare tail converges at it, the split of welfare
into consumption and pollution, and the classification against the planner's,
period by period.  The point is re-solved rather than read from the CSV because
none of this survives a row.
"""
function inspect_point(p::Params, s0::AbstractVector, base, sp_base::Vector{String},
                       ratio_base::Vector{Float64}, c, label::AbstractString; T::Int)
    pc = with(p; phiW = c[1], phiz = c[2], phiP = c[3], phiX = c[4])
    r = solve_case(pc, s0; T = T, prev = base.ok ? base : nothing)
    println("\n-- ", label, " --")
    if !r.ok
        @printf("   did not solve: |F| = %.3e by %s at T = %d\n", r.nrm, r.method, r.mo.T)
        return nothing
    end
    bet = discount(pc)
    gfac = bet * r.mo.Gam^(1 - pc.eta)
    wp = welfare_parts(r.mo, r.x)
    wb = welfare_parts(base.mo, base.x)
    ce = consumption_equivalent(pc, welfare(base.mo, base.x), wp)
    sol = unpack(r.mo, r.x)
    st, ratio = state_path(pc, r.mo, r.x)
    dd = divergence_date(sp_base, st)
    @printf("   %s, |F| = %.3e, T = %d, Gam = %.6f, tail factor = %.6f (%s)\n",
            r.method, r.nrm, r.mo.T, r.mo.Gam, gfac,
            wp.tail_ok ? "tail summed" : "tail dropped: it diverges")
    @printf("   welfare %.6f = Uc %.6f - Vp %.6f; planner %.6f = Uc %.6f - Vp %.6f; CE %.6f%%\n",
            wp.total, wp.Uc, wp.Vp, wb.total, wb.Uc, wb.Vp, 100 * ce)
    @printf("   terminal C = %.6g (planner %.6g), C_T/C_T^planner = %.6f\n",
            sol.blocks[end].C, unpack(base.mo, base.x).blocks[end].C,
            sol.blocks[end].C / unpack(base.mo, base.x).blocks[end].C)
    cp = check_path(r.mo, r.x; verbose = false)
    @printf("   ledger %.2e, cumulative N / bound %.4f, leakage / budget %.4f, periods below floor %d\n",
            cp.ledger_rel_error, cp.cumulative_N / cp.cumulative_N_bound,
            cp.cumulative_leakage / cp.material_budget, length(cp.periods_below_floor))
    @printf("   state at T: %s (planner %s); leaves the planner's state at t = %s\n",
            st[end], isempty(sp_base) ? "?" : sp_base[end],
            dd < 0 ? "never" : "$dd (year $(1900 + dd))")
    if isfinite(ratio[end])
        mi = argmin(ratio)
        @printf("   survival ratio: min %.6g at t = %d, %.6g at T; planner min %.6g, %.6g at T\n",
                ratio[mi], mi - 1, ratio[end],
                isempty(ratio_base) ? NaN : minimum(ratio_base),
                isempty(ratio_base) ? NaN : ratio_base[end])
        @printf("   survival margin crossed at t = %d (planner t = %d)\n",
                settle_date(ratio, >(1)),
                isempty(ratio_base) ? -1 : settle_date(ratio_base, >(1)))
    end
    @printf("   enters its final state at t = %d (planner t = %d)\n",
            settle_date(st, ==(st[end])),
            isempty(sp_base) ? -1 : settle_date(sp_base, ==(sp_base[end])))
    dd_all = [t for t in 0:min(length(st), length(sp_base))-1 if st[t+1] != sp_base[t+1]]
    @printf("   dates at which the two classifications differ: %s\n",
            isempty(dd_all) ? "none" :
            "$(length(dd_all)), t = $(first(dd_all)) to $(last(dd_all))")
    for t in 0:25:r.mo.T
        @printf("      t = %3d  state %s (planner %s)  survival %.6g\n",
                t, st[t+1], t + 1 <= length(sp_base) ? sp_base[t+1] : "?", ratio[t+1])
    end
    return (; r, ce, divergence = dd, states = st, ratios = ratio)
end

# ---------------------------------------------------------------------------
# the combined table
# ---------------------------------------------------------------------------

"""
    write_panelled_table(path; caption, label, colspec, header, body, notes)

`write_table` of the harness writes one block of rows and terminates each with
`\\\\`; this one takes the body verbatim, because the D3 table is two panels
separated by a rule and a panel heading is not a row.  The banner names this
script, since this is the file that generates it.
"""
function write_panelled_table(path::AbstractString; caption::AbstractString,
                              label::AbstractString, colspec::AbstractString,
                              header::AbstractString, body::Vector{String},
                              notes::Vector{String})
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "%% GENERATED by model/scripts/run_d3.jl on ",
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
        for line in body
            println(io, line)
        end
        println(io, "\\bottomrule")
        println(io, "\\end{tabular}")
        println(io, "\\begin{tablenotes}[flushleft]")
        println(io, "\\footnotesize")
        println(io, "\\item[] \\textit{Note:} ", join(notes, " "))
        println(io, "\\end{tablenotes}")
        println(io, "\\end{threeparttable}")
        println(io, "\\end{table}")
    end
    return path
end

"""
    split_csv(line) -> Vector{String}

One line of the harness's CSV, with the quoting `csv_quote` applies: a label
such as `(1,1,1,1)` carries commas and is written quoted, so splitting on commas
is not enough.
"""
function split_csv(line::AbstractString)
    out, buf, inq = String[], IOBuffer(), false
    i = firstindex(line)
    while i <= lastindex(line)
        c = line[i]
        if inq && c == '"' && i < lastindex(line) && line[nextind(line, i)] == '"'
            print(buf, '"')
            i = nextind(line, i)
        elseif c == '"'
            inq = !inq
        elseif c == ',' && !inq
            push!(out, String(take!(buf)))
        else
            print(buf, c)
        end
        i = nextind(line, i)
    end
    push!(out, String(take!(buf)))
    return out
end

"The columns of one run's CSV that the note's table uses, read back."
function read_rows(path::AbstractString)
    lines = filter(!isempty, strip.(readlines(path)))
    cols = Symbol.(split_csv(lines[1]))
    return [begin
                v = Dict(zip(cols, split_csv(ln)))
                (; kind = v[:kind], label = v[:label], state = v[:state],
                   converged = v[:converged] == "true",
                   ce_vs_planner = parse(Float64, v[:ce_vs_planner]),
                   survival_ratio = parse(Float64, v[:survival_ratio]),
                   Minf = parse(Float64, v[:Minf]),
                   cum_leak = parse(Float64, v[:cum_leak]),
                   gatefee_sign_change = parse(Int, v[:gatefee_sign_change]))
            end for ln in lines[2:end]]
end

"One corner's row of the combined table."
function corner_row(r)
    # The costs are of order 1e-4 percent on this calibration, so the harness's
    # three digits round every one of them to zero; the column is reported in
    # units of 1e-5 percent instead of being printed as a row of zeros.
    return join((tex_escape(r.label), r.state,
                 tex_num(1e7 * r.ce_vs_planner; digits = 2),
                 tex_num(r.survival_ratio; digits = 2),
                 tex_num(r.Minf; digits = 1),
                 tex_num(r.cum_leak; digits = 1),
                 tex_date(r.gatefee_sign_change)), " & ") * " \\\\"
end

# ---------------------------------------------------------------------------
# the run
# ---------------------------------------------------------------------------

d = read_calibration(joinpath(DATA, "calibration.json"))
p0, s0, cases = calibrated_params(d), calibrated_states(d), calibration_cases(d)

# The floorless baseline, and the largest floor of the calibration's grid that
# D1 could solve: its fourth point, 47.5, does not solve on either file
# (`data/processed/d1_baseline_report.md`).
const FLOORS = [cases.Rbar_grid[1], cases.Rbar_grid[3]]

panels = Any[]
for rb in FLOORS
    tag = floor_tag(rb)
    if TABLE_ONLY
        rows = read_rows(joinpath(D3_OUT, "instruments_$tag.csv"))
        push!(panels, (; rb, corners = filter(r -> r.kind == "corner", rows)))
        continue
    end
    p = with(p0; Rbar = rb)
    println("\n", repeat("=", 78))
    @printf("E3 at Rbar = %g (%s), T = %d, budget %g h\n", rb, tag, T_REQ, HOURS)
    println(repeat("=", 78))
    t0 = time()
    res = experiment_instruments(p, s0; T = T_REQ, hours = HOURS,
                                 outdir = D3_TMP, texdir = D3_TMP)
    wall = time() - t0
    csv = relocate(joinpath(D3_TMP, "instruments", "instruments.csv"),
                   joinpath(D3_OUT, "instruments_$tag.csv"))
    tex = relocate(joinpath(D3_TMP, "Instruments.tex"),
                   joinpath(D3_OUT, "Instruments_$tag.tex"))
    @printf("\nrows: %s\ntable: %s\nwall clock %.1f s, stopped on budget: %s\n",
            csv, tex, wall, res.stopped)

    for r in res.rows
        @printf("%-8s %-18s conv=%s T=%d |F|=%.1e %-14s state=%-2s CE=%9.5f%% Minf=%.5g Tres=%.4g surv=%s gate<0 %d leak=%.5g %.0fs\n",
                r.kind, r.label, r.converged, r.T_reached, r.resid, r.method, r.state,
                100 * r.ce_vs_planner, r.Minf, r.residence, tex_num(r.survival_ratio),
                r.gatefee_sign_change, r.cum_leak, r.seconds)
    end

    corners = filter(r -> r.kind == "corner", res.rows)
    i0 = findfirst(r -> (r.phiW, r.phiz, r.phiP, r.phiX) == (1.0, 1.0, 1.0, 1.0), corners)
    planner_state = i0 === nothing ? "-" : corners[i0].state
    headline = filter(r -> r.converged && r.state != planner_state, corners)
    violations = filter(r -> r.converged && !isnan(r.ce_vs_planner) &&
                             r.ce_vs_planner < -CE_TOL, res.rows)
    unsolved = filter(r -> !r.converged, res.rows)

    println("\n-- summary at Rbar = ", rb, " --")
    println("   planner corner state: ", planner_state)
    println("   corners differing from it: ",
            isempty(headline) ? "none" : join((r.label for r in headline), ", "))
    println("   ordering violations (CE < 0): ",
            isempty(violations) ? "none" : join((r.label for r in violations), ", "))
    println("   points that did not converge: ",
            isempty(unsolved) ? "none" :
            join((@sprintf("%s (|F| = %.2e, %s, T = %d)", r.label, r.resid, r.method,
                           r.T_reached) for r in unsolved), "; "))

    # What gets the period-by-period treatment: every corner whose endpoint
    # state differs from the planner's, every ordering violation, and
    # laissez-faire whether or not it does either.
    probes = Tuple{String,Any}[]
    for r in headline
        push!(probes, ("HEADLINE " * r.label * "  (dials off: " *
                       join(dials_off((r.phiW, r.phiz, r.phiP, r.phiX)), "; ") * ")", r))
    end
    for r in violations
        any(q -> q[2] === r, probes) ||
            push!(probes, ("ORDERING VIOLATION " * r.label, r))
    end
    for r in filter(r -> r.kind == "corner" && r.converged &&
                         (r.phiW, r.phiz, r.phiP, r.phiX) == (0.0, 0.0, 0.0, 0.0), res.rows)
        any(q -> q[2] === r, probes) || push!(probes, ("laissez-faire " * r.label, r))
    end
    if !isempty(probes)
        # The planner corner has to be re-solved: the harness returns rows, not
        # paths, and the period-by-period comparison needs both paths.
        base = solve_case(with(p; phiW = 1.0, phiz = 1.0, phiP = 1.0, phiX = 1.0), s0;
                          T = T_REQ)
        sp_base, ratio_base = base.ok ? state_path(p, base.mo, base.x) :
                              (String[], Float64[])
        if base.ok
            @printf("\nplanner corner re-solved: %s, |F| = %.3e, T = %d\n",
                    base.method, base.nrm, base.mo.T)
            @printf("   enters its final state %s at t = %d; survival margin crossed at t = %d\n",
                    sp_base[end], settle_date(sp_base, ==(sp_base[end])),
                    settle_date(ratio_base, >(1)))
            for t in 0:25:base.mo.T
                @printf("   planner t = %3d  state %s  survival %.6g\n",
                        t, sp_base[t+1], ratio_base[t+1])
            end
        else
            println("\nplanner corner did not re-solve: |F| = ", base.nrm)
        end
        for (lab, r) in probes
            inspect_point(p, s0, base, sp_base, ratio_base,
                          (r.phiW, r.phiz, r.phiP, r.phiX), lab; T = T_REQ)
        end
    end
    push!(panels, (; rb, rows = res.rows, corners, planner_state, wall,
                    stopped = res.stopped, csv, tex))
end

# The note's table: both floors, one panel each, corners only, as the harness's
# own table does -- the single-dial paths are in the CSVs.
body = String[]
letters = ("A", "B")
for (k, pan) in enumerate(panels)
    k > 1 && push!(body, "\\addlinespace")
    push!(body, @sprintf("\\multicolumn{7}{l}{\\textit{Panel %s. \$\\bar R = %g\$%s}} \\\\",
                         letters[min(k, 2)], pan.rb,
                         pan.rb == 0 ? ", no floor" : " Gt, the largest floor that solves"))
    append!(body, corner_row.(pan.corners))
end
tex = write_panelled_table(joinpath(TABLE_ROOT, "Instruments.tex");
    caption = "The cost of the three market failures, at the corners of the policy space",
    label = "tab:q:res:instruments", colspec = "lcrrrrr",
    header = "\$(\\phi^W,\\phi^z,\\phi^P,\\phi^X)\$ & State & CE cost (\$10^{-5}\$\\%) & " *
             "\$\\mathcal M_\\infty/(\\bar R\\mathcal T)\$ & \$\\mathcal M_\\infty\$ & " *
             "\$\\sum\\Xi\$ & Gate fee \$<0\$",
    body = body,
    notes = ["Each dial is at one, the Pigouvian level of the instrument it switches on, " *
             "or at zero: \$\\phi^W\$ property rights over the waste stock, \$\\phi^z\$ the " *
             "material-content charge, \$\\phi^P\$ the emission tax, \$\\phi^X\$ the discovery " *
             "tax. The consumption-equivalent cost is the proportional consumption supplement " *
             "that would make the corner as good as the planner corner \$(1,1,1,1)\$, which is " *
             "therefore zero by construction, in units of \$10^{-5}\$ percent of consumption; " *
             "the planner corner is the maximum of the problem, so a negative entry would be a " *
             "horizon diagnostic and not a result, and entries below \$0.1\$ are at the " *
             "precision of the comparison itself. " *
             "\$\\mathcal M_\\infty\$ is the retained endowment at the horizon reached and " *
             "\$\\sum\\Xi\$ cumulative leakage to the environment, both in gigatonnes; the " *
             "survival ratio is infinite without a floor. Dates are periods since 1900; a " *
             "dash is an event that does not occur along the path, and at \$\\phi^W = 0\$ " *
             "there is no gate fee to change sign, \$\\tau^{\\mathcal W}=-\\phi^Wp^{\\mathcal W}\$ " *
             "being identically zero. " *
             "Every row is one solved path at \$T = " * string(T_REQ) * "\$; the four " *
             "single-dial paths between the corners are in the run's CSVs."])
println("\ncombined table: ", tex)
isdir(D3_TMP) && rm(D3_TMP; recursive = true)
