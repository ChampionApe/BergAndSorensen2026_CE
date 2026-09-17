"""
The stacked residual system of `writing/docs/quant_model.tex`.

Two implementations are carried deliberately:

  * `residual_market!`  -- written from the market conditions of Part II, with
    the four policy dials;
  * `residual_planner!` -- written from the planner's first-order and costate
    conditions of Part I, in terms of `Psi`, `zeta` and `pW`.

They are algebraically identical when the dials are at `(1,1,1,1)`
(Proposition "decentralisation"), and `test/runtests.jl` checks that at random
points of the state and control space.  Keeping both is the point: the test
catches transcription errors that a single implementation cannot.

Variable layout.  For `t = 0, ..., T-1` a block of 18 unknowns
`[controls(6); costates(6); states_{t+1}(6)]`; a final block of 12 unknowns
`[controls(6); costates(6)]` at `t = T`.  Residual blocks have the same shape.
Residual block `t` involves only blocks `t-1`, `t` and `t+1`, so the Jacobian is
block-tridiagonal.
"""

const NBLK = NC + NM + NS   # 18
const NEND = NC + NM        # 12

"""
    Model(p; T, s0, Gam)

`T` is the index of the terminal period, `s0` the initial state vector, `Gam`
the terminal growth factor of the costate closure (1 in a stationary regime,
`exp(g)` on a balanced growth path).
"""
struct Model
    p::Params
    T::Int
    s0::Vector{Float64}
    Gam::Float64
    terminal::Symbol   # :closure  -- the growth-adjusted costate closure
                       # :shutdown -- T is the last operating period and the
                       #              continuation is V_stop
end
Model(p::Params; T::Int, s0::AbstractVector, Gam::Real = exp(cbgp_growth(p)),
      terminal::Symbol = :closure) =
    Model(p, T, collect(float.(s0)), float(Gam), terminal)

nvar(mo::Model) = NBLK * mo.T + NEND

@inline blockoffset(t::Int) = NBLK * t
@inline ctrl_view(x, t) = view(x, blockoffset(t) + 1 : blockoffset(t) + NC)
@inline cost_view(x, t) = view(x, blockoffset(t) + NC + 1 : blockoffset(t) + NC + NM)
@inline next_state_view(x, t) = view(x, blockoffset(t) + NC + NM + 1 : blockoffset(t) + NBLK)

"State at period t: the initial condition at t = 0, otherwise carried by block t-1."
@inline state_view(mo::Model, x, t) = t == 0 ? view(mo.s0, 1:NS) : next_state_view(x, t - 1)

# ---------------------------------------------------------------------------
# smoothed complementarity
# ---------------------------------------------------------------------------

@inline smax(a, b, e) = e <= 0 ? max(a, b) : 0.5 * (a + b + sqrt((a - b)^2 + e^2))
@inline smin(a, b, e) = e <= 0 ? min(a, b) : 0.5 * (a + b - sqrt((a - b)^2 + e^2))

"""
    mcp(y, f, l, u, e)

Min-map of the complementarity problem `f <= 0 at y = l`, `f = 0` interior,
`f >= 0 at y = u`, smoothed with width `e`.  Exact at `e = 0`.
"""
@inline function mcp(y, f, l, u, e)
    z = smax(y + f, l, e)
    return isinf(u) ? z - y : smin(z, u, e) - y
end

# ---------------------------------------------------------------------------
# market residuals
# ---------------------------------------------------------------------------

