# D3: E3, the cost of the three market failures (2026-09-17)

Task D3 of `notes/plan_calibration_experiments.md`: E3 (`experiment_instruments`) on the calibrated
baseline `calibration.json`, at `T = 400` through `model/scripts/run_d3.jl`, which wraps the harness
and adds the diagnostics a CSV row cannot hold (`d3_instruments.txt` is the full log). The rows are
`model/output/instruments/instruments_Rbar0.csv` and `instruments_Rbar23p756.csv` (gitignored); the
generated table is `writing/quant/Tables/Instruments.tex`, written as two panels by `run_d3.jl`
rather than by the harness, because one table the reader can compare across the floor is the point.
Dates are periods from 1900. The metals bound is excluded: D1 found it infeasible.

Each run is the 16 corners of `(phiW, phiz, phiP, phiX)` plus the four single-dial paths from the
planner corner in steps of 0.25 -- 36 points, of which 16 are corners and 4 duplicate the planner
corner -- every point continued in the dials from the planner corner, budget 6 hours.

**Why twice.** D1's baseline (`abar = 1`, `Rbar = 0`) has no floor, and without a floor the survival
ratio is infinite by construction: the question the theory poses in
`writing/docs/theory_market_implementation.tex`, *Laissez-faire and the survival margin* -- can
missing instruments turn a state-C economy into a state-A one -- cannot be posed there at all. So E3
is run at `Rbar = 0` and again at `Rbar = 23.756` Gt, the largest floor of the calibration's grid
that solves (D1: `Rbar = 47.5` does not solve on either file; at 23.756 the planner corner is state
C with survival ratio 83.0).

## Panel A: no floor, `Rbar = 0`

| dials | state | CE cost (%) | M_inf (Gt) | residence | survival | gate fee < 0 | cum. leakage (Gt) |
|---|---|---|---|---|---|---|---|
| (1,1,1,1) planner | C | 0 | 86010 | 42.86 | inf | 139 | 13450 |
| (0,1,1,1) | C | 0.00037 | 76332 | 42.77 | inf | none | 12910 |
| (1,0,1,1) | C | 0.00008 | 81287 | 42.75 | inf | 139 | 13526 |
| (1,1,0,1) | C | 0.00078 | 84497 | 42.86 | inf | 0 | 15215 |
| (1,1,1,0) | C | 0.00001 | 88619 | 42.86 | inf | 139 | 13889 |
| (0,0,1,1) | C | 0.00037 | 76332 | 42.77 | inf | none | 12910 |
| (0,1,0,1) | C | 0.00078 | 74976 | 42.77 | inf | none | 14551 |
| (0,1,1,0) | C | 0.00038 | 79100 | 42.76 | inf | none | 13265 |
| (1,0,0,1) | C | 0.00082 | 79619 | 42.76 | inf | 0 | 15508 |
| (1,0,1,0) | C | 0.00008 | 84011 | 42.75 | inf | 140 | 13933 |
| (1,1,0,0) | C | 0.00085 | 86984 | 42.86 | inf | 0 | 15767 |
| (0,0,0,1) | C | 0.00078 | 74976 | 42.77 | inf | none | 14551 |
| (0,0,1,0) | C | 0.00038 | 79100 | 42.76 | inf | none | 13265 |
| (0,1,0,0) | C | 0.00082 | 77638 | 42.76 | inf | none | 15005 |
| (1,0,0,0) | C | 0.00087 | 82209 | 42.75 | inf | 0 | 16038 |
| (0,0,0,0) laissez-faire | C | 0.00082 | 77638 | 42.76 | inf | none | 15005 |

Single-dial paths from the planner corner (the ends of each path are corners above):

| point | state | CE cost (%) | M_inf (Gt) | gate fee < 0 | cum. leakage (Gt) |
|---|---|---|---|---|---|
| phiW = 0.75 | C | 0.00002 | 83570 | 139 | 13347 |
| phiW = 0.50 | C | 0.00009 | 81168 | 139 | 13221 |
| phiW = 0.25 | C | 0.00021 | 78767 | 139 | 13075 |
| phiz = 0.75 | C | 0.00000 | 84677 | 139 | 13473 |
| phiz = 0.50 | C | 0.00002 | 83457 | 139 | 13493 |
| phiz = 0.25 | C | 0.00004 | 82332 | 139 | 13511 |
| phiP = 0.75 | C | 0.00005 | 85695 | 133 | 13818 |
| phiP = 0.50 | C | 0.00019 | 85346 | 125 | 14226 |
| phiP = 0.25 | C | 0.00044 | 84952 | 115 | 14685 |
| phiX = 0.75 | C | 0.00000 | 86594 | 139 | 13545 |
| phiX = 0.50 | C | 0.00000 | 87220 | 139 | 13649 |
| phiX = 0.25 | C | 0.00000 | 87894 | 139 | 13763 |

