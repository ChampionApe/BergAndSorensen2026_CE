using Test, Random, LinearAlgebra

include(joinpath(@__DIR__, "..", "src", "CircularEconomy.jl"))
using .CircularEconomy

const P = baseline_params()
const S0 = baseline_states()

"Central finite difference."
fd(f, x; h = 1e-6) = (f(x + h * max(abs(x), 1)) - f(x - h * max(abs(x), 1))) /
                     (2h * max(abs(x), 1))

@testset "CircularEconomy" begin

@testset "parameter restrictions" begin
    @test isempty(check_params(P))
    # the post-shutdown restriction is (1-delta)^(1-eta) < 1+rho and it binds
    @test !isempty(check_params(baseline_params(eta = 2.0)))
    @test isempty(check_params(baseline_params(eta = 2.0, rho = 0.06)))
    # mu_h = 1 is admissible -- the one-period buffer -- and only mu_h outside
    # (0,1] is refused
    @test isempty(check_params(baseline_params(mu_h = 1.0)))
    @test !isempty(check_params(baseline_params(mu_h = 1.2)))
    @test !isempty(check_params(baseline_params(mu_h = 0.0)))
end

@testset "yield function" begin
    # The globally concave forms: the exponential tail at any xi, and the power
    # tail only for psi <= 1.
    for (tail, psia) in ((:exp, 2.0), (:power, 1.0), (:power, 0.7)), abar in (0.7, 1.0)
        p = baseline_params(tail = tail, abar = abar, psi_a = psia)
        a0, ap0, al0 = recycling_yield(p, 0.0)
        @test a0 == 0                       # a(0) = 0
        @test al0 == 0                      # alpha(0) = 0
        prev = -Inf
        for x in (0.1, 0.5, 1.0, 2.0, 5.0, 20.0)
            a, ap, al = recycling_yield(p, x)
            @test 0 < a < abar + 1e-12      # bounded by the ceiling
            @test ap > 0                    # a' > 0
            @test isapprox(al, a - ap * x; atol = 1e-12)   # alpha = a - a'x
            # concavity gives 0 <= alpha <= abar; at large x, alpha reaches abar
            # to floating-point precision, so the upper bound is not strict here
            @test 0 <= al <= abar + 1e-12
            @test a > prev; prev = a        # strictly increasing
            # a' is tiny at large x on the exponential tail, so the finite
            # difference needs an absolute tolerance as well as a relative one
            @test isapprox(ap, fd(y -> recycling_yield(p, y)[1], x); rtol = 1e-4, atol = 1e-10)
        end
        # approaches the ceiling; the power tail does so only polynomially, so
        # the tolerance is set by the tail rather than by arithmetic
        @test isapprox(recycling_yield(p, 1e8)[1], abar; rtol = 1e-3)
        # a'' < 0 everywhere on the concave forms
        @test recycling_yield(p, 0.5)[2] > recycling_yield(p, 1.0)[2] >
              recycling_yield(p, 2.0)[2]
    end
end

@testset "the power tail is S-shaped for psi > 1" begin
    # a = abar*u/(1+u) with u = (xi x)^psi behaves like abar*(xi x)^psi near the
    # origin, so for psi > 1 it is convex there: a'' > 0, a' is non-monotone,
    # and alpha = a - a'x goes negative.  This violates the maintained
    # assumption a'' < 0, and check_params says so.  It remains an admissible
    # description of the *tail*, which is all the closure criterion uses.
    p = baseline_params(tail = :power, abar = 1.0, psi_a = 2.0)
    @test any(occursin.("S-shaped", check_params(p)))
    @test recycling_yield(p, 0.05)[3] < 0                      # alpha < 0 near 0
    @test recycling_yield(p, 0.01)[2] < recycling_yield(p, 0.1)[2]   # a' rising: a'' > 0
    @test recycling_yield(p, 5.0)[3] > 0                       # but fine in the tail
    @test recycling_yield(p, 50.0)[2] < recycling_yield(p, 5.0)[2]   # and a'' < 0 there
end

@testset "tail elasticity classifies the tail" begin
    pe = baseline_params(tail = :exp, abar = 1.0)
    pp = baseline_params(tail = :power, abar = 1.0, psi_a = 2.0)
    @test tail_elasticity(pe, 10.0) > tail_elasticity(pe, 1.0)      # -> infinity
    @test isapprox(tail_elasticity(pp, 1e4), 2.0; rtol = 1e-3)      # -> psi
end

