"""
The within-period block: definitions and materials accounting.

The ordering below is the acyclic ordering of `writing/docs/quant_model.tex`
eq. (within) and (accounting).  Nothing here depends on a period-t object
defined later in the list, which is what makes the stacked Jacobian
block-tridiagonal.  In particular the handled flow is drawn from the
predetermined stock, so the material block contains no within-period fixed
point.
"""

# state / control / costate layout ------------------------------------------
const NS = 6   # states:   K, S, X, P, MK, Wst
const NC = 6   # controls: C, I, N, D, varpi, KR
const NM = 6   # costates: q, pS, pX, pP, pM, pWst

const IK, IS, IX, IP, IMK, IWS = 1, 2, 3, 4, 5, 6
const IC, II, IN, ID, IVW, IKR = 1, 2, 3, 4, 5, 6
const IQ, IPS, IPX, IPP, IPM, IPW = 1, 2, 3, 4, 5, 6

const EPS_T = 1e-10   # floor on treated tonnage before x = KR/T is formed

"""
    period_block(p, t, s, c) -> NamedTuple

Everything determined within period `t` by the states `s` and controls `c`.
`feasible = false` flags either `R < Rbar` (below the material floor, where the
technology is undefined) or a non-positive activity aggregate.
"""
function period_block(p::Params, t::Int, s::AbstractVector, c::AbstractVector)
    K, S, X, Pst, MK, Wst = s[IK], s[IS], s[IX], s[IP], s[IMK], s[IWS]
    C, I, N, D, vw, KR = c[IC], c[II], c[IN], c[ID], c[IVW], c[IKR]

    # --- recycling block ---------------------------------------------------
    H = p.mu_h * max(Wst, zero(Wst))
    Ttr = clamp(vw, zero(vw), one(vw)) * H
    x = KR / max(Ttr, EPS_T)
    a, ap, alpha = recycling_yield(p, x)
    RR = a * Ttr
    R = N + RR

    # --- production --------------------------------------------------------
    KY = K - KR
    Y, FK, FR, FP, ok = production(p, t, KY, R, Pst)

    # --- cost flows --------------------------------------------------------
    G = I + p.delta * K
    CN, CN_N, CN_S = extraction(p, t, N, S)
    CD, CD_D, CD_X = exploration(p, t, D, X)
    cW, mcW = handling_cost(p, t, vw)
    CW = cW * H

    # --- accounting (quant_model.tex eq. accounting) -----------------------
    Dbase = p.omY * Y + p.omN * CN + p.omD * CD + p.omW * CW + p.omC * C
    den = Dbase + p.phiI * G
    feasible = ok && den > 0
    Omega = feasible ? R / den : zero(R)
    sigma = R > 0 ? Omega * p.phiI * G / R : zero(R)
    Nbase = p.OmNS * N + p.OmDS * D
    W = R - Omega * p.phiI * G + p.delta * MK + Nbase
    Xi = H * (1 - vw + p.dW * vw) - p.dW * RR

    return (; K, S, X, Pst, MK, Wst, C, I, N, D, vw, KR,
             H, Ttr, x, a, ap, alpha, RR, R, KY, Y, FK, FR, FP,
             G, CN, CN_N, CN_S, CD, CD_D, CD_X, cW, mcW, CW,
             Dbase, den, Omega, sigma, Nbase, W, Xi, feasible)
end

"""
    price_block(p, t, b, m) -> NamedTuple

The period-t price system of `writing/docs/quant_model.tex` eq. (prices),
written once for the market economy with the four policy dials.  At
`(phiW, phiz, phiP, phiX) = (1,1,1,1)` every object below coincides with the
corresponding planner shadow price: `tauW = pW`, `zz = zeta`, `pR = Psi - pW`,
`rK = F_K (1 - zeta Om^Y)` and `Lam = lambda`.
"""
function price_block(p::Params, t::Int, b, m::AbstractVector)
    pWst, pM, pP, pX = m[IPW], m[IPM], m[IPP], m[IPX]

    tauW = -p.phiW * pWst                 # gate fee (a price, not a tax)
    zeta_star = b.sigma * (tauW - pM)     # efficient material-content price
    z = p.phiz * (zeta_star - tauW)       # the instrument
    zz = z + tauW                         # total charge per embodied tonne

    tauP = p.phiP * pP
    tauX = -p.phiX * pX

    wedgeY = 1 - zz * p.omY * b.Omega     # (1 - zz*Om^Y)
    rK = b.FK * wedgeY
    pR = b.FR * wedgeY + z

    Lam = uprime(p, b.C) / (1 + zz * p.omC * b.Omega)
    return (; tauW, zeta_star, z, zz, tauP, tauX, wedgeY, rK, pR, Lam)
end

"Gross-up factor 1 + zz*Omega*om^j on a final-good flow of type j."
grossup(zz, Omega, om) = 1 + zz * Omega * om

"""
    handling_dividend(p, b, pr) -> h

The private handling dividend of eq. (costates), last row, per handled tonne
(before multiplication by the handling share).
"""
function handling_dividend(p::Params, b, pr)
    leak = 1 - b.vw * (1 - p.dW) - p.dW * b.alpha * b.vw
    return b.alpha * b.vw * pr.pR - grossup(pr.zz, b.Omega, p.omW) * b.cW - pr.tauP * leak
end

"Effective survival factor of the stockpile, 1 - mu(1 - alpha*varpi): the single
number saying how close the simulated economy is to a closed loop."
effective_survival(p::Params, b) = 1 - p.mu_h * (1 - b.alpha * b.vw)