"Within-period residuals shared by both formulations: goods constraint plus the
five control margins, written from market prices."
function control_residuals_market!(r, p::Params, b, pr, m, e)
    PhiI = b.Omega * p.phiI
    r[1] = b.Y - (b.C + b.I + p.delta * b.K + b.CN + b.CD + b.CW)
    r[2] = m[IQ] - 1 - PhiI * (pr.z + m[IPM])
    gN = pr.pR - (b.CN_N * grossup(pr.zz, b.Omega, p.omN) + pr.tauW * p.OmNS + m[IPS])
    r[3] = mcp(b.N, gN, 0.0, Inf, e)
    gD = m[IPS] - (b.CD_D * grossup(pr.zz, b.Omega, p.omD) + pr.tauW * p.OmDS + pr.tauX)
    r[4] = mcp(b.D, gD, 0.0, Inf, e)
    gV = b.alpha * pr.pR + pr.tauP * ((1 - p.dW) + p.dW * b.alpha) -
         grossup(pr.zz, b.Omega, p.omW) * b.mcW
    r[5] = mcp(b.vw, gV, 0.0, 1.0, e)
    gK = b.ap * (pr.pR + p.dW * pr.tauP) - pr.rK
    r[6] = mcp(b.KR, gK, 0.0, Inf, e)
    return r
end

"Dividends and survival factors of Table 'costates', market form."
function costate_terms_market(p::Params, b, pr, m)
    _, ret = decay(p, b.Pst)
    divs = (
        pr.rK,
        -b.CN_S * grossup(pr.zz, b.Omega, p.omN),
        -b.CD_X * grossup(pr.zz, b.Omega, p.omD),
        vprime(p, b.Pst) / pr.Lam - b.FP * pr.wedgeY,
        p.delta * pr.tauW,
        p.mu_h * handling_dividend(p, b, pr),
    )
    surv = (1 - p.delta, 1.0, 1.0, ret, 1 - p.delta, 1 - p.mu_h)
    return divs, surv
end

function transition_residuals!(r, p::Params, b, snext)
    th, _ = decay(p, b.Pst)
    r[1] = snext[IK]  - (b.K + b.I)
    r[2] = snext[IS]  - (b.S + b.D - b.N)
    r[3] = snext[IX]  - (b.X + b.D)
    r[4] = snext[IP]  - (b.Pst + b.Xi - th * b.Pst)
    r[5] = snext[IMK] - ((1 - p.delta) * b.MK + b.Omega * p.phiI * b.G)
    r[6] = snext[IWS] - ((1 - p.mu_h) * b.Wst + b.W)
    return r
end

"""
    residual_market!(F, mo, x; smooth = 0.0)

Full stacked residual vector of the market economy with the dials in `mo.p`.
"""
function residual_market!(F::AbstractVector, mo::Model, x::AbstractVector; smooth::Real = 0.0)
    p, T = mo.p, mo.T
    e = float(smooth)

    # period T objects are needed by block T-1, so build them once
    bT = period_block(p, T, state_view(mo, x, T), ctrl_view(x, T))
    prT = price_block(p, T, bT, cost_view(x, T))

    bnext, prnext = bT, prT
    for t in T-1:-1:0
        b = period_block(p, t, state_view(mo, x, t), ctrl_view(x, t))
        pr = price_block(p, t, b, cost_view(x, t))
        m = cost_view(x, t)
        mn = cost_view(x, t + 1)
        off = blockoffset(t)

        control_residuals_market!(view(F, off+1:off+NC), p, b, pr, m, e)

        Rf = pr.Lam / (discount(p) * prnext.Lam)          # 1 + r_{t+1}
        divs, surv = costate_terms_market(p, bnext, prnext, mn)
        for k in 1:NM
            F[off + NC + k] = Rf * m[k] - (divs[k] + surv[k] * mn[k])
        end

        transition_residuals!(view(F, off+NC+NM+1:off+NBLK), p, b, next_state_view(x, t))

        bnext, prnext = b, pr
    end

    # terminal block
    offT = blockoffset(T)
    control_residuals_market!(view(F, offT+1:offT+NC), p, bT, prT, cost_view(x, T), e)
    terminal_residuals!(view(F, offT+NC+1:offT+NC+NM), mo, bT, prT, cost_view(x, T), :market)
    return F
end

# ---------------------------------------------------------------------------
# planner residuals (independent transcription, for the equivalence test)
# ---------------------------------------------------------------------------

