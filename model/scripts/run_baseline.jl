#=
Baseline run.

Solves the planner's problem on the illustrative parameter set, reports the
long-run blocks it should converge to, runs the verification checks, and walks
the four policy dials.  Nothing here is a calibrated result; the parameters are
the placeholders of `src/calibration.jl`.

    julia --project=. scripts/run_baseline.jl
=#

include(joinpath(@__DIR__, "..", "src", "CircularEconomy.jl"))
using .CircularEconomy
using Printf

const T  = 200
const S0 = baseline_states()

rule(s) = (println(); println(s); println(repeat("-", length(s))))

# ---------------------------------------------------------------------------
rule("Parameters and analytic long-run objects")

p = baseline_params()
w = check_params(p)
isempty(w) ? println("parameter checks: all pass") :
             foreach(x -> println("  WARNING: ", x), w)

@printf("beta_K = %.4f   gamma = %.4f\n", beta_K(p), gamma_R(p))
@printf("circular growth rate g   = %.5f per period\n", cbgp_growth(p))
gb, nu = bdp_rates(p)
@printf("balanced-demat. rates    = g %.5f, nu %.5f  (g_B2 / g_C = %.3f)\n",
        gb, nu, gb / cbgp_growth(p))

cc = closure_check(p; A = 0.5)
@printf("closure criterion: closes = %s, cumulated leakage = %.4g, ", cc.closes, cc.leak_sum)
@printf("x growth relative to g = %.3f\n", cc.x_growth_relative_to_g)

# ---------------------------------------------------------------------------
rule("Planner path")

mo = Model(p; T = T, s0 = S0)
x0 = initial_guess(mo; Rtarget = 0.6)
@time x, ok, nrm = solve_path(mo, x0)
@printf("converged = %s, |F| = %.3e, unknowns = %d\n", ok, nrm, nvar(mo))
ok || error("baseline path did not solve")

sol = unpack(mo, x)
Y, R, N, a, vw = series.(Ref(sol), (:Y, :R, :N, :a, :vw))
Wst = sol.states[:, IWS]
tauW, zz = pseries.(Ref(sol), (:tauW, :zz))

println()
@printf("%5s %8s %8s %8s %9s %7s %7s %9s %9s\n",
        "t", "Y", "R", "N", "W stock", "a", "varpi", "gate fee", "zeta")
for t in 1:25:T+1
    @printf("%5d %8.3f %8.4f %8.4f %9.2f %7.4f %7.3f %+9.4f %+9.4f\n",
            t-1, Y[t], R[t], N[t], Wst[t], a[t], vw[t], tauW[t], zz[t])
end

# the date at which waste stops being a liability and becomes a resource
sw = findfirst(<(0), tauW)
sw === nothing ? println("\ngate fee never turns negative over the horizon") :
                 @printf("\ngate fee turns negative at t = %d: waste becomes a resource\n", sw-1)

# ---------------------------------------------------------------------------
rule("Verification")

res = check_path(mo, x)
@printf("market vs planner residual gap = %.3e\n", compare_residuals(mo, x))
@printf("welfare = %.6f\n", welfare(mo, x))

# where the path is heading, against the analytic circular growth path
Minf = res.retained_endowment
c = cbgp(p; Minf = Minf)
@printf("\nagainst the analytic CBGP at M_inf = %.3f:\n", Minf)
@printf("  residence time T      = %.2f periods (1/mu = %.1f, sigma/delta = %.2f)\n",
        c.residence, 1/p.mu_h, c.sigma_inf/p.delta)
@printf("  implied R_inf         = %.4f   (path R_T = %.4f)\n", c.Rinf, R[end])
@printf("  K/Y                   = %.3f\n", c.k)
@printf("  normalised prices: Psi %.4f, zeta %+.4f, pW %+.4f, q %.4f\n",
        c.Psi_hat, c.zeta_hat, c.pW_hat, c.q_inf)
p.Rbar > 0 && @printf("  survival ratio M_inf/(Rbar*T) = %.3f\n", Minf/(p.Rbar*c.residence))

# ---------------------------------------------------------------------------
rule("Policy dials")

@printf("%-30s %12s %9s %9s %9s\n", "policy", "welfare", "a_T", "cum leak", "M_inf")
for (nm, kw) in (("planner (1,1,1,1)",            (;)),
                 ("no emission tax",              (phiP = 0.0,)),
                 ("no discovery tax",             (phiX = 0.0,)),
                 ("no material-content charge",   (phiz = 0.0,)),
                 ("no waste property rights",     (phiW = 0.0,)),
                 ("laissez-faire",                (phiW = 0.0, phiz = 0.0,
                                                   phiP = 0.0, phiX = 0.0)))
    pp = baseline_params(; kw...)
    mm = Model(pp; T = T, s0 = S0)
    # Continue in the dials from the planner corner rather than solving each
    # policy cold: it is the best-conditioned point of the policy space and its
    # solution is independently characterised.
    xx, okk, _ = isempty(kw) ? (x, true, nrm) : continuate(mo, mm, x; steps = 6)
    if !okk
        xx, okk, _ = solve_path(mm, initial_guess(mm; Rtarget = 0.6))
    end
    if okk
        ss = unpack(mm, xx)
        @printf("%-30s %12.4f %9.4f %9.3f %9.3f\n", nm, welfare(mm, xx),
                series(ss, :a)[end],
                sum((1 - b.a * b.vw) * b.H for b in ss.blocks),
                ss.states[end, IMK] + ss.states[end, IWS])
    else
        @printf("%-30s %12s\n", nm, "FAILED")
    end
end

println("\nThe planner corner maximises welfare; every missing instrument lowers it.")
println("Watch the last two columns together: an instrument can raise the retained")
println("endowment while lowering welfare, because over-extraction brings mass in.")