@testset "production derivatives" begin
    for ss in (1.0, 2.0, 0.5, Inf)
        p = baseline_params(sigma_s = ss)
        KY, R, Pst = 2.5, 0.7, 0.4
        Y, FK, FR, FP, ok = production(p, 3, KY, R, Pst)
        @test ok && Y > 0
        @test isapprox(FK, fd(k -> production(p, 3, k, R, Pst)[1], KY); rtol = 1e-5)
        @test isapprox(FR, fd(r -> production(p, 3, KY, r, Pst)[1], R); rtol = 1e-5)
        @test isapprox(FP, fd(q -> production(p, 3, KY, R, q)[1], Pst); rtol = 1e-5)
    end
    # the material floor: nothing is produced below it
    pf = baseline_params(Rbar = 0.5)
    @test production(pf, 0, 2.0, 0.4, 0.0)[5] == false
    @test production(pf, 0, 2.0, 0.4, 0.0)[1] == 0
    @test production(pf, 0, 2.0, 0.6, 0.0)[5] == true
end

@testset "cost function derivatives" begin
    p = baseline_params()
    CN, CN_N, CN_S = extraction(p, 5, 0.4, 12.0)
    @test isapprox(CN_N, fd(n -> extraction(p, 5, n, 12.0)[1], 0.4); rtol = 1e-5)
    @test isapprox(CN_S, fd(s -> extraction(p, 5, 0.4, s)[1], 12.0); rtol = 1e-5)
    @test CN_S < 0                                   # a larger reserve is cheaper
    CD, CD_D, CD_X = exploration(p, 5, 0.2, 30.0)
    @test isapprox(CD_D, fd(d -> exploration(p, 5, d, 30.0)[1], 0.2); rtol = 1e-5)
    @test isapprox(CD_X, fd(xx -> exploration(p, 5, 0.2, xx)[1], 30.0); rtol = 1e-5)
    @test CD_X > 0                                   # past discovery is a liability
    @test extraction(p, 5, 0.0, 12.0)[1] == 0        # C^N(0,S) = 0
    @test exploration(p, 5, 0.0, 30.0)[1] == 0       # C^D(0,X) = 0
    # marginal exploration cost diverges at the ceiling
    @test exploration(p, 5, 0.0, p.Xmax - 1e-8)[2] > 1e6
    # marginal treatment cost is zero at varpi = 0 (the choke is the collection charge)
    @test isapprox(handling_cost(p, 0, 0.0)[2], p.cc0)
    @test isapprox(handling_cost(p, 0, 1.0)[2], p.cc0 + p.cT0)    # and finite at varpi = 1
end

@testset "complementarity map" begin
    # interior: reduces to f = 0
    @test mcp(0.5, 0.0, 0.0, 1.0, 0.0) == 0
    # lower corner with a negative gain is a solution
    @test mcp(0.0, -3.0, 0.0, Inf, 0.0) == 0
    # lower corner with a positive gain is not
    @test mcp(0.0, 3.0, 0.0, Inf, 0.0) != 0
    # upper corner with a positive gain is a solution
    @test mcp(1.0, 3.0, 0.0, 1.0, 0.0) == 0
    # a control outside its box can never solve
    @test mcp(-0.2, 0.0, 0.0, 1.0, 0.0) != 0
    @test mcp(1.2, 0.0, 0.0, 1.0, 0.0) != 0
    # smoothing vanishes as e -> 0
    @test abs(mcp(0.5, 0.1, 0.0, 1.0, 1e-8) - mcp(0.5, 0.1, 0.0, 1.0, 0.0)) < 1e-7
end

@testset "materials accounting identities" begin
    Random.seed!(20260826)
    for _ in 1:50
        s = [3 + rand(), 15 + 5rand(), 25 + rand(), 0.5rand(), 1 + rand(), 1 + 3rand()]
        c = [0.4 + 0.3rand(), 0.05rand(), 0.3rand(), 0.05rand(), rand(), 0.05rand()]
        b = period_block(P, 3, s, c)
        b.feasible || continue
        # the intensity condition, solved for Omega
        @test isapprox(b.R, b.Omega * (b.Dbase + P.phiI * b.G); rtol = 1e-12)
        # the ledger
        @test isapprox(b.W, b.R - b.Omega * P.phiI * b.G + P.delta * b.MK + b.Nbase;
                       rtol = 1e-12)
        # the storage share
        @test isapprox(b.sigma, b.Omega * P.phiI * b.G / b.R; rtol = 1e-12)
        # emissions written linearly in H and R^R
        @test isapprox(b.Xi, (1 - b.vw + P.dW * b.vw * (1 - b.a)) * b.H; rtol = 1e-10)
        # the throughput cap of Lemma "stock bound and throughput cap"
        @test b.R <= b.N + P.abar * P.mu_h * s[IWS] + 1e-10
    end
