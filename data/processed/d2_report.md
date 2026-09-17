# D2: E2 circularity and E4 the gate fee (2026-09-17)

Task D2 of `notes/plan_calibration_experiments.md`: `experiment_circularity` (E2) and
`experiment_gatefee` (E4) on the calibrated baseline `data/processed/calibration.json`, at
`T = 400` through `model/scripts/run_d2.jl`, which wraps the harness of `run_experiments.jl`.
Logs: `d2_circularity.txt`, `d2_gatefee.txt`, `d2_gatefee_xi.txt`. Rows:
`model/output/circularity/` (per floor and stacked) and `model/output/gatefee/` (gitignored).
Generated tables: `writing/quant/Tables/Circularity.tex` and `GateFee.tex`.

Dates are periods from 1900. Material in Gt, prices in trillions of 2011 dollars per Gt, which
is 1000 US$ per tonne. The metals bound is excluded throughout: D1 found it infeasible at
`mu_N = 0`. `Rbar = 47.5` is excluded because D1 found it unsolvable on both files.

Grids, taken from the file's `cases` and not written as literals: `abar` in {1, 0.85, 0.708} (the
two calibrated ceilings and the midpoint), `xi` in {0.907, 2.722, 8.166} (the ends of
`xi_range` around the point value), `Rbar` in {0, 9.502}. Nine cells per floor, eighteen in all,
each against a no-recycling counterfactual at `abar = 0.01` solved at the same `xi` and the same
floor (three per floor, reused down the ceiling column).

## E2: what circularity buys

| Rbar | abar | xi | state | CE gain (%) | era ends | shutdown | sum Xi | Xi avoided | M_inf | survival | Hotelling max | s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 1 | 0.91 | C | 0.0009 | -- | -- | 11664 | 16767 | 74839 | inf | 0.0702 | 272 |
| 0 | 1 | 2.72 | C | 0.0065 | -- | -- | 6107 | 22312 | 86010 | inf | 0.0708 | 9 |
| 0 | 1 | 8.17 | C | 0.0400 | -- | -- | 3263 | 25146 | 92343 | inf | 0.0708 | 8 |
| 0 | 0.85 | 0.91 | B | 0.0006 | -- | -- | 16285 | 12146 | 53247 | inf | 0.0685 | 8 |
| 0 | 0.85 | 2.72 | B | 0.0037 | -- | -- | 11427 | 16991 | 58781 | inf | 0.0697 | 8 |
| 0 | 0.85 | 8.17 | B | 0.0194 | -- | -- | 8920 | 19490 | 61641 | inf | 0.0705 | 7 |
| 0 | 0.708 | 0.91 | B | 0.0003 | -- | -- | 19728 | 8703 | 39710 | inf | 0.0676 | 9 |
| 0 | 0.708 | 2.72 | B | 0.0020 | -- | -- | 15181 | 13238 | 42587 | inf | 0.0683 | 10 |
| 0 | 0.708 | 8.17 | B | 0.0092 | -- | -- | 12690 | 15720 | 43961 | inf | 0.0686 | 9 |
| 9.5 | 1 | 0.91 | C | 0.0010 | -- | -- | 12727 | 17267 | 74148 | 181.9 | 0.0755 | 251 |
| 9.5 | 1 | 2.72 | C | 0.0086 | -- | -- | 6896 | 23085 | 85387 | 209.7 | 0.0755 | 7 |
| 9.5 | 1 | 8.17 | C | 0.0950 | -- | -- | 3741 | 26231 | 91934 | 225.8 | 0.0768 | 9 |
| 9.5 | 0.85 | 0.91 | A | 0.0006 | -- | 280 | 17384 | 12610 | 52725 | 129.6 | 0.0755 | 7 |
| 9.5 | 0.85 | 2.72 | A | 0.0045 | -- | 280 | 12267 | 17714 | 58301 | 143.5 | 0.0755 | 8 |
| 9.5 | 0.85 | 8.17 | A | 0.0330 | -- | 280 | 9502 | 20470 | 61263 | 150.8 | 0.0755 | 8 |
| 9.5 | 0.708 | 0.91 | A | 0.0004 | -- | 280 | 20878 | 9115 | 39306 | 96.8 | 0.0755 | 8 |
| 9.5 | 0.708 | 2.72 | A | 0.0024 | -- | 280 | 16085 | 13896 | 42208 | 104.0 | 0.0755 | 8 |
| 9.5 | 0.708 | 8.17 | A | 0.0134 | -- | 280 | 13366 | 16606 | 43638 | 107.6 | 0.0755 | 8 |

