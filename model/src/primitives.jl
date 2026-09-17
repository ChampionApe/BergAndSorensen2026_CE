"""
Primitive functions and their derivatives, exactly as specified in
`writing/docs/Appendix_workhorse.tex`, Section "Functional forms".

Every function here is a pure function of parameters, the period index `t`
(periods since the base date) and its own arguments.  Nothing in this file
touches the equilibrium system.
"""

# ---------------------------------------------------------------------------
# trends
# ---------------------------------------------------------------------------

"Exponentially converging coefficient: z(t) = z_inf + (z0 - z_inf) e^{-g t}."
conv(z0, zinf, g, t) = zinf + (z0 - zinf) * exp(-g * t)

Atrend(p::Params, t) = p.A0 * exp(p.gA * t)
Btrend(p::Params, t) = p.B0 * exp(p.gB * t)
cN_t(p::Params, t)   = conv(p.cN0, p.cN_inf, p.gcN, t)
cD_t(p::Params, t)   = conv(p.cD0, p.cD_inf, p.gcD, t)
cc_t(p::Params, t)   = conv(p.cc0, p.cc_inf, p.gcc, t)
cT_t(p::Params, t)   = conv(p.cT0, p.cT_inf, p.gcT, t)

# ---------------------------------------------------------------------------
# preferences
# ---------------------------------------------------------------------------

"""
Floors used to extend the primitives smoothly into the infeasible region.

Newton iterates wander outside the domain (negative consumption, an exhausted
reserve, a treated share above one) and a residual that returns `Inf` or `NaN`
there kills the line search.  Every primitive below is therefore defined on the
whole real line by flooring its arguments.  This never affects a solution: the
complementarity residuals cannot vanish at a point where a bounded control lies
outside its box, so the extension changes the path Newton takes and not the
point it reaches.
"""
const FLOOR_C = 1e-12   # consumption
const FLOOR_S = 1e-12   # reserve
const FLOOR_X = 1e-12   # room below the discovery ceiling

util(p::Params, C)   = (Cg = max(C, FLOOR_C);
                        p.eta == 1 ? log(Cg) : Cg^(1 - p.eta) / (1 - p.eta))
uprime(p::Params, C) = max(C, FLOOR_C)^(-p.eta)
disutil(p::Params, P)   = p.psi_v * max(P, 0)^(1 + p.varphi) / (1 + p.varphi)
vprime(p::Params, P)    = p.psi_v * max(P, 0)^p.varphi

# ---------------------------------------------------------------------------
# final goods
# ---------------------------------------------------------------------------

"""
    production(p, t, KY, R, P) -> (Y, FK, FR, FP, ok)

CES aggregate of capital and effective materials with returns exponent `mu_F`
and exponential pollution damage.  `ok = false` signals `R < Rbar`, the region
below the material floor, where the technology is not defined and `Y = 0`.

`FR` is the derivative with respect to `R` (not to the effective input), so it
already carries the material-augmenting level `B(t)`.
"""
function production(p::Params, t, KY, R, Pstock)
    Re = R - p.Rbar
    if Re <= 0 || KY <= 0
        return (zero(R), zero(R), zero(R), zero(R), false)
    end
    A = Atrend(p, t)
    B = Btrend(p, t)
    Z = B * Re
    damp = exp(-p.kappa * Pstock)
    if p.sigma_s == 1
        b = p.beta_s
        Q = KY^b * Z^(1 - b)
        shK, shZ = b, 1 - b
    else
        r = isinf(p.sigma_s) ? 1.0 : (p.sigma_s - 1) / p.sigma_s
        b = p.beta_s
        Qr = b * KY^r + (1 - b) * Z^r
        Q = Qr^(1 / r)
        shK = b * KY^r / Qr
        shZ = (1 - b) * Z^r / Qr
    end
    Y = A * damp * Q^p.mu_F
    FK = p.mu_F * Y * shK / KY
    FR = p.mu_F * Y * shZ / Re          # dY/dR = (dY/dZ) * B and Z = B*Re
    FP = -p.kappa * Y
    return (Y, FK, FR, FP, true)
end

"Dematerialized output F(K, Rbar, 0) in the limit Z -> 0; finite only for sigma_s > 1."
function production_dematerialized(p::Params, t, K)
    p.sigma_s > 1 || return zero(K)
    A = Atrend(p, t)
    expo = isinf(p.sigma_s) ? p.mu_F : p.mu_F * p.sigma_s / (p.sigma_s - 1)
    return A * (p.beta_s^expo) * K^p.mu_F
