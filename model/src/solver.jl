"""
Newton solver for the stacked system.

The Jacobian is block-tridiagonal in time (residual block `t` involves blocks
`t-1`, `t`, `t+1` only), so it is recovered by structured finite differences:
perturbing every third block simultaneously never mixes two entries of the same
Jacobian row.  One Jacobian therefore costs `3 * NBLK` residual evaluations
regardless of the horizon, and the resulting sparse matrix is factorised
directly.  This keeps the implementation free of automatic-differentiation
dependencies.
"""

using LinearAlgebra, SparseArrays, Printf

blocksize(mo::Model, t::Int) = t == mo.T ? NEND : NBLK

"""
    jacobian(mo, x, resid!; smooth) -> SparseMatrixCSC

Structured finite-difference Jacobian.  `resid!` is `residual_market!` or
`residual_planner!`.
"""
function jacobian(mo::Model, x::Vector{Float64}, resid!; smooth::Real = 0.0)
    n = nvar(mo)
    F0 = Vector{Float64}(undef, n); resid!(F0, mo, x; smooth = smooth)
    Fp = Vector{Float64}(undef, n)
    xp = similar(x)
    Is, Js, Vs = Int[], Int[], Float64[]
    sizehint!(Is, n * (2 * NBLK + NEND)); sizehint!(Js, n * (2 * NBLK + NEND))
    sizehint!(Vs, n * (2 * NBLK + NEND))

    hs = zeros(Float64, n)   # per-column step, recorded for the shared sweep
    for color in 0:2, j in 1:NBLK
        copyto!(xp, x)
        touched = Int[]
        for t in color:3:mo.T
            j > blocksize(mo, t) && continue
            col = blockoffset(t) + j
            h = sqrt(eps(Float64)) * max(abs(x[col]), 1.0)
            hs[col] = h
            xp[col] += h
            push!(touched, t)
        end
        isempty(touched) && continue
        resid!(Fp, mo, xp; smooth = smooth)
        for t in touched
            col = blockoffset(t) + j
            h = hs[col]
            for tr in max(t - 1, 0):min(t + 1, mo.T)
                r0 = blockoffset(tr)
                for k in 1:blocksize(mo, tr)
                    row = r0 + k
                    d = (Fp[row] - F0[row]) / h
                    if d != 0
                        push!(Is, row); push!(Js, col); push!(Vs, d)
                    end
                end
            end
        end
    end
    return sparse(Is, Js, Vs, n, n)
end

"""
    newton!(mo, x, resid!; smooth, tol, maxiter, verbose) -> (converged, |F|)

Newton with backtracking on the residual norm.  Returns in place.
"""
function newton!(mo::Model, x::Vector{Float64}, resid!;
                 smooth::Real = 0.0, tol::Real = 1e-9, maxiter::Int = 60,
                 verbose::Bool = false, maxstep::Real = Inf)
    n = nvar(mo)
    F = Vector{Float64}(undef, n); Ft = similar(F); xt = similar(x)
    resid!(F, mo, x; smooth = smooth)
    nrm = norm(F, Inf)
    for it in 1:maxiter
        (isfinite(nrm) && nrm <= tol) && return (true, nrm)
        J = jacobian(mo, x, resid!; smooth = smooth)
        dx = try
            -(J \ F)
        catch err
            verbose && @warn "linear solve failed" err
            return (false, nrm)
        end
        all(isfinite, dx) || return (false, nrm)
        sc = min(1.0, maxstep / max(norm(dx, Inf), eps()))
        ok = false
        a = sc
        for _ in 1:40
            @. xt = x + a * dx
            resid!(Ft, mo, xt; smooth = smooth)
            nt = norm(Ft, Inf)
            if isfinite(nt) && nt < nrm
                copyto!(x, xt); copyto!(F, Ft); nrm = nt; ok = true; break
            end
            a *= 0.5
        end
        verbose && @printf("  newton %3d  |F| = %.3e  step = %.3g\n", it, nrm, a)
        ok || return (false, nrm)
    end
    return (norm(F, Inf) <= tol, norm(F, Inf))
end

"""
    solve_path(mo, x0; resid!, schedule, tol, verbose) -> (x, converged, |F|)

Solves the system along a homotopy in the complementarity smoothing width,
finishing at `smooth = 0` so that the returned solution satisfies the exact
Kuhn--Tucker conditions.
"""
function solve_path(mo::Model, x0::AbstractVector;
                    resid! = residual_market!,
                    schedule = [1e-1, 1e-2, 1e-3, 1e-4, 1e-5, 0.0],
                    tol::Real = 1e-9, maxiter::Int = 60, verbose::Bool = false,
                    maxstep::Real = Inf)
    x = collect(float.(x0))
    conv, nrm = false, Inf
    for e in schedule
        verbose && @printf("smoothing e = %.1e\n", e)
        conv, nrm = newton!(mo, x, resid!; smooth = e, tol = tol,
                            maxiter = maxiter, verbose = verbose, maxstep = maxstep)
        if !conv
            verbose && @printf("  did not converge at e = %.1e (|F| = %.3e)\n", e, nrm)
            return (x, false, nrm)
        end
    end
    return (x, conv, nrm)
