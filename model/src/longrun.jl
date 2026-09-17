"""
Analytic long-run blocks.

Three objects, all solved independently of the path solver so that they can be
used as terminal conditions, as starting points, and above all as checks: a
solved path is required to converge to them.

  * `restpoint_B1`  -- the dematerialized rest point of the stationary regime
    (workhorse eqs. mgr, restprices, pWstar), for the choke case `sigma_s = Inf`.
  * `cbgp`          -- the circular balanced growth path (workhorse eqs.
    cbgp:multipliers, cbgp:solution, cbgp:little).
  * `closure_check` -- the tail criterion of Proposition "closure criterion".
"""

# ---------------------------------------------------------------------------
# scalar root finding (stdlib only)
# ---------------------------------------------------------------------------

"Bisection on a sign change; returns `nothing` if the bracket is not bracketing."
function bisect(f, lo, hi; tol = 1e-12, maxit = 200)
    flo, fhi = f(lo), f(hi)
    (isfinite(flo) && isfinite(fhi) && flo * fhi <= 0) || return nothing
    for _ in 1:maxit
        mid = 0.5 * (lo + hi)
        fm = f(mid)
        (hi - lo) < tol * max(1.0, abs(mid)) && return mid
        if flo * fm <= 0
            hi, fhi = mid, fm
        else
            lo, flo = mid, fm
        end
    end
    return 0.5 * (lo + hi)
end

"Expand a bracket outward from `x0` until `f` changes sign."
function bracket(f, x0, step; grow = 1.6, maxit = 200)
    lo, hi = x0, x0 + step
    flo, fhi = f(lo), f(hi)
    for _ in 1:maxit
        (isfinite(flo) && isfinite(fhi) && flo * fhi <= 0) && return (lo, hi)
        step *= grow
        lo, flo = hi, fhi
        hi = lo + step
        fhi = f(hi)
    end
    return nothing
end

"""
    invert_aprime(p, v) -> x

The unique root of `a'(x) = v` on the decreasing branch of `a'`, which is where
the recycling-capital margin lives.  Returns `0.0` when `v >= a'(0)` on the
exponential tail (the corner), and locates the mode first on the power tail,
where `a'` rises before it falls.
"""
function invert_aprime(p::Params, v)
    v <= 0 && return Inf
    if p.tail === :exp
        ap0 = p.abar * p.xi
        v >= ap0 && return 0.0
        return log(ap0 / v) / p.xi
    end
    # power tail: scan for the mode, then bisect to the right of it
    xm, best = 0.0, -Inf
    for k in -12:0.25:12
        x = exp(k)
        _, ap, _ = recycling_yield(p, x)
        if ap > best
            best, xm = ap, x
        end
    end
    v >= best && return xm
    f(x) = (recycling_yield(p, x)[2] - v)
    br = bracket(f, xm, xm)
    br === nothing && return Inf
    r = bisect(f, br[1], br[2])
    return r === nothing ? Inf : r
end

# ---------------------------------------------------------------------------
# B1: the dematerialized rest point (choke case)
# ---------------------------------------------------------------------------

