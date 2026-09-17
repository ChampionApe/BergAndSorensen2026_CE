# Research log — the quantitative implementation

Session log for work inside `model/`. Cross-cutting work, the theory and the writing go to the root
`RESEARCH_LOG.md` instead. Newest entry first, at most ~10 lines each: what changed, why, where to look.
`/wrapup` is the pass that writes these.

The history of the implementation up to 2026-09-17 is in the root log, which was the only log until the
split. Nothing is lost; it simply starts here.

## 2026-09-17 — Source made ASCII-clean

- **Five BOMs and two `÷` operators removed** (`CircularEconomy.jl`, `guess.jl`, `longrun.jl`,
  `period.jl`, `primitives.jl`; `solver.jl`, `sufficiency.jl` → `div(a, b)`). The ASCII-only convention
  was stated in `model/README.md` but not held, and a BOM is invisible in an editor. 742 tests before
  and after.
- **Symbol table added, as `model/SYMBOLS.md`**, the one place a document symbol and a Julia identifier
  are written beside each other, with the three clashes (`mu`, `beta`, `sigma`) recorded. The table is
  what makes the ASCII choice affordable; `code_style.md` fixes the transliteration rules.
