"""
Post-solution diagnostics.

Everything here is a check the model should pass without having been told to.
The five items of `writing/quant/quant_solution.tex`, Section "Verification",
are implemented as `check_path`.
"""

"""
    unpack(mo, x) -> NamedTuple of matrices

Rebuilds the solution as `(T+1) x n` matrices for states, controls, costates,
plus the per-period blocks and prices.
"""
function unpack(mo::Model, x::AbstractVector)
    T = mo.T
    S = Matrix{Float64}(undef, T + 1, NS)
    C = Matrix{Float64}(undef, T + 1, NC)
    M = Matrix{Float64}(undef, T + 1, NM)
    blocks = Vector{Any}(undef, T + 1)
    prices = Vector{Any}(undef, T + 1)
    for t in 0:T
        s = state_view(mo, x, t)
        c = ctrl_view(x, t)
        m = cost_view(x, t)
        S[t+1, :] .= s; C[t+1, :] .= c; M[t+1, :] .= m
        b = period_block(mo.p, t, s, c)
        blocks[t+1] = b
        prices[t+1] = price_block(mo.p, t, b, m)
    end
    return (; states = S, controls = C, costates = M, blocks, prices)
end

"Series accessor: `series(sol, :Y)` pulls a field out of every period block."
series(sol, f::Symbol) = [getfield(b, f) for b in sol.blocks]
pseries(sol, f::Symbol) = [getfield(pr, f) for pr in sol.prices]

"""
    check_path(mo, x; verbose = true) -> NamedTuple

Runs the five verification checks and returns their worst violations.
"""
function check_path(mo::Model, x::AbstractVector; verbose::Bool = true)
    p, T = mo.p, mo.T
    sol = unpack(mo, x)
    B, S = sol.blocks, sol.states

    # (1) the collected ledger, period by period.  This is *not* an identity of
    #     the code: W is built from the ledger, but the collected form also uses
    #     the two transitions, so a violation means the transitions and the
    #     accounting have come apart.
    ledger_err = 0.0
    for t in 0:T-1
        b = B[t+1]
        dMK = S[t+2, IMK] - S[t+1, IMK]
        dWs = S[t+2, IWS] - S[t+1, IWS]
        lhs = (1 - b.a * b.vw) * b.H
        rhs = b.N - dMK - dWs + b.Nbase
        ledger_err = max(ledger_err, abs(lhs - rhs) / max(1.0, abs(rhs)))
    end

    # (2) cumulative bounds
    cumN = sum(b.N for b in B)
    budget_N = S[1, IS] + (p.Xmax - S[1, IX])
    cum_leak = sum((1 - b.a * b.vw) * b.H for b in B)
    Bud = (1 + p.OmNS) * budget_N + p.OmDS * (p.Xmax - S[1, IX]) + S[1, IMK] + S[1, IWS]

    # (3) throughput bound under a hard ceiling
    cumH = sum(b.H for b in B)
    hard_bound = p.abar < 1 ? Bud / (1 - p.abar) : Inf

    # (4) how close is the loop
    surv = [effective_survival(p, b) for b in B]

    # (5) floor violations
    below_floor = findall(t -> !B[t].feasible, 1:T+1)

    res = (; ledger_rel_error = ledger_err,
            cumulative_N = cumN, cumulative_N_bound = budget_N,
            cumulative_leakage = cum_leak, material_budget = Bud,
            cumulative_H = cumH, hard_ceiling_bound = hard_bound,
            effective_survival_final = surv[end],
            effective_survival_max = maximum(surv),
            periods_below_floor = below_floor,
            retained_endowment = S[end, IMK] + S[end, IWS])

    if verbose
        @printf("ledger relative error      %.3e\n", res.ledger_rel_error)
        @printf("cumulative N / bound       %.4f  (%.4g / %.4g)\n",
                res.cumulative_N / res.cumulative_N_bound, res.cumulative_N,
                res.cumulative_N_bound)
        @printf("cumulative leakage / B     %.4f\n", res.cumulative_leakage / res.material_budget)
        if isfinite(res.hard_ceiling_bound)
            @printf("cumulative H / bound       %.4f\n", res.cumulative_H / res.hard_ceiling_bound)
        end
        @printf("effective survival factor  %.5f  (1 - mu = %.5f)\n",
                res.effective_survival_final, 1 - p.mu_h)
        @printf("retained endowment M_inf   %.4g\n", res.retained_endowment)
        isempty(below_floor) || @printf("PERIODS BELOW THE FLOOR:   %d\n", length(below_floor))
    end
    return res
end

"""
    welfare(mo, x; include_terminal = true) -> Float64

Discounted lifetime utility along the path.  When `include_terminal`, the tail
beyond `T` is valued by continuing consumption at the terminal growth factor,
which is consistent with the terminal closure of the costates.
"""
function welfare(mo::Model, x::AbstractVector; include_terminal::Bool = true)
    p, T = mo.p, mo.T
    bet = discount(p)
    sol = unpack(mo, x)
    U = 0.0
    for t in 0:T
        b = sol.blocks[t+1]
        U += bet^t * (util(p, b.C) - disutil(p, b.Pst))
    end
    if include_terminal
        CT = sol.blocks[end].C
        gfac = bet * mo.Gam^(1 - p.eta)
        gfac < 1 || return U   # tail diverges; report the truncated sum
        U += bet^(T + 1) * util(p, CT * mo.Gam) / (1 - gfac)
    end
    return U
end

"""
    compare_residuals(mo, x; smooth = 0.0) -> Float64

Largest absolute difference between the market and planner transcriptions of the
residual system.  Zero to machine precision at the planner corner of the policy
space is Proposition "decentralisation" checked as an algebraic identity.
"""
function compare_residuals(mo::Model, x::AbstractVector; smooth::Real = 0.0)
    n = nvar(mo)
    Fm = Vector{Float64}(undef, n); residual_market!(Fm, mo, x; smooth = smooth)
    Fp = Vector{Float64}(undef, n); residual_planner!(Fp, mo, x; smooth = smooth)
    scale = max(1.0, maximum(abs, Fp))
    return maximum(abs, Fm .- Fp) / scale
end
