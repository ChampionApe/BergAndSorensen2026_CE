# D4: E5, the surface over the floor and the ceiling (2026-09-18)

Task D4 of `notes/plan_calibration_experiments.md`: `experiment_surface` (E5) on the calibrated
baseline `data/processed/calibration.json`, at `T = 400` through `model/scripts/run_d4.jl`, which
wraps the harness of `run_experiments.jl` and adds two things the surface alone cannot say: where
the floor stops being solvable at all, and whether the shutdown date the search returns is a date
or an artefact. Logs: `d4_surface.txt` (the surface and the edge) and `d4_shutdown.txt`. Rows:
`model/output/surface/surface.csv`, `edge.csv` and `shutdown_grid.csv` (gitignored). The generated
table is `writing/quant/Tables/Surface.tex`, written by `run_d4.jl` from the two CSVs so that it
can carry the shutdown column and the edge.

Dates are periods from 1900, material in Gt. The metals bound is excluded throughout: D1 found it
infeasible at `mu_N = 0`. The grids are the calibration file's `cases` plus the intermediate floors
the task set: `Rbar` in {0, 2, 4, 6, 9.502, 14, 19, 23.756} -- the file's own values at the two
floors D1 solved, not the report's rounded 9.5 and 23.8 -- and `abar` in {1, 0.85, 0.708}, the two
calibrated ceilings and the midpoint D2 used. Each ceiling's row is walked upward from `Rbar = 0`
by continuation, and the shutdown search runs wherever the state is collapse.

## The surface

Each cell is state / survival ratio `M_inf/(Rbar*T)` / shutdown date; a dash is an event that does
not occur or a search that converged on no date. Every one of the 24 cells solved.

| Rbar | abar = 1 | abar = 0.85 | abar = 0.708 |
|---|---|---|---|
| 0 | C / inf / -- | B / inf / -- | B / inf / -- |
| 2 | C / 1001.9 / -- | A / 686.2 / 280 | A / 497.7 / 280 |
| 4 | C / 500.2 / -- | A / 342.5 / 280 | A / 248.4 / 280 |
| 6 | C / 333.0 / -- | A / 228.0 / 280 | A / 165.3 / 280 |
| 9.502 | C / 209.7 / -- | A / 143.5 / 280 | A / 104.0 / 280 |
| 14 | C / 141.8 / -- | A / 97.0 / 280 | A / 70.3 / 280 |
| 19 | C / 104.1 / -- | A / 71.1 / 280 | A / 51.5 / 280 |
| 23.756 | C / 83.0 / -- | A / 56.7 / -- | A / 41.0 / -- |

The dash at `Rbar = 23.756` under both hard ceilings is D1's result reproduced -- the harness's
search converges on no date there -- and the shutdown section below shows it to be a step-length
artefact rather than a property of the cell.

**The surface has no interior structure in the floor.** The retained endowment barely moves along
a ceiling row: `M_inf` falls from 86010 to 84467 Gt at `abar = 1` between `Rbar = 0` and
`Rbar = 23.756`, 1.8 percent, and the residence time is constant at 42.86 (42.76 at `abar = 0.85`,
42.71 at `abar = 0.708`) to four figures. The survival ratio is therefore `M_inf/(Rbar*T)` with a
numerator that is very nearly fixed: a hyperbola in the floor, and nothing more. What the floor
does change monotonically is the date the gate fee turns negative, which comes forward as the floor
rises: 139 to 117 at `abar = 1`, 155 to 138 at `abar = 0.85`, 171 to 157 at `abar = 0.708`.

**The state is decided by the ceiling alone.** At `abar = 1` every floor in the grid is state C; at
either hard ceiling every positive floor is state A and `Rbar = 0` is state B. There is no interior
boundary in `Rbar` anywhere in the solvable range, and there cannot be one: the survival margin is
crossed at ratio 1, and the smallest ratio on the whole grid is 41.0. D3's arithmetic put the floor
that laissez-faire would fail to clear at about 1.8e3 Gt; the largest floor that solves at all is
34.5 Gt (below). **On this calibration E5 cannot exhibit a crossing of the survival margin, and the
reason is not that the margin was not searched but that the model cannot be solved anywhere near
it.** That is the result of the experiment.