end

@testset "planner and market residuals coincide at the planner corner" begin
    # This is Proposition "decentralisation" as an algebraic identity, checked
    # at arbitrary points rather than only at a solution.
    Random.seed!(1850)
    mo = Model(P; T = 12, s0 = S0)
    x = initial_guess(mo; Rtarget = 0.6, warn = false)
    for _ in 1:20
        y = x .* (1 .+ 0.15 .* randn(length(x)))
        gap = compare_residuals(mo, y)
        @test gap < 1e-10
    end
    # and away from the corner they must differ, or the dials do nothing
    mo2 = Model(baseline_params(phiP = 0.0); T = 12, s0 = S0)
    x2 = initial_guess(mo2; Rtarget = 0.6, warn = false)
    @test compare_residuals(mo2, x2) > 1e-8
end

@testset "long-run rate formulae" begin
    p = baseline_params()
    # the circular growth rate solves the production row
    g = cbgp_growth(p)
    @test isapprox((1 - beta_K(p)) * g, p.gA + gamma_R(p) * p.gB; rtol = 1e-12)
    # the BDP rates solve both rows jointly
    gb, nu = bdp_rates(p)
    @test isapprox((1 - beta_K(p)) * gb, p.gA + gamma_R(p) * (p.gB - nu); rtol = 1e-10)
    @test isapprox((p.mu_N - 1) * nu, gb; rtol = 1e-10)
    # balanced dematerialization is strictly slower than the closed loop
    @test gb < g
    # mu_N = 1 is the sustained-level case, not a failure
    g1, nu1 = bdp_rates(baseline_params(mu_N = 1.0))
    @test isapprox(g1, 0.0; atol = 1e-12)
    @test isapprox(nu1, p.gB + p.gA / gamma_R(p); rtol = 1e-10)
    # and outside the admissible region there is no exponential BDP
    @test bdp_rates(baseline_params(mu_N = 0.1)) === nothing
end

@testset "circular balanced growth path block" begin
    p = baseline_params()
    c = cbgp(p; Minf = 30.0)
    # Little's law
    @test isapprox(c.Rinf * c.residence, 30.0; rtol = 1e-10)
    @test isapprox(c.residence, 1 / p.mu_h + c.sigma_inf / p.delta; rtol = 1e-12)
    # the closed form solves the block it came from
    @test isapprox(c.Psi_hat, gamma_R(p) * (1 - c.zeta_hat * c.Omega_hat * p.omY) + c.zeta_hat;
                   rtol = 1e-10)
    @test isapprox(c.zeta_hat, c.sigma_inf * (1 - c.DeltaM) * c.pW_hat; rtol = 1e-10)
    @test isapprox(c.pW_hat, -c.ThetaW * c.Psi_hat; rtol = 1e-12)
    # signs: waste is an asset, embodied material carries a negative price,
    # installed capital is worth more than its goods cost
    @test c.pW_hat < 0
    @test c.zeta_hat < 0
    @test c.q_inf > 1
    @test 0 < c.DeltaM < 1
    # regularity: the consumption wedge must stay positive
    @test c.consumption_wedge > 0
    # a patient planner values the stockpile more
    @test cbgp(with(p; rho = 0.005); Minf = 30.0).ThetaW > c.ThetaW
    # the survival condition fails when the floor is too high
    @test_throws ErrorException cbgp(with(p; Rbar = 10.0); Minf = 30.0)
end

@testset "closure criterion" begin
    # a hard ceiling can never close the loop
    @test closure_check(baseline_params(abar = 0.7)).closes == false
    # the exponential tail closes it, with x rising linearly (log growth -> 0)
    ce = closure_check(baseline_params(tail = :exp, abar = 1.0); A = 0.5)
    @test ce.closes
    @test ce.x_growth_relative_to_g < 0.1
    # the power tail closes it too, with x growing at exactly g/(1+psi)
    for psia in (1.0, 2.0, 3.0)
        cp = closure_check(baseline_params(tail = :power, abar = 1.0, psi_a = psia); A = 0.5)
        @test cp.closes
        @test isapprox(cp.x_growth_relative_to_g, 1 / (1 + psia); rtol = 0.02)
    end
