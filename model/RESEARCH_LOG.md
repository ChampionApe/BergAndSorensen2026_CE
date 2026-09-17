# Research log — the quantitative implementation

Session log for work inside `model/`. Cross-cutting work, the theory and the writing go to the root
`RESEARCH_LOG.md` instead. Newest entry first, at most ~10 lines each: what changed, why, where to look.
`/wrapup` is the pass that writes these.

The history of the implementation up to 2026-09-17 is in the root log, which was the only log until the
split. Nothing is lost; it simply starts here.

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
