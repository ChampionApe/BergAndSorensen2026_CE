"""
Sufficiency checks.

Implements the verification protocol of `writing/docs/Appendix_sufficiency.tex`:

  * `convexity_report`   -- conditions (C1)-(C5) on the primitives, one line each;
  * `wellposed_report`   -- the long-run assumption (i)-(iii) of the theory note,
    evaluated at a cell's growth and material decay rates;
  * `tvc_report`         -- the six boundary terms of the sufficiency inequality;
  * `perturbation_test`  -- a random search over feasible deviations;
  * `deviation_profile`  -- the value profile along one deviation direction,
    which is what actually distinguishes a local optimum from a Skiba point;
  * `absorbing_shutdown` -- the sufficient condition for a shutdown to be permanent.

In a problem that is not globally concave, a deviation that improves welfare is
not a failure to be suppressed but the informative output: it is an explicit
alternative path.
"""

# ---------------------------------------------------------------------------
# (C1)-(C5): conditions on primitives
# ---------------------------------------------------------------------------

"""
    convexity_report(p; Pmax = nothing, verbose = true) -> Vector{NamedTuple}

Checks each convexity condition of Appendix "Sufficiency", Table "Convexity
conditions for the workhorse specification".  `Pmax`, when supplied, is the
largest pollution stock reached along the path of interest, which is what
condition (C4) has to be evaluated against.
"""
function convexity_report(p::Params; Pmax = nothing, verbose::Bool = true)
    out = NamedTuple[]

    push!(out, (name = "C1 technology",
                holds = 0 < p.mu_F < 1 && p.sigma_s > 0,
                detail = "CES is concave and homogeneous of degree one, raised to " *
                         "mu_F = $(p.mu_F) in (0,1)"))

    push!(out, (name = "C1 damages",
                holds = p.kappa == 0,
                detail = p.kappa == 0 ?
                    "no output damages: F is concave jointly with P" :
                    "multiplicative damages exp(-kappa*P), kappa = $(p.kappa), are convex " *
                    "in P and break joint concavity; the violation is proportional to " *
                    "kappa^2 * F and vanishes as P -> 0"))

    a_concave = p.tail === :exp || p.psi_a <= 1
    push!(out, (name = "C2 recycling",
                holds = a_concave,
                detail = a_concave ?
                    "a is concave, so the perspective R(T,KR) = T a(KR/T) is concave" :
                    "power tail with psi_a = $(p.psi_a) > 1 is convex near the origin, " *
                    "so the recycling technology is not concave"))

    push!(out, (name = "C2 treatment",
                holds = p.chi_T > 0,
                detail = "cT is convex, so its perspective H cT(T/H) is jointly convex in (T,W)"))

    okN = p.chi_N >= p.mu_N && p.kap_N == 0
    push!(out, (name = "C3 extraction",
                holds = okN,
                detail = okN ? "CN is jointly convex in (N,S)" :
                    "N^(1+chi_N) S^(-mu_N) needs chi_N >= mu_N (chi_N = $(p.chi_N), " *
                    "mu_N = $(p.mu_N)" * (p.chi_N >= p.mu_N ? ", satisfied" : ", VIOLATED") *
                    "); the linear term kap_N = $(p.kap_N) is never jointly convex for " *
                    "mu_N > 0 -- and it is exactly what gives extraction a finite choke, " *
                    "hence the possibility of stranding"))

    okD = p.chi_D >= p.mu_D && p.kap_D == 0
    push!(out, (name = "C3 exploration",
                holds = okD,
                detail = okD ? "CD is jointly convex in (D,X)" :
                    "as extraction: needs chi_D >= mu_D (chi_D = $(p.chi_D), " *
                    "mu_D = $(p.mu_D)) and kap_D = 0 (kap_D = $(p.kap_D))"))

    thr = p.thetaP == 0 ? Inf : 2 / p.thetaP
    okT = p.thetaP == 0 || (Pmax !== nothing && Pmax <= thr)
    push!(out, (name = "C4 decay",
                holds = okT,
                detail = p.thetaP == 0 ?
                    "constant decay: (1 - theta) P is linear" :
                    "(1 - theta(P)) P is convex iff theta_P * P <= 2, i.e. P <= " *
                    "$(round(thr, digits = 3))" *
                    (Pmax === nothing ? " (no path supplied)" :
                     "; path max P = $(round(Pmax, digits = 3))")))

    push!(out, (name = "C5 intensity",
                holds = p.phiI == 0,
                detail = p.phiI == 0 ?
                    "no material stored in durables: the intensity condition is vacuous" :
                    "phi_I = $(p.phiI) > 0, so the intensity condition " *
                    "m (D + phi_I G) = R phi_I G is bilinear. Sufficiency is then " *
                    "conditional on the intensity path; the unverified deviations are " *
                    "those that change it"))

    if verbose
        for r in out
            @printf("%-16s %-6s %s\n", r.name, r.holds ? "ok" : "FAILS", r.detail)
        end
        n = count(r -> !r.holds, out)
        println()
        println(n == 0 ?
            "All conditions hold: the convexified problem is a concave programme." :
            "$n condition(s) fail. Sufficiency is conditional -- see the appendix, and " *
            "run deviation_profile / perturbation_test on the computed path.")
    end
    return out