end

@testset "long-run classifier" begin
    # The taxonomy of Section "Taxonomy".  A hard ceiling decides from the
    # parameters alone: with a floor the material era has bounded duration,
    # without one the material block decays exponentially.
    sA, mA = classify_longrun(baseline_params(abar = 0.7, Rbar = 0.35))
    @test sA == :A
    @test mA.floor && mA.hard_ceiling && !mA.closes
    sB, mB = classify_longrun(baseline_params(abar = 0.7))
    @test sB == :B
    @test !mB.floor && mB.hard_ceiling
    # the soft ceiling without a floor needs only the closure criterion
    @test classify_longrun(baseline_params())[1] == :C
    # with a floor it needs a path, and the parameter method says so
    @test_throws ErrorException classify_longrun(baseline_params(Rbar = 0.35))

    # the illustrative baseline converges to the CBGP (README, "What is
    # verified"), which is state C
    mo = Model(P; T = 60, s0 = S0)
    x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
    @test ok
    s, m = classify_longrun(mo, x)
    @test s == :C
    @test m.closes && !m.floor && !m.hard_ceiling
    @test isfinite(m.leak_sum)
    @test m.Minf > 0
    @test isapprox(m.residence, 1 / P.mu_h + m.sigma / P.delta; rtol = 1e-12)
    @test m.survival_ratio == Inf
    # the survival condition, read against the same path's retained endowment:
    # a floor below the path's own turnover flow M_inf / T is cleared, one
    # above it is not, and the margin reported is the ratio of the two
    Rflow = m.Minf / m.residence
    sC, mC = classify_longrun(with(P; Rbar = 0.5 * Rflow); Minf = m.Minf, sigma = m.sigma, A = m.A)
    @test sC == :C
    @test isapprox(mC.survival_ratio, 2.0; rtol = 1e-10)
    sA2, mA2 = classify_longrun(with(P; Rbar = 2.0 * Rflow); Minf = m.Minf, sigma = m.sigma, A = m.A)
    @test sA2 == :A
    @test isapprox(mA2.survival_ratio, 0.5; rtol = 1e-10)
end

@testset "the stationary rest point is a return point" begin
    # Verification item 3 of the quantitative note, the benchmark half: with
    # the trends off, the linear aggregate and the terminal closure at Gam = 1,
    # a path started a few percent away from the closed-form dematerialized
    # rest point of Appendix D returns to it.  At these parameters the closed
    # form strands the whole reserve, so no tonne is ever extracted and the
    # material stocks drain towards zero at the handling share.
    p = baseline_params(gA = 0.0, gB = 0.0, sigma_s = Inf)
    rp = restpoint_stationary(p)
    @test rp.all_stranded
    kick = 0.03
    mo = Model(p; T = 60, s0 = [(1 + kick) * rp.K, 20.0, 25.0, 0.02, 0.05, 0.05], Gam = 1.0)
    x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.0, warn = false))
    @test ok
    sol = unpack(mo, x)
    b = sol.blocks[end]; m = sol.costates[end, :]
    # the goods block returns: closer at T than the shock, and within tolerance
    @test abs(b.K / rp.K - 1) < 1e-3 < kick
    @test isapprox(b.Y, rp.Y; rtol = 1e-3)
    @test isapprox(b.C, rp.C; rtol = 5e-3)
    # the reserve is never touched and the material flow has all but vanished
    @test maximum(series(sol, :N)) < 1e-10
    @test b.R < 1e-2
    # the prices return to the closed form.  The rest point reports the
    # stockpile price in the workhorse's sign, which is the gate fee tauW = -pW.
    @test isapprox(m[IQ], 1.0; atol = 1e-3)
    @test isapprox(m[IPP], rp.pP; rtol = 1e-3)
    @test isapprox(m[IPM], rp.pM; rtol = 1e-3)
    @test isapprox(pseries(sol, :tauW)[end], rp.pW; rtol = 1e-3)
    @test abs(m[IPS]) < 1e-8 && abs(m[IPX]) < 1e-8
    # and so do the recycling margins
    @test isapprox(b.x, rp.x; rtol = 1e-2)
    @test isapprox(b.vw, rp.varpi; atol = 1e-9)
    @test check_path(mo, x; verbose = false).ledger_rel_error < 1e-7
end

