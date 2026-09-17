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
        for (K, W, Pst) in ((5.0, 10.0, 0.5), (80.0, 40.0, 5.0), (0.3, 0.2, 0.05))
            V, VK, VW, VP = value_stop_gradient(p, K, W, Pst)
            @test isfinite(V) && V == value_stop(p, K, W, Pst)
            @test isapprox(VK, fd(k -> value_stop(p, k, W, Pst), K); rtol = 1e-6)
            # the stock derivatives are differenced on the legacy term alone:
            # the cake term (~1e3) does not depend on them and would swamp a
            # derivative of order 1e-3 with rounding through the step
            @test isapprox(VW, -fd(w -> legacy_emissions_value(p, w, Pst), W); rtol = 1e-6)
            @test isapprox(VP, -fd(q -> legacy_emissions_value(p, W, q), Pst); rtol = 1e-6)
            @test VK > 0 && VW < 0 && VP < 0
        end
    end
    # the legacy value alone is the recursion's value, and a stockpile of zero
    # leaves only the decay of what is already in the air
    p = baseline_params()
    leg = legacy_emissions(p, 0.0, 1.0)
    @test leg.value == legacy_emissions_value(p, 0.0, 1.0)
    @test leg.dW > 0 && leg.dP > 0
    # where the cake-eating condition fails the value is -Inf, not a number
    @test value_stop(baseline_params(eta = 2.0), 5.0, 1.0, 0.1) == -Inf
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
    Kn, _, _, Pn, _, Wn = successor_state(pf, sol.blocks[end])
    _, VK, VW, VP = value_stop_gradient(pf, Kn, Wn, Pn)
    Lam = sol.prices[end].Lam
    m = sol.costates[end, :]
    @test isapprox(m[IQ], VK / Lam; rtol = 1e-8)
    @test isapprox(m[IPW], VW / Lam; rtol = 1e-8)
    @test isapprox(m[IPP], -VP / Lam; rtol = 1e-8)
    @test abs(m[IPS]) < 1e-9 && abs(m[IPX]) < 1e-9
    @test pseries(sol, :tauW)[end] > 0
    # the scored value is the path's felicity plus the discounted V_stop
    bet = discount(pf)
    U = sum(bet^t * (util(pf, sol.blocks[t+1].C) - disutil(pf, sol.blocks[t+1].Pst))
            for t in 0:mo.T)
    @test isapprox(res.best.value, U + bet^(mo.T + 1) * value_stop(pf, Kn, Wn, Pn); rtol = 1e-12)
end