end

# ---------------------------------------------------------------------------
# the long-run assumptions
# ---------------------------------------------------------------------------

"""
    wellposed_report(p; g = cbgp_growth(p), nu = 0.0, verbose = true) -> Vector{NamedTuple}

Assumption "well-posedness and regularity" of
`writing/docs/theory_planner_longrun.tex`, evaluated at the growth rate `g` and
material decay rate `nu` of one cell of the classification (`nu = 0` on the
circular path C, `nu > 0` on a balanced dematerialization path B).  One row per
inequality, with the margin by which it holds or fails:

    (i)    ln(1+rho) > (1-eta) g          lifetime utility converges
    (ii)   e^(g+nu) < 1+r                 a rent growing with the material value
           (1-delta) e^(g+nu) < 1+r       is a convergent sum, and the prices of
           (1-mu) e^(g+nu) < 1+r          embodied material and of the stockpile
                                          are finite and of the right sign
    (iii)  (1-delta)^(1-eta) < 1+rho      collapse paths can be ranked

with `1+r = (1+rho) e^(eta g)`, the Euler equation on a balanced path.  The last
two rows of (ii) are consequences of the first and are reported separately
because they are the ones a calibration breaks first: (ii) at `nu = 0` is (i)
restated, so on a circular path only `delta` and `mu` can pull them apart.

Only (i) and (iii) are conditions on primitives, which is why `check_params`
carries those two -- (i) at the circular rate, the one growth rate the
primitives fix -- and the rest need a cell and live here.  `margin = rhs - lhs`,
positive when the condition holds.
"""
function wellposed_report(p::Params; g::Real = cbgp_growth(p), nu::Real = 0.0,
                          verbose::Bool = true)
    Rf = interest_factor(p, exp(g))          # 1 + r = (1+rho) e^{eta g}
    Gn = exp(g + nu)
    rows = (("(i) well-posedness", (1 - p.eta) * g, log(1 + p.rho),
             "utility converges at g = $(round(g, digits = 5)); vacuous for eta >= 1"),
            ("(ii) regularity", Gn, Rf,
             "e^(g+nu) < 1+r at nu = $(round(nu, digits = 5)): the reserve rent sums"),
            ("(ii) embodied M", (1 - p.delta) * Gn, Rf,
             "Delta_M in (0,1): embodied material carries a finite price"),
            ("(ii) stockpile", (1 - p.mu_h) * Gn, Rf,
             p.mu_h >= 1 ? "vacuous at the buffer corner mu_h = 1" :
                           "the stockpile multiplier is finite"),
            ("(iii) cake-eating", (1 - p.delta)^(1 - p.eta), 1 + p.rho,
             "a path on which production has ceased has a finite value"))
    out = [(name = n, holds = rhs > lhs, lhs = lhs, rhs = rhs,
            margin = rhs - lhs, detail = d) for (n, lhs, rhs, d) in rows]

    verbose && print_wellposed(out)
    return out
end

