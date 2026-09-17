# The Environmental Macroeconomics of the Circular Economy (2026)

## What this project is

A Ramsey growth model with exhaustible natural resources, used to study the optimal recycling of
polluting waste products. The same model is carried in three versions: a theoretical model with a social
planner, an equivalent decentralized market version, and a quantitative version of the market model with
explicit functional forms. `README.md` maps the repository; `model/README.md` covers the quantitative
implementation and its method.

Two things distinguish the model from a standard environmental Ramsey problem, and several conventions
below exist to protect one of them: an anthropogenic **waste stock** with its own transition and
handling share, and a **hard material floor** below which the technology is undefined.

The project has three written outputs, each its own Overleaf project:

| | | |
|---|---|---|
| `writing/paper/` | the paper, with Peter Birch Sørensen | <https://da.overleaf.com/project/6a4378918a3c3c23fe9d9afa> |
| `writing/docs/` | the theory note: planner, market, derivations, notation | <https://da.overleaf.com/project/6a74e6678784f21dd0dbe8bc> |
| `writing/quant/` | the quantitative note: computable model, solution, calibration, data | <https://da.overleaf.com/project/6aabe8521dad1168d7b72885> |

The two notes are one document split in two, so the theory, which is nearly frozen, is not re-exported
every time the calibration moves. They refer to each other by section name through the `\theory` and
`\quant` macros in their preambles, never by `\ref`, which does not resolve across Overleaf projects
(`docs_style.md` §5). The notes and the paper are the same model in two time conventions — the notes
are discrete time, the paper continuous — and a symbol does not always mean the same object in both.
`writing/docs/notation.tex` names the two that differ outright.

## Where the conventions live

One owner per fact. Read the guide covering what you are about to write, and do not restate it in a
third place.

| | |
|---|---|
| `docs_style.md` | **how `writing/docs/` and `writing/quant/` are written**: prose, LaTeX, what a section must contain, where data documentation goes |
| `paper_style.md` | **how `writing/paper/` is written**, as the list of differences from `docs_style.md` — it does not repeat it |
| `code_style.md` | **how `model/src/` is written**: the notation it inherits, the shape of a file, what earns a comment |
| `writing/docs/notation.tex` | **the notation** and the rules behind it, as an appendix to the note |
| `model/README.md` | the file map, the method, the known limitations |
| `model/SYMBOLS.md` | the **symbol table**: document symbol beside Julia identifier |
| `README.md` | the repository map |
| `notes/TODO.md` | the one open list. Closed work is in the logs, not here |
| `notes/overleafSync.md` | the sync procedure, which has traps in it |

`writing/_archive/` is superseded writing, reserved as the basis for a later, more purely theoretical
paper. `archive/` is everything else that is history, indexed in `archive/INDEX.md`. Both are kept out
of default searches by `.rgignore`. Do not read either unless a live file points there, and never
restate their content into a live file — link to it.

## Invariants

These fail silently rather than loudly, which is why they are here rather than in a guide.

- **`--project=.` on every Julia invocation, run from `model/`.** Without it Julia uses the global
  environment and this project's pinning is ignored, with no error message at all.
- **`model/src/` is ASCII only.** Not a preference: a stray re-encoding on Windows silently corrupts a
  Unicode operator in Julia source, and the corruption survives a passing test suite. That includes the
  byte-order mark, and operators with an ASCII spelling — `div(a, b)`, never `a ÷ b`. It is also why the
  symbol table in `model/SYMBOLS.md` exists: the document's symbols and the source's identifiers are
  related by a lookup, not by a search. Check with `grep -P '[\x80-\xFF]' model/src/*.jl`, which should
  return nothing.
- **A symbol clash is broken once, in `model/SYMBOLS.md`, and never a second way in a
  second file.** Three are broken today: `mu`, `beta` and `sigma` each name a second object in the
  quantitative specialisation.
- **Each folder under `writing/` is self-contained** — its own `main.tex`, `Packages.tex`,
  `References.bib`. That folder is what gets uploaded to Overleaf, so a file it `\input`s from outside
  compiles here and fails there. `overleaf.py` refuses an export that would break this, including a
  reference matching only case-insensitively, because Overleaf runs on Linux and this machine does not.
- **A file marked `%% ALMOST DONE` is edited minimally**, only where something it states has actually
  changed. The whole planner part carries the marker today. `docs_style.md` §1.
- **Do not hand-edit a file carrying a `%% GENERATED` banner.** Nothing generates one yet; when the
  quantitative results start landing in tex they will, and `overleaf.py` already protects them.
- **Documentation is part of the work, not a write-up phase.** A change to the model that is not
  reflected in the notes under `writing/` is unfinished.

## Working conventions

- **Discuss before building.** On research-style questions, lay out the options first rather than
  implementing the first one. Prefer an established package to a hand-rolled algorithm.
- **Tests.** `julia --project=. test/runtests.jl` from `model/`. One `@testset` per concern, all
  registered in that file. Write checks straight into the file that will keep them. 742 pass today; a
  red suite is reported as red, with the failing assertion.
- **Do not compile tex.** Add the file under `writing/` and let the user compile locally.
- **Data documentation has three homes**, split by one rule: what a reader needs to reproduce or
  interpret a number goes in the quantitative note's data appendix; why we chose this over that goes
  in `notes/data/`, one file per decision area; the transformation itself lives in the pipeline
  script. `docs_style.md` §5 is the rule, and `data/SOURCES.md` keeps provenance.
- **Logs, at end of session.** After a full working session, *before shutting it down* — not during
  every interaction — append a short entry to the relevant log: the root `RESEARCH_LOG.md` for
  cross-cutting work, the theory and the writing; `model/RESEARCH_LOG.md` for the quantitative
  implementation. `/wrapup` is that pass in full.
- **Context budget, so the docs stay cheap to read.** A `README.md` stays under ~100 lines and holds
  orientation only (purpose, file map, how to run, invariants as one-liners, status, open items). A log
  entry is at most ~10 lines: what changed, why, where to look. Anything longer — measurements,
  investigations, superseded plans — goes to `archive/` with a pointer from the live file, or to
  `writing/_archive/` if it is writing.
- **Docs that must stay current.** `model/README.md`'s file map and limitations, and `model/SYMBOLS.md`
  when a symbol is added or a clash broken; `notes/TODO.md`'s open items; `writing/overleaf.py`'s `PROJECTS` when a writing project
  is added; `data/SOURCES.md` when a data file is added, with the provenance line
  `notes/data_plan_global_1850.md` specifies — full citation, URL, access date, licence.

## Local gotchas (Windows)

- `PYTHONUTF8=1` for any Python run whose output is redirected to a file — otherwise the first non-ASCII
  character raises `UnicodeEncodeError` and a passing run reports failure for a clerical reason. It is
  set for the session in `.claude/settings.json`.
- PowerShell's `*>` redirection writes UTF-16.
- **Line endings are not drift.** `writing/paper/` is LF; the old `BergAndSorensen2026_circular`
  repository is CRLF. Comparing the two without `diff --strip-trailing-cr` makes near-identical files
  look like they differ by hundreds of lines.