end

# ---------------------------------------------------------------------------
# continuation
# ---------------------------------------------------------------------------

"""
    solve_with_shutdown(p, s0, dates; guess_kwargs, kwargs...) -> NamedTuple

Searches over the shutdown date.  For each candidate `Td` in `dates` the smooth
system is solved on `[0, Td]` with the continuation valued by `V_stop`, and the
candidate is scored by

    sum_{t <= Td} beta^t [u(C_t) - v(P_t)]  +  beta^{Td+1} V_stop(state_{Td+1}).

Returns the best candidate together with the full table, so that a flat or
multi-peaked objective is visible rather than silently resolved.  This is the
discrete comparison of `writing/quant/quant_solution.tex`, Section "Paths that
hit the floor"; it adds a scalar grid search and no dimension to the problem.

Dates are visited in ascending order.  Each is first attempted *warm*, from the
previous converged date's solution extended by `extend_horizon`; failing that,
*cold* by `shutdown_cold_start`.  A date on which both fail, or whose solved
path falls below the floor, is skipped and the table row carries `ok = false`
and a `reason`; the row of a converged date records the `route` taken.
"""
function solve_with_shutdown(p::Params, s0::AbstractVector, dates;
                             guess_kwargs = (; Rtarget = 0.6), floor_steps::Int = 6,
                             verbose::Bool = false, kwargs...)
    table = NamedTuple[]
    best = nothing
    prev = nothing
    for Td in sort!(collect(Int, dates))
        mo = Model(p; T = Td, s0 = s0, Gam = 1.0, terminal = :shutdown)
        ok, route, reason, x, nrm = false, :warm, "", Float64[], Inf
        if prev !== nothing && prev.mo.T < Td
            _, x0 = extend_horizon(prev.mo, prev.x, Td)
            x, ok, nrm = solve_path(mo, x0; verbose = verbose, kwargs...)
            ok || (reason = @sprintf("warm start from T = %d stalled at |F| = %.1e; ",
                                     prev.mo.T, nrm))
        end
        if !ok
            route = :cold
            x, ok, nrm, why = shutdown_cold_start(mo; guess_kwargs = guess_kwargs,
                                                  floor_steps = floor_steps,
                                                  verbose = verbose, kwargs...)
            ok || (reason *= why)
        end
        if ok
            sol = unpack(mo, x)
            if any(b -> !b.feasible, sol.blocks)
                ok, reason = false, "the solved path falls below the floor"
            end
        end
        verbose && @printf("shutdown date %d: %s%s\n", Td, ok ? "converged, $route" : "skipped: ", reason)
        if !ok
            push!(table, (; Td, ok = false, value = -Inf, resid = nrm, route, reason))
            continue
        end
        sol = unpack(mo, x)
        bet = discount(p)
        U = sum(bet^t * (util(p, sol.blocks[t+1].C) - disutil(p, sol.blocks[t+1].Pst))
                for t in 0:Td)
        Kn, _, _, Pn, MKn, Wn = successor_state(p, sol.blocks[end])
        V = U + bet^(Td + 1) * value_stop(p, Kn, Wn, Pn, MKn)
        push!(table, (; Td, ok = true, value = V, resid = nrm, route, reason))
        prev = (; mo, x)
        if best === nothing || V > best.value
            best = (; Td, value = V, x, mo)
        end
    end
    return (; best, table)
end

