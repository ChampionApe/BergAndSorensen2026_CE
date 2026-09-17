# TODO

The one open list. Closed work goes to `RESEARCH_LOG.md` or `model/RESEARCH_LOG.md`, not a tick here.
An item says what it waits on, so it can be picked up cold.

**Do not renumber.** These numbers are cited from `code_style.md` and `paper_style.md`. A closed item
leaves a gap; a new one takes the next free number.

## Writing and Overleaf

1. *(closed 2026-09-17 — both Overleaf projects connected and pushed.)*
2. **Unlink the GitHub integration from the paper's Overleaf project.** The push route is now
   `overleaf.py`, and running both against one project is what the sync discipline exists to prevent.
   Overleaf → Menu → GitHub → unlink. Until this is done, a GitHub sync could still overwrite the
   project from the retired `BergAndSorensen2026_circular` repository, which is 2026-08-06 content.
3. **Decide what the notes and `paper` each own.** They are documents of the same model in two time
   conventions — the notes are discrete time, the paper continuous. Neither states the relation
   to the other, and the reader of either would want it in one sentence. The note itself was split
   2026-09-17 into `writing/docs/` (theory) and `writing/quant/` (quantitative); that half is settled.
10. **The quantitative note names the theory results it uses but does not yet restate them.** The 43
   cross-document references were rewritten 2026-09-17 to name their target section (`docs_style.md`
   §5); the equations it leans on — the collected ledger, the equations of motion, the net waste-stock
   recursion, the survival condition — are still only named. Waits on the cut of the docs, since much
   of the surrounding text may go.
11. **`notes/data/` and the data appendix of the quantitative note exist as a rule, not as files.**
   `docs_style.md` §5 says what goes where; the first file lands with the first decision under 5.
4. **The two appendix stubs**, `Appendix_exogenousPhiI.tex` and `Appendix_constantPhiI.tex`. Both are
   three lines. Either write them or drop them from `main.tex`.

## Calibration and data

5. **Two decisions before any downloading**, from `notes/data_plan_global_1850.md`: which materials, and
   whether the base year is 1850 (with a backcast) or 1900 (observed).
6. **`model/src/calibration.jl` is illustrative, not calibrated.** Every number in it is a placeholder,
   and every result quoted anywhere is therefore illustrative too. This is the item that turns the
   quantitative part real, and it waits on 5.

## Model

7. **The shutdown branch is fragile** and is not covered by the test suite: roughly a quarter of
   candidate dates stall just short of tolerance. `model/README.md`, Known limitations. Results from it
   are provisional until this is either fixed or fenced by tests.
8. **`p^M = 0` is imposed at the shutdown handover** — `V_stop` ignores the material released by capital
   as it is eaten. Decide whether that is an approximation worth documenting or a bug worth fixing.
9. **The horizon wall at `T ≈ 300–325`** is the model's conditioning, not the solver's. Nothing is lost
   at the current calibration, but a calibration that depletes faster hits it sooner — revisit after 6.
