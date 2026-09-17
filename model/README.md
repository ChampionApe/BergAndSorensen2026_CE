# `model/` — quantitative implementation

Julia implementation of the quantitative model documented in
`writing/quant/quant_model.tex`, `quant_solution.tex` and `quant_calibration.tex`.
Standard-library dependencies only (`LinearAlgebra`, `SparseArrays`, `Printf`).

```
julia --project=. test/runtests.jl           # 825 tests, ~14 s
julia --project=. scripts/run_baseline.jl    # baseline path + policy dials, ~30 s
julia --project=. scripts/run_sufficiency.jl # convexity, transversality, deviations
```

## The one idea to hold on to

The social planner's problem and the decentralised market economy are **the same
residual system** evaluated at different points of a four-dimensional policy
space. The planner is the corner `(phiW, phiz, phiP, phiX) = (1, 1, 1, 1)`:

| dial | instrument | at 1 | at 0 |
|---|---|---|---|
| `phiW` | property rights over the waste stock | gate fee `tauW = -pW` | free dumping |
| `phiz` | material-content charge | `z = zeta - tauW` | no charge |
| `phiP` | emission tax | `tauP = pP` | no tax |
| `phiX` | discovery tax | `tauX = -pX` | common-pool exploration |

Two independent transcriptions of the residuals are carried — `residual_market!`
written from the market conditions of Part II, and `residual_planner!` written
from the planner's conditions of Part I — and they are required to agree to
machine precision at the planner corner, at arbitrary points of the state and
control space. That is the decentralisation proposition tested as an algebraic
identity rather than as a property of a solution, and it is the main reason the
duplication is worth its cost.

## Layout

| file | contents |
|---|---|
| `src/parameters.jl` | `Params`, derived rates, `check_params` |
| `src/primitives.jl` | functional forms and derivatives |
| `src/period.jl` | within-period definitions, accounting, price block |
| `src/residuals.jl` | the stacked system, both transcriptions |
| `src/terminal.jl` | terminal closure, `V_stop`, the shutdown state |
| `src/longrun.jl` | stationary rest point, circular growth path, closure criterion, long-run classifier |
| `src/solver.jl` | Newton, continuation in parameters and horizon, shutdown-date search |
| `src/guess.jl` | starting values |
| `src/diagnostics.jl` | verification checks, welfare, series accessors |
| `src/sufficiency.jl` | convexity conditions, transversality, feasible-direction tests |
| `src/calibration.jl` | **illustrative** parameter sets — not calibrated |

## Method, in one paragraph

The system is solved as one large square nonlinear system in all
`12(T+1) + 6T` unknowns rather than by shooting. Because the within-period
block is acyclic — the handled flow is drawn from a predetermined stock, so
there is no within-period fixed point — residual block `t` involves only blocks
`t-1`, `t`, `t+1`, and the Jacobian is block-tridiagonal. It is recovered by
structured finite differences: perturbing every third block at once never mixes
two entries of a row, so one Jacobian costs `3 x 18` residual evaluations
whatever the horizon. Corner conditions enter through the min-map of the
complementarity problem, smoothed along a homotopy that finishes at zero so the
returned solution satisfies the exact Kuhn–Tucker conditions.

A 200-period planner path (3612 unknowns) solves in about 2.5 s.

## What is verified

Every solved path is checked against things the model should satisfy without
having been told to:

- the collected ledger holds period by period (~1e-11), which ties the
  accounting to the transitions rather than merely restating it;
- cumulative extraction respects the discovery bound, and cumulative leakage the
  material budget;
- the planner and market transcriptions agree at the planner corner (~1e-16);
- the solved path converges to the independently computed circular balanced
  growth path — on the baseline, Little's law predicts `R_inf = 2.74` against a
  path value of `2.82` still converging at `T = 200`;
- the closure criterion reproduces the analytic tail results: recycling
  intensity grows at exactly `g/(1+psi)` on a power tail and linearly in time on
  an exponential one;
- `classify_longrun` reads the taxonomy of the theory note's Section 3 off a
  path -- floor and ceiling from the parameters, closure from the tail
  criterion, survival from Little's law against the path's retained endowment
  -- and returns its margins with the state. The baseline is `:C` (`M_inf =
  45.2`, residence time 57 periods at `T = 60`). Diagnostic only: it names the
  state, it does not verify convergence to it;
- the shutdown handover prices every stock handed over: `q`, `pW`, `pP` and
  `pM` at `T` are the exact derivatives of `V_stop` per unit of income, and
  its legacy recursion carries the `delta M^K` inflow — the material the eaten
  capital keeps releasing — that the theory note's eq. (app:wh:Vstop) records
  as omitted. Measured on `baseline_params(Rbar = 0.35)` over the dates
  `10:10:200`: the inflow raises the legacy term by 40–56%, moves `V_stop` by
  0.05–0.5% of its value and the search's objective by under 0.05%, and leaves
  the best date where it was (the last of the grid; the objective is monotone
  there, and on the `abar = 0.7` variant too). Small, but exact, tested and
  free, so it is the default rather than a recorded approximation; `pM` at
  the handover is about 0.8 of the gate fee;
- the stationary benchmark of Appendix D is a return point: with the trends
  off, the linear aggregate and the terminal closure at `Gam = 1`, a path
  started 3% away from the closed-form dematerialized rest point returns to
  it, goods block and prices within 1e-3 at `T = 60`.