Diagnostics, uniform across the grid: `T_reached = 400` of 400 requested everywhere, `|F|` between
5.8e-11 and 1.2e-10, ledger error below 2.5e-12, market-planner gap 2.8e-14, `tvc` capital factor
0.9540, all four well-posedness conditions holding, no period below the floor, cumulative `N` over
its bound between 0.578 and 0.614, and no cell's material era ending within the horizon. The
closure criterion has `leak_sum = 0.081` at `abar = 1` (the loop closes) and `Inf` at both hard
ceilings (it does not), which is what puts the hard-ceiling rows in A or B rather than C.

## The solvability edge

Bisection on `Rbar` between 23.756, which D1 solved, and 47.512, which it did not, six probes per
ceiling, each continued from the last floor that solved. **Both ceilings give the same edge to four
significant figures: the largest floor that solves is 34.52 Gt and the smallest that does not is
34.89 Gt**, a bracket 0.371 Gt wide. The probes were identical in sequence at the two ceilings
(35.634 fails, 29.695, 32.664, 34.149 solve, 34.892 fails, 34.520 solves), which is itself a
finding: the edge is the same under both ceilings and is therefore not the recycling ceiling's.
A finer walk afterwards at `abar = 1`, in steps of 0.046 Gt from the last solved floor, narrows the
bracket to **[34.6132, 34.6190] Gt**: 34.6132 solves to 1.2e-10 and a step of 0.006 Gt beyond it
does not solve at all.

`R at t = 0` and the slack are the same under both ceilings to four figures.

| Rbar | abar = 1 | abar = 0.708 | R at t = 0 | min R - Rbar |
|---|---|---|---|---|
| 23.756 | C, survival 83.0 | A, survival 41.0 | 26.63 | 2.873 |
| 29.695 | C, survival 66.1 | A, survival 32.6 | 32.31 | 2.619 |
| 32.664 | C, survival 60.0 | A, survival 29.6 | 35.18 | 2.516 |
| 34.149 | C, survival 57.4 | A, survival 28.3 | 36.62 | 2.472 |
| 34.520 | C, survival 56.8 | A, survival 28.0 | 36.98 | 2.461 |
| 34.892 | not solved | not solved | | |
| 47.512 | not solved (D1) | not solved (D1) | | |

**The floor is a demand on 1900, not on the long run.** On every solved path the minimum of
material input over the whole horizon is at `t = 0`, and it sits 2.5 to 2.9 Gt above the floor: the
path meets the floor in the base year and grows away from it. The floorless path of this
calibration uses 5.74 Gt in 1900, 10.1 in 1925, 17.1 in 1950 and 42.5 in 2000, and does not reach
23.756 Gt until `t = 68` (1968) or 47.512 Gt until `t = 106` (2006). So a floor of 9.5 Gt asks the
1900 economy for 1.7 times the material input it would otherwise choose, 23.756 Gt asks 4.6 times,
the edge at 34.52 asks 6.4 times, and the plan's fourth grid point, 47.512 Gt, asks 8.3 times --
of an economy with the 1900 capital stock, the 1900 reserve and the 1900 extraction technology.
**The floor grid is therefore a grid of base years, and it is bounded by one.** Nothing in the
failure is about the distant future: the paths that do solve at 34.5 Gt are ordinary state-C or
state-A paths with survival ratios in the tens, settled long before the horizon, and the floor is
slack at every date after the first. The constraint that binds is the one on 1900, and the edge
sits at 6.4 times 1900 material input, which puts the plan's fourth grid point, half of 2015 input,
out of reach. What the solver reports at the edge is not the first period failing to deliver the
floor -- it delivers 37.1 Gt against a floor of 34.66 -- but the recycling margins' corner
conditions breaking on the path that delivers it. The economic reading and the numerical one agree
on the scale, at 6 to 8 times the base year's throughput, and should not be run together beyond
that.

How the failure presents, from `edge.csv` (the residual of each route, in the order tried) and from
the two step-by-step diagnoses run afterwards at `abar = 1`:

- *continuation* from the last solved floor is the route that decides the edge, and it fails there
  at any step length. At 34.892 from 34.149 it stalls at `|F| = 0.25` (`abar = 1`; 0.045 at
  `abar = 0.708`); walking the same gap in steps of 0.046 Gt, 34.5668 and 34.6132 solve to 1.2e-10
  and 34.6190 -- 0.006 Gt further -- stalls at 4.2e-2. **The wall does not recede as the step is
  refined, which is what makes it an edge rather than a step length.**