"""
    restpoint_B1(p) -> NamedTuple

Rest point of the stationary regime with the linear aggregate (`sigma_s = Inf`),
where the marginal value of a tonne is finite and the material era can end by
choice.  Trends are evaluated at their limits, so run this with `gA = gB = 0`
and the cost coefficients at `*_inf`.
"""
function restpoint_B1(p::Params)
    isinf(p.sigma_s) || @warn "restpoint_B1 is the closed form for sigma_s = Inf; " *
                              "with finite sigma_s > 1 materials stay essential at the margin"
    A, B = p.A0, p.B0
    rd = p.rho + p.delta
    Kst = (p.mu_F * A * p.beta_s^p.mu_F / rd)^(1 / (1 - p.mu_F))
    Yst = rd * Kst / p.mu_F
    Cst = (p.rho + p.delta * (1 - p.mu_F)) / p.mu_F * Kst
    lam = uprime(p, Cst)
    pP = p.kappa * Yst / (p.rho + p.theta0)                    # v'(0) = 0
    FR = rd * (1 - p.beta_s) * B / p.beta_s                    # finite choke value
    sig = p.phiI * p.delta * Kst /
          (p.omY * Yst + p.omC * Cst + p.phiI * p.delta * Kst)

    # the recycling block: one equation in pW, everything else in closed form
    function block(pW)
        pM = p.delta / rd * pW
        zeta = sig * p.rho / rd * pW
        Psi = FR + zeta
        GK = Psi - pW + p.dW * pP
        x = (p.abar * p.xi * GK <= rd) ? 0.0 : invert_aprime(p, rd / max(GK, eps()))
        _, _, alpha = recycling_yield(p, x)
        Gv = alpha * (Psi - pW) + pP * ((1 - p.dW) + p.dW * alpha)
        cc, cT = p.cc_inf, p.cT_inf
        vw = Gv <= cc ? 0.0 : min(1.0, ((Gv - cc) / cT)^(1 / p.chi_T))
        cW = cc * vw + cT * vw^(1 + p.chi_T) / (1 + p.chi_T)
        leak = 1 - vw * (1 - p.dW) - p.dW * alpha * vw
        lhs = pW * (1 - alpha * vw + p.rho / p.mu_h)
        rhs = cW + pP * leak - alpha * vw * Psi
        return (lhs - rhs, (; pM, zeta, Psi, x, alpha, vw, cW))
    end

    f(pW) = block(pW)[1]
    br = bracket(f, 0.0, max(1e-6, 0.05 * abs(pP) + 1e-6))
    if br === nothing
        br = bracket(f, 0.0, -max(1e-6, 0.05 * abs(pP) + 1e-6))
    end
    pW = br === nothing ? NaN : bisect(f, br[1], br[2])
    _, blk = block(pW)

    # Stranded reserve (workhorse eq. stranded).  When the net value of a virgin
    # tonne is non-positive at the rest point, the choke binds at every reserve
    # level and the whole reserve is stranded; `all_stranded` flags that case
    # rather than reporting an infinite terminal reserve as if it were a number.
    net = blk.Psi - pW * (1 + p.OmNS)
    all_stranded = net <= 0
    Sinf = all_stranded ? Inf : p.Sref * (p.cN_inf * p.kap_N / net)^(1 / p.mu_N)

    return (; K = Kst, Y = Yst, C = Cst, lambda = lam, pP, pW, pM = blk.pM,
            all_stranded, virgin_net_value = net,
            zeta = blk.zeta, Psi = blk.Psi, FR, sigma = sig,
            x = blk.x, alpha = blk.alpha, varpi = blk.vw, Sinf,
            pS = 0.0, pX = 0.0,
            # Omega = 0 at the rest point, so Phi^I = Omega*phiI = 0 and q = 1
            q = 1.0)
end

# ---------------------------------------------------------------------------
# C: the circular balanced growth path
# ---------------------------------------------------------------------------

"""
    cbgp(p; Minf) -> NamedTuple

The circular balanced growth path.  `Minf` is the retained material endowment
`M_inf` of eq. (cbgp:retained); the circulating flow follows from Little's law,
`R_inf = M_inf / (1/mu + sigma_inf/delta)`.  The block is simultaneous only
through the capital--output ratio and is solved by fixed-point iteration.

Normalised prices carry a hat: `m_hat = m * R^e_inf / Y`.
"""
function cbgp(p::Params; Minf::Real, iters::Int = 500, tol::Real = 1e-13)
    g = cbgp_growth(p)
    Gam = exp(g)
    Rf = interest_factor(p, Gam)
    Rf > Gam || error("cbgp: 1 + r must exceed e^g (Assumption on bounded values); " *
                      "got Rf = $Rf, Gam = $Gam")
    bk, ga = beta_K(p), gamma_R(p)

    ThetaW = p.mu_h * Gam / (Rf - Gam)
    DeltaM = p.delta * Gam / (Rf - (1 - p.delta) * Gam)
    DeltaP = Gam / (Rf - (1 - p.theta0) * Gam)

    k = bk / (Rf - 1 + p.delta)             # starting guess: K/Y without wedges
    local out
    for _ in 1:iters
        vsG = (Gam - 1 + p.delta) * k
        dbar = p.omY + p.omC * (1 - vsG) + p.phiI * vsG
        sig = p.phiI * vsG / dbar
        Tres = 1 / p.mu_h + sig / p.delta            # residence time
        Rinf = Minf / Tres
        Re = Rinf - p.Rbar
        Re > 0 || error("cbgp: R_inf = $Rinf does not clear the floor Rbar = $(p.Rbar); " *
                        "the survival condition M_inf > Rbar * T fails")
        Omh = Rinf / (dbar * Re)
        Ups = sig * (1 - DeltaM) * ThetaW
        den = 1 + Ups * (1 - ga * Omh * p.omY)
        den > 0 || error("cbgp: regularity condition 1 + Upsilon(1 - gamma*Omega_hat*omY) > 0 fails")
        Psih = ga / den
        zeth = -Ups * Psih
        pWh = -ThetaW * Psih
        pMh = DeltaM * pWh
        pPh = DeltaP * p.kappa * Re * (1 - zeth * Omh * p.omY)
        qinf = 1 - p.phiI * (1 - sig) * (1 - DeltaM) * Omh * pWh
        knew = bk * (1 - zeth * Omh * p.omY) / ((Rf - 1 + p.delta) * qinf)
        out = (; g, Gam, Rf, ThetaW, DeltaM, DeltaP, Upsilon = Ups,
                k = knew, varsigmaG = vsG, dbar, sigma_inf = sig, residence = Tres,
                Rinf, Re, Omega_hat = Omh, Psi_hat = Psih, zeta_hat = zeth,
                pW_hat = pWh, pM_hat = pMh, pP_hat = pPh, q_inf = qinf,
                ThetaG = 1 + ThetaW + p.dW * pPh / Psih,
                consumption_wedge = 1 + zeth * Omh * p.omC)
        abs(knew - k) < tol * max(1.0, abs(k)) && break
        k = knew
    end
    return out