## Panel B: `Rbar = 23.756` Gt

| dials | state | CE cost (%) | M_inf (Gt) | residence | survival | gate fee < 0 | cum. leakage (Gt) |
|---|---|---|---|---|---|---|---|
| (1,1,1,1) planner | C | 0 | 84467 | 42.86 | 82.95 | 117 | 15390 |
| (0,1,1,1) | C | 0.00014 | 74972 | 42.77 | 73.79 | none | 14767 |
| (1,0,1,1) | C | 0.00009 | 79834 | 42.76 | 78.60 | 118 | 15436 |
| (1,1,0,1) | C | 0.00070 | 83168 | 42.86 | 81.68 | 0 | 16912 |
| (1,1,1,0) | C | 0.00004 | 87049 | 42.86 | 85.50 | 118 | 15816 |
| (0,0,1,1) | C | 0.00014 | 74972 | 42.77 | 73.79 | none | 14767 |
| (0,1,0,1) | C | 0.00067 | 73794 | 42.77 | **72.62** | none | 16199 |
| (0,1,1,0) | C | 0.00020 | 77701 | 42.76 | 76.48 | none | 15112 |
| (1,0,0,1) | C | 0.00073 | 78388 | 42.76 | 77.17 | 0 | 17162 |
| (1,0,1,0) | C | 0.00014 | 82522 | 42.75 | 81.26 | 119 | 15831 |
| (1,1,0,0) | C | 0.00083 | 85643 | 42.86 | 84.11 | 0 | 17437 |
| (0,0,0,1) | C | 0.00067 | 73794 | 42.77 | **72.62** | none | 16199 |
| (0,0,1,0) | C | 0.00020 | 77701 | 42.76 | 76.48 | none | 15112 |
| (0,1,0,0) | C | 0.00078 | 76428 | 42.77 | 75.23 | none | 16632 |
| (1,0,0,0) | C | 0.00085 | 80957 | 42.75 | 79.71 | 0 | 17667 |
| (0,0,0,0) laissez-faire | C | 0.00078 | 76428 | 42.77 | 75.23 | none | 16632 |

| point | state | CE cost (%) | M_inf (Gt) | survival | gate fee < 0 | cum. leakage (Gt) |
|---|---|---|---|---|---|---|
| phiW = 0.75 | C | 0.00001 | 82072 | 80.70 | 117 | 15266 |
| phiW = 0.50 | C | 0.00004 | 79714 | 78.43 | 117 | 15119 |
| phiW = 0.25 | C | 0.00008 | 77360 | 76.14 | 117 | 14953 |
| phiz = 0.75 | C | 0.00001 | 83159 | 81.78 | 118 | 15405 |
| phiz = 0.50 | C | 0.00002 | 81962 | 80.66 | 118 | 15417 |
| phiz = 0.25 | C | 0.00005 | 80858 | 79.60 | 118 | 15427 |
| phiP = 0.75 | C | 0.00004 | 84189 | 82.68 | 110 | 15716 |
| phiP = 0.50 | C | 0.00017 | 83885 | 82.38 | 102 | 16073 |
| phiP = 0.25 | C | 0.00039 | 83548 | 82.05 | 92 | 16467 |
| phiX = 0.75 | C | 0.00000 | 85044 | 83.52 | 118 | 15483 |
| phiX = 0.50 | C | 0.00001 | 85663 | 84.13 | 118 | 15584 |
| phiX = 0.25 | C | 0.00002 | 86330 | 84.79 | 118 | 15694 |

The tables here are in percent; the generated table `Tables/Instruments.tex` carries the corner rows
of both panels with the same column in units of 1e-5 percent, because at three digits every cost in
percent prints as zero.

Every one of the 72 points converged to `|F| = 1.2e-10` at `T = 400`. `CE cost` is the proportional
consumption supplement that makes the corner as good as the planner corner; `M_inf` and the survival
ratio are read at the horizon reached, `residence` is `1/mu + sigma_T/delta`, `gate fee < 0` is the
first date the gate fee turns negative and `none` in that column at `phiW = 0` means there is no gate
fee at all, `tauW = -phiW pW` being identically zero -- not a fee that stays positive.

## The headline: there is none, and the margin is not close