"Prints the table of a `wellposed_report`; shared with `tvc_report`."
function print_wellposed(out)
    @printf("%-20s %-6s %12s %12s %12s  %s\n",
            "condition", "", "lhs", "rhs", "margin", "reading")
    for r in out
        @printf("%-20s %-6s %12.6f %12.6f %12.6f  %s\n",
                r.name, r.holds ? "ok" : "FAILS", r.lhs, r.rhs, r.margin, r.detail)
    end
    n = count(r -> !r.holds, out)
    println(n == 0 ?
        "All four long-run conditions hold at this (g, nu)." :
        "$n condition(s) fail at this (g, nu): the cell they describe is not " *
        "well posed here.")
    return nothing
end

# ---------------------------------------------------------------------------
# transversality
# ---------------------------------------------------------------------------

"""
    tvc_report(mo, x; verbose = true, window = 20) -> NamedTuple

The six boundary terms `beta^t * Lambda_t * m_t * x_{t+1}` of the sufficiency
inequality, evaluated at the end of the path, with their per-period decay factor
over the last `window` periods.  Proposition "transversality" says five of them
vanish for free because mass conservation bounds the states; only the capital
term is a genuine condition, and it is condition (i) of the long-run
assumptions, so it is read off `wellposed_report` rather than tested twice.

The report is evaluated at the path's own rates: `g = log(Gam)` from the
terminal closure, and `nu` measured on the solved path's material input `R` over
the last `window` periods.  A measured `nu < 0` is a path whose material input is
still rising, not a dematerialization rate; the conditions are then evaluated at
`nu = 0`, which is the binding case, and the measured value is returned as
`nu_path`.
"""
function tvc_report(mo::Model, x::AbstractVector; verbose::Bool = true, window::Int = 20)
    p, T = mo.p, mo.T
    sol = unpack(mo, x)
    bet = discount(p)
    names = ("K", "S", "X", "P", "MK", "W")
    signs = (1.0, 1.0, 1.0, -1.0, -1.0, 1.0)   # costate signs of eq. costates-def

    term(t) = begin
        Lam = sol.prices[t+1].Lam
        m = view(sol.costates, t+1, :)
        xn = t < T ? view(sol.states, t+2, :) :
                     collect(successor_state(p, sol.blocks[end]))
        ntuple(i -> bet^t * Lam * signs[i] * m[i] * xn[i], 6)
    end

    endv = term(T)
    prev = term(max(T - window, 0))
    ratio = ntuple(i -> abs(prev[i]) > 0 ?
                        (abs(endv[i]) / abs(prev[i]))^(1 / max(window, 1)) : NaN, 6)
    asym = bet * mo.Gam^(1 - p.eta)

    # the cell's rates: g from the terminal closure, nu from the path's own R
    gpath = log(mo.Gam)
    i0 = max(T + 1 - window, 1)
    span = (T + 1) - i0
    R1, R0 = sol.blocks[T+1].R, sol.blocks[i0].R
    nu_path = (span > 0 && R1 > 0 && R0 > 0) ? -log(R1 / R0) / span : 0.0
    wp = wellposed_report(p; g = gpath, nu = max(nu_path, 0.0), verbose = false)

    if verbose
        @printf("%-4s %16s %14s\n", "state", "boundary term", "decay/period")
        for i in 1:6
            @printf("%-4s %16.6e %14.5f\n", names[i], endv[i], ratio[i])
        end
        println()
        println("Five of these vanish for free: S, X, P, MK and W are bounded on every")
        println("feasible path by the material budget and the discovery ceiling, so only")
        println("the capital term is a genuine transversality condition. Asymptotically")
        @printf("it decays at beta * e^((1-eta) g) = %.5f", asym)
        println(", which is condition (i) below.")
        if any(r -> isfinite(r) && r > 1, ratio)
            println()
            println("Some measured decay factors exceed one. That is a statement about the")
            println("horizon, not about transversality: the path is still in transition at")
            println("T, so the boundary terms have not yet begun to fall at their asymptotic")
            println("rate. Lengthen the horizon to see them turn.")
        end
        println()
        @printf("Long-run assumptions at g = %.5f, nu = %.5f (measured %.5f):\n",
                gpath, max(nu_path, 0.0), nu_path)
        print_wellposed(wp)
    end
    return (; terms = endv, decay = ratio, names, capital_tvc_factor = asym,
            asymptotic_ok = wp[1].holds, wellposed = wp, g = gpath, nu_path)
end

# ---------------------------------------------------------------------------
# feasible deviations
# ---------------------------------------------------------------------------