@testset "the shutdown state" begin
    p = baseline_params()
    s_stop, gC = cake_policy(p)
    @test s_stop > 0
    @test isapprox(gC, ((1 - p.delta) / (1 + p.rho))^(1 / p.eta))
    # the cake path satisfies its own Euler equation and its own budget
    K = 5.0
    C0 = s_stop * K
    K1 = (1 - p.delta) * K - C0
    @test isapprox(K1, gC * K; rtol = 1e-12)
    C1 = s_stop * K1
    @test isapprox(uprime(p, C0), discount(p) * (1 - p.delta) * uprime(p, C1); rtol = 1e-10)
    # more capital, and less waste in the ground, in the air or embodied in
    # the capital being eaten, are all better
    @test value_stop(p, 6.0, 10.0, 0.5, 2.0) > value_stop(p, 5.0, 10.0, 0.5, 2.0)
    @test value_stop(p, 5.0, 10.0, 0.5, 2.0) > value_stop(p, 5.0, 20.0, 0.5, 2.0)
    @test value_stop(p, 5.0, 10.0, 0.5, 2.0) > value_stop(p, 5.0, 10.0, 1.5, 2.0)
    @test value_stop(p, 5.0, 10.0, 0.5, 2.0) > value_stop(p, 5.0, 10.0, 0.5, 4.0)
end

@testset "a solved path" begin
    mo = Model(P; T = 60, s0 = S0)
    x, ok, nrm = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
    @test ok
    @test nrm < 1e-8
    sol = unpack(mo, x)
    # every period is above the floor and produces
    @test all(b -> b.feasible, sol.blocks)
    @test all(b -> b.Y > 0 && b.C > 0, sol.blocks)
    r = check_path(mo, x; verbose = false)
    # the collected ledger holds, which ties the accounting to the transitions
    @test r.ledger_rel_error < 1e-7
    # the cumulative bounds of Section "The material budget"
    @test r.cumulative_N <= r.cumulative_N_bound
    @test r.cumulative_leakage <= r.material_budget
    # market and planner transcriptions still agree at the solution
    @test compare_residuals(mo, x) < 1e-10
    # the treatment share sits in its box and the loop is partially closed
    @test all(b -> -1e-9 <= b.vw <= 1 + 1e-9, sol.blocks)
    @test effective_survival(P, sol.blocks[end]) > 1 - P.mu_h
end

@testset "mu_h = 1 (buffer corner)" begin
    # The one-period buffer: the stockpile is last period's waste flow and
    # nothing runs off, W_{t+1} = W_t.  The corner is admissible, not
    # degenerate -- nothing divides by 1 - mu_h, the stockpile costate
    # recursion collapses to pW_t = h_{t+1}/(1+r) because the survival term
    # drops out, and Little's law gives a residence time of 1 + sigma/delta.
    p1 = baseline_params(mu_h = 1.0)
    @test isempty(check_params(p1))

    # the two transcriptions still agree at the planner corner, at arbitrary
    # points of the state and control space
    Random.seed!(1851)
    mo = Model(p1; T = 12, s0 = S0)
    xg = initial_guess(mo; Rtarget = 0.6, warn = false)
    for _ in 1:20
        y = xg .* (1 .+ 0.15 .* randn(length(xg)))
        @test compare_residuals(mo, y) < 1e-10
    end

    # a horizon solves, and on the solved path the ledger holds period by
    # period and the stockpile carries exactly one period of waste
    mo1 = Model(p1; T = 60, s0 = S0)
    x1, ok, _ = solve_path(mo1, initial_guess(mo1; Rtarget = 0.6, warn = false))
    @test ok
    sol = unpack(mo1, x1)
    @test all(b -> b.feasible, sol.blocks)
    @test check_path(mo1, x1; verbose = false).ledger_rel_error < 1e-7
    @test maximum(abs(sol.states[t+2, IWS] - sol.blocks[t+1].W) for t in 0:mo1.T-1) < 1e-8
    # the effective survival factor is alpha*varpi here, not 1 - mu = 0: at the
    # corner the stockpile survives only through the material it returns
    @test isapprox(effective_survival(p1, sol.blocks[end]),
                   sol.blocks[end].alpha * sol.blocks[end].vw; rtol = 1e-12)

    # the CBGP block is computable at the corner and Little's law reads 1 + sigma/delta
    c = cbgp(p1; Minf = 30.0)
    @test isapprox(c.residence, 1 + c.sigma_inf / p1.delta; rtol = 1e-12)
    @test isapprox(c.Rinf * c.residence, 30.0; rtol = 1e-10)
    @test c.pW_hat < 0
end

