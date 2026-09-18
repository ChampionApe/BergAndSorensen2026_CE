# `model/` — quantitative implementation

Julia implementation of the quantitative model documented in
`writing/quant/quant_model.tex`, `quant_solution.tex` and `quant_calibration.tex`.
Standard-library dependencies only (`LinearAlgebra`, `SparseArrays`, `Printf`).

```
julia --project=. test/runtests.jl              # 1234 tests, ~35 s
julia --project=. scripts/run_baseline.jl       # baseline path + policy dials, ~30 s
julia --project=. scripts/run_sufficiency.jl    # convexity, transversality, deviations
julia --project=. scripts/run_experiments.jl    # the harness: E1 to E5; --calibration=, --only=, --hours=, --T=
julia --project=. scripts/run_d1.jl             # E1 on the calibrated baseline and on the metals bound
julia --project=. scripts/run_d2.jl             # E2 and E4, one run per floor, and E4 at each end of xi
julia --project=. scripts/run_d3.jl             # E3, the 16 corners and the dial paths, with and without a floor
julia --project=. scripts/run_d4.jl             # E5: the surface, the solvability edge, the shutdown-date grid
julia --project=. scripts/run_e2_sensitivity.jl # the review's two sensitivities (damages x 6.69, DICE preferences)
```

`run_experiments.jl` writes one CSV per experiment under `output/` (gitignored, regenerable) and one
`%% GENERATED` table per experiment under `writing/quant/Tables/`. With no `--calibration` it runs on
the illustrative set and says so: nothing from such a run is a result. The five drivers wrap the
harness on the calibrated set, take `--only=table` to rebuild a table from the CSVs without solving,
and report to `data/processed/d1_baseline_report.md` to `d4_report.md`.

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
from the market conditions of Part II, `residual_planner!` from the planner's of
Part I — and are required to agree to machine precision at the planner corner, at
arbitrary points of the state and control space: the decentralisation proposition
as an algebraic identity rather than a property of a solution, which is why the
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
| `src/json.jl` | minimal JSON reader, for the calibration file only |
| `src/calibration.jl` | the **illustrative** parameter set, and the calibrated one read from `data/processed/calibration.json` |
| `scripts/` | `run_experiments.jl` is the harness, one function per experiment; `run_d1.jl` to `run_d4.jl` and `run_e2_sensitivity.jl` are the phase-D and review drivers of `notes/plan_calibration_experiments.md` |
| `test/` | `runtests.jl` registers every `@testset`; `test_experiments.jl` and `test_shutdown.jl` are the two that solve |

## Method, in one paragraph

The system is solved as one large square nonlinear system in all `12(T+1) + 6T`
unknowns rather than by shooting. The within-period block is acyclic — the
handled flow is drawn from a predetermined stock, so there is no within-period
fixed point — so residual block `t` involves only blocks `t-1`, `t`, `t+1` and
the Jacobian is block-tridiagonal, recovered by structured finite differences:
perturbing every third block at once never mixes two entries of a row, so one
Jacobian costs `3 x 18` residual evaluations whatever the horizon. Corner
conditions enter through the min-map of the complementarity problem, smoothed
along a homotopy that finishes at zero, so the returned solution satisfies the
exact Kuhn–Tucker conditions. The recycling-capital margin is solved in the
intensity `x = K^R/T` rather than in `K^R`: at the no-treatment corner the two
vanish together at a fixed ratio and the row written in `K^R` has a Jacobian
scaling as `1/T`, where Newton stalled at `|F| ~ 1e-4`; in `x` the row
`a'(x)(Psi - pW) = F_K` is well posed at every `T`, including `T = 0`, where it
selects the `alpha` the treatment margin needs to decide that no tonne is worth
treating. The sixth control is therefore `x` (slot `IXR`), and `K^R = xT` is
derived in the period block.

A 200-period planner path (3612 unknowns) solves in about 2.5 s; a 400-period
calibrated one in a few minutes from a cold start.

## What is verified

Every solved path is checked against things the model should satisfy without
having been told to:

- the collected ledger holds period by period (~1e-11), which ties the
  accounting to the transitions rather than merely restating it;
- cumulative extraction respects the discovery bound, and cumulative leakage the
  material budget;
- the planner and market transcriptions agree at the planner corner (~1e-16);
- the no-treatment corner is reached to tolerance: at municipal handling
  charges (`test/fixtures/calibration_notreatment.json`) the solved path has
  `varpi = 0` and `K^R = 0` in every period, the intensity interior on its
  margin and the marginal treated tonne not paying;
- the solved path converges to the independently computed circular balanced
  growth path: Little's law predicts `R_inf = 2.74` against a path value of
  `2.82` still converging at `T = 200`;
- the closure criterion reproduces the analytic tail results: recycling
  intensity grows at exactly `g/(1+psi)` on a power tail and linearly in time on
  an exponential one;
