#=
Sufficiency verification.

Runs the protocol of `writing/docs/Appendix_sufficiency.tex`: which convexity
conditions hold, whether transversality is satisfied, and whether any feasible
deviation beats the computed path.  On the illustrative calibration by default,
which is not a result; on the calibrated set with `--calibration=`.

    julia --project=. scripts/run_sufficiency.jl
    julia --project=. scripts/run_sufficiency.jl --calibration=../data/processed/calibration.json
=#

include(joinpath(@__DIR__, "..", "src", "CircularEconomy.jl"))
using .CircularEconomy
using Printf

rule(s) = (println(); println(s); println(repeat("-", length(s))))

calfile = let a = filter(s -> startswith(s, "--calibration="), ARGS)
    isempty(a) ? nothing : a[1][length("--calibration=")+1:end]
end
if calfile === nothing
    @warn "run_sufficiency: no calibration file given, so the illustrative set is used. Nothing from this run is a result."
    p, S0 = baseline_params(), baseline_states()
    # the floor and hard-ceiling variant the absorbing-shutdown question is asked on
    pf = baseline_params(Rbar = 0.35, abar = 0.7)
else
    println("calibration file: ", calfile)
    d = read_calibration(calfile)
    p, S0 = calibrated_params(d), calibrated_states(d)
    cs = calibration_cases(d)
    pf = with(p; Rbar = length(cs.Rbar_grid) >= 2 ? cs.Rbar_grid[2] : p.Rbar,
                 abar = length(cs.abar) >= 2 ? cs.abar[2] : p.abar)
end

rule("Convexity conditions (C1)-(C5)")
convexity_report(p)

rule("Solving, by horizon continuation")
@time mo, x, ok, nrm = solve_long(p, S0, 300; start_T = 150, step = 50, verbose = true)
@printf("reached T = %d, converged = %s, |F| = %.2e\n", mo.T, ok, nrm)
sol = unpack(mo, x)
@printf("reserve at T = %.5f  (the stiff wall is where this reaches zero)\n",
        sol.states[end, IS])

rule("Horizon sensitivity")
mo2, x2, _ = solve_long(p, S0, 150; start_T = 100, step = 50)
n = 101
ya = series(unpack(mo2, x2), :Y)[1:n]
yb = series(sol, :Y)[1:n]
ca = series(unpack(mo2, x2), :C)[1:n]
cb = series(sol, :C)[1:n]
@printf("T = %d against T = %d, over t = 0..%d:\n", mo2.T, mo.T, n - 1)
@printf("  max relative change in Y  %.3e\n", maximum(abs.(ya .- yb) ./ yb))
@printf("  max relative change in C  %.3e\n", maximum(abs.(ca .- cb) ./ cb))

rule("Transversality")
tvc_report(mo, x)

rule("Feasible-direction test: profiles")
println("Extraction -- probes the non-convexity introduced by the finite choke.")
deviation_profile(mo, x; control = IN, window = 0:100, grid = -0.5:0.125:0.5)
println()
println("Investment -- probes the bilinear intensity condition.")
deviation_profile(mo, x; control = II, window = 0:100, grid = -0.4:0.1:0.4)

rule("Feasible-direction test: random search")
perturbation_test(mo, x; ndraws = 400)

rule("Is a shutdown absorbing?  (floor $(pf.Rbar), ceiling $(pf.abar))")
for (nm, st) in (("terminal state of the growth path", sol.states[end, :]),
                 ("a depleted economy", S0 .* [0.05, 1e-4, 1.0, 1.0, 0.05, 0.05]))
    r = absorbing_shutdown(pf, st)
    @printf("%-34s %s\n", nm, r.detail)
end

println()
println("Read together: the conditions that fail are named, the directions in which")
println("they could bite have been searched, and nothing beat the candidate. That is")
println("verification, not proof -- the appendix is explicit about the difference.")
