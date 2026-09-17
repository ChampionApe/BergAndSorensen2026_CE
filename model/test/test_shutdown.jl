# The shutdown branch: the value of the shutdown state, its handover to the
# smooth system, and the search over the shutdown date.  Included from
# runtests.jl inside the top-level testset; `P`, `S0` and `fd` are its.

@testset "V_stop gradient" begin
    # The terminal block prices the handover with the exact derivatives of
    # V_stop; a finite difference of the value is what used to stall the
    # solver (terminal_shutdown!).  The two must agree where the finite
    # difference is accurate, on both tail families and with saturating decay.
    for p in (baseline_params(), baseline_params(eta = 1.0),
              baseline_params(thetaP = 0.5, varphi = 1.5))
        for (K, W, Pst, MK) in ((5.0, 10.0, 0.5, 2.0), (80.0, 40.0, 5.0, 8.0),
                                (0.3, 0.2, 0.05, 0.1))
            V, VK, VW, VP, VM = value_stop_gradient(p, K, W, Pst, MK)
            @test isfinite(V) && V == value_stop(p, K, W, Pst, MK)
            @test isapprox(VK, fd(k -> value_stop(p, k, W, Pst, MK), K); rtol = 1e-6)
            # the stock derivatives are differenced on the legacy term alone:
            # the cake term (~1e3) does not depend on them and would swamp a
            # derivative of order 1e-3 with rounding through the step
            @test isapprox(VW, -fd(w -> legacy_emissions_value(p, w, Pst, MK), W); rtol = 1e-6)
            @test isapprox(VP, -fd(q -> legacy_emissions_value(p, W, q, MK), Pst); rtol = 1e-6)
            @test isapprox(VM, -fd(m -> legacy_emissions_value(p, W, Pst, m), MK); rtol = 1e-6)
            @test VK > 0 && VW < 0 && VP < 0 && VM < 0
            # the derivatives satisfy the aftermath's own costate recursions:
            # one step forward along W' = (1-mu)W + delta MK, MK' = (1-delta)MK,
            # P' = P + mu W - theta(P)P, the envelope conditions of L(W,P,MK) =
            # v(P) + beta L(W',P',MK') hold with the recursion's own retention
            bet = discount(p)
            L0 = legacy_emissions(p, W, Pst, MK)
            th, ret = decay(p, Pst)
            L1 = legacy_emissions(p, (1 - p.mu_h) * W + p.delta * MK,
                                  Pst + p.mu_h * W - th * Pst, (1 - p.delta) * MK)
            @test isapprox(L0.dW, bet * ((1 - p.mu_h) * L1.dW + p.mu_h * L1.dP); rtol = 1e-9)
            @test isapprox(L0.dMK, bet * (p.delta * L1.dW + (1 - p.delta) * L1.dMK); rtol = 1e-9)
            @test isapprox(L0.dP, vprime(p, Pst) + bet * ret * L1.dP; rtol = 1e-9)
        end
    end
    p = baseline_params()
    # the legacy value alone is the recursion's value; with nothing embodied
    # the stream is the theory's no-inflow recursion, and embodied material
    # adds to it -- V_stop understated the legacy damage before the inflow
    leg = legacy_emissions(p, 0.0, 1.0, 0.0)
    @test leg.value == legacy_emissions_value(p, 0.0, 1.0, 0.0)
    @test leg.dW > 0 && leg.dP > 0 && leg.dMK > 0
    @test legacy_emissions_value(p, 10.0, 0.5, 2.0) > legacy_emissions_value(p, 10.0, 0.5, 0.0)
    # every tonne embodied ends up in the air: with no decay of the pollution
    # stock, the cumulated undiscounted emission of MK is MK itself, so with
    # linear disutility and no discounting the inflow's value is v'(.) * MK
    pl = baseline_params(theta0 = 1e-9, theta_min = 1e-9, varphi = 0.0, rho = 1e-9)
    @test isapprox(legacy_emissions_value(pl, 0.0, 0.0, 2.0; horizon = 20000),
                   pl.psi_v * 2.0 * 20000 - pl.psi_v * 2.0 * (1 / pl.delta + 1 / pl.mu_h);
                   rtol = 1e-2)
    # where the cake-eating condition fails the value is -Inf, not a number
    @test value_stop(baseline_params(eta = 2.0), 5.0, 1.0, 0.1, 1.0) == -Inf
end

@testset "shutdown-date search on the floor calibration" begin
    pf = baseline_params(Rbar = 0.35)
    dates = 25:25:150
    res = solve_with_shutdown(pf, S0, dates)
    @test length(res.table) == length(dates)
    # every date the search visits converges, or says why it was skipped
    for row in res.table
        @test row.ok || !isempty(row.reason)
        row.ok && @test row.resid < 1e-9
        row.ok && @test row.route in (:warm, :cold)
    end
    @test all(row -> row.ok, res.table)
    @test res.best !== nothing
    # the objective is finite and monotone on this calibration: the floor is
    # never reached, so operating one period longer is always better and the
    # search returns the last date offered rather than an interior one
    vals = [row.value for row in res.table]
    @test all(isfinite, vals)
    @test issorted(vals)
    @test res.best.Td == last(dates)

    # the best path satisfies what every solved path must
    mo, x = res.best.mo, res.best.x
    r = check_path(mo, x; verbose = false)
    @test r.ledger_rel_error < 1e-7
    @test isempty(r.periods_below_floor)
    @test r.cumulative_N <= r.cumulative_N_bound
    @test compare_residuals(mo, x) < 1e-10

    # and the handover prices the stocks handed over: the terminal costates
    # are the derivatives of V_stop per unit of income, reserves and
    # discoveries are worthless, and the gate fee is positive at the end
    sol = unpack(mo, x)
    Kn, _, _, Pn, MKn, Wn = successor_state(pf, sol.blocks[end])
    _, VK, VW, VP, VM = value_stop_gradient(pf, Kn, Wn, Pn, MKn)
    Lam = sol.prices[end].Lam
    m = sol.costates[end, :]
    @test isapprox(m[IQ], VK / Lam; rtol = 1e-8)
    @test isapprox(m[IPW], VW / Lam; rtol = 1e-8)
    @test isapprox(m[IPP], -VP / Lam; rtol = 1e-8)
    @test isapprox(m[IPM], -VM / Lam; rtol = 1e-8)
    @test abs(m[IPS]) < 1e-9 && abs(m[IPX]) < 1e-9
    @test pseries(sol, :tauW)[end] > 0
    # the embodied material is a liability at the handover, priced below the
    # stockpile's tonne because it reaches the stockpile only as the capital
    # depreciates
    @test 0 < m[IPM] < -m[IPW]
    # the scored value is the path's felicity plus the discounted V_stop
    bet = discount(pf)
    U = sum(bet^t * (util(pf, sol.blocks[t+1].C) - disutil(pf, sol.blocks[t+1].Pst))
            for t in 0:mo.T)
    @test isapprox(res.best.value, U + bet^(mo.T + 1) * value_stop(pf, Kn, Wn, Pn, MKn); rtol = 1e-12)
end
