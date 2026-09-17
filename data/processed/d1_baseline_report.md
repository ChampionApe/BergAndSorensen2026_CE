# D1: the calibrated baseline (2026-09-17)

Task D1 of `notes/plan_calibration_experiments.md`: E1 (`experiment_taxonomy`) on the baseline
`calibration.json` and on the metals bound `calibration_metals.json`, at `T = 400` through
`model/scripts/run_d1.jl`, which wraps the harness and prints the full diagnostics per row
(`d1_taxonomy.txt`); `scripts/run_sufficiency.jl --calibration=` on the baseline
(`d1_sufficiency.txt`). The rows are `model/output/taxonomy/taxonomy.csv` (gitignored); the
generated tables are `writing/quant/Tables/Taxonomy.tex` and `Tables/metals/Taxonomy.tex`.
Dates are periods from 1900. Charges at the D0b level (`c4_handling_level.json`).

## The baseline, `abar = 1, Rbar = 0`

| | |
|---|---|
| state | **C**, perpetual circular growth; closes = true, leak sum 0.082 |
| M_inf | 8.60e4 Gt (retained endowment at T) |
| residence time | 42.9 periods (1/mu = 28.7, sigma_inf/delta = 14.2) |
| survival ratio | infinite (no floor) |
| shutdown | none (not a collapse path) |
| gate fee < 0 from | t = 139 (2039) |
| treated share | 0 until t = 103 (2003), 0.251 in 2015, 1 from t = 172 (2072) |
| horizon | T_reached = 400 of 400 requested; converged, resid 1.2e-10 |
| window 1900-2000 moving T = 200 -> 400 | dY = 8.4e-6, dC = 1.8e-5 (criterion 1e-3: settled) |
| reserve | S_T/S_0 = 0.176 at T = 400, min S = 2360 Gt, (S_ref/S)^mu_N = 24.7; **2% of S_0 not reached within T = 400** |
| cumulative N / bound | 0.578; leakage / budget 0.078; ledger 2.3e-12; no period below the floor |
| effective survival at T | 0.99949 (1 - mu = 0.96511) |
| market-planner gap | 2.8e-14 |
| tvc | capital boundary term 2.2e-8 decaying at 0.9858 per period; asymptotic factor beta e^((1-eta)g) = 0.9540 < 1 |
| wellposed at g = 0.02524, nu = 0 | (i) margin 0.047, (ii) regularity 0.049, (ii) embodied M 0.088, (ii) stockpile 0.085, (iii) cake-eating 0.022: all hold |
| at T | Y = 2.14e5, C = 1.28e5, R = 2451, N = 222, RR = 2229, x = 2.28 |

Sufficiency on the baseline (`d1_sufficiency.txt`, T = 300): convexity fails on the same four
conditions as the illustrative set, damages, extraction and exploration (chi < mu and the linear
choke term), and the intensity condition (phi_I = 4.61 > 0); the solve reaches T = 300 at 1.5e-11
with the reserve at 0.50 of S_0; the 1900-2000 window moves by 3.1e-4 (Y) and 7.1e-4 (C) between
T = 150 and T = 300; the extraction and investment profiles are single-peaked at zero; the random
search over 400 draws (90 feasible) finds a best gain of -2.8e-10; the shutdown is absorbing for a
depleted economy and not for the terminal state of the growth path. Verdict: nothing beats the
computed path in the directions searched; verification, not proof.

## The rest of the E1 grid on the baseline file

| case | state | M_inf | residence | survival ratio | shutdown | gate fee < 0 | T reached | notes |
|---|---|---|---|---|---|---|---|---|
| abar 1, Rbar 9.5 | C | 8.54e4 | 42.9 | 209.7 | -- | 132 | 400 | treated share 0.324 in 2015; window T = 200 -> 400: dY 1.2e-5, dC 1.5e-5 |
| abar 1, Rbar 23.8 | C | 8.45e4 | 42.9 | 83.0 | -- | 117 | 400 | treated share 0.420 in 2015; window dY 4.1e-6, dC 5.7e-6 |
| abar 1, Rbar 47.5 | -- | | | | | | 150 | **not solved**: the floor homotopy from the Rbar = 0 path and the cold solve both fail (resid 1.0 is the unsolved guess); the floor is eight times 1900 material input (5.7 Gt) |
| abar 0.708, Rbar 0 | B | 4.26e4 | 42.7 | infinite | -- | 171 | 400 | hard ceiling, does not close; treated share 0 in 2015, leaves 0 at t = 128; window dY = 2.3e-5, dC = 3.0e-6 |
| abar 0.708, Rbar 9.5 | A | 4.22e4 | 42.7 | 104.0 | 280 | 166 | 400 | shutdown date from the 7-point grid 80..320: best 280, second from the top; window dY 2.0e-5, dC 4.8e-6 |
| abar 0.708, Rbar 23.8 | A | 4.16e4 | 42.7 | 41.0 | -- | 157 | 400 | shutdown search: no candidate date converged; window dY 1.1e-5, dC 9.4e-6 |
| abar 0.708, Rbar 47.5 | -- | | | | | | 150 | not solved, as above |