end

# ---------------------------------------------------------------------------
# recycling yield
# ---------------------------------------------------------------------------

"""
    recycling_yield(p, x) -> (a, aprime, alpha)

Average yield, marginal product of recycling capital, and marginal recycling
yield `alpha = a - a' x`.  Both tail families of the workhorse are supported.
"""
function recycling_yield(p::Params, x0)
    x = max(x0, zero(x0))
    if x <= 0
        ap0 = p.tail === :exp ? p.abar * p.xi :
              (p.psi_a == 1 ? p.abar * p.xi : (p.psi_a > 1 ? zero(x) : Inf))
        return (zero(x), oftype(x, ap0), zero(x))
    end
    if p.tail === :exp
        e = exp(-p.xi * x)
        a = p.abar * (1 - e)
        ap = p.abar * p.xi * e
        return (a, ap, a - ap * x)
    else
        w = (p.xi * x)^p.psi_a
        a = p.abar * w / (1 + w)
        ap = p.abar * p.psi_a * p.xi * (p.xi * x)^(p.psi_a - 1) / (1 + w)^2
        return (a, ap, a - ap * x)
    end
end

"Tail elasticity eps_a = x a'(x) / (abar - a(x)); classifies the tail (workhorse eq. cbgp:elasticity)."
function tail_elasticity(p::Params, x)
    a, ap, _ = recycling_yield(p, x)
    short = p.abar - a
    short <= 0 && return Inf
    return x * ap / short
end

# ---------------------------------------------------------------------------
# extraction and exploration
# ---------------------------------------------------------------------------

"""
    extraction(p, t, N, S) -> (CN, CN_N, CN_S)

Power cost with a linear term.  `CN_S < 0`: a larger reserve makes extraction
cheaper.  Guards `S -> 0`, where marginal cost diverges.
"""
function extraction(p::Params, t, N0, S0)
    S = max(S0, FLOOR_S)
    N = max(N0, zero(N0))
    sc = cN_t(p, t) * (p.Sref / S)^p.mu_N
    CN = sc * (p.kap_N * N + N^(1 + p.chi_N) / (1 + p.chi_N))
    CN_N = sc * (p.kap_N + N^p.chi_N)
    CN_S = -p.mu_N * CN / S
    return (CN, CN_N, CN_S)
end

"""
    exploration(p, t, D, X) -> (CD, CD_D, CD_X)

Marginal cost diverges as `X -> Xmax`, which is the exhaustible-discovery
property; no constraint `X <= Xmax` is ever imposed.
"""
function exploration(p::Params, t, D0, X)
    D = max(D0, zero(D0))
    room = max(p.Xmax - X, FLOOR_X)
    sc = cD_t(p, t) * ((p.Xmax - p.Xref) / room)^p.mu_D
    CD = sc * (p.kap_D * D + D^(1 + p.chi_D) / (1 + p.chi_D))
    CD_D = sc * (p.kap_D + D^p.chi_D)
    CD_X = p.mu_D * CD / room
    return (CD, CD_D, CD_X)
end

# ---------------------------------------------------------------------------
# waste handling and pollution decay
# ---------------------------------------------------------------------------

"""
    handling_cost(p, t, w) -> (cW, mcW)

Average handling cost per handled tonne and the marginal cost of raising the
treated share.  Collection is charged per *treated* tonne, so dumping is free
and the lower corner is a genuine choke at `cc`.
"""
function handling_cost(p::Params, t, w0)
    w = clamp(w0, zero(w0), one(w0))
    cc = cc_t(p, t)
    cT = cT_t(p, t)
    cW = cc * w + cT * w^(1 + p.chi_T) / (1 + p.chi_T)
    mcW = cc + cT * w^p.chi_T
    return (cW, mcW)
end

"""
    decay(p, P) -> (theta, retention)

`retention` is the *marginal* retention factor `1 - theta - theta' P`, which is
what enters the pollution costate, not the average factor `1 - theta`.
"""
function decay(p::Params, Pstock0)
    Pstock = max(Pstock0, zero(Pstock0))
    e = exp(-p.thetaP * Pstock)
    th = p.theta_min + (p.theta0 - p.theta_min) * e
    thp = -p.thetaP * (p.theta0 - p.theta_min) * e
    return (th, 1 - th - thp * Pstock)
end