"Planner shadow prices at a period, from the costates directly."
function planner_prices(p::Params, b, m::AbstractVector)
    pW = -m[IPW]                                  # eq. sum:W
    zeta = b.sigma * (pW - m[IPM])                # eq. zeta-explicit
    wedgeY = 1 - zeta * p.omY * b.Omega
    Psi = b.FR * wedgeY + zeta                    # eq. shorthand
    FKt = b.FK * wedgeY
    lam = uprime(p, b.C) / (1 + zeta * p.omC * b.Omega)
    return (; pW, zeta, wedgeY, Psi, FKt, lam)
end

function control_residuals_planner!(r, p::Params, b, sp, m, e)
    PhiI = b.Omega * p.phiI
    r[1] = b.Y - (b.C + b.I + p.delta * b.K + b.CN + b.CD + b.CW)
    r[2] = m[IQ] - (1 - PhiI * (1 - b.sigma) * (sp.pW - m[IPM]))
    gN = sp.Psi - (b.CN_N * grossup(sp.zeta, b.Omega, p.omN) + m[IPS] + sp.pW * (1 + p.OmNS))
    r[3] = mcp(b.N, gN, 0.0, Inf, e)
    gD = (m[IPS] + m[IPX]) - (b.CD_D * grossup(sp.zeta, b.Omega, p.omD) + sp.pW * p.OmDS)
    r[4] = mcp(b.D, gD, 0.0, Inf, e)
    Gv = b.alpha * (sp.Psi - sp.pW) + m[IPP] * ((1 - p.dW) + p.dW * b.alpha)
    r[5] = mcp(b.vw, Gv - grossup(sp.zeta, b.Omega, p.omW) * b.mcW, 0.0, 1.0, e)
    GK = sp.Psi - sp.pW + p.dW * m[IPP]
    r[6] = mcp(b.KR, b.ap * GK - sp.FKt, 0.0, Inf, e)
    return r
end

function costate_terms_planner(p::Params, b, sp, m)
    _, ret = decay(p, b.Pst)
    leak = 1 - b.vw * (1 - p.dW) - p.dW * b.alpha * b.vw
    h = b.alpha * b.vw * (sp.Psi - sp.pW) -
        grossup(sp.zeta, b.Omega, p.omW) * b.cW - m[IPP] * leak
    divs = (
        sp.FKt,
        -b.CN_S * grossup(sp.zeta, b.Omega, p.omN),
        -b.CD_X * grossup(sp.zeta, b.Omega, p.omD),
        vprime(p, b.Pst) / sp.lam - b.FP * sp.wedgeY,
        p.delta * sp.pW,
        p.mu_h * h,
    )
    surv = (1 - p.delta, 1.0, 1.0, ret, 1 - p.delta, 1 - p.mu_h)
    return divs, surv
end

function residual_planner!(F::AbstractVector, mo::Model, x::AbstractVector; smooth::Real = 0.0)
    p, T = mo.p, mo.T
    e = float(smooth)

    bT = period_block(p, T, state_view(mo, x, T), ctrl_view(x, T))
    spT = planner_prices(p, bT, cost_view(x, T))

    bnext, spnext = bT, spT
    for t in T-1:-1:0
        b = period_block(p, t, state_view(mo, x, t), ctrl_view(x, t))
        sp = planner_prices(p, b, cost_view(x, t))
        m, mn = cost_view(x, t), cost_view(x, t + 1)
        off = blockoffset(t)

        control_residuals_planner!(view(F, off+1:off+NC), p, b, sp, m, e)

        Rf = sp.lam / (discount(p) * spnext.lam)
        divs, surv = costate_terms_planner(p, bnext, spnext, mn)
        for k in 1:NM
            F[off + NC + k] = Rf * m[k] - (divs[k] + surv[k] * mn[k])
        end

        transition_residuals!(view(F, off+NC+NM+1:off+NBLK), p, b, next_state_view(x, t))
        bnext, spnext = b, sp
    end

    offT = blockoffset(T)
    control_residuals_planner!(view(F, offT+1:offT+NC), p, bT, spT, cost_view(x, T), e)
    terminal_residuals!(view(F, offT+NC+1:offT+NC+NM), mo, bT, spT, cost_view(x, T), :planner)
    return F
end