Every solved row: market-planner gap 2.8e-14 or below, tvc factor 0.9540, all four long-run
conditions holding, ledger error below 3e-12, no period below the floor, cumulative N / bound
0.58 to 0.61. The reserve does not reach 2% of S_0 on any solved row within T = 400 (S_T/S_0
between 0.145 and 0.176). Every solved row's 1900-2000 window moves by less than 3e-5 between
T = 200 and T = 400: the wall does not bite, and D2 to D5 may proceed on the baseline.

## The metals bound

| case | state | M_inf | residence | survival ratio | shutdown | gate fee < 0 | T reached |
|---|---|---|---|---|---|---|---|
| abar 0.708, Rbar 0 | B | 5.27e5 | 42.7 | infinite | -- | 230 | 400 |
| abar 0.708, Rbar 9.5 | A | 5.28e5 | 42.7 | 1300.8 | 320 | 230 | 400 (window T = 100 -> 400: dY 0.17, dC 0.19) |
| abar 0.708, Rbar 23.8 | A | 5.28e5 | 42.7 | 520.7 | -- | 229 | 400 (window dY 0.18, dC 0.20) |
| abar 0.708, Rbar 47.5 | -- | | | | | | 150 (not solved) |

**These rows are not feasible paths and should not be read as results.** The bound floors `mu_N`
at zero, so the extraction cost has no stock effect, the reserve costate is zero throughout, and
nothing in the residual system carries `S >= 0`: the solved reserve crosses zero at t = 60 (1960)
and reaches -4.2e5 Gt at T = 400, `cumulative N / bound` is 195 and `cumulative leakage /
budget` 68. The solver converges (resid 2e-10, gap 1e-16, tvc and wellposed as the baseline)
because the system it solves is consistent; the model it solves is a cornucopian one. What the
bound would need is a terminal complementarity on the reserve (`S_T >= 0`, `pS_T >= 0`) so that a
Hotelling rent exists at `mu_N = 0`; that is a model change and is recorded in `model/README.md`,
*Known limitations*. The bound's own `mu_N` range runs up to the baseline's value, and running it
at any positive `mu_N` would give a feasible path. Treated share in 2015 on the bound: 0. On the
floor rows the 1900-2000 window moves by 17 to 20 percent between T = 100 and T = 400, which is
the horizon criterion failing outright: on this bound nothing is settled, for the same reason.

## What looks wrong or needs a decision

1. **The metals bound is infeasible** (above). The bound as a JSON is fine; the model at
   `mu_N = 0` is not closed.
2. **`Rbar = 47.5` does not solve on either file.** The plan's grid puts the floor at half of 2015
   material input; that is eight times the 1900 input. The row is reported as unsolved, not as a
   state.
3. **The recycled share in 2015** on the fitted baseline is 0.22 against 0.096 observed (D0b): the
   charges hit the treated share, not the recycled share; the miss is `xi`'s and the stockpile
   reading's, and the E2 grid over `xi` is where it will show.
4. **The shutdown search** converged on one A-row and on no date of the other; the best date found
   (280 of a grid ending at 320) may be the grid's edge rather than an interior optimum.
5. **The reserve is far from the wall**: at T = 400 it is 0.176 of S_0 on the baseline, so the
   horizon can be extended well past 2300 before the `(S_ref/S)^mu_N` conditioning bites. The
   first stop `solve_long` made on this calibration (T = 261 with `min_step = 5`) was the
   extrapolated tail's, not the model's, and `min_step` is one period now.