**No corner's state differs from the planner's at either floor.** All 72 points are state C. At
`Rbar = 0` that is forced -- the survival ratio is infinite and the classification then turns on the
closure criterion alone, which is a statement about the yield tail and the growth rate, both
primitives. At `Rbar = 23.756` it is not forced, and it is the result: the planner corner's survival
ratio is 82.95 and the worst corner's, `(0,0,0,1)` -- property rights, the content charge and the
emission tax off, the discovery tax on, and identical to `(0,1,0,1)` because the content charge is
inert once property rights are gone -- is 72.62. Every corner is between 72.6 and 85.5: the three
failures move the retained endowment by at most 13% (12.6% below the planner at the worst corner,
3.1% above it at `(1,1,1,0)`), and the margin `M_inf > Rbar*T` is still cleared by a factor of 73
there. The laissez-faire corner is not even the worst one: at 75.23 it sits above `(0,0,0,1)`,
because switching the discovery tax off *raises* the retained endowment (next section).

Because there is no headline corner, the run compares the laissez-faire path with the planner's
period by period anyway -- the classifier applied to the path truncated at `t` -- so that "the
instruments do not move this economy across the survival margin" is a claim about every date and not
about the endpoint. At `Rbar = 23.756` the two classifications agree at every one of the 401 dates.
Both paths read as state A in 1900, where the retained endowment (52 Gt: 35.6 of in-use stock and
16.4 of stockpile) is far below the floor's own turnover requirement of about 720 Gt at the 1900
residence time, and both cross the survival margin at the same date, **`t = 21`, the year 1921**
(minimum ratio 0.0721 at `t = 0` on both). From there both read as C to `T = 400`. The laissez-faire
ratio is in fact marginally *above* the planner's until somewhere between `t = 125` and `t = 150`
(3.75 against 3.72 at `t = 125`) and below it thereafter by about 9 percent (10.68 against 11.74 at
`t = 200`, 75.23 against 82.95 at `T`): the leakage the missing instruments cause is a slow stock
effect, not an early one. At `Rbar = 0` both paths are C at every date from `t = 0`.

What it would take to cross. On this calibration the survival condition is `M_inf > Rbar*T` with
`T = 42.8` and `M_inf` around 7.6e4 Gt at `T = 400` under laissez-faire, so the floor would have to be
about 1.8e3 Gt -- 75 times the largest floor that solves here, and some 300 times 1900 material input
(5.7 Gt) -- before laissez-faire failed to clear it. Two caveats on that arithmetic. `M_inf` is read
at the horizon reached and is not a limit: on a state-C path it is still growing at `T = 400` (it is
1352 Gt at `T = 40` against 84467 at `T = 400`), so the survival ratio is horizon-dependent and only
the comparison *across corners at the same horizon* is meaningful. And `Rbar = 47.5` does not solve,
so the floors between there and 1.8e3 Gt are not reachable with the present solver: the statement is
that the margin is far away in this calibration, not that it has been searched to.

## The ordering check

**No non-planner point has a positive consumption-equivalent gain at either floor.** The smallest
non-zero entries are the `phiX` path at `Rbar = 0`, 4.4e-7, 1.8e-6 and 4.3e-6 percent at
`phiX = 0.75, 0.50, 0.25`: positive, and rounding to zero in the tables above. The four `phi* = 1.00`
points of the dial paths are the planner corner re-solved by continuation from itself and return
exactly 0 (`Rbar = 0`) and 2.2e-14 percent (`Rbar = 23.756`), which is the continuation route
checking itself. Two remarks.

- The check is horizon-sensitive exactly as `experiment_instruments`' docstring warns. The same run
  at `T = 40` (the smoke test of the driver, on the same calibration) puts two corners, `(1,0,1,1)`
  and `(1,0,1,0)`, *above* the planner, the first by 0.001%: at that horizon the welfare tail, not
  the allocation, decides the comparison. At `T = 400` nothing is above the planner. Nothing in this
  report is from a short run.
- The entries below about 1e-6 percent are at the level of the comparison's own precision: the paths
  converge to `|F| = 1.2e-10` and the welfare differences that produce them are 1e-8 in absolute
  value against a welfare level of -35.8. Read them as zero rather than as a ranking.

## Run times

| stage | wall clock | of which |
|---|---|---|
| `Rbar = 0`, 36 points | 443 s | cold planner solve by `solve_long` 223 s; 35 continuations, 5 to 8 s each |
| `Rbar = 0` probes | 228 s | one planner re-solve (223 s) plus the laissez-faire continuation |
| `Rbar = 23.756`, 36 points | 446 s | planner corner by floor homotopy from `Rbar = 0`, 227 s; continuations 5 to 7 s |
| `Rbar = 23.756` probes | 233 s | as above |
| whole run | 1350 s (22.5 min) | against a budget of 6 hours per floor, which was never approached |

