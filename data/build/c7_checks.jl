# C7: the calibrated set through the model's own checks.
#
# Run from model/:   julia --project=. ../data/build/c7_checks.jl [path/to/calibration.json]
# Writes nothing; the output is quoted in writing/quant/quant_data.tex, Section
# "Checks on the calibrated set", and captured to data/processed/c7_checks.txt by the
# shell that runs it.  Nothing under model/ is touched (phase C reads the model only).

include(joinpath(@__DIR__, "..", "..", "model", "src", "CircularEconomy.jl"))
using .CircularEconomy
using Printf

path = length(ARGS) >= 1 ? ARGS[1] : joinpath(@__DIR__, "..", "processed", "calibration.json")
println("calibration file: ", path)

p = calibrated_params(path; check = false)
s0 = calibrated_states(path)
cases = calibration_cases(path)

println("\n== calibrated_params: loads; ", length(calibration_sources(path)), " parameters carry a source")
println("states [K S X P MK W] = ", s0)
println("cases: ", cases)

println("\n== check_params")
w = check_params(p)
isempty(w) ? println("no warnings: every maintained restriction holds") : foreach(println, w)

println("\n== derived rates")
g = cbgp_growth(p)
@printf("beta_K = %.4f, gamma_R = %.4f\n", beta_K(p), gamma_R(p))
@printf("C-cell growth g = %.5f per year; interest factor 1+r = %.5f\n", g, interest_factor(p, exp(g)))
bd = bdp_rates(p)
if bd === nothing
    println("bdp_rates: no balanced-dematerialization solution in the exponential family " *
            "((mu_N - 1)(1 - beta_K) + gamma_R <= 0)")
else
    @printf("bdp_rates: g = %.5f, nu = %.5f per year\n", bd[1], bd[2])
end

println("\n== convexity_report")
convexity_report(p)

println("\n== wellposed_report at the C-cell rate (nu = 0)")
wellposed_report(p; g = g, nu = 0.0)
if bd !== nothing
    println("\n== wellposed_report at the B-cell rates")
    wellposed_report(p; g = bd[1], nu = bd[2])
end

println("\n== the pollution price scale at 1900 (rough)")
th, _ = decay(p, s0[IP])
Y0 = production(p, 0, s0[IK], 7.562, s0[IP])[1]
r0 = interest_factor(p, exp(g)) - 1
@printf("Y(1900) at R = 7.562 Gt: %.4f trillion; damage share kappa*P0 = %.2e; kappa*Y0/(r+theta) = %.3e trillion/Gt (= %.2f US dollars per tonne)\n",
        Y0, p.kappa * s0[IP], p.kappa * Y0 / (r0 + th), 1000 * p.kappa * Y0 / (r0 + th))
