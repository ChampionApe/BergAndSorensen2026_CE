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
11. *(closed 2026-09-18 — `notes/data/` holds seven decision files and the data appendix is
   `writing/quant/quant_data.tex` with its `%% GENERATED` tables; `docs_style.md` §5 is the rule they
   follow.)*
4. *(closed 2026-09-17 — both stubs dropped from `main.tex` and deleted, plan 2B of
   `notes/plan_longrun_restructure.md`.)*

## Calibration and data

5. *(closed 2026-09-18 — both decisions ruled before phase B: all four material categories on a mass
   basis with metals only as a reported bound, and 1900 observed as the base year;
   `notes/plan_calibration_experiments.md` §0, decisions D1 and D2.)*
6. *(closed 2026-09-18 — the calibrated set is `data/processed/calibration.json`, built by
   `data/build/c1` to `c6` and read by `calibrated_params`; `src/calibration.jl` keeps the
   illustrative set and its docstring says so. The results are in `writing/quant/quant_results.tex`.)*
12. **The damage coefficient prices overburden it was never bridged to** (review R2). `kappa` is the
   integrated-assessment loss per GtCO2 times the fossil share of DPO, and DPO excludes unused
   extraction, but the model's own leakage carries `OmNS * N`: 45 percent of what reaches `P` in 2015
   is overburden and the fossil share of the model's flow is nearer 0.14. Either refit `kappa` on the
   fossil share of the model's waste flow, which roughly halves it, or book `Nbase` into the stockpile
   and not into the leakage, which is a model change. Waits on a ruling on decision D4.
13. **`c_N_inf` is pinned at the 2006-2015 mean of the implied series** (review R8), which is 1.9 times
   the 2015 value because the price index peaked in 2008, and the model's 2015 extraction cost is then
   13.1 percent of output against the 6.8 percent share it was built to reproduce. Refit on a smoothed
   price index or pin the end at 2015, and state the window in `notes/data/calibration.md`.
14. **The metals bound is infeasible at `mu_N = 0`** (review R12; `model/README.md`, Known
   limitations): no stock effect, no reserve rent, and the solved reserve goes negative. The smallest
   repair with a source is Mudd's energy-grade elasticity of 0.285 as the metals `mu_N`, keeping zero
   as the range's infeasible bottom and testing `min S > 0` before anything is reported. Until then
   `Tables/metals/` is not an input to the note.
15. **`P_0` and the `P` series are converted at different compositions** (review R18): `c5` uses the
   1900 composition and `c0_series.py` the 2000-2015 one, so the JSON's 79.0 Gt and `series.csv`'s
   39.0 Gt are the same stock twice. Convert both at the composition `kappa` uses, or say in the
   appendix that `P` is tonnes at a composition and which one.
16. **`Omega^{N,S}` puts EU-15 ratios on the world composition** (review R9), and it is the largest
   component of the model's waste flow. The world figure is in Schandl et al. (2018), which Wiley
   refuses to serve: recorded under *Not obtained* in `data/SOURCES.md`. Until it is in hand the low
   end of the range (0.76) is the better point and the appendix should say why.
17. **`phi^I` is constant against a stored share that tripled** (review R19): 0.164 in 1900 and 0.519
   in 2015 in the data, 0.259 and 0.322 on the solved path, so `M^K` is wrong in both directions and
   the 1900 waste flow is ten percent low. A time-varying `phi^I` is the model change
   `theory_planner_setup.tex` sets aside; recorded as a limitation until that is reopened.
18. **`mu_D` is an elasticity of cost per discovery, applied to a fossil-dominated aggregate** (review
   R20). It hardly matters at the point, because `Xmax` is 6.6 times `X_0`; the sensitivity that would
   matter is `Xmax` at its low end, 17,217 Gt, which no phase-D run touched. One E1 row at
   `Xmax = low` would settle it.
19. **The baseline preference pair decides every welfare level in the tables** (review R1, R14).
   `rho = 3.74` percent is the intercept of a seven-point regression of PWT's internal rate of return,
   which is gross of risk premia and taxes, and at that rate a date 200 years out carries weight 8e-5.
   The sensitivity exists (`Tables/Sensitivity.tex`, `kappa` times 6.69 and the DICE pair); the
   decision on which pair the baseline should use does not. Waits on RKB.
20. **The MANUAL downloads are still pending**, collected with everything else that could not be
   obtained in the *Not obtained* table of `data/SOURCES.md`, twenty rows with what each holds and
   why it failed. Kinnaman, Shinkuma and Yamamoto (2014) and Schandl et al. (2018) are the two that
   would change a number, items 16 above and the `xi` evidence. Each needs a browser, not a script.

## Model

7. *(closed 2026-09-18 — the stall was the terminal block: `V_stop`'s derivatives were nested finite
   differences and are exact now. Every date the search visits converges or skips with a recorded
   reason and `test/test_shutdown.jl` covers it; what remains is items 21 and 22.)*
8. *(closed 2026-09-18 — `V_stop`'s legacy recursion carries the `delta M^K` inflow and prices `pM` at
   the handover from the same recursion. Measured, tested and the default; `model/README.md`, What is
   verified.)*
9. **The horizon wall at `T ≈ 300–325`** is the model's conditioning, not the solver's. On the
   calibrated set it did not bite: the reserve never reaches 2 percent of `S_0` within the horizon,
   sitting at 0.18 of it at `T = 400`, so nothing was lost and the wall binds only well beyond the
   reported window.
21. **The harness's cold route is inert at a real floor** (D4, `data/processed/d4_report.md`).
   `solve_long`'s default guess targets `Rtarget = 0.6` Gt, the illustrative set's scale, so at any
   floor above that the starting path is below the floor in every period and Newton returns
   `|F| = 1.0` without moving: the third route decides nothing and its verdicts must not be quoted.
   The fix is one line, scaling `Rtarget` with `Rbar` and `s0` or taking it from the floorless path.
22. **The shutdown branch has a horizon wall of its own at `Td ≈ 285`**, and `floor_steps = 6` is too
   short at a large floor (D4). Dates from 290 fail at the handover to `V_stop`, so every reported
   `T^dagger` is the branch's wall and not an optimum, and at `Rbar = 23.756` the default homotopy
   makes every date look unsolvable where `floor_steps = 24` converges on nine. Solver work, not
   model work.
23. **The laissez-faire corner does not converge at `T = 400` under a large damage coefficient** (E2,
   `Tables/Sensitivity.tex`): it stalls in the `varpi` complementarity rows between 6.2 and 6.4 times
   `kappa` on every continuation route and solves cold only to `T = 358`, 337 with the DICE preference
   pair. Those two cells are reported at that horizon against the planner corner re-solved there; a
   wider smoothing schedule, or continuation in two parameters at once, is what has not been tried.