The two planner re-solves are the price of the period-by-period comparison: `experiment_instruments`
returns rows, not paths, and the comparison needs both paths. Rebuilding the note's table from the
CSVs without re-solving is `scripts/run_d3.jl --table-only`.

## Non-converged points

None. All 72 points reached `T = 400` with `|F|` between 8.7e-11 and 1.5e-10; 70 by continuation
from the planner corner, the two planner corners themselves by `solve_long` (`Rbar = 0`) and by the
floor homotopy (`Rbar = 23.756`). The ledger holds at 1.2e-12 and no period is below the floor on
either probed path.

## What looks wrong or needs a decision

1. **The three failures cost almost nothing in consumption.** The whole of laissez-faire is worth
   0.00082% of consumption without a floor and 0.00078% with one -- under one part in 100,000 -- while
   it raises cumulative leakage by 12% (13450 to 15005 Gt) and cuts the retained endowment by 10%.
   The reason is not the solver: the weight the objective puts on period `t` decays at
   `beta e^((1-eta)g) = 0.954` per period (D1's `tvc` factor), while the damage channel is a stock
   effect that builds over centuries, and `psi_v = 0` (D4, `notes/data/pollution.md`) switches the
   utility channel off entirely, so the pollution disutility `Vp` is exactly zero at every corner and
   all damage reaches welfare through `F_P = -kappa Y` with `kappa = 6.8e-6` per Gt. Whether that is
   the right price for a tonne in the environment is a calibration question for E1, not a solver
   question, but it is what makes E3's headline unmeasurably small here.
2. **Switching the discovery tax off improves the survival margin.** `(1,1,1,0)` has `M_inf` 87049
   against the planner's 84467 and a survival ratio of 85.50 against 82.95, and the whole `phiX` path
   is monotone in that direction; welfare still falls, by 0.00004%. The theory note's *Laissez-faire
   and the survival margin* says each of the three failures "pushes it the wrong way", naming
   excessive exploration as burning "real resources and displaced mass". In this calibration the
   sign on that channel is the other way: more exploration means more reserves, more extraction and
   more matter retained in the anthroposphere at any date, which helps survival while costing
   welfare. Either the sentence needs qualifying or the quantitative model does not support it for
   `phi^X`; flagged for E1 and E2.
3. **The material-content charge is inert without property rights.** The four pairs that differ only
   in `phiz` at `phiW = 0` -- `(0,1,1,1)/(0,0,1,1)`, `(0,1,0,1)/(0,0,0,1)`, `(0,1,1,0)/(0,0,1,0)`,
   `(0,1,0,0)/(0,0,0,0)` -- have identical welfare, `M_inf`, leakage and survival ratio to every
   printed digit at both floors (they differ only in the residual of their own Newton solve). This is
   the theory's precondition -- *who owns the stockpile* -- as an identity rather than an argument:
   with `tauW = 0` the material liability `pM` is zero, so `zeta_star = sigma(tauW - pM) = 0` and
   `z = phiz * zeta_star` is zero whatever `phiz` is. Worth stating in the write-up; it also means the
   16 corners contain only 12 distinct allocations.
4. **The consumption equivalent understates the cost of a corner.** `welfare` values the tail beyond
   `T` by continuing consumption at the terminal growth factor and nothing else, and the laissez-faire
   path ends with 0.7 to 0.8% *more* consumption than the planner's at `T = 400` (and 10% less
   retained material and a larger pollution stock, neither of which the tail prices). The tail is
   small at `T = 400` -- which is why the ordering check passes -- but it works in the corner's
   favour, so the costs in the tables are a lower bound.
5. **The gate fee turns negative immediately when the emission tax is off.** Every corner with
   `phiP = 0` and `phiW = 1` has the fee negative from `t = 0`, against `t = 117` (floor) or `t = 139`
   (no floor) at the planner corner: without a price on emissions the stockpile is an asset from the
   start. The `phiP` path shows it moving continuously (139, 133, 125, 115, 0 as `phiP` falls from 1
   to 0 without a floor), so the jump to `t = 0` is the last step, not a discontinuity in the solve.
   E4 is the experiment that owns this number; it is reported here only because E3's table carries the
   date.
6. **The classifier reads 1900 as state A on the floor calibration** (survival ratio 0.072) and
   crosses within the first quarter-century. That is the truncated-path reading working as designed,
   but it means a row's state is a statement about the horizon reached and nothing else; `M_inf` at
   `T = 400` is not a limit.

Nothing in `model/src/` or `model/scripts/run_experiments.jl` was changed: the harness needed no fix.
`model/scripts/run_d3.jl` is new and is the only script this task adds.
