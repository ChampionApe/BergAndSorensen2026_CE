# Research log — the quantitative implementation

Session log for work inside `model/`. Cross-cutting work, the theory and the writing go to the root
`RESEARCH_LOG.md` instead. Newest entry first, at most ~10 lines each: what changed, why, where to look.
`/wrapup` is the pass that writes these.

The history of the implementation up to 2026-09-17 is in the root log, which was the only log until the
split. Nothing is lost; it simply starts here.

## 2026-09-18 - The calibration run inside `model/` (phases A, D0 and D, branch `calibration`)

- **The no-treatment corner** (D0a): the sixth control is the intensity `x = K^R/T`, not `K^R`, whose
  Kuhn-Tucker row is a 0/0 at the corner with a Jacobian scaling as `1/T` and stalled at
  `|F| ~ 1e-4`; in `x` it is well posed at `T = 0` and selects the `alpha` the treatment margin
  needs. Fixture test on the phase C set; `SYMBOLS.md` slot `IXR`.
- **The handling charges are fitted, not read** (D0b): the Kaza ladder gives `cT/cc = 2` and no level,
  so `data/build/c4_handling_level.jl` bisects the common factor until the path reproduces the 2015
  treated share (1.242; `varpi_2015 = 0.252`). The recycled share is reported and missed, 0.22
  against 0.096, which is `xi` and the stockpile reading rather than the charges (review R4).
- **The harness and five drivers**: `scripts/run_experiments.jl` carries E1 to E5, and `run_d1.jl` to
  `run_d4.jl` and `run_e2_sensitivity.jl` run them on the calibrated set, reporting to
  `data/processed/d*_report.md`. A1 fixed the shutdown branch (exact `V_stop` gradient) and A2 gave
  the handover its `delta M^K` inflow; A3 is `calibrated_params`.
- **What D4 left in *Known limitations***: the surface is featureless in `Rbar` and the solvability
  edge is 34.61 Gt, 6.4 times 1900 material input, because the floor binds in the base year; the cold
  route is inert at a real floor and `floor_steps = 6` too short at a large one; and the branch's own
  wall at `Td` about 285 makes the shutdown date 280 a wall, not an optimum. TODO 21 to 23.
- 825 -> 1234 tests. Two commits are misattributed (review R24): `010c112` "Cal A5" carries B5's
  nineteen files, and `9d02e25` "Cal B5" is empty and says why.

## 2026-09-17 (overnight) - Code in line with the three-state theory

- **`mu_h` in (0,1]**: one line in `check_params`; nothing in the source divided by `1 - mu_h`. Tested at
  the buffer corner (planner/market agreement, ledger, `W_{t+1} = W_t`, residence time `1 + sigma/delta`).
- **`wellposed_report(p; g, nu)`** in `sufficiency.jl` evaluates the five inequalities that replace the
  theory's Assumption 2; `tvc_report` extends to it and measures `nu` on the path. Finding: the
  illustrative baseline fails $e^{g+\nu}<1+r$ at its own balanced-dematerialization rates, a property
  of the placeholder numbers, asserted as such in the tests.
- **`classify_longrun`** in `longrun.jl` returns `:A`, `:B` or `:C` with its margins; baseline is `:C`.
- **Rest-point benchmark test added**, the one `quant_solution.tex` promised and the suite never ran;
  `restpoint_B1` renamed `restpoint_stationary`. Note the closed form reports `pW` in the gate-fee
  sign. `SYMBOLS.md` gained `Minf` and `residence`. 742 → 825 tests.

## 2026-09-17 — Source made ASCII-clean

- **Five BOMs and two `÷` operators removed** (`CircularEconomy.jl`, `guess.jl`, `longrun.jl`,
  `period.jl`, `primitives.jl`; `solver.jl`, `sufficiency.jl` → `div(a, b)`). The ASCII-only convention
  was stated in `model/README.md` but not held, and a BOM is invisible in an editor. 742 tests before
  and after.
- **Symbol table added, as `model/SYMBOLS.md`**, the one place a document symbol and a Julia identifier
  are written beside each other, with the three clashes (`mu`, `beta`, `sigma`) recorded. The table is
  what makes the ASCII choice affordable; `code_style.md` fixes the transliteration rules.
