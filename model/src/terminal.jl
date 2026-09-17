"""
Terminal conditions, and the value of the shutdown state.

The six terminal conditions all take the single form of
`writing/quant/quant_solution.tex` eq. (terminal): if from date T onward the
dividend of a costate and the costate itself grow at a common factor `Gam`
while the survival factor is constant, then

    m_T * (1 + r_inf - s_T * Gam) = Gam * div_T,     1 + r_inf = Gam^eta (1+rho).

`Gam = 1` gives the rest-point formulae of the stationary benchmark; `Gam = e^g`
gives the circular balanced growth path of trending technology.  The stockpile row is closed with its
*primitive* survival factor `1 - mu`; the substitution `tauW = -pW` inside the
dividend then makes it algebraically equivalent to closing the net recursion
with the effective factor `1 - mu(1 - alpha*varpi)`, so no switch between a
collapse mode and a circular mode is needed anywhere.
"""

"""
    terminal_residuals!(r, mo, b, pr, m, which)

`which` is `:market` or `:planner`, selecting which price transcription
supplies the dividends.  The two agree when the dials are at (1,1,1,1).
"""
function terminal_residuals!(r, mo::Model, b, pr, m::AbstractVector, which::Symbol)
    mo.terminal === :shutdown && return terminal_shutdown!(r, mo, b, pr, m, which)
    p, Gam = mo.p, mo.Gam
    divs, surv = which === :market ? costate_terms_market(p, b, pr, m) :
                                     costate_terms_planner(p, b, pr, m)
    Rinf = interest_factor(p, Gam)
    for k in 1:NM
        r[k] = m[k] * (Rinf - surv[k] * Gam) - Gam * divs[k]
    end
    return r
end

"""
    successor_state(p, b) -> (K, S, X, P, MK, W)

The state period `t`'s choices leave behind, computed from the transitions.
Used by the shutdown closure, which values the stocks the last operating period
hands to an economy that no longer produces.
"""
function successor_state(p::Params, b)
    th, _ = decay(p, b.Pst)
    return (b.K + b.I,
            b.S + b.D - b.N,
            b.X + b.D,
            b.Pst + b.Xi - th * b.Pst,
            (1 - p.delta) * b.MK + b.Omega * p.phiI * b.G,
            (1 - p.mu_h) * b.Wst + b.W)
end

"""
    terminal_shutdown!(r, mo, b, pr, m, which)

Terminal conditions when period `T` is the last operating period: the costates
dated `T` price the stocks handed over, so they equal the derivatives of
`V_stop` divided by the marginal value of income.

Reserves and cumulative discoveries are worthless after a shutdown, `pS = pX = 0`.
`pM = 0` is a simplification: `V_stop` as implemented ignores the material
released by the capital stock as it is eaten, so the embodied-material liability
is not priced at the handover.  It is small relative to the stockpile term and
is recorded as a known approximation rather than hidden.
"""
function terminal_shutdown!(r, mo::Model, b, pr, m::AbstractVector, which::Symbol)
    p = mo.p
    Kn, _, _, Pn, _, Wn = successor_state(p, b)
    Lam = which === :market ? pr.Lam : pr.lam

    fd(f, v) = (h = 1e-5 * max(abs(v), 1.0); (f(v + h) - f(v - h)) / (2h))
    V_K = fd(k -> value_stop(p, k, Wn, Pn), Kn)
    V_W = fd(w -> value_stop(p, Kn, w, Pn), Wn)
    V_P = fd(q -> value_stop(p, Kn, Wn, q), Pn)

    r[IQ]  = m[IQ]  - V_K / Lam
    r[IPS] = m[IPS]
    r[IPX] = m[IPX]
    r[IPP] = m[IPP] + V_P / Lam
    r[IPM] = m[IPM]
    r[IPW] = m[IPW] - V_W / Lam
    return r
end

# ---------------------------------------------------------------------------
# the shutdown state
# ---------------------------------------------------------------------------

"""
    cake_policy(p) -> (s_stop, gamma_C)

Exact post-shutdown policy of `writing/docs/Appendix_workhorse.tex` eq. (cake):
with `Y = 0` the economy eats its depreciating capital stock, consumption is
`C_t = s_stop * K_t` and capital falls at factor `gamma_C`.
"""
function cake_policy(p::Params)
    gC = ((1 - p.delta) / (1 + p.rho))^(1 / p.eta)
    return ((1 - p.delta) - gC, gC)
end

"""
    legacy_emissions_value(p, Wst, P0; horizon = 2000) -> Float64

Discounted disutility of the legacy emission stream after a shutdown: the
stockpile drains geometrically at factor `1 - mu`, passes to the environment
untreated, and the pollution stock decays back to zero.  Evaluated by direct
recursion, which is one dimensional and cheap.
"""
function legacy_emissions_value(p::Params, Wst, P0; horizon::Int = 2000)
    bet = discount(p)
    Pst, Wt, acc, df = P0, Wst, 0.0, 1.0
    for _ in 0:horizon
        acc += df * disutil(p, Pst)
        th, _ = decay(p, Pst)
        Xi = p.mu_h * Wt
        Pst = Pst + Xi - th * Pst
        Wt *= (1 - p.mu_h)
        df *= bet
        df < 1e-16 && break
    end
    return acc
end

"""
    value_stop(p, K, Wst, P) -> Float64

`V_stop` of `writing/docs/Appendix_workhorse.tex` eq. (Vstop): the closed-form
cake-eating value of the capital stock, less the discounted disutility of the
legacy emission stream.  Assumes `varpi = 0` after the shutdown, which is
optimal where the collection charge exceeds the diversion gain; where it is not,
this is a lower bound on the value of stopping.
"""
function value_stop(p::Params, K, Wst, Pst)
    s_stop, gC = cake_policy(p)
    (s_stop > 0 && K > 0) || return -Inf
    bet = discount(p)
    den = 1 - bet * gC^(1 - p.eta)
    den > 0 || return -Inf
    cake = p.eta == 1 ?
        (log(s_stop * K) + bet * log(gC) / (1 - bet)) / (1 - bet) :
        (s_stop * K)^(1 - p.eta) / ((1 - p.eta) * den)
    return cake - legacy_emissions_value(p, Wst, Pst)
end