`sum Xi`, `Xi avoided` and `M_inf` in Gt; the CE gain is the consumption supplement that would
make the no-recycling counterfactual as good as the cell; `survival` is `M_inf/(Rbar T)`, which
under a hard ceiling is reported but does not decide the state. Counterfactual welfare is
-35.7646 at `Rbar = 0` and -38.7343 at `Rbar = 9.502`, within 2e-8 across the three `xi`, which
is the consistency check that at `abar = 0.01` the tail rate no longer matters; counterfactual
emissions are 28410 to 28431 Gt and 29972 to 29994 Gt.

The classification reproduces D1 cell for cell where the two grids meet: `abar 1, Rbar 9.5` is C
with survival 209.7, `abar 0.708, Rbar 9.5` is A with survival 104.0 and shutdown 280, and
`abar 0.708, Rbar 0` is B. The signs are all as the theory would order them: the CE gain and the
emissions avoided rise in `xi` and in `abar`, `M_inf` more than doubles between the worst and the
best cell (39306 to 92343 Gt), and cumulative emissions fall by a factor of six across the grid.

## E4: the gate fee

On the baseline (`abar = 1`, `Rbar = 0`), `phiW = 1` at the planner corner and at the
laissez-faire corner of the other three dials.

| setting | (phiW,phiz,phiP,phiX) | tauW 1900 | maximum | sign change | tauW at sign change | minimum | tauW at T | T | \|F\| | route | s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| planner corner | (1,1,1,1) | 1.5167e-4 | 1.9374e-3 at t = 107 (2007) | t = 139 (2039) | -1.2657e-4 | -5.1088 at t = 399 | -5.0988 | 400 | 1.2e-10 | solve_long | 338 |
| property rights only | (1,0,0,0) | -1.9271e-9 | -1.9271e-9 at t = 0 | t = 0, numerically | -1.9271e-9 | -3.8487 at t = 400 | -3.8487 | 400 | 1.2e-10 | continuation | 10 |

In dollars per tonne the planner's gate fee is 0.15 in 1900, peaks at 1.94 in 2007, crosses zero
in 2039 and reaches -5099 in 2300; it passes -1 $/t in 2045, -10 $/t in 2072, -100 $/t in 2143
and -1000 $/t in 2237. The sign change at t = 139 is D1's date for the same calibration.

At the laissez-faire corner of the other three dials the waste stock is priced at essentially
nothing for half a century -- 1.9e-9 in 1900, and it first passes -1e-6 at t = 58 (1958),
-1e-4 at t = 99 (1999) and -1e-3 at t = 121 (2021) -- and then converges towards the planner's
path, ending at -3.85 against -5.10. The reading is that the *positive* part of the gate fee is
the pollution liability: with `phiP = 0` the leakage is unpriced, nothing makes holding waste
costly, and all that is left is the discounted option value of the material, which is positive
from the first period. That is why the sign change is at t = 0 there and not an event.

The paths CSV carries all twelve columns the harness promises -- `setting, t, tauW, z, zz,
zeta_star, pWst, Wst, R, a, varpi, Xi` -- for 401 periods of each setting, 802 data rows.