"""
    assert_solved(mo, x; tol) -> Float64

Refuses to run a sufficiency test on a point that does not satisfy the necessary
conditions.  This guard is not defensive padding: a deviation test applied to a
non-converged path will cheerfully report that some deviation beats it, which is
true and entirely uninformative, because the path was never a critical point.
"""
function assert_solved(mo::Model, x::AbstractVector; tol::Real = 1e-6)
    F = Vector{Float64}(undef, nvar(mo))
    residual_market!(F, mo, x)
    nrm = maximum(abs, F)
    nrm <= tol || error("the path does not satisfy the necessary conditions " *
                        "(|F| = $(round(nrm, sigdigits = 3)) > $tol). Solve it first: a " *
                        "deviation test on a non-critical point tells you nothing.")
    return nrm
end

"""
    simulate_from_controls(mo, Cmat) -> (states, blocks, ok)

Forward-simulates the path implied by a control matrix in which consumption is
ignored and re-derived from the goods constraint.  The result satisfies every
transition and the goods constraint by construction, so the only feasibility
questions left are `C > 0` and the material floor.

The within-period ordering is what makes this possible: output and the cost
flows do not depend on consumption, and consumption enters only the waste base,
so setting it residually leaves the block acyclic.
"""
function simulate_from_controls(mo::Model, Cmat::AbstractMatrix)
    p, T = mo.p, mo.T
    S = Matrix{Float64}(undef, T + 1, NS)
    S[1, :] .= mo.s0
    blocks = Vector{Any}(undef, T + 1)
    ctrls = copy(Cmat)
    for t in 0:T
        b0 = period_block(p, t, view(S, t+1, :), view(ctrls, t+1, :))
        b0.feasible || return (S, blocks, false)
        Cres = b0.Y - b0.I - p.delta * b0.K - b0.CN - b0.CD - b0.CW
        Cres > 0 || return (S, blocks, false)
        ctrls[t+1, IC] = Cres
        b = period_block(p, t, view(S, t+1, :), view(ctrls, t+1, :))
        b.feasible || return (S, blocks, false)
        blocks[t+1] = b
        if t < T
            th, = decay(p, b.Pst)
            S[t+2, :] .= (b.K + b.I, b.S + b.D - b.N, b.X + b.D,
                          b.Pst + b.Xi - th * b.Pst,
                          (1 - p.delta) * b.MK + b.Omega * p.phiI * b.G,
                          (1 - p.mu_h) * b.Wst + b.W)
            all(isfinite, view(S, t+2, :)) || return (S, blocks, false)
            S[t+2, IS] < 0 && return (S, blocks, false)
        end
    end
    return (S, blocks, true)
end

"""
    test_value(mo, blocks, term_prices) -> Float64

The objective of eq. (vtest): discounted felicity over the horizon plus the
terminal states valued at the *candidate's* shadow prices.  Valuing terminal
states at fixed prices is what makes deviations comparable, and it is exactly
the boundary term the sufficiency inequality carries.
"""
function test_value(mo::Model, blocks, term_prices)
    p, T = mo.p, mo.T
    bet = discount(p)
    V = 0.0
    for t in 0:T
        b = blocks[t+1]
        V += bet^t * (util(p, b.C) - disutil(p, b.Pst))
    end
    xn = collect(successor_state(p, blocks[end]))
    signs = (1.0, 1.0, 1.0, -1.0, -1.0, 1.0)
    V += bet^T * term_prices.Lam * sum(signs[i] * term_prices.m[i] * xn[i] for i in 1:6)
    return V
end

"Shadow prices of the candidate, used to value terminal states in the tests."
terminal_prices(sol) = (; Lam = sol.prices[end].Lam, m = collect(sol.costates[end, :]))

"Apply a scalar deviation `e` to one control over a window of dates."
function apply_deviation(base::AbstractMatrix, control::Int, win, e::Real)
    ctrl = copy(base)
    for t in win
        r = t + 1
        if control == IVW
            ctrl[r, IVW] = clamp(ctrl[r, IVW] + e, 0.0, 1.0)
        elseif control == II
            ctrl[r, II] += e * abs(ctrl[r, II] + 1e-3)
        else
            ctrl[r, control] = max(0.0, ctrl[r, control] * (1 + e))
        end
    end
    return ctrl