end

"""
    survival_ratio(p; Minf) -> Float64

`M_inf / (Rbar * T)` of eq. (cbgp:survival): the single number the theory says
decides survival in the bottom-right cell.  Values above one mean the retained
endowment clears the floor at the economy's own turnover rate.  Returns `Inf`
when there is no floor.
"""
function survival_ratio(p::Params; Minf::Real)
    p.Rbar <= 0 && return Inf
    # sigma_inf needs the CBGP block, which needs a feasible R_inf; fall back to
    # the coarse primitive bound mu*B > Rbar when the fine one is infeasible.
    try
        c = cbgp(p; Minf = Minf)
        return Minf / (p.Rbar * c.residence)
    catch
        return p.mu_h * Minf / p.Rbar
    end
end

# ---------------------------------------------------------------------------
# the closure criterion
# ---------------------------------------------------------------------------

"""
    closure_check(p; g, A, horizon) -> NamedTuple

Evaluates the criterion of Proposition "closure criterion": along a CBGP the
capital margin pins `a'(x_t) = A e^{-g t}`, and the loop closes iff the leakage
rates `L_t = abar - a(x_t)` are summable.  Reports the leakage sum, the implied
path of `x_t`, and whether the recycling capital share vanishes.

`A` defaults to `a'` evaluated at the current intensity implied by a unit
scale; supply the model-consistent value from a solved path when checking one.
"""
function closure_check(p::Params; g::Real = cbgp_growth(p), A::Real = 1.0,
                       horizon::Int = 4000, tol::Real = 1e-10)
    if g <= 0
        return (; closes = false, leak_sum = Inf, x = Float64[], leak = Float64[],
                x_growth_relative_to_g = NaN, tail = p.tail, abar = p.abar,
                reason = "no growth: the capital margin does not push x to infinity")
    end
    if p.abar < 1
        # Lemma "cumulated leakage" is violated outright: leakage per handled
        # tonne is bounded below by 1 - abar > 0 however large x becomes.
        return (; closes = false, leak_sum = Inf, x = Float64[], leak = Float64[],
                x_growth_relative_to_g = NaN, tail = p.tail, abar = p.abar,
                reason = "hard ceiling: leakage is bounded below by 1 - abar = " *
                         "$(round(1 - p.abar, digits = 4)), so cumulated leakage diverges")
    end
    xs, Ls = Float64[], Float64[]
    tot = 0.0
    for t in 0:horizon
        x = invert_aprime(p, A * exp(-g * t))
        isfinite(x) || break
        a, _, _ = recycling_yield(p, x)
        L = 1 - a                       # leakage from a fully closed loop
        push!(xs, x); push!(Ls, L)
        tot += L
        (L < tol && t > 10) && break
    end
    # The tail is summable when the terms are still decaying at the end of the
    # horizon; a logarithmic tail with iota <= 1 fails exactly here.
    tail_ok = length(Ls) < horizon + 1 ||
              (Ls[end] * (horizon + 1) < 1e-3 * max(tot, 1.0))
    # x_t must be o(e^{gt}) for the recycling capital share to vanish
    share_trend = length(xs) > 20 ?
        log(xs[end] / xs[max(end - 20, 1)]) / (20 * g) : NaN
    return (; closes = tail_ok && isfinite(tot), leak_sum = tot,
            x = xs, leak = Ls, x_growth_relative_to_g = share_trend,
            tail = p.tail, abar = p.abar,
            reason = tail_ok ? "" : "leakage still non-negligible at the horizon: " *
                                    "the tail may not be summable")
end