**The sign change against `xi`** (E2's row schema has no sign-change column, so this was run
separately, `d2_gatefee_xi.txt`, and writes under `output/gatefee/xi*/`; the committed table
stays the baseline's):

| xi | planner corner | property rights only |
|---|---|---|
| 0.907 | t = 193 (2093), tauW_T = -5.491 | t = 0, tauW_0 = -8.0e-12, tauW_T = -4.264 |
| 2.722 | t = 139 (2039), tauW_T = -5.099 | t = 0, tauW_0 = -1.9e-09, tauW_T = -3.849 |
| 8.166 | t = 79 (1979), tauW_T = -4.896 | t = 0, tauW_0 = -2.3e-07, tauW_T = -3.647 |

Monotone and correctly signed -- a cheaper recovery technology makes waste an asset sooner -- but
the range is 114 years across the range of one parameter. See below.

## Run times and convergence

E2: 16.0 minutes for both floors, 18 of 18 grid points, neither run stopping on its 6-hour
budget. The two cold solves (the first cell of each floor) took 272 s and 251 s, the latter by
the floor homotopy from `Rbar = 0`; every other cell continued from its neighbour in 7 to 10 s.
E4: 5.9 minutes for the two settings, the second by continuation; the `xi` variants 9.3 minutes
of solve time for four more (the two cold planner solves 195 s and 345 s). Total machine time for
D2 about 32 minutes, alongside D3 on the same machine.

**Every grid point converged.** All 18 E2 cells and all 6 E4 solves reached `T_reached = 400` of
400 requested, with `|F|` between 5.8e-11 and 1.2e-10. Routes: 1 cold `solve_long`, 1 floor
homotopy and 16 continuations for E2; 3 cold and 3 continuations for E4. No point was skipped, none
hit a budget, and no shutdown search failed (`shutdown_status = ok` on all six collapse cells).

## What looks wrong

1. **The Hotelling deviation is 6.8 to 7.7 percent in every cell, collapse or not, and is
   essentially invariant to `abar` and `xi`.** This is not a solver artefact and not specific to
   the collapse cells. Checked directly (`T = 200`, baseline and the `abar = 0.708, Rbar = 9.502`
   collapse cell): the interest rate `Lam_t/(beta Lam_{t+1})` runs at 1.064 to 1.080, while the
   reserve costate `pS` grows at 1.015 to 1.027, a *signed* shortfall of 4.6 to 5.9 percent at
   every date, and `Psi` -- which the harness compares, and which equals `pS` plus the marginal
   extraction cost plus `pW(1+Om^{N,S})` -- deviates a little more. The mechanism is visible in
   the same run: discovery is active throughout and large (`D` goes from 1.57 to 131 Gt a year
   while `N` goes from 5.7 to 154), so the reserve barely falls over two centuries (13429 to
   11204 Gt) and its shadow price is pinned by the marginal discovery cost, not by the interest
   rate. On this calibration there is no Hotelling path to check. Either the check should net out
   the extraction cost and the discovery arbitrage, or the note should say that the Hotelling
   reading does not apply while the exploration margin is interior. Flagged for E1.
2. **The consumption-equivalent gains are three to four orders of magnitude smaller than the
   physical effect.** Recycling avoids 8700 to 26200 Gt of cumulative leakage -- 30 to 88 percent
   of the counterfactual's total -- and is worth between 0.0003 and 0.095 percent of consumption.
   The arithmetic is consistent rather than broken: with `eta = 1.409`, `rho = 3.74%` and
   consumption growing at 2.5 percent, the discounted weight on periods after 2100 is about 1e-4
   of the total, `kappa = 6.8e-6` per Gt makes even a 10000 Gt difference in the pollution stock
   a 7 percent output effect, and the recycling margin is inactive until 2003 in any case. But it
   means the headline of E2 on this calibration is "circularity is worth almost nothing in
   welfare and a great deal in tonnes", which the write-up must state rather than bury. A gain of
   0.01 percent is also within the horizon tolerance of the welfare tail, so the *ranking* across
   cells is safer than any single level.
3. **The floor `Rbar = 9.502` is not a perturbation of the baseline; it is a different economy.**
   `Rbar` enters the technology as `R - Rbar`, and 9.5 Gt is 1.66 times the model's own 1900
   material input at `Rbar = 0` (5.74 Gt), so effective material input in the early decades is
   near zero and welfare falls from -35.76 to -38.73, far more than anything the experiment
   varies. The floor rows are internally consistent and converge, but they should not be read as
   a scarcity assumption about the distant future. This matters for D4 as well, whose whole grid
   is the floor.
4. **No cell's material era ends within `T = 400`** (`era_length = -1` in all eighteen rows,
   including the six the classifier calls collapse), while the shutdown search returns **exactly
   280 in all six collapse cells** regardless of `abar` and `xi`. The search grid is
   {80, 120, 160, 200, 240, 280, 320}, so 280 is interior rather than at the edge, but a date
   that does not move at all across two ceilings and a ninefold range of `xi` is either a flat
   objective or a 40-period grid too coarse to see the difference. D1 reported the same 280 on
   its one A-row. The "era length" column of the table is therefore empty everywhere and buys
   nothing on this calibration.
5. **The sign-change date is the least robust number in D2.** It moves from 1979 to 2093 -- 114
   years -- across the range of `xi` alone, and `xi` is the parameter `notes/data/waste_recycling.md`
   records as the thin spot. At the high end the model says waste was already an asset in 1979,
   which is before the base of the calibration window for the treated share. Monotone and
   correctly signed, but no single date should be quoted without the range.
6. **The generated table prints the laissez-faire corner's gate fee as `-0.0` with a sign change
   at 0**, which reads as "waste is a resource from 1900" when the value is -1.9e-9, numerically
   zero. The harness is not wrong -- `first_date(<(0), tauW)` is what it says -- but the cell is
   misleading and the write-up must not read a date off it. Not fixed here; the harness belongs
   to E3's agent this session.
7. **The gate fee's minimum is at the horizon edge in every setting** (t = 399 or t = 400), so
   the "minimum" column is the last point of the path and not a feature. At the planner corner
   `tauW` also ticks back up in the final period (-5.1088 at t = 399, -5.0988 at t = 400), which
   is the terminal closure block and not economics.
8. **Magnitudes to sanity-check before they are quoted.** The planner's gate fee is 0.15 US$ per
   tonne in 1900 and 1.94 in 2007, two orders of magnitude below observed landfill tipping fees.
   That is what should happen -- `tauW` is the shadow price of the waste *stock* and excludes the
   handling costs `c^c` and `c_T`, which are where a real gate fee's money goes -- but the note
   should say so explicitly, or a reader will take it as a failed validation.