end

"""
    deviation_profile(mo, x; control, window, grid, verbose) -> NamedTuple

Traces the test value along a one-dimensional family of feasible deviations, so
that the *shape* of the objective in that direction is visible rather than only
its slope at zero.

This is the diagnostic that matters in a non-convex problem.  A profile that is
single-peaked at zero is consistent with local optimality; a profile with a
second local maximum is a Skiba-type alternative that has been found, not merely
suspected.  Two directions are worth tracing, and they are the two places
Appendix "Sufficiency" says concavity fails:

  * `control = IN` scales extraction over a window, probing the non-convexity
    that a finite extraction choke (`kap_N > 0`) introduces;
  * `control = II` shifts investment against consumption, which moves the
    material intensity and so probes the bilinear intensity condition.

Note the treatment share is perturbed additively (it is a share), the others
proportionally.
"""
function deviation_profile(mo::Model, x::AbstractVector;
                           control::Int = IN, window = nothing,
                           grid = -1.0:0.25:1.0, verbose::Bool = true,
                           tol::Real = 1e-6)
    assert_solved(mo, x; tol = tol)
    T = mo.T
    sol = unpack(mo, x)
    tp = terminal_prices(sol)
    base = copy(sol.controls)
    win = window === nothing ? (0:T) : window

    _, b0, ok0 = simulate_from_controls(mo, base)
    ok0 || error("the candidate path is not reproducible by forward simulation")
    V0 = test_value(mo, b0, tp)

    eps = collect(grid)
    vals = fill(NaN, length(eps))
    for (k, e) in enumerate(eps)
        _, blocks, ok = simulate_from_controls(mo, apply_deviation(base, control, win, e))
        ok && (vals[k] = test_value(mo, blocks, tp) - V0)
    end

    fin = findall(isfinite, vals)
    bestk = isempty(fin) ? 0 : fin[argmax(vals[fin])]
    nloc = 0
    for j in 2:length(fin)-1
        a, b, c = vals[fin[j-1]], vals[fin[j]], vals[fin[j+1]]
        (b > a && b > c) && (nloc += 1)
    end
    bg = isempty(fin) ? NaN : maximum(vals[fin])
    be = isempty(fin) ? NaN : eps[bestk]
    clean = isempty(fin) ? false : (bg <= 1e-8 * max(abs(V0), 1.0) && nloc <= 1)

    if verbose
        nm = control == IN ? "N (extraction)" : control == II ? "I (investment)" :
             control == IVW ? "varpi (treatment)" : control == IXR ? "x (recycling capital per treated tonne)" :
             "control $control"
        @printf("deviation profile in %s over %d periods\n", nm, length(win))
        @printf("%8s %16s\n", "eps", "value gain")
        for (e, v) in zip(eps, vals)
            @printf("%8.2f %16s\n", e, isfinite(v) ? (@sprintf "%+.4e" v) : "infeasible")
        end
        println()
        @printf("best gain %+.3e at eps = %.2f; interior local maxima: %d\n", bg, be, nloc)
        println(clean ?
            "Single-peaked at zero: consistent with local optimality in this direction." :
            "NOT single-peaked at zero. Inspect: this is a candidate alternative path.")
    end
    return (; eps, gain = vals, best_eps = be, best_gain = bg,
            interior_local_maxima = nloc, single_peaked = clean, V0)
end