@testset "policy dials move the allocation the right way" begin
    # A long horizon is needed here, not for accuracy of the path but because
    # welfare is compared across policies: at rho = 1.5% a 60-period truncation
    # leaves 40% of the discounted weight in the terminal approximation, which
    # is not comparable across policies and can reverse the ranking.
    T = 150
    solve_for(p) = begin
        mo = Model(p; T = T, s0 = S0)
        x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
        ok || return nothing
        sol = unpack(mo, x)
        (; U = welfare(mo, x),
           leak = sum((1 - b.a * b.vw) * b.H for b in sol.blocks),
           Minf = sol.states[end, IMK] + sol.states[end, IWS])
    end
    base = solve_for(baseline_params())
    @test base !== nothing
    for kw in ((phiP = 0.0,), (phiz = 0.0,), (phiX = 0.0,), (phiW = 0.0,),
               (phiW = 0.0, phiz = 0.0, phiP = 0.0, phiX = 0.0))
        alt = solve_for(baseline_params(; kw...))
        @test alt !== nothing
        # the planner corner maximises welfare
        @test alt.U <= base.U + 1e-8
    end
    # Dropping the emission tax unambiguously raises cumulative leakage: the
    # treatment share and the recycling yield both fall.
    nop = solve_for(baseline_params(phiP = 0.0))
    @test nop.leak > base.leak
    # Its effect on the retained endowment is *not* unambiguous, and this is
    # worth recording rather than asserting away.  Two channels run against
    # each other: more leakage takes mass out, but the cheaper (untaxed) waste
    # stream also means more virgin extraction, which brings mass in with its
    # overburden.  Which dominates depends on the horizon -- at T = 60 the
    # inflow channel wins, by T = 150 the leakage channel does.
    @test nop.Minf < base.Minf
end

@testset "perspective functions are the convexity of the recycling block" begin
    # The claim of Appendix "Sufficiency": with treated tonnage T as the control
    # rather than the treated share, both the recycling technology and the
    # handling cost appear as perspective functions.
    mid(f, a, b) = f((a .+ b) ./ 2) - (f(a) + f(b)) / 2   # > 0 => concave here

    # R(T,KR) = T a(KR/T) is concave iff a is concave
    pe = baseline_params(tail = :exp, abar = 1.0)
    Rp(p) = v -> v[1] * recycling_yield(p, v[2] / v[1])[1]
    Random.seed!(7)
    for _ in 1:40
        a = [0.5 + rand(), 0.5 + rand()]
        b = [0.5 + rand(), 0.5 + rand()]
        @test mid(Rp(pe), a, b) >= -1e-12          # concave
    end
    # and it is NOT concave when a is not.  The S-shaped power tail is convex
    # only close to the origin, so the violation has to be looked for there.
    pp = baseline_params(tail = :power, abar = 1.0, psi_a = 2.0)
    @test mid(Rp(pp), [1.0, 0.01], [1.0, 0.2]) < -1e-10

    # H cT(T/H) is jointly convex in (T,H)
    p = baseline_params()
    cTp = v -> v[2] * (p.cT0 * (v[1] / v[2])^(1 + p.chi_T) / (1 + p.chi_T))
    for _ in 1:40
        a = [0.1 + rand(), 1.0 + rand()]
        b = [0.1 + rand(), 1.0 + rand()]
        @test mid(cTp, a, b) <= 1e-12              # convex
    end
end

@testset "convexity report" begin
    r = convexity_report(P; verbose = false)
    @test length(r) == 8
    byname = Dict(x.name => x for x in r)
    # the baseline violates exactly the conditions the appendix says it does
    @test byname["C1 technology"].holds
    @test byname["C2 recycling"].holds          # exponential tail is concave
    @test byname["C2 treatment"].holds
    @test byname["C4 decay"].holds              # thetaP = 0, so linear
    @test !byname["C1 damages"].holds           # multiplicative damages
    @test !byname["C3 extraction"].holds        # finite choke kap_N > 0
    @test !byname["C5 intensity"].holds         # phiI > 0

    # a parameter set meeting every condition: the convexified problem is concave
    clean = baseline_params(kappa = 0.0, phiI = 0.0, kap_N = 0.0, kap_D = 0.0,
                            chi_N = 1.6, chi_D = 1.6, thetaP = 0.0,
                            tail = :exp, abar = 1.0)
    @test all(x -> x.holds, convexity_report(clean; verbose = false))

    # and the power tail with psi > 1 breaks the recycling condition
    pw = convexity_report(baseline_params(tail = :power, psi_a = 2.0); verbose = false)
    @test !Dict(x.name => x for x in pw)["C2 recycling"].holds