- *what fails at the edge is the recycling block's corner conditions, not the floor.* At the first
  floor that does not solve the stalled iterate is perfectly feasible -- `R = 37.11` in 1900
  against a floor of 34.66, no period below the floor, no infeasible block -- and its largest
  residual rows are the complementarity rows of the recycling margins: the intensity margin `x` at
  `t = 23` and `t = 59` and the treated share `varpi` at `t = 46, 47` and `t = 176` to `179`, all
  about 4e-2 to 5e-2. Newton cannot hold those min-maps consistent at the first smoothing level,
  `e = 1e-1`. Nothing in the goods block, the transitions or the costates is large.
- *the floor homotopy* from the floorless path, which is the harness's second route, fails much
  earlier and for a different reason: eight equal steps to a target of 34.89 Gt are steps of
  4.36 Gt in the floor, and it breaks at the third of them, at `Rbar = 13.08`, a floor the surface
  itself solves comfortably. That stalled iterate *is* infeasible early -- `R = 0.13` in 1900
  against a floor of 13.08, four periods below the floor, 1900 to 1903, and the largest rows are
  the `varpi` complementarity at `t = 0` to `3` and at `t = 181` to `184`. This is the only place
  in the whole run where a path sits below the floor in the early decades, and it is a failed
  iterate rather than a solution. Lengthening the homotopy to 24 steps climbs further before it
  fails and so reports a larger residual (1.1 to 14), which is why more steps look worse.
- *the cold solve* as the harness calls it is inert on this calibration and its verdict should not
  be quoted. `solve_long`'s default guess targets `Rtarget = 0.6` Gt of material input -- the
  illustrative set's scale -- so at any floor above that the simulated starting path is below the
  floor in all 151 periods, `initial_guess` warns exactly that, and Newton returns `|F| = 1.0`
  without moving. Every `cold solve_long` line in an edge row is this.
- *a cold solve from a floor-scaled guess* (`Rtarget = 1.2 Rbar`, a route this driver adds so that
  the cold verdict means something) is feasible in all but one period and then diverges: `|F|`
  reaches 1e23 in the investment and capital-costate rows around `t = 143` to `t = 150`.

Two caveats. The edge is where **Newton stops reaching tolerance**, not a proof that no path exists
above it. And the bisection's own bracket is 0.371 Gt wide because six probes were the budget; the
finer walk that narrows it to 0.006 Gt was run at `abar = 1` only.

## The shutdown date

`path_facts` searches seven dates spaced 40 apart, and D1 and D2 both returned exactly 280 in every
collapse cell, which is what this stage was asked to check. Two cells, `abar = 0.708` at
`Rbar = 9.502` and at `Rbar = 23.756`, on `200:10:400`:

| Td | 200 | 210 | 220 | 230 | 240 | 250 | 260 | 270 | 280 | 290 to 400 |
|---|---|---|---|---|---|---|---|---|---|---|
| value, Rbar = 9.502 | -38.74571 | -38.74119 | -38.73841 | -38.73669 | -38.73563 | -38.73498 | -38.73458 | -38.73433 | -38.73417 | no solve |
| value, Rbar = 23.756 | -49.49135 | -49.48680 | -49.48400 | -49.48228 | -49.48122 | -49.48056 | -49.48015 | -49.47990 | -49.47975 | no solve |

**The objective is monotone increasing in the date, and 280 is the last date at which the shutdown
branch converges at all.** It is not an interior optimum. The increments decay geometrically by a
factor of 0.62 per ten periods -- 4.5e-3, 2.8e-3, 1.7e-3, 1.1e-3, 6.6e-4, 4.1e-4, 2.5e-4, 1.6e-4 --
so the whole eighty periods from 200 to 280 are worth 1.2e-2 against a level of 38.7, three parts
in ten thousand, and the extrapolated value at an infinitely postponed shutdown is about 2.5e-4
above the value at 280. The reading is that the planner would postpone the shutdown indefinitely
and that the model, at this horizon, cannot name a date. **Every shutdown date in D1, D2 and the
table above is the horizon of the shutdown branch and must be labelled as such**; the generated
table's note now says so.

What stops at 290 is not the floor. Dates 290 to 400 fail in `shutdown_cold_start`'s second stage,
the handover of the floorless closure path to `V_stop`, with `|F|` from 7.2 to 22, and the
residuals are *identical* at the two floors (7.169551912 at `Td = 290` in both cells) because that
stage solves the `Rbar = 0` problem. The shutdown branch has its own horizon wall at `Td` about
285 on this calibration, independent of the floor.