- `classify_longrun` reads the taxonomy of the theory note's Section 3 off a
  path -- floor and ceiling from the parameters, closure from the tail
  criterion, survival from Little's law against the retained endowment -- and
  returns its margins with the state. Diagnostic only: it names the state, it
  does not verify convergence to it;
- the shutdown handover prices every stock handed over: `q`, `pW`, `pP` and
  `pM` at `T` are the exact derivatives of `V_stop` per unit of income, and its
  legacy recursion carries the `delta M^K` inflow — the material the eaten
  capital keeps releasing — that the theory note's eq. (app:wh:Vstop) records as
  omitted. On `baseline_params(Rbar = 0.35)` over `10:10:200` the inflow raises
  the legacy term by 40–56% and moves `V_stop` by 0.05–0.5%, the search's
  objective by under 0.05%, and the best date not at all; exact, tested and
  free, so it is the default rather than a recorded approximation;
- the stationary benchmark of Appendix D is a return point: with the trends
  off, the linear aggregate and the terminal closure at `Gam = 1`, a path
  started 3% away from the closed-form dematerialized rest point returns to
  it, goods block and prices within 1e-3 at `T = 60`;
- **the calibrated baseline** (`data/processed/calibration.json`, phase C) is
  state `:C` at `T = 400` and settled there: `|F| = 1.2e-10`, ledger 2.3e-12,
  market–planner gap 2.8e-14, all four well-posedness conditions holding, the
  1900–2000 window moving by 8e-6 in `Y` between `T = 200` and `T = 400`
  against the 1e-3 criterion of `quant_solution.tex` Section *Horizon*, the
  reserve still at 0.18 of `S_0` so the wall below never bites, and nothing
  beating the computed path in the random search or along the extraction,
  investment and recycling profiles (`data/processed/d1_baseline_report.md`).

## Sufficiency

The model is not globally concave, so the solver returns a point satisfying the
*necessary* conditions. `src/sufficiency.jl` implements the protocol of
`writing/docs/Appendix_sufficiency.tex`:

- `convexity_report(p)` — checks (C1)–(C5) on the primitives and says which
  fail. Four fail on both parameter sets: multiplicative damages, the extraction
  and exploration costs (a finite choke), the intensity condition (`phiI > 0`).
- `wellposed_report(p; g, nu)` — Assumption "well-posedness and regularity" of
  the theory note as four inequalities with their margins, at one cell's growth
  and material decay rates. `check_params` warns on the two that are conditions
  on primitives; `tvc_report` evaluates all four at the path's own rates. The
  illustrative set fails `e^(g+nu) < 1+r` at its own balanced-dematerialization
  rates; the calibrated set holds all four.
- `tvc_report(mo, x)` — the six boundary terms. Five vanish for free, because
  mass conservation bounds their states; only the capital term is a genuine
  condition, and it holds iff `beta * e^((1-eta)g) < 1`, which is condition (i)
  above and is read off that report rather than tested twice.
- `deviation_profile(mo, x; control, window, grid)` — the value profile along one
  deviation direction, and the diagnostic that matters: single-peaked at zero is
  consistent with local optimality, a second peak is a Skiba-type alternative
  *found* rather than suspected.
- `perturbation_test(mo, x)` — random search over feasible deviations.
- `absorbing_shutdown(p, state)` — whether a shutdown can be permanent.

Both deviation tests refuse to run on a path that does not satisfy the necessary
conditions. That guard is load-bearing: applied to a non-converged path, they
happily report that some deviation "beats" it, which is true and useless. On the
illustrative set and on the calibrated one alike, nothing beats the computed
path in the searches run. That is verification, not proof.

## Two things the code found that the theory drafts had wrong

1. **The power-tail yield function is not globally concave.** `a = abar u/(1+u)`
   with `u = (xi x)^psi` behaves like `abar (xi x)^psi` near the origin, so for
   `psi > 1` it is convex there, `a'` is non-monotone and the marginal recycling
   yield `alpha = a - a'x` is negative. Global concavity needs `psi <= 1`;
   `check_params` warns and the appendix records it.
2. **The post-shutdown cake-eating problem needs `(1-delta)^(1-eta) < 1+rho`.**
   Below that, a collapsing economy has no interior consumption plan for its
   remaining capital and collapse paths cannot be ranked at all. At
   `delta = 0.05` this requires `rho > 2.6%` when `eta = 1.5`.

## Known limitations

