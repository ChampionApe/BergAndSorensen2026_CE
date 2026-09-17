"""
Starting values.

A perfect-foresight path with six states and six costates needs a starting
point that is at least feasible in the goods constraint and roughly right in
the price block, or Newton spends its first iterations discovering that
consumption cannot be negative.  The construction here is deliberately crude on
the quantity side and careful on the price side: quantities come from a forward
simulation under simple rules, and the costates are then obtained by sweeping
the exact recursions backwards from the terminal closure, holding quantities
fixed.  That second step is cheap and buys most of the conditioning.
"""

"""
    simulate_quantities(mo; Rtarget, gR, cshare, share_KR, varpi0, ...) -> (states, controls)

Forward simulation under simple rules: recycling capital is a fixed share of the
capital stock, the treated share is fixed, virgin extraction tops material input
up to a target path, and *consumption is a fixed share of output net of cost
flows*, with investment taking the residual of the goods constraint.

The direction matters.  Taking consumption as the residual instead lets it hit
its floor whenever costs rise, which sends the marginal value of income to
infinity and the costate residuals with it; letting investment absorb the shock
keeps the guess feasible even on paths where the economy is contracting, which
is exactly where a starting point is hardest to find.
"""
function simulate_quantities(mo::Model; Rtarget::Real, gR::Real = 0.0,
                             cshare::Real = 0.65,
                             share_KR::Real = 0.01, varpi0::Real = 0.5,
                             Dshare::Real = 0.5, depletion::Real = 0.02,
                             discovery::Real = 0.01)
    p, T = mo.p, mo.T
    S = Matrix{Float64}(undef, T + 1, NS)
    C = Matrix{Float64}(undef, T + 1, NC)
    S[1, :] .= mo.s0
    xcap = p.tail === :exp ? log(10.0) / p.xi : 9.0^(1 / p.psi_a) / p.xi   # a(xcap) = 0.9 abar
    for t in 0:T
        K, Sr, X, Pst, MK, Wst = S[t+1, :]
        vw = varpi0
        H = p.mu_h * Wst
        Ttr = vw * H
        # The control is the intensity x = KR/T.  A fixed share of the capital
        # stock is the guess for KR, and x follows from it, capped where the
        # yield reaches nine tenths of its ceiling: beyond that a' is flat, and
        # a guess that starts there (a small treated flow puts KR/T in the
        # hundreds) gives Newton no gradient to work with.
        xR = Ttr > 0 ? min(share_KR * K / Ttr, xcap) : 0.0
        KR = xR * Ttr
        a, _, _ = recycling_yield(p, xR)
        RR = a * Ttr
        # Extraction is capped at a fixed share of the remaining reserve and
        # discovery at a share of the remaining room below the ceiling, so that
        # the simulated path never drives a cost function to its singularity.
        # Without these caps the guess exhausts the reserve in finite time and
        # the extraction cost, and with it the whole residual vector, explodes.
        Rtar = Rtarget * exp(gR * t)
        N = min(max(Rtar - RR, 0.0), depletion * max(Sr, 0.0))
        D = min(Dshare * N, discovery * max(p.Xmax - X, 0.0))
        R = N + RR
        KY = K - KR
        Y, = production(p, t, KY, R, Pst)
        CN, = extraction(p, t, N, Sr)
        CD, = exploration(p, t, D, X)
        cW, = handling_cost(p, t, vw)
        CW = cW * H
        avail = Y - CN - CD - CW
        Cc = max(cshare * avail, 1e-4 * max(Y, 1.0))
        I = avail - Cc - p.delta * K          # residual; may be negative
        I = max(I, -0.5 * K)                  # never scrap more than half of K
        C[t+1, :] .= (Cc, I, N, D, vw, xR)

        if t < T
            b = period_block(p, t, view(S, t+1, :), view(C, t+1, :))
            th, = decay(p, Pst)
            S[t+2, :] .= (K + I, Sr + D - N, X + D,
                          Pst + b.Xi - th * Pst,
                          (1 - p.delta) * MK + b.Omega * p.phiI * b.G,
                          (1 - p.mu_h) * Wst + b.W)
            S[t+2, IS] = max(S[t+2, IS], 1e-8)
            S[t+2, IP] = max(S[t+2, IP], 0.0)
        end
    end
    return (S, C)
end

"""
    costate_sweep!(M, mo, S, C; passes)

Solves the costate recursions backwards with quantities held fixed, starting
from the terminal closure.  Prices depend on the costates, so the terminal block
is iterated to a fixed point and the sweep repeated `passes` times.
"""
function costate_sweep!(M::Matrix{Float64}, mo::Model, S::Matrix{Float64},
                        C::Matrix{Float64}; passes::Int = 5)
    p, T = mo.p, mo.T
    Rinf = interest_factor(p, mo.Gam)
    blocks = [period_block(p, t, view(S, t+1, :), view(C, t+1, :)) for t in 0:T]
    for _ in 1:passes
        # terminal block, by fixed point
        for _ in 1:50
            pr = price_block(p, T, blocks[T+1], view(M, T+1, :))
            divs, surv = costate_terms_market(p, blocks[T+1], pr, view(M, T+1, :))
            for k in 1:NM
                den = Rinf - surv[k] * mo.Gam
                M[T+1, k] = abs(den) > 1e-10 ? mo.Gam * divs[k] / den : 0.0
            end
        end
        # backward sweep
        for t in T-1:-1:0
            prn = price_block(p, t + 1, blocks[t+2], view(M, t+2, :))
            pr = price_block(p, t, blocks[t+1], view(M, t+1, :))
            Rf = pr.Lam / (discount(p) * prn.Lam)
            divs, surv = costate_terms_market(p, blocks[t+2], prn, view(M, t+2, :))
            for k in 1:NM
                M[t+1, k] = (divs[k] + surv[k] * M[t+2, k]) / Rf
            end
        end
    end
    return M
end

"""
    initial_guess(mo; kwargs...) -> Vector{Float64}

Packs the simulated quantities and swept costates into the stacked variable
vector.
"""
function initial_guess(mo::Model; passes::Int = 5, warn::Bool = true, kwargs...)
    S, C = simulate_quantities(mo; kwargs...)
    if warn
        bad = count(t -> !period_block(mo.p, t, view(S, t+1, :), view(C, t+1, :)).feasible,
                    0:mo.T)
        bad == 0 || @warn "starting path is below the material floor in $bad of $(mo.T+1) " *
                          "periods; Newton will have nothing to work with. Raise `Rtarget` " *
                          "or `depletion`, or lower `Rbar`."
    end
    M = zeros(Float64, mo.T + 1, NM)
    M[:, IQ] .= 1.0
    costate_sweep!(M, mo, S, C; passes = passes)
    x = zeros(Float64, nvar(mo))
    for t in 0:mo.T
        ctrl_view(x, t) .= view(C, t+1, :)
        cost_view(x, t) .= view(M, t+1, :)
        t < mo.T && (next_state_view(x, t) .= view(S, t+2, :))
    end
    return x
end