"""
    perturbation_test(mo, x; ndraws, scales, seed, verbose) -> NamedTuple

Random search over feasible deviations: perturbs `(I, N, D, varpi, x)` over a
random window of dates at a random scale, with consumption absorbing the goods
constraint.  Returns the best gain found, which should be non-positive up to
numerical error.

This complements `deviation_profile` rather than replacing it: the random search
covers many directions shallowly, the profile covers one direction properly.
"""
function perturbation_test(mo::Model, x::AbstractVector;
                           ndraws::Int = 400, scales = (0.01, 0.05, 0.2),
                           seed::Int = 20260827, verbose::Bool = true,
                           tol::Real = 1e-6)
    assert_solved(mo, x; tol = tol)
    T = mo.T
    sol = unpack(mo, x)
    tp = terminal_prices(sol)
    base = copy(sol.controls)

    _, b0, ok0 = simulate_from_controls(mo, base)
    ok0 || error("the candidate path is not reproducible by forward simulation")
    V0 = test_value(mo, b0, tp)

    rng = MersenneTwister(seed)
    best_gain, best, nfeas = -Inf, nothing, 0
    Yscale = maximum(b.Y for b in sol.blocks)

    for draw in 1:ndraws
        sc = scales[1 + (draw - 1) % length(scales)]
        t0 = rand(rng, 0:T)
        len = rand(rng, 1:max(1, div(T, 4)))
        ctrl = copy(base)
        for t in t0:min(t0 + len, T)
            r = t + 1
            ctrl[r, II]  += sc * Yscale * randn(rng)
            ctrl[r, IN]   = max(0.0, ctrl[r, IN] * (1 + sc * randn(rng)))
            ctrl[r, ID]   = max(0.0, ctrl[r, ID] * (1 + sc * randn(rng)))
            ctrl[r, IVW]  = clamp(ctrl[r, IVW] + sc * randn(rng), 0.0, 1.0)
            ctrl[r, IXR]  = max(0.0, ctrl[r, IXR] * (1 + sc * randn(rng)))
        end
        _, blocks, ok = simulate_from_controls(mo, ctrl)
        ok || continue
        nfeas += 1
        gain = test_value(mo, blocks, tp) - V0
        if gain > best_gain
            best_gain = gain
            best = (; draw, scale = sc, t0, len, gain)
        end
    end

    rel = best_gain / max(abs(V0), 1.0)
    clean = best_gain <= 1e-8 * max(abs(V0), 1.0)
    if verbose
        @printf("feasible draws          %d / %d\n", nfeas, ndraws)
        @printf("candidate test value    %.8f\n", V0)
        @printf("best deviation gain     %+.3e  (relative %+.3e)\n", best_gain, rel)
        if clean
            println("No feasible deviation improved on the candidate: consistent with")
            println("local optimality over the directions searched.")
        else
            println("A deviation BEAT the candidate. Either the solver returned a")
            println("non-optimal critical point, or the problem is locally non-concave")
            println("here and this is a genuine alternative path. Inspect `best`.")
            println("  ", best)
        end
    end
    return (; V0, best_gain, relative_gain = rel, feasible_draws = nfeas, best, clean)
end

# ---------------------------------------------------------------------------
# absorbing shutdown
# ---------------------------------------------------------------------------

"""
    absorbing_shutdown(p, state; t = 0) -> NamedTuple

Proposition "absorbing shutdown": after production ceases, the throughput cap
can never again clear the floor if

    abar * mu * (MK + W)  +  N_max  <  Rbar,

where `N_max` is the largest extraction the remaining capital could finance in a
single period.  Mass conservation makes `MK + W` at the shutdown date an upper
bound on the stockpile at every later date.

Where this fails, a shutdown followed by a restart -- financed by scrapping
capital, whose embodied material feeds the waste stock -- is not excluded, and a
search over single shutdown dates is searching over too small a family.
"""
function absorbing_shutdown(p::Params, state::AbstractVector; t::Int = 0)
    K, S, X, Pst, MK, Wst = state
    p.Rbar > 0 || return (; absorbing = true, slack = Inf, Nmax = 0.0,
                          recycled_cap = 0.0,
                          detail = "no floor: shutdown is not a possibility")
    budget = (1 - p.delta) * K
    f(N) = extraction(p, t, N, S)[1] - budget
    Nmax = if f(0.0) >= 0
        0.0
    else
        br = bracket(f, 0.0, max(1e-3, budget))
        br === nothing ? Inf : something(bisect(f, br[1], br[2]), Inf)
    end
    cap = p.abar * p.mu_h * (MK + Wst) + Nmax
    return (; absorbing = cap < p.Rbar, slack = p.Rbar - cap, Nmax,
            recycled_cap = p.abar * p.mu_h * (MK + Wst),
            detail = cap < p.Rbar ?
                "throughput cap $(round(cap, digits = 4)) < floor $(p.Rbar): permanent" :
                "throughput cap $(round(cap, digits = 4)) >= floor $(p.Rbar): a restart is " *
                "not excluded, so the operating set may not be a single interval")
end