- **The shutdown branch converges on every date it reaches, and skips with a
  reason where it cannot.** The stall that used to hit most candidate dates was
  the terminal block: the derivatives of `V_stop` were nested finite differences
  whose rounding noise (~1e-8) exceeded the outer Jacobian's step, so the
  terminal rows were wrong by O(1). They are exact now (`value_stop_gradient`),
  and the search starts each date from the solved closure model — the cold guess
  never worked there, its Jacobian is singular — before handing over to `V_stop`
  and walking the floor in. On `baseline_params(Rbar = 0.35)` every date of
  `10:10:200` converges to |F| ~ 1e-11, and `test/test_shutdown.jl` covers the
  search. Two qualifications from the calibrated set (`d4_report.md`). **The
  branch has a horizon wall of its own at `Td` about 285**: dates from 290 fail
  at the handover to `V_stop` with |F| from 7 to 22, identical under two floors
  because that stage solves the `Rbar = 0` problem, and the objective is
  monotone on `200:10:400`, so the 280 the search returns is the wall and not an
  optimum — every `T^dagger` must say so. And **`floor_steps = 6` is too short
  at a large floor**: at `Rbar = 23.756` every date stalls at |F| ~ 2e-6 and the
  cell looks unsolvable, while at `floor_steps = 24` nine converge. TODO 7.
- **`solve_long`'s cold route is inert at a real floor.** Its default guess
  targets `Rtarget = 0.6` Gt, the illustrative set's material scale; on a
  calibration whose 1900 input is 5.74 Gt the simulated path lies below any
  positive floor in every period, `initial_guess` warns, and Newton returns
  |F| = 1.0 without moving. Every "cold" verdict in a continuation or edge row is
  that, and is not evidence that no path exists. Scaling `Rtarget` with `Rbar`
  and `s0` is the one-line fix; `run_d4.jl` works around it in its own driver.
- The terminal closure assumes a common growth factor `Gam` for every costate
  from `T` onward.
- **There is a horizon wall, and it is the model's, not the solver's.** On a
  path that ends the material era by exhaustion the reserve is driven towards
  zero, the extraction cost carries `(S_ref/S)^mu_N`, which diverges there, and
  the Newton system inherits that conditioning. On the illustrative set (task A5)
  `solve_long` asked for `T = 600` converges up to **`T = 323`**, then fails at
  `329` with `|F| = 4e-3` and returns the longest horizon it reached; there the
  reserve is `S = 0.34` against `S_0 = 20` and `(S_ref/S)^mu_N = 455`. **The
  wall is at the date the reserve reaches about 2% of its initial level, not at
  a fixed `T`**, so a calibration that depletes faster hits it sooner, and every
  experiment row carries `T_reached` beside `T_requested`: read it before
  reading the row. On the calibrated set it does not bite — the reserve is still
  at 0.18 of `S_0` at `T = 400` — and the one early stop there (`T = 261` at
  `min_step = 5`) was `extend_horizon`'s extrapolated tail failing to follow a
  three-percent growth path six periods ahead. `min_step` is one period now, and
  a wall is declared only when even that fails.
- **A calibration with `mu_N = 0` has no scarcity mechanism.** The extraction
  cost carries no stock effect, the reserve costate's dividend is zero, the
  terminal closure gives `pS_T = 0` so `pS = 0` throughout, and nothing in the
  residual system carries `S >= 0`. On the metals bound
  (`data/processed/calibration_metals.json`, `mu_N` floored at zero) the solved
  path exhausts the reserve at `t = 60` and drives it negative; the rows are
  infeasible and `check_path` says so. A Hotelling rent there needs a terminal
  complementarity `S_T >= 0`, `pS_T >= 0`, a model change not made here; the
  bound's own range puts `mu_N` up to the baseline's value.
- **A large damage coefficient stalls the laissez-faire corner.** In the
  review's sensitivity (`scripts/run_e2_sensitivity.jl`, `kappa` times 6.69) the
  corner with no instruments stalls in the `varpi` complementarity rows between
  6.2 and 6.4 times `kappa` on every continuation route and converges cold only
  to `T = 358` (337 with the DICE preference pair), so those two cells are
  reported at that horizon against the planner corner re-solved there.
- The parameters in `src/calibration.jl` are the illustrative set; the
  calibrated one is read from `data/processed/calibration.json`, and
  `notes/data/calibration.md` records the judgements behind it.

## Conventions

- `SYMBOLS.md` is the symbol-to-identifier table: the only place a document symbol and a Julia
  identifier are written beside each other, including the three clashes (`mu`, `beta`, `sigma`) the
  quantitative specialisation forces the source to break. Read it before touching `src/`.
- Rates are per period; `dt` is years per period (default 1).
- Sources are ASCII only, deliberately: a stray re-encoding on Windows silently
  corrupts unicode operators in Julia source, which is what makes `SYMBOLS.md`
  load-bearing. The rule covers the byte-order mark, invisible in an editor, and
  operators with an ASCII spelling: `div(a, b)`, never `a ÷ b`. Checked with
  `LC_ALL=C grep -P '[\x80-\xFF]' src/*.jl test/*.jl scripts/*.jl`, which should return nothing
  (without `LC_ALL=C` a UTF-8 locale matches characters, not bytes, and misses a BOM).
- `recycling_yield`, not `yield` — the latter collides with `Base.yield`.
- `code_style.md` at the repository root is the full guide.