end

@testset "transversality report" begin
    mo = Model(P; T = 60, s0 = S0)
    x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
    @test ok
    r = tvc_report(mo, x; verbose = false)
    @test r.asymptotic_ok                       # beta e^{(1-eta)g} < 1
    @test all(isfinite, r.terms)
    # the capital condition is condition (i) of the long-run assumptions, read
    # off the report rather than transcribed a second time
    @test r.asymptotic_ok == (r.capital_tvc_factor < 1)
    @test length(r.wellposed) == 5
    @test all(x -> x.holds, r.wellposed)
    @test isapprox(r.g, cbgp_growth(P); rtol = 1e-12)
    # nu is measured on the path's own material input; the baseline is still
    # converging from below at T = 60, so the measured rate is not positive and
    # the conditions are evaluated at the binding value nu = 0
    @test r.nu_path <= 0
    # violating Assumption "bounded values" makes the capital condition fail
    bad = baseline_params(eta = 0.5, rho = 0.005)
    mob = Model(bad; T = 10, s0 = S0)
    @test tvc_report(mob, initial_guess(mob; Rtarget = 0.6, warn = false);
                     verbose = false).asymptotic_ok == false
end

@testset "the long-run assumptions" begin
    # Assumption "well-posedness and regularity" of the theory note: (i) makes
    # lifetime utility converge, (ii) makes the balanced price blocks finite and
    # of the right sign, (iii) makes collapse paths rankable.  (i) and (iii) are
    # conditions on primitives and check_params carries them; the rows of (ii)
    # need the cell's material decay rate nu and only exist here.
    byname(r) = Dict(x.name => x for x in r)

    # the illustrative baseline satisfies all of them on the circular path
    base = wellposed_report(P; verbose = false)
    @test length(base) == 5
    @test all(x -> x.holds, base)

    # but not at the balanced-dematerialization rates of the same parameters:
    # nu = 3.1% per period is fast enough that the reserve rent does not sum.
    # That is a property of the illustrative numbers, not of the model, and it
    # is why the report is evaluated at a cell rather than at primitives.
    gb, nu = bdp_rates(P)
    bd = byname(wellposed_report(P; g = gb, nu = nu, verbose = false))
    @test !bd["(ii) regularity"].holds

    # (i) fails when a patient planner meets a low eta, and check_params says so
    # at the circular rate, the one growth rate the primitives fix
    slow = baseline_params(eta = 0.5, rho = 0.005)
    @test !byname(wellposed_report(slow; verbose = false))["(i) well-posedness"].holds
    @test any(occursin.("log(1+rho) > (1-eta)*g", check_params(slow)))

    # (ii) and its two consequences fail in turn as nu rises: the parent first,
    # then the rows carrying the survival factors 1-delta and 1-mu
    mild = byname(wellposed_report(P; nu = 0.03, verbose = false))
    @test !mild["(ii) regularity"].holds
    @test mild["(ii) embodied M"].holds
    @test mild["(ii) stockpile"].holds
    fast = byname(wellposed_report(P; nu = 0.5, verbose = false))
    @test !fast["(ii) regularity"].holds
    @test !fast["(ii) embodied M"].holds
    @test !fast["(ii) stockpile"].holds
    # at the buffer corner the stockpile row is vacuous: 1 - mu = 0 < 1 + r
    @test byname(wellposed_report(baseline_params(mu_h = 1.0); nu = 0.5,
                                  verbose = false))["(ii) stockpile"].holds

    # (iii) fails at eta = 2 with delta = 0.05 unless rho rises with it, which
    # is why the illustrative set holds eta = 1.1
    hi = baseline_params(eta = 2.0)
    @test !byname(wellposed_report(hi; verbose = false))["(iii) cake-eating"].holds
    @test any(occursin.("cake-eating", check_params(hi)))
    @test all(x -> x.holds,
              wellposed_report(baseline_params(eta = 2.0, rho = 0.06); verbose = false))
end

