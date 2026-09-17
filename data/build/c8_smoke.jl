# C8: the smoke test of the calibrated baseline.
#
# Run from model/:   julia --project=. ../data/build/c8_smoke.jl [path/to/calibration.json]
# Solves the planner corner at T = 60 from a fresh initial guess, first with the
# harness's solve_long (the route solve_case takes when there is no previous grid
# point and Rbar = 0), then, if that fails, the same solve on the set rescaled to
# the illustrative units (100 trillion dollars, 100 gigatonnes) to tell a scale
# failure from a calibration failure.  Also reports the date at which the reserve
# reaches two percent of S0 on the guess path.  Nothing under model/ is changed.

include(joinpath(@__DIR__, "..", "..", "model", "src", "CircularEconomy.jl"))
using .CircularEconomy
using Printf

path = length(ARGS) >= 1 ? ARGS[1] : joinpath(@__DIR__, "..", "processed", "calibration.json")
T = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 60
println("calibration file: ", path, ";  T = ", T)

# A third argument "cheap" scales the collection and treatment charges by a tenth: the
# diagnostic that tells a stall at the treatment corner from a stall elsewhere.
cheap = length(ARGS) >= 3 && ARGS[3] == "cheap"
p = calibrated_params(path; check = false)
if cheap
    p = with(p; cc0 = 0.1 * p.cc0, cc_inf = 0.1 * p.cc_inf, cT0 = 0.1 * p.cT0, cT_inf = 0.1 * p.cT_inf)
    println("handling charges scaled by 0.1 (diagnostic)")
end
s0 = calibrated_states(path)
R1900 = 7.562   # Haas et al. (2020) material input in 1900, the guess's material target

"Print the quantities the brief asks for at t = 0 and t = T."
function report(mo, x, ok, nrm; label = "")
    @printf("%s converged = %s, |F| = %.3e, T = %d, Gam = %.5f\n", label, ok, nrm, mo.T, mo.Gam)
    sol = unpack(mo, x)
    for t in (0, mo.T)
        b = sol.blocks[t+1]; pr = sol.prices[t+1]
        @printf("  t = %3d: Y = %.4f, R = %.4f, N = %.4f, RR = %.4f, varpi = %.4f, gate fee tauW = %.4e, zeta = %.4e, pP = %.4e, S = %.1f, P = %.2f\n",
                t, b.Y, b.R, b.N, b.RR, b.vw, pr.tauW, pr.zz, sol.costates[t+1, IPP], b.S, b.Pst)
    end
    return sol
end

"Rescale a calibrated set to units 100 times larger (the illustrative convention)."
function rescaled(p::Params, s0; f = 100.0)
    q = with(p;
        A0 = p.A0 * f^(p.mu_F - 1),          # Y/f from (K/f, R/f)
        cN0 = p.cN0 * f^p.chi_N, cN_inf = p.cN_inf * f^p.chi_N, kap_N = p.kap_N / f, Sref = p.Sref / f,
        cD0 = p.cD0 * f^p.chi_D, cD_inf = p.cD_inf * f^p.chi_D, kap_D = p.kap_D / f,
        Xmax = p.Xmax / f, Xref = p.Xref / f,
        kappa = p.kappa * f, Rbar = p.Rbar / f)
    return q, s0 ./ f
end

function try_solve(p, s0, T; Rtarget, label)
    t0 = time()
    mo, x, ok, nrm = solve_long(p, s0, T; start_T = T, guess_kwargs = (; Rtarget = Rtarget))
    @printf("%s: solve_long took %.1f s\n", label, time() - t0)
    sol = report(mo, x, ok, nrm; label = label)
    return mo, x, ok, nrm, sol
end

println("\n== the guess path: where does S reach 2% of S0?")
mo0 = Model(p; T = 2000, s0 = s0)
S, C = simulate_quantities(mo0; Rtarget = R1900)
i = findfirst(t -> S[t+1, IS] <= 0.02 * s0[IS], 0:2000)
if i === nothing
    @printf("  not within 2000 periods; S(2000) = %.1f = %.3f of S0 (N on the guess is capped at %.1f = Rtarget)\n",
            S[end, IS], S[end, IS] / s0[IS], R1900)
else
    @printf("  at t = %d (year %d)\n", i - 1, 1900 + i - 1)
end
gC = cbgp_growth(p)
S2, _ = simulate_quantities(mo0; Rtarget = R1900, gR = gC)
i2 = findfirst(t -> S2[t+1, IS] <= 0.02 * s0[IS], 0:2000)
@printf("  with the guess's material target growing at the C-cell rate %.4f: %s\n", gC,
        i2 === nothing ? "not within 2000 periods" : "t = $(i2 - 1) (year $(1900 + i2 - 1))")

println("\n== solve at the calibrated units")
mo, x, ok, nrm, sol = try_solve(p, s0, T; Rtarget = R1900, label = "calibrated units")
if ok
    println("\n== check_path")
    check_path(mo, x)
    println("\n== classify_longrun")
    println(classify_longrun(mo, x))
else
    println("\n== the same solve on the rescaled set (goods and material in units 100 times larger)")
    q, sq = rescaled(p, s0)
    try_solve(q, sq, T; Rtarget = R1900 / 100, label = "rescaled")
    println("\n== solve_path directly from initial_guess at the calibrated units, verbose")
    mo1 = Model(p; T = T, s0 = s0)
    x0 = initial_guess(mo1; Rtarget = R1900)
    x1, ok1, nrm1 = solve_path(mo1, x0; verbose = true)
    report(mo1, x1, ok1, nrm1; label = "direct")
end
