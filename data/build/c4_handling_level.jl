# C4, the level of the handling charges (task D0b of notes/plan_calibration_experiments.md).
#
# Run from model/:   julia --project=. ../data/build/c4_handling_level.jl
# Order: after c4_waste.py has written the municipal charges into calibration.json; then
# c4_waste.py again, which reads the sidecar this script writes, then c_metals.py and
# appendix_tables.py.
#
# The municipal-solid-waste cost ladder of Kaza et al. (2018) gives the shape of the
# handling cost -- the ratio of the treatment scale cT to the collection charge cc -- but
# not its level for the whole handled flow, of which municipal waste is three percent
# (notes/data/waste_recycling.md).  At the municipal level applied to the whole flow no
# tonne is worth treating (data/processed/c8_smoke.txt).  This script holds the ratio
# cT/cc at the ladder's and chooses the common level so that the solved planner path
# reproduces the observed 2015 circularity: the treated share varpi in 2015 at the reading
# block B1's outflow decomposition gives (recovery over recovery plus disposal, non-biomass,
# c4_waste.csv), by bracketing and bisection on the level in at most MAXSOLVES solves,
# stopping within TOL of the target.  The recycled share RR/W in 2015 (secondary input over
# the outflows from use, b1_material_block.csv) is the second target and one scalar cannot
# hit both, so its miss is reported, not fitted; xi, the other free parameter, is a range
# and is not moved.  The model's recycled share is RR over the outflows from use, W less
# the unused extraction the model books into W, on the data's definition.
#
# Writes data/processed/c4_handling_level.json (the level, the targets, what was achieved,
# the solves taken, the same shares on the metals bound at that level, and a horizon
# check); c4_waste.py turns the level into cc0 and cT0.  Nothing under model/ is changed.

include(joinpath(@__DIR__, "..", "..", "model", "src", "CircularEconomy.jl"))
using .CircularEconomy
using Printf

const PROCESSED = normpath(joinpath(@__DIR__, "..", "processed"))
const INTERIM = normpath(joinpath(@__DIR__, "..", "interim"))
const CAL = joinpath(PROCESSED, "calibration.json")
const OUT = joinpath(PROCESSED, "c4_handling_level.json")
const T = 200            # horizon of each solve; 2015 is t = 115 from 1900, 85 periods short of it
const T_CHECK = 300      # the horizon check on the fitted level, by continuation from T
const MAXSOLVES = 10
const TOL = 0.05         # relative, on the treated share
const BRACKET = (0.25, 4.0)   # levels relative to the municipal ladder; 1 is the ladder itself, its own range is [0.57, 1.43]

"A value from a long-format CSV row; the note may carry commas but comes last."
function csv_value(path, name; namecol = 1, valcol = 2, filter = nothing)
    for line in eachline(path)
        f = split(line, ',')
        length(f) >= valcol || continue
        f[namecol] == name || continue
        (filter === nothing || filter(f)) || continue
        return parse(Float64, f[valcol])
    end
    error("$path has no row $name")
end

c4(name) = csv_value(joinpath(PROCESSED, "c4_waste.csv"), name)
"year,series,category,value,unit,source,method of block B1."
b1(series, year; category = "total", source = "haas2020") =
    csv_value(joinpath(INTERIM, "b1_material_block.csv"), series; namecol = 2, valcol = 4,
              filter = f -> f[1] == string(year) && f[3] == category && f[6] == source)

cc_msw = 0.5e-3 * (c4("cc_usd_low") + c4("cc_usd_high"))   # midpoints, US$/t to trillion $/Gt
cT_msw = 0.5e-3 * (c4("cT_usd_low") + c4("cT_usd_high"))   # (the factor of c_common.py)
vw_target = c4("treated_share_recycling_only")
rr_target = b1("RR", 2015) / b1("W", 2015)
R1900 = b1("R", 1900)                    # the guess's material target
meta = calibration_meta(CAL)
t2015 = 2015 - Int(meta["base_year"])
s0 = calibrated_states(CAL)

"""
The 2015 circularity of the solved planner path at a level of the charges.  A cold
solve at `start_T`, extended to `T` by `solve_long`'s continuation where they differ;
`S_min` is the smallest reserve along the path, because nothing in the residual system
keeps the reserve non-negative when the stock effect of extraction is off.
"""
function circularity(path, level; T = T, start_T = T)
    p = calibrated_params(path; check = false,
                          cc0 = level * cc_msw, cc_inf = level * cc_msw,
                          cT0 = level * cT_msw, cT_inf = level * cT_msw)
    t0 = time()
    mo, x, ok, nrm = solve_long(p, s0, T; start_T = start_T, step = 50,
                                guess_kwargs = (; Rtarget = R1900))
    sol = unpack(mo, x)
    b = sol.blocks[t2015 + 1]
    pr = sol.prices[t2015 + 1]
    i = findfirst(<(0), pseries(sol, :tauW))
    return (; level, ok, nrm, T = mo.T, seconds = time() - t0,
             vw = b.vw, rr = b.RR / (b.W - b.Nbase), avw = b.a * b.vw, x = b.x, a = b.a,
             tauW = pr.tauW, CW_over_Y = b.CW / b.Y,
             vw0 = sol.blocks[1].vw, vwT = sol.blocks[end].vw,
             S_min = minimum(series(sol, :S)),
             gatefee_sign_change = i === nothing ? -1 : i - 1)
end

function report(r)
    @printf("  level %.4f: converged = %s |F| = %.1e T = %d (%.1f s)  varpi_2015 = %.4f  RR/W_2015 = %.4f  a varpi = %.4f  x = %.3f  varpi_0 = %.3f  varpi_T = %.3f  C^W/Y = %.4f  gate fee < 0 from t = %d  min S = %.1f\n",
            r.level, r.ok, r.nrm, r.T, r.seconds, r.vw, r.rr, r.avw, r.x, r.vw0, r.vwT,
            r.CW_over_Y, r.gatefee_sign_change, r.S_min)