"""
    shutdown_cold_start(mo; guess_kwargs, floor_steps, kwargs...) -> (x, ok, |F|, reason)

A shutdown-terminated path from nothing, in three stages, each from the last:
the floorless problem under the ordinary terminal closure, which is the
well-tested solve; the same path handed over to `V_stop`; and the floor raised
to its target in `floor_steps` steps.  The floor makes the residual
discontinuous -- output jumps to zero below it -- so a Newton step that crosses
it cannot be recovered by backtracking, which is why it is walked in.  The cold
guess of `initial_guess` does not work under the shutdown terminal: its costate
sweep is built on the closure, and Newton from there runs into a singular
Jacobian on every date tried.
"""
function shutdown_cold_start(mo::Model; guess_kwargs = (; Rtarget = 0.6),
                             floor_steps::Int = 6, kwargs...)
    p, Td, s0 = mo.p, mo.T, mo.s0
    p0 = with(p; Rbar = 0.0)
    moc = Model(p0; T = Td, s0 = s0)
    x, ok, nrm = solve_path(moc, initial_guess(moc; guess_kwargs...); kwargs...)
    ok || return (x, false, nrm, @sprintf("floorless closure solve stalled at |F| = %.1e", nrm))
    mo0 = Model(p0; T = Td, s0 = s0, Gam = 1.0, terminal = :shutdown)
    x, ok, nrm = solve_path(mo0, x; kwargs...)
    ok || return (x, false, nrm, @sprintf("handover to V_stop stalled at |F| = %.1e", nrm))
    if p.Rbar > 0
        x, ok, nrm = continuate(mo0, mo, x; steps = floor_steps, kwargs...)
        ok || return (x, false, nrm, @sprintf("floor homotopy stalled at |F| = %.1e", nrm))
    end
    return (x, true, nrm, "")
end

"""
    extend_horizon(mo, x, Tnew) -> (mo_long, x0_long)

Builds a starting point for a longer horizon out of a solved shorter one: the
solved blocks are copied, and the tail is filled by extrapolating each variable
geometrically at the growth factor it exhibits over the last two solved periods.

This is the reliable way to reach long horizons.  A cold guess deteriorates with
`T` -- the simple rules of `simulate_quantities` drift further from the solution
the longer they run -- whereas the solved path already carries the right
asymptotic behaviour and only needs continuing.  Growth factors are clamped so
that a variable which happens to be turning over near `T` cannot generate an
explosive tail.
"""
function extend_horizon(mo::Model, x::AbstractVector, Tnew::Int;
                        clampfac = (0.85, 1.2), depletion::Real = 0.05,
                        lag::Int = 20, win::Int = 40)
    Tnew > mo.T || error("extend_horizon: Tnew must exceed the current horizon")
    p = mo.p
    sol = unpack(mo, x)
    mo2 = Model(p, Tnew, mo.s0, mo.Gam, mo.terminal)

    # Growth factors are estimated over a window that stops `lag` periods short
    # of T.  The last few periods of a finite-horizon solve are distorted by the
    # terminal closure -- investment in particular jumps -- so their period-to-
    # period ratios are not the asymptotic ones, and extrapolating them produces
    # an explosive tail.
    i2 = max(2, mo.T + 1 - lag)
    i1 = max(1, i2 - win)
    span = max(i2 - i1, 1)
    gfac(M, j) = begin
        a, b = M[i2, j], M[i1, j]
        (abs(b) > 1e-14 && a * b > 0) ? clamp((a / b)^(1 / span), clampfac[1], clampfac[2]) : 1.0
    end
    gm = [gfac(sol.costates, j) for j in 1:NM]
    gN, gD, gX = gfac(sol.controls, IN), gfac(sol.controls, ID), gfac(sol.controls, IXR)

    C = Matrix{Float64}(undef, Tnew + 1, NC)
    C[1:mo.T+1, :] .= sol.controls
    S = Matrix{Float64}(undef, Tnew + 1, NS)
    S[1, :] .= mo.s0

    for t in 0:Tnew
        if t > mo.T
            # Investment is pinned to balanced growth of the capital stock rather
            # than extrapolated, and consumption is taken residually from the
            # goods constraint, so the tail is feasible by construction.
            C[t+1, II]  = (mo.Gam - 1) * S[t+1, IK]
            C[t+1, IN]  = min(C[t, IN] * gN, depletion * max(S[t+1, IS], 0.0))
            C[t+1, ID]  = min(C[t, ID] * gD, depletion * max(p.Xmax - S[t+1, IX], 0.0))
            C[t+1, IVW] = clamp(C[t, IVW], 0.0, 1.0)
            # the intensity is extrapolated; the capital it implies, x T, is
            # kept below the capital stock so that KY stays positive
            Ttr = C[t+1, IVW] * p.mu_h * max(S[t+1, IWS], 0.0)
            xcap = Ttr > 0 ? 0.9 * max(S[t+1, IK], 0.0) / Ttr : Inf
            C[t+1, IXR] = clamp(C[t, IXR] * gX, 0.0, xcap)
            b0 = period_block(p, t, view(S, t+1, :), view(C, t+1, :))
            Cres = b0.Y - b0.I - p.delta * b0.K - b0.CN - b0.CD - b0.CW
            C[t+1, IC] = max(Cres, 1e-6 * max(b0.Y, 1.0))
        end
        b = period_block(p, t, view(S, t+1, :), view(C, t+1, :))
        t == Tnew && break
        th, = decay(p, b.Pst)
        S[t+2, :] .= (b.K + b.I, max(b.S + b.D - b.N, 1e-8), b.X + b.D,
                      max(b.Pst + b.Xi - th * b.Pst, 0.0),
                      (1 - p.delta) * b.MK + b.Omega * p.phiI * b.G,
                      max((1 - p.mu_h) * b.Wst + b.W, 1e-8))
    end

    # Costates: solved values up to T, extrapolated beyond, then swept backwards
    # against the new quantities so that the price block is internally consistent.
    M = Matrix{Float64}(undef, Tnew + 1, NM)
    M[1:mo.T+1, :] .= sol.costates
    for t in mo.T+1:Tnew
        M[t+1, :] .= sol.costates[end, :] .* gm .^ (t - mo.T)
    end
    costate_sweep!(M, mo2, S, C; passes = 3)

    x2 = zeros(Float64, nvar(mo2))
    for t in 0:Tnew
        ctrl_view(x2, t) .= view(C, t+1, :)
        cost_view(x2, t) .= view(M, t+1, :)
        t < Tnew && (next_state_view(x2, t) .= view(S, t+2, :))
    end
    return (mo2, x2)