@testset "feasible-direction tests" begin
    mo = Model(P; T = 80, s0 = S0)
    x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
    @test ok

    # the candidate must be reproducible by forward simulation with consumption
    # taken residually -- this is what makes the deviations feasible by
    # construction, and it is a real check on the within-period ordering
    sol = unpack(mo, x)
    _, blocks, okf = simulate_from_controls(mo, sol.controls)
    @test okf
    @test maximum(abs(blocks[t].C - sol.blocks[t].C) for t in 1:mo.T+1) < 1e-8

    # a non-critical point must be refused
    bad = copy(x); bad[7] *= 1.5
    @test_throws ErrorException perturbation_test(mo, bad; ndraws = 2, verbose = false)
    @test_throws ErrorException deviation_profile(mo, bad; verbose = false)

    # no random feasible deviation beats the candidate
    pt = perturbation_test(mo, x; ndraws = 120, verbose = false)
    @test pt.feasible_draws > 20
    @test pt.clean

    # and the profile is single-peaked at zero in each direction the appendix
    # names as a place concavity could fail
    for ctrl in (IN, II, IXR)
        pr = deviation_profile(mo, x; control = ctrl, window = 0:40,
                               grid = -0.5:0.1:0.5, verbose = false)
        @test pr.best_gain <= 1e-8 * max(abs(pr.V0), 1.0)
        @test pr.single_peaked
    end
end

@testset "absorbing shutdown" begin
    pf = baseline_params(Rbar = 0.35, abar = 0.7)
    # a depleted economy cannot restart
    poor = absorbing_shutdown(pf, [0.2, 0.01, 25.0, 0.1, 0.05, 0.05])
    @test poor.absorbing
    @test poor.slack > 0
    # one with a large capital and waste stock might
    rich = absorbing_shutdown(pf, [10.0, 5.0, 25.0, 0.5, 5.0, 40.0])
    @test !rich.absorbing
    # without a floor the question does not arise
    @test absorbing_shutdown(baseline_params(), [1.0, 1.0, 25.0, 0.1, 1.0, 1.0]).absorbing
end

@testset "horizon continuation" begin
    # extend_horizon must preserve the solved portion exactly
    mo = Model(P; T = 60, s0 = S0)
    x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
    @test ok
    mo2, x2 = extend_horizon(mo, x, 90)
    @test mo2.T == 90
    @test nvar(mo2) == 18 * 90 + 12
    s1, s2 = unpack(mo, x), unpack(mo2, x2)
    @test maximum(abs.(s1.controls .- s2.controls[1:61, :])) < 1e-12
    # states are re-derived by forward simulation rather than copied, so they
    # agree only to the accuracy with which the solved path satisfies its own
    # transitions -- which is the solver tolerance, not machine precision
    @test maximum(abs.(s1.states .- s2.states[1:61, :])) < 1e-7
    # and the extended guess must solve
    x3, ok3, _ = solve_path(mo2, x2)
    @test ok3

    # Horizon sensitivity: the window of interest must stop moving as T grows.
    # A short horizon is genuinely contaminated -- T = 60 differs from T = 250 by
    # about 10% over its own span -- so the test is that the difference shrinks,
    # not that any one horizon is right.
    mo_a, x_a, ok_a, _ = solve_long(P, S0, 150; start_T = 100, step = 50)
    mo_b, x_b, ok_b, _ = solve_long(P, S0, 250; start_T = 100, step = 50)
    @test ok_a && ok_b
    ya = series(unpack(mo_a, x_a), :Y)[1:101]
    yb = series(unpack(mo_b, x_b), :Y)[1:101]
    y0 = series(unpack(mo, x), :Y)[1:61]
    @test maximum(abs.(ya .- yb) ./ yb) < 1e-2                     # 150 vs 250: close
    @test maximum(abs.(y0 .- yb[1:61]) ./ yb[1:61]) >
          maximum(abs.(ya[1:61] .- yb[1:61]) ./ yb[1:61])          # and shrinking in T
end

@testset "hard ceiling versus soft ceiling" begin
    T = 60
    run(p) = begin
        mo = Model(p; T = T, s0 = S0)
        x, ok, _ = solve_path(mo, initial_guess(mo; Rtarget = 0.6, warn = false))
        (ok, ok ? unpack(mo, x) : nothing)
    end
    okh, solh = run(baseline_params(abar = 0.7))
    oks, sols = run(baseline_params(abar = 1.0))
    @test okh && oks
    # under a hard ceiling the yield plateaus below the ceiling and the gate fee
    # stays positive: waste remains a liability
    @test series(solh, :a)[end] < 0.7
    @test pseries(solh, :tauW)[end] > 0
    # under a soft ceiling the yield climbs towards one
    @test series(sols, :a)[end] > series(solh, :a)[end]
end

include("test_experiments.jl")   # the calibration interface and the experiment harness
include("test_shutdown.jl")      # the shutdown-date search and the handover

end # testset