**D1's "no candidate date converged" at `Rbar = 23.756` is a step-length artefact.** At the default
`floor_steps = 6` every date of the grid stalls in `shutdown_cold_start`'s floor homotopy at `|F|`
about 2e-6 to 3e-6. At `floor_steps = 24` the same 21 dates behave exactly like the 9.502 cell:
nine converge, 200 to 280, monotone, best 280. The two cells' increments agree to three figures.
This is the one respect in which `model/README.md`'s "the shutdown branch converges on every date
tried, and skips with a reason where it cannot" is optimistic: on a calibration with a large floor
it skips every date, at a residual that four times the homotopy steps removes. Not fixed here --
the harness is not this task's -- but it is worth a line in *Known limitations* and in TODO 7.

## Run times and convergence

| stage | wall clock | of which |
|---|---|---|
| E5, 24 cells | 16.5 min | cold solves at `Rbar = 0` 305 s, 157 s, 102 s; 21 continuations 5 to 8 s; fourteen shutdown searches inside `path_facts` |
| the edge, 14 probes | 9.2 min | two floorless solves 229 s and 116 s; each solved probe 7 to 8 s by continuation; each failed probe 33 s over five routes |
| the shutdown grids | 7.6 min | 2.1 min at `Rbar = 9.502`, 1.7 min for the failed pass at 23.756, 3.7 min for its `floor_steps = 24` repeat |
| the two edge diagnoses | 11 min | one floorless solve each, then the homotopy or the chain of floors step by step; run afterwards, from a scratch script, not from the driver |
| whole run | about 37 min | the surface and edge in one process, the shutdown grids in another, in parallel on the same machine; the diagnoses afterwards, alone |

The 8-hour budget was never approached: the surface asked for 24 cells and finished 24. Rebuilding
the note's table from the CSVs, `scripts/run_d4.jl --only=table`, solves nothing and takes seconds.

**Non-converged points.** None in the surface: 24 of 24 cells converged at `T = 400`. In the edge
search, four probes by construction -- 35.634 and 34.892 at each ceiling -- with the routes and
residuals above; these are the bisection's failing side and are the result, not a loss. In the
shutdown grids, 12 of 21 dates in each cell (290 to 400, at the `V_stop` handover) and, at the
default homotopy length, all 21 dates of the `Rbar = 23.756` cell.

## What looks wrong

1. **The shutdown date is not an optimum** (above). This closes D1's open item 4 and D2's item 4:
   the 280 that did not move across two ceilings and a ninefold range of `xi` is the last date the
   branch solves, and the objective is flat to 3e-4 over the range that does solve. Any use of
   `T^dagger` in the write-up must say so.
2. **The harness's cold route cannot decide anything on this calibration.** `Rtarget = 0.6` Gt is
   the illustrative set's material scale; this calibration's 1900 input is 5.74 Gt. Every "cold
   solve_long" verdict at a positive floor is a guess that never left the starting point. A
   one-line default -- scale `Rtarget` with `Rbar` and with `s0`, or take it from the floorless
   path -- would make the third route mean something. D4 works around it in its own driver and
   does not touch the harness.
3. **`floor_steps = 6` is too short for the shutdown branch at a large floor** (above), which makes
   a cell look unsolvable when it is not.
4. **The surface is featureless in `Rbar`.** Because `M_inf` moves by under 2 percent across the
   floor grid, the survival ratio is a hyperbola and every cell of a ceiling column says the same
   thing. If the note wants a surface with structure it has to come from `abar`, or from a floor
   range the solver cannot reach.
5. **The three-state taxonomy is only two-valued here.** The ceiling decides everything: `abar = 1`
   gives C at every floor, a hard ceiling gives B without a floor and A with one. The survival
   margin, the theory's own third boundary, is 50 times beyond the solvability edge.
6. **`Rbar = 9.502` remains a different economy, not a perturbation** (D2's item 3), and the edge
   makes the point sharper: the whole solvable floor range asks the 1900 economy for between 1.7
   and 6.4 times the material input it would otherwise choose, so every row of this surface is a
   counterfactual 1900 as much as a counterfactual future.
7. **What breaks at the edge is the smoothed complementarity, not the economics.** The failing
   iterate is feasible, its transitions and costates hold, and the large rows are the min-maps of
   the treated share and the recycling intensity at the first smoothing level of `solve_path`'s
   schedule, `e = 1e-1`. The obvious thing to try before believing the edge is a longer schedule
   starting from a wider smoothing, or the same continuation in two parameters at once; neither
   was tried here, and until one is, 34.61 Gt is the largest floor this solver reaches rather than
   the largest the model admits.
