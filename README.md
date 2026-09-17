# BergAndSorensen2026_CE

*The Environmental Macroeconomics of the Circular Economy* (2026), by Rasmus K. Berg and Peter Birch
Sørensen. This file is a map. `CLAUDE.md` holds the conventions and points at the three style guides:
**`docs_style.md`** for the two technical notes, **`paper_style.md`** for the paper, **`code_style.md`**
for `model/src/`.

A Ramsey growth model with exhaustible resources and optimal recycling of polluting waste. Two
primitives distinguish it from a standard environmental Ramsey problem: an anthropogenic **waste stock**
with its own transition and handling share, and a **hard material floor** below which the technology is
undefined. The model is carried in three versions — a social planner, its decentralization, and a
quantitative version with explicit functional forms — and the third is what `model/` implements.

## Three documents

Each folder under `writing/` is one Overleaf project and is self-contained: its own `main.tex`,
`Packages.tex`, `References.bib`. `writing/overleaf.py` moves each in both directions and
`notes/overleafSync.md` is the procedure.

| | | |
|---|---|---|
| `writing/paper/` | the paper, **continuous time** | <https://da.overleaf.com/project/6a4378918a3c3c23fe9d9afa> |
| `writing/docs/` | the theory note, **discrete time** | <https://da.overleaf.com/project/6a74e6678784f21dd0dbe8bc> |
| `writing/quant/` | the quantitative note, **discrete time** | <https://da.overleaf.com/project/6aabe8521dad1168d7b72885> |

The theory note runs planner → market, with the derivations, the workhorse specification, the
sufficiency protocol and the notation appendix behind them; the planner part is marked `%% ALMOST DONE`
and is edited minimally. The quantitative note is the computable model, its solution, its calibration,
and the data appendix once the calibration lands. The two notes cite each other by section name, never
by `\ref` (`docs_style.md` §5). The notes and the paper are the same model in two time conventions, so a
symbol does not always mean the same object in both; `writing/docs/notation.tex` names the two that
differ.

## The model

```
cd model
julia --project=. test/runtests.jl           # 742 tests, ~15 s
julia --project=. scripts/run_baseline.jl    # baseline path + policy dials, ~30 s
julia --project=. scripts/run_sufficiency.jl # convexity, transversality, deviations
```

Julia, standard library only. The planner and the market are **one residual system**, the planner
nested as a corner of a four-dimensional policy space, and both transcriptions are carried and required
to agree to machine precision — the decentralisation proposition as an algebraic identity rather than a
property of a solution. A 200-period path solves in ~2.5 s. `model/README.md` is the file map, the
method and the known limitations, and `model/SYMBOLS.md` is the symbol table; read both before
touching `model/src/`.

Sources are **ASCII only**, deliberately, and the symbol table is what makes that affordable.

## Layout

**`data/`** — raw and processed inputs, not results. Empty: `notes/data_plan_global_1850.md` is the
plan, and two decisions come before any downloading. When it fills, the pipeline script owns the
transformations and emits the quantitative note's data-appendix tables as `%% GENERATED` tex,
`data/SOURCES.md` keeps provenance, and `notes/data/` holds one file per decision area: the
alternatives, the reason, the date. The rule that splits reader-facing from process is
`docs_style.md` §5.

**`results/`** — solved output. Empty: nothing is published from the model yet, and every number the
quantitative part currently states is illustrative, because `model/src/calibration.jl` holds
placeholders rather than a calibration.

**`notes/`** — the live working notes. `TODO.md` is the one open list; `overleafSync.md` is the sync
procedure; the rest are topic notes on the long run, residence time and the data plan.

**`archive/`** — history, indexed in `archive/INDEX.md`. **`writing/_archive/`** — superseded writing,
reserved as the basis for a later, more purely theoretical paper. `.rgignore` keeps both out of default
searches.

**`RESEARCH_LOG.md`** — session log for cross-cutting work, the theory and the writing;
`model/RESEARCH_LOG.md` for the quantitative implementation.

## Status

The theory is settled: the planner problem and its long-run taxonomy, the decentralization and its three
results, and the sufficiency protocol. The quantitative implementation solves, verifies itself against
the analytics, and passes 742 tests — but it is **not calibrated**, and the shutdown branch is fragile
and untested.

Next, in order: the two data decisions, then the calibration, then whatever the paper's quantitative
section is actually going to claim. Open items, with what each waits on: `notes/TODO.md`.