end

"""
    solve_long(p, s0, T; start_T, step, kwargs...) -> (mo, x, ok, nrm)

Solves at horizon `T` by first solving at `start_T` and then extending the
horizon in increments of `step`, re-solving at each stage.  Use this rather than
a cold solve whenever `T` is large.

The step is halved on a failure and the horizon reached is returned once it
falls below `min_step`.  The default is one period: a solve costs about a
second, and on the calibrated set a fast-growing circular path that the
extrapolated tail of `extend_horizon` cannot follow six periods ahead is still
followed one period ahead, so a wall declared at a larger step is the guess's
and not the model's.
"""
function solve_long(p::Params, s0::AbstractVector, T::Int;
                    start_T::Int = 150, step::Int = 50, min_step::Int = 1,
                    Gam = exp(cbgp_growth(p)),
                    guess_kwargs = (; Rtarget = 0.6), verbose::Bool = false, kwargs...)
    mo = Model(p; T = min(start_T, T), s0 = s0, Gam = Gam)
    x, ok, nrm = solve_path(mo, initial_guess(mo; guess_kwargs...); kwargs...)
    ok || return (mo, x, false, nrm)
    st = step
    while mo.T < T
        Tn = min(mo.T + st, T)
        mo2, x0 = extend_horizon(mo, x, Tn)
        x2, ok2, nrm2 = solve_path(mo2, x0; kwargs...)
        verbose && @printf("  horizon %d: converged = %s, |F| = %.2e\n", Tn, ok2, nrm2)
        if ok2
            mo, x, nrm = mo2, x2, nrm2
            st = min(step, 2 * st)
        else
            # Halve the step and retry.  Failure here is usually not a solver
            # problem but a stiff phase of the model: as the reserve approaches
            # exhaustion the factor (S_ref/S)^mu_N diverges, and the horizon at
            # which that happens is a property of the calibration.
            st = div(st, 2)
            if st < min_step
                verbose && @printf("  stalling at horizon %d; returning the longest solve\n", mo.T)
                return (mo, x, false, nrm)
            end
        end
    end
    return (mo, x, true, nrm)
end

"""
    continuate(mo_from, mo_to, x0; steps, kwargs...)

Solves a sequence of models linearly interpolating every `Float64` field of the
parameter set from `mo_from.p` to `mo_to.p`, each from the previous solution.
Used to walk into the hard corners of the parameter space (a positive floor, a
soft ceiling, trending technology) and across the policy dials.
"""
function continuate(mo_from::Model, mo_to::Model, x0::AbstractVector;
                    steps::Int = 8, verbose::Bool = false, kwargs...)
    x = collect(float.(x0))
    flds = fieldnames(Params)
    ok, nrm = false, Inf
    for i in 1:steps
        w = i / steps
        vals = map(flds) do f
            a, b = getfield(mo_from.p, f), getfield(mo_to.p, f)
            (a isa Float64 && b isa Float64) ? (1 - w) * a + w * b : b
        end
        p = Params(; NamedTuple{flds}(vals)...)
        mo = Model(p, mo_to.T, mo_to.s0,
                   (1 - w) * mo_from.Gam + w * mo_to.Gam, mo_to.terminal)
        verbose && @printf("continuation step %d/%d\n", i, steps)
        x, ok, nrm = solve_path(mo, x; verbose = verbose, kwargs...)
        ok || return (x, false, nrm)
    end
    return (x, ok, nrm)
end
