# TODO

The one open list. Closed work goes to `RESEARCH_LOG.md` or `model/RESEARCH_LOG.md`, not a tick here.
An item says what it waits on, so it can be picked up cold.

## Writing and Overleaf

1. **First push of `docs` to its Overleaf project**
   (<https://da.overleaf.com/project/6a74e6678784f21dd0dbe8bc>). `notes/overleafSync.md` §1. Needs a
   terminal of your own, once, so the credential manager can take the Git token.
2. **Cut the paper over to `overleaf.py`.** `notes/overleafSync.md` §2, which has one step that must be
   done by hand first: check Overleaf's history for co-author edits made after 2026-08-06, because the
   local copy is ahead (the $\zeta$ normalisation and $q = 1+\phi^K p^M$) and a `--force` push would
   discard anything newer online. Then unlink the GitHub integration.
3. **Decide what `docs` and `paper` each own.** They are two documents of the same model in two time
   conventions — the technical note is discrete time, the paper continuous. Neither states the relation
   to the other, and the reader of either would want it in one sentence.
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