end

@printf("targets: varpi_2015 = %.4f (B1, recovery over recovery plus disposal, non-biomass), RR/W_2015 = %.4f\n",
        vw_target, rr_target)
@printf("municipal ladder: cc = %.4f, cT = %.4f trillion \$/Gt, ratio cT/cc = %.3f held\n",
        cc_msw, cT_msw, cT_msw / cc_msw)

# Bracket: the ladder itself (no treatment) and the low end.  The treated share falls in
# the level, so varpi(level) - target changes sign on the bracket.
solves = NamedTuple[]
hi = circularity(CAL, BRACKET[2]); push!(solves, hi); report(hi)
lo = circularity(CAL, BRACKET[1]); push!(solves, lo); report(lo)
hi.ok && lo.ok || error("a bracket end did not converge")
lo.vw > vw_target > hi.vw ||
    error(@sprintf("the target %.3f is not bracketed: varpi = %.3f at level %.3g and %.3f at level %.3g",
                   vw_target, lo.vw, lo.level, hi.vw, hi.level))
best = abs(lo.vw - vw_target) < abs(hi.vw - vw_target) ? lo : hi
while length(solves) < MAXSOLVES && abs(best.vw - vw_target) > TOL * vw_target
    global lo, hi, best
    mid = circularity(CAL, sqrt(lo.level * hi.level))   # bisection in the log of the level
    push!(solves, mid); report(mid)
    mid.ok || error("the solve at level $(mid.level) did not converge")
    abs(mid.vw - vw_target) < abs(best.vw - vw_target) && (best = mid)
    mid.vw > vw_target ? (lo = mid) : (hi = mid)
end
hit = abs(best.vw - vw_target) <= TOL * vw_target
@printf("\nfitted level %.4f after %d solves: varpi_2015 = %.4f against %.4f (%s), RR/W_2015 = %.4f against %.4f (miss %+.1f%%)\n",
        best.level, length(solves), best.vw, vw_target,
        hit ? "within tolerance" : "NOT within tolerance",
        best.rr, rr_target, 100 * (best.rr / rr_target - 1))

println("\nhorizon check on the fitted level, T = $T_CHECK by continuation from T = $T:")
chk = circularity(CAL, best.level; T = T_CHECK, start_T = T); report(chk)

println("\nthe metals bound at the fitted level:")
met = circularity(joinpath(PROCESSED, "calibration_metals.json"), best.level); report(met)

# --- the sidecar ---------------------------------------------------------------------
num(x) = isfinite(x) ? @sprintf("%.12g", x) : "null"
open(OUT, "w") do io
    println(io, "{")
    println(io, "  \"built_by\": \"data/build/c4_handling_level.jl\",")
    println(io, "  \"date\": \"", Libc.strftime("%Y-%m-%d", time()), "\",")
    println(io, "  \"method\": \"cT/cc held at the ratio of the municipal ladder; the level chosen by bisection so that the solved planner path's treated share in 2015 (t = $t2015, T = $T) matches the B1 reading; the recycled share is reported, not fitted\",")
    println(io, "  \"level\": ", num(best.level), ",")
    println(io, "  \"cc0\": ", num(best.level * cc_msw), ",")
    println(io, "  \"cT0\": ", num(best.level * cT_msw), ",")
    println(io, "  \"cc0_msw_scale\": ", num(cc_msw), ",")
    println(io, "  \"cT0_msw_scale\": ", num(cT_msw), ",")
    println(io, "  \"T\": ", T, ",")
    println(io, "  \"t_2015\": ", t2015, ",")
    println(io, "  \"solves\": ", length(solves), ",")
    println(io, "  \"tolerance\": ", num(TOL), ",")
    println(io, "  \"within_tolerance\": ", hit, ",")
    println(io, "  \"targets\": {\"treated_share_2015\": ", num(vw_target),
            ", \"recycled_share_2015\": ", num(rr_target), "},")
    println(io, "  \"achieved\": {\"treated_share_2015\": ", num(best.vw),
            ", \"recycled_share_2015\": ", num(best.rr),
            ", \"recovered_share_of_handled_2015\": ", num(best.avw), ", \"x_2015\": ", num(best.x),
            ", \"treated_share_1900\": ", num(best.vw0),
            ", \"handling_cost_over_output_2015\": ", num(best.CW_over_Y),
            ", \"gatefee_sign_change\": ", best.gatefee_sign_change, ", \"resid\": ", num(best.nrm), "},")
    println(io, "  \"horizon_check\": {\"T_requested\": ", T_CHECK, ", \"T_reached\": ", chk.T,
            ", \"treated_share_2015\": ", num(chk.vw), ", \"recycled_share_2015\": ", num(chk.rr), "},")
    println(io, "  \"metals_bound\": {\"treated_share_2015\": ", num(met.vw),
            ", \"recycled_share_2015\": ", num(met.rr), ", \"converged\": ", met.ok,
            ", \"S_min\": ", num(met.S_min), "},")
    println(io, "  \"solve_table\": [")
    for (i, r) in enumerate(solves)
        println(io, "    {\"level\": ", num(r.level), ", \"treated_share_2015\": ", num(r.vw),
                ", \"recycled_share_2015\": ", num(r.rr), ", \"converged\": ", r.ok,
                ", \"resid\": ", num(r.nrm), "}", i < length(solves) ? "," : "")
    end
    println(io, "  ]")
    println(io, "}")
end
println("\nwrote ", OUT)