## Sufficiency

The model is not globally concave, so the solver returns a point satisfying the
*necessary* conditions. `src/sufficiency.jl` implements the protocol of
`writing/docs/Appendix_sufficiency.tex`:

- `convexity_report(p)` — checks (C1)–(C5) on the primitives and says which
  fail. On the illustrative calibration four fail: multiplicative damages, the
  extraction and exploration cost functions (because they have a finite choke),
  and the intensity condition (because `phiI > 0`).
- `wellposed_report(p; g, nu)` — Assumption "well-posedness and regularity" of
  the theory note as four inequalities with their margins, at one cell's growth
  rate and material decay rate. `check_params` warns on the two that are
  conditions on primitives; `tvc_report` evaluates all four at the path's own
  rates. The illustrative set passes all four on the circular path and fails
  `e^(g+nu) < 1+r` at its own balanced-dematerialization rates.
- `tvc_report(mo, x)` — the six boundary terms. Five vanish for free, because
  mass conservation bounds their states; only the capital term is a genuine
  condition, and it holds iff `beta * e^((1-eta)g) < 1`, which is condition (i)
  above and is read off that report rather than tested twice.
- `deviation_profile(mo, x; control, window, grid)` — the value profile along
  one deviation direction. This is the diagnostic that matters: a profile
  single-peaked at zero is consistent with local optimality, a second peak is a
  Skiba-type alternative *found* rather than suspected.
- `perturbation_test(mo, x)` — random search over feasible deviations.
- `absorbing_shutdown(p, state)` — whether a shutdown can be permanent.

Both deviation tests refuse to run on a path that does not satisfy the necessary
conditions. That guard is load-bearing: applied to a non-converged path, they
happily report that some deviation "beats" it, which is true and useless.

On the illustrative calibration nothing beats the computed path — in the random
search or along the extraction, investment and recycling-capital profiles. That
is verification, not proof.

## Two things the code found that the theory drafts had wrong

1. **The power-tail yield function is not globally concave.** `a = abar u/(1+u)`
   with `u = (xi x)^psi` behaves like `abar (xi x)^psi` near the origin, so for
   `psi > 1` it is convex there: `a'' > 0`, `a'` is non-monotone, and the
   marginal recycling yield `alpha = a - a'x` is negative. Global concavity
   needs `psi <= 1`. `check_params` warns; the appendix now records it.
2. **The post-shutdown cake-eating problem needs `(1-delta)^(1-eta) < 1+rho`.**
   Below that, a collapsing economy has no interior consumption plan for its
   remaining capital and collapse paths cannot be ranked at all. At
   `delta = 0.05` this requires `rho > 2.6%` when `eta = 1.5`. The illustrative
   baseline holds `eta = 1.1` for exactly this reason.

## Known limitations

- **The shutdown branch converges on every date tried, and skips with a
  reason where it cannot.** The stall "just short of tolerance" that used to
  hit most candidate dates was the terminal block: the derivatives of `V_stop`
  were nested finite differences, whose rounding noise (~1e-8) exceeded the
  step of the outer finite-difference Jacobian, so the terminal rows were wrong
  by O(1). They are now exact (`value_stop_gradient`), and the search starts
  each date from the solved closure model — the cold guess never worked under
  the shutdown terminal, its Jacobian is singular — before handing over to
  `V_stop` and walking the floor in. On `baseline_params(Rbar = 0.35)` every
  date of `10:10:200` converges to |F| ~ 1e-11, about 3 s per date; the warm
  start from the previous date rarely takes, and the table records the route
  and, for a skipped date, why. The test suite covers the search
  (`test/test_shutdown.jl`).
- The terminal closure assumes a common growth factor `Gam` for every costate
  from `T` onward.
- **There is a horizon wall, and it is the model's, not the solver's.** On a
  path that ends the material era by exhaustion, `(S_ref/S)^mu_N` diverges as
  the reserve empties, and the Newton system inherits that conditioning. Cold
  solves stall around `T = 220` on the illustrative calibration; `solve_long`
  reaches `T ≈ 300–325` by adaptive horizon continuation and then reports the
  longest horizon it reached rather than failing. The window of interest has
  stopped moving well before that (`Y` and `C` change by ~1e-3 over `t = 0..100`
  when `T` goes 150 → 300), so nothing is lost here — but a calibration that
  depletes faster would hit the wall sooner.
- The parameters in `src/calibration.jl` are placeholders. See
  `notes/data_plan_global_1850.md` for the calibration plan.

## Symbols

`SYMBOLS.md` is the symbol-to-identifier table: the only place a document symbol and a Julia
identifier are written beside each other, including the three clashes (`mu`, `beta`, `sigma`) that
the quantitative specialisation forces the source to break. Read it before touching `src/`.

## Conventions

- Rates are per period; `dt` is years per period (default 1).
- Sources are ASCII only, deliberately: a stray re-encoding on Windows silently
  corrupts unicode operators in Julia source. This is why `SYMBOLS.md` exists,
  and why it is load-bearing rather than decorative. The rule covers the
  byte-order mark, which is invisible in an editor, and operators that have an
  ASCII spelling: `div(a, b)`, never `a ÷ b`. Checked with
  `grep -P '[\x80-\xFF]' src/*.jl`, which should return nothing.
- `recycling_yield`, not `yield` — the latter collides with `Base.yield`.
- `code_style.md` at the repository root is the full guide.
