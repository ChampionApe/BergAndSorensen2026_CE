# BergAndSorensen2026_CE

Code base for *The Environmental Macroeconomics of the Circular Economy* (2026). A Ramsey growth
model with exhaustible resources, used to study the optimal recycling of polluting waste.

See `CLAUDE.md` for project conventions. This file is a map of the repo and a statement of where
things stand.

## Layout
- `writing/docs/` — the technical note: the authoritative statement of the model, derivations
  included. Single root, no parallel drafts.
- `writing/draft/` — the paper itself, the version that goes to Overleaf. Prose and results, not
  derivations.
- `model/` — Julia implementation of the quantitative model.
- `data/` — raw and processed inputs (not results).
- `results/` — output tables, figures, model instances, solution databases.
- `notes/` — working notes for smaller tasks.
- `RESEARCH_LOG.md` — session log, appended at the end of a working session. Records what was
  settled and why; searchable context, not a changelog.

Everything predating the 2026-08-18 reset is kept under `writing/_archive/`.

## Status

**Model docs** under `writing/docs` cover the planner's problem in continuous time. The long-run
section is organised around a classification theorem: four sustained-consumption configurations
(stationary state, balanced circular path, materially expanding growth, dematerialised
consumption), a selection map over three primitives, and per-path results — three paths
characterised (SS and BCP in general; MEG under the workhorse tails, via
`Appendix_workhorse.tex` and Proposition `prop:sp:wh:meg`), DC placed but open in profile. A
workhorse functional-form family (Stone-Geary CES with a material floor, parametrised tails)
carries the parametric results and doubles as the spec of the future quantitative model. The
**collapse analysis** (C → 0) now completes the map (`theory_planner_longrun.tex`
§Collapse + `Appendix_collapse.tex`): damped vs catastrophic collapse split by one condition
(η−1)|g_C| < ρ (= finite value = convergent prices = transversality); a Cobb–Douglas + regime
(E) lead case — self-similar descent at a common rate floored at −δ, stranded reserves (the
mirror of "never stranded" on sustained paths), the loop fed by the depreciating capital
stock, pollution priced away; hard essentiality (the floor) makes every collapse a
finite-time shutdown with U₀ = −∞, so the growth-(E)-essential cell has no damped regular
path at all (the (E)-column twin of gap xii). Side effect: Assumption regular(ii) gained a
cumulative-protection clause (workhorse χ ≥ 1) closing a finite-time-exhaustion hole in the
no-terminal-corner step. Gaps list now fifteen items in `Appendix_longrun.tex`. Agreed next
step: transition dynamics. `writing/draft` is not up to date with any of this.

**The quantitative model is not started in code.** `model/`, `data/`, `results/` and `notes/`.
