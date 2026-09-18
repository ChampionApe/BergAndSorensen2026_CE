# `data/` — the calibration pipeline

Everything between a downloaded file and `data/processed/calibration.json`, which is the only file
`model/src/calibration.jl` reads. Provenance is `SOURCES.md`; the decisions are in `notes/data/`,
one file per area; the numbers a reader needs are in `writing/quant/quant_data.tex`.

## Layout

| | |
|---|---|
| `raw/<source>/` | the file as downloaded, **never edited**. A format conversion sits beside the original with the command that made it. Large PDFs and non-redistributable copies are `.gitignore`d and re-downloaded by the command in `SOURCES.md` |
| `build/` | one Python script per source, `b<block>_<source>.py`, plus one block script that joins them; then the `c*` calibration scripts. Standard library, pandas, openpyxl, pyarrow, pypdf |
| `interim/` | one long-format CSV per source and per block: `year, series, value, unit, source, method` |
| `processed/` | the calibration itself: `calibration.json`, `calibration_metals.json`, `series.csv` (the model-facing annual series), the `c*` block outputs, the `c7`/`c8` check logs, and the phase-D reports `d1_baseline_report.md` to `d4_report.md` |

## Rebuilding

From the repository root, with `PYTHONUTF8=1` set (without it a non-ASCII character in redirected
output raises `UnicodeEncodeError` and a good run reports failure):

```
PYTHONUTF8=1 python data/build/b1_*.py   # sources first, then b1_material_block.py
PYTHONUTF8=1 python data/build/b2_*.py   # ... b2_macro_block.py, then b2_omega_join.py
PYTHONUTF8=1 python data/build/b3_*.py   # ... b3_resource_block.py
PYTHONUTF8=1 python data/build/b4_*.py   # ... b4_waste_block.py
PYTHONUTF8=1 python data/build/b5_*.py   # ... b5_pollution_block.py
PYTHONUTF8=1 python data/build/c1_accounting.py c2_production_trends.py c3_extraction.py c4_waste.py
julia --project=. ../data/build/c4_handling_level.jl      # from model/, then c4_waste.py again
PYTHONUTF8=1 python data/build/c5_preferences_damages.py c6_states.py c0_series.py c_metals.py
julia --project=. ../data/build/c7_checks.jl              # from model/; c8_smoke.jl likewise
PYTHONUTF8=1 python data/build/appendix_tables.py         # the %% GENERATED tables of the appendix
```

Each script names its inputs and outputs in its docstring; the block script of a `b` block runs
last within it. `c0_series.py` runs after the `c` blocks because it reads `calibration.json`.
`c4_handling_level.jl` solves the model to fit the level of the handling charges, so it sits between
two runs of `c4_waste.py`. The generated tables are never hand-edited.

## Method vocabulary

Every interim and processed row carries `source` and `method`, and the method is the claim the row
makes about itself:

- **observed** — the source's own number, read from a machine-readable file.
- **transcribed** — the source's own number, typed in from a published table with the page or table
  number in the script.
- **reconstructed** — built on an assumption the source does not make (the pre-1950 use split, the
  composed reserve path, the pollution stock at a fixed composition). Flagged at the row level.
- **fitted** — chosen so that something reproduces a target, with the target named in the script.
- **aggregated**, **derived**, **computed** — arithmetic on rows of the first two kinds.

A value that could not be obtained is empty and listed under *Not obtained* in `SOURCES.md`; it is
never replaced by an estimate.
