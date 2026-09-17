# Plan: from placeholder values to real simulations of E1 to E5 (drafted 2026-09-18)

The brief for a multi-night unattended run. It takes the quantitative model from the illustrative
parameters of `model/src/calibration.jl` to a calibrated baseline and the experiments of
`writing/quant/quant_calibration.tex`, Section *Experiments*. Every agent reads this file first,
then `CLAUDE.md`, `docs_style.md` §5 (where data documentation goes), `code_style.md` when it
touches `model/src/`, and `notes/data_plan_global_1850.md`, which is the source-by-source plan
this file schedules and does not repeat. Work lands on the branch `calibration`, one commit per
task, message `Cal <task id>: <what>`. No agent compiles tex or pushes to Overleaf.

## 0. Decisions taken (confirmed by RKB before launch; do not reopen)

| id | decision | choice |
|---|---|---|
| D1 | Which materials | All four material-flow categories on a mass basis as the baseline; metals only as the reported bound. `quant_calibration.tex` §*The aggregation cost of one material* already commits to this. |
| D2 | Base year | **1900, observed data.** 1850 with a backcast is a robustness variant (task B6), built only if time allows, never the baseline. `quant_model.tex` says the baseline starts at 1850; task E2 changes that sentence. |
| D3 | The waste stock $\mathcal W$ | The **broad reading**: cumulative outflows to controlled and uncontrolled disposal, less cumulative recovery. $\mu$ is then calibrated so that $\mu\mathcal W$ reproduces the observed handled flow. The specification tension the data plan §5 records (geometric draw versus age-dependent recovery) is written down in `notes/data/waste_stock.md`, not papered over. |
| D4 | Pollution | Strategy **(B) CO$_2$ as indicator** for the baseline, amended 2026-09-18 after B5: the model's transition adds $\Xi$ in tonnes of material to $P$, so $P$ is the stock of material that has reached the environment and has not regenerated, in gigatonnes of material; the CO$_2$ evidence is the bridge that prices it. The damage per tonne of $P$ is the integrated-assessment loss per GtCO$_2$ times the GtCO$_2$ released per Gt of $\Xi$ at the calibration-window composition (fossil share of the outflow times the CO$_2$ mass per tonne of fuel); the decay rate is the constant carbon-cycle decay B5 identified, since the exponential-decay form is not identified beyond a constant; $P_0$ is the 1900 atmospheric excess stock converted at the same ratio. Land-use CO$_2$ is outside the model and said so. Strategy (A) is a variant, recorded in `notes/data/pollution.md`. |
| D5 | Units | Goods in trillions of 2011 international dollars, material in gigatonnes, one period one year, pollution in gigatonnes of material (D4). `quant_model.tex` §*Period length and units* is updated to say so (E2). |
| D7 | Initial reserves (ruled 2026-09-18 after B3) | $S_0$ = cumulative extraction 1900 to the reserve vintage plus reserves at that vintage; $X_0=S_0$ plus pre-1900 extraction, a lower bound where the latter is unknown. The reserve stock and the discovery ceiling cover the exhaustible categories, fossil fuels and ores; construction minerals and biomass draw on sources whose stock effect is treated as nil over the horizon, and task C3 records how the one-material $S$ is composed and what the alternative would be. |
| D6 | Horizon | Baseline solved by continuation to the longest horizon `solve_long` reaches; results reported for 1900 to 2300; the terminal date and the diagnostics of `quant_solution.tex` §*Horizon* reported beside every table. |

## 1. Rules that every task obeys

- **No number from memory.** Every value in `data/` traces to a downloaded file or to a cited
  table with page or table number, recorded in `data/SOURCES.md` with full citation, URL, access
  date and licence. A value an agent cannot download is recorded as `MANUAL: <url>` in
  `data/SOURCES.md` and the task continues without it; the morning review downloads it. An agent
  that cannot obtain a series does not estimate a stand-in; it leaves the cell empty and says so.
- **Observed and reconstructed are different things.** Every processed series carries `source`
  and `method` columns; a reconstructed value is flagged at the row level.
- **Provenance beats convenience.** Raw files under `data/raw/<source>/` are never edited. One
  pipeline script per source under `data/build/`, Python, run with `PYTHONUTF8=1`, standard
  library plus pandas, openpyxl and pyarrow, which are installed. Interim files are long-format
  CSV, one row per (year, series, value, unit, source, method).
- **The three homes of data documentation** (`docs_style.md` §5): what a reader needs to
  reproduce a number goes in the quantitative note's data appendix; why we chose this over that
  goes in `notes/data/<area>.md`, one file per decision area; the transformation lives in the
  script. Nothing is stated in two of them.
- **Code invariants**: `julia --project=.` from `model/`; `model/src/` ASCII only; symbol clashes
  broken only in `model/SYMBOLS.md`; every new identifier for a document symbol goes in that
  table; the suite (825 today) ends green after every commit, count reported.
- **Faithful reporting.** A task that could not be finished says what was left and why. A solve
  that did not converge is reported as such with its residual. A number that looks wrong is
  reported as looking wrong, not adjusted.
- **Generated tex** is written under a `%% GENERATED by data/build/<script> on <date>` banner and
  never hand-edited; `overleaf.py` protects it.

## 2. Phases and dependencies

```
A (code readiness)  ─┐
                     ├─► C (calibration) ─► D (simulation) ─► E (review, write-up)
B (data pipeline)   ─┘
```
A and B run in parallel. C waits for all of B and for A3. D waits for C and all of A. E waits
for D. Inside a phase, tasks run in parallel unless a dependency is stated.

## Phase A: code readiness (parallel with B)

### A1. The shutdown branch — Fable
TODO 7. `solve_with_shutdown` stalls just short of tolerance on about a quarter of candidate dates
and is untested. Read `model/src/solver.jl`, `terminal.jl`, `model/README.md` *Known
limitations*. Diagnose the stall on a floor calibration (`baseline_params(Rbar = 0.35)`) over a
grid of dates: is it the homotopy step in `Rbar`, the smoothing schedule, or the terminal value
function's derivative at the handover? Fix what is fixable; where a date genuinely does not admit a
solution, make the search skip it with a recorded reason rather than stall. Add a `@testset`
that runs the date search on that calibration and asserts convergence on every date the search
visits, or a documented skip. Update *Known limitations*. Acceptance: the testset is green and
the README no longer calls the branch fragile, or it says exactly which dates fail and why.

### A2. The shutdown handover — Fable, after A1
TODO 8. `V_stop` imposes $p^M=0$ at the handover and its legacy stream omits the material the
eaten capital releases, $\delta M^K_t$ (the theory note records this beside the formula in
`Appendix_proofs.tex`). Implement the inflow: after the shutdown $M^K$ decays at $1-\delta$ (plus
whatever scrapping releases), the waste it releases enters $\mathcal W$, and the legacy stream is
$\mu\mathcal W_t$ with that inflow. Then decide $p^M$ at the handover from the same recursion.
Measure the change in $V^{\mathrm{stop}}$ and in the optimal shutdown date on the floor
calibration; if below one percent of the value, the approximation may stay with the measurement
recorded in the README; otherwise the implementation becomes the default. Either way: a test, the
README, and one sentence in `Appendix_proofs.tex` beside `eq:app:wh:Vstop` if the formula changed
(that is the one file under `writing/` this task may touch).

### A3. The calibration interface — Opus
`model/src/calibration.jl` gains `calibrated_params(path)` and `calibrated_states(path)` that read
`data/processed/calibration.json` (schema below) into `Params` and the six initial states, with
unit conversion per D5 performed in the pipeline, not in Julia. `baseline_params()` stays as the
illustrative set, renamed in its docstring to say so. A `@testset` reads a fixture JSON committed
under `model/test/fixtures/` and round-trips it. Schema, one JSON object:
```
{ "meta": {"base_year": 1900, "units": {...}, "built_by": "...", "date": "..."},
  "params": { "<julia field name>": {"value": x, "low": x, "high": x, "source": "<notes/data file or appendix subsection>"} , ... },
  "states": { "K0": ..., "S0": ..., "X0": ..., "P0": ..., "MK0": ..., "W0": ... },
  "cases": { "abar": [1.0, 0.85], "Rbar_grid": [...], "xi_range": [lo, hi], "muN_range": [lo, hi] } }
```
Field names are the Julia identifiers of `model/SYMBOLS.md`. Missing `low`/`high` means a point.

### A4. The experiment harness — Opus, after A3
`model/scripts/run_experiments.jl` with one function per experiment, each writing CSV under
`model/output/<experiment>/` and a `%% GENERATED` tex table under `writing/quant/Tables/`:
- **E1** `experiment_taxonomy(p, s0)`: solve by `solve_long`, run `check_path`, `tvc_report`,
  `wellposed_report`, `classify_longrun`; report the state, $\mathcal M_\infty$, $\mathcal T$,
  the survival ratio, the shutdown date if any, the date the gate fee changes sign, and the
  horizon diagnostics. One row per case in `cases`.
- **E2** `experiment_circularity(p, s0; abar_grid, xi_grid)`: for each $(\bar a,\xi)$, the welfare
  gain relative to the no-recycling counterfactual (defined as $\bar a\to0.01$, so the recycling
  margin hits its corner; state the definition in the table note), the length of the material
  era where it ends, cumulative $\Xi$. In the collapse cells also the Hotelling check
  $\Psi_{t+1}/\Psi_t$ against $1+r_{t+1}$.
- **E3** `experiment_instruments(p, s0)`: the 16 corners of $(\phi^W,\phi^z,\phi^P,\phi^X)$ plus
  the four single-dial paths from the planner corner in steps of 0.25; welfare in consumption
  equivalents, and the classification at each point, so that a crossing of the survival margin
  shows up as a change of state.
- **E4** `experiment_gatefee(p, s0)`: the gate fee path and its sign-change date under
  $\phi^W=1$ at the planner corner and at the laissez-faire corner of the other three dials.
- **E5** `experiment_surface(p, s0; Rbar_grid, abar_cases)`: E1's headline numbers as a surface.
Each function takes an `hours` budget and stops cleanly, writing what it has, when exceeded.
Solves reuse the previous grid point as the starting guess (continuation in the parameter). A
test runs each function on the illustrative set with tiny grids and `T = 40` and checks the files
appear with the expected columns.

### A5. The horizon wall — Opus, after A4, informational
TODO 9. On the illustrative set, record where `solve_long` stops and why (the $(S_{\mathrm{ref}}/S)^{\mu_N}$
conditioning). Do not change the model. Write the finding to the README so that phase D knows
what to expect on a calibration that depletes faster.

## Phase B: the data pipeline (parallel with A; Opus, one agent per block)

Each block: download into `data/raw/<source>/`, add the `data/SOURCES.md` entry, write
`data/build/<source>.py` producing `data/interim/<source>.csv`, and write or extend
`notes/data/<area>.md` with the alternatives, the reason and the date. The `data/` layout is §8
of the data plan; create it. Each agent reports every series it produced with years covered, and
every series it could not obtain.

### B1. The core material block — Opus
Sources: Krausmann et al. 2018 (GEC 52, open access, supplementary annual series 1900–2015:
extraction by category, stock additions, outflows, recycling, DPO); Krausmann et al. 2017 (PNAS,
in-use stocks 1900–2010 by material group); Haas et al. 2015 and the 2020 update (end-of-life
recycled share of input); UN IRP Global Material Flows Database (1970–2024, DE by category, for
the recent end and consistency). Produce, global, 1900–2020 where the sources allow, by the four
categories and in total: used extraction `N`, unused extraction (overburden) for $\Omega^{N,S}$,
secondary input `RR`, total material input `R`, waste generation `W` (outflows plus waste to
stock), DPO as the counterpart of $\Xi$, in-use stock `MK`, and the cumulative-disposal series
that D3 turns into `Wstock`. Where two sources overlap, keep both and record the discrepancy in
`notes/data/material_flows.md`. This block is where the paper's contribution rests; take the
time it needs.

### B2. Macro aggregates and the use split — Opus
Maddison Project Database 2023 (global GDP and population 1820–2022); Penn World Table 10.01
(capital stock, investment share, 1950–2019); a perpetual-inventory capital stock 1900–1950 from
Maddison GDP and historical investment shares, cross-checked against Piketty and Zucman 2014
wealth–income ratios and flagged reconstructed. The GDP use split into consumption and gross
capital formation (PWT shares; pre-1950 assumed at the 1950 split and flagged). Output: `Y`, `C`,
`G`, `K` in D5 units, 1900–2020, and the model's activity aggregate $\mathcal D+\phi^IG$ once B1's
weights exist (a second script that joins B1 and B2 produces `Omega` on the model's definition).

### B3. The resource side — Opus
Jacks 2019 real commodity prices 1850–2015 (his public dataset); USGS Data Series 140 (long US
production and price series); USGS Mineral Commodity Summaries (reserves and reserve base by
commodity, latest); Global Carbon Budget fossil CO$_2$ back to 1750 with standard carbon
contents for fossil mass; ore-grade and energy-per-tonne evidence (Mudd 2010; Calvo, Mudd, Valero
and Valero 2016; West 2011), which is a literature assembly: tabulate the reported grade and
energy series with citations. Reserves and resources: `S0` constructed as cumulative extraction
since 1900 plus current reserves less extraction to date, by category; `X0` as cumulative
extraction plus current reserves; $\bar X_{\max}$ as a **range** from Rogner et al. 2012 (fossil),
BGR Energy Study, Rankin 2011 and the USGS assessments (metals). Exploration: Schodde's public
MinEx series on discoveries per exploration dollar; S&P World Exploration Trends is commercial,
record as MANUAL if the public summaries do not carry the numbers. `notes/data/resources.md`
records the depletion-versus-technology identification problem for $\mu_N$ and the two channels
(prices, ore grades).

### B4. Waste handling and recycling — Opus
Kaza et al. 2018, *What a Waste 2.0* (World Bank, open data: MSW generation, treatment shares,
open dumping, unit costs of collection and disposal by income group); UNEP Global Waste
Management Outlook 2024; UNEP IRP 2011 *Recycling Rates of Metals* (Graedel et al.) and Graedel
et al. 2011; Reck and Graedel 2012; Cullen 2017; the Circularity Gap Report for the headline
aggregate. Output: treatment and dumping shares for $\varpi_0$ and $d^W$; collection and disposal
unit costs for $c^c$ and the level of $c_T$; the cost gradient of coverage (OECD and Eurostat
waste statistics, cost against treatment share across countries) for $\chi_T$; end-of-life
recycling rates by metal for the metals-only bound; the recovery-cost gradient evidence for $\xi$
as a range, assembled from engineering process-cost studies where public. `notes/data/waste_recycling.md`
records that $\xi$ is the thin spot and what was and was not found.

### B5. Pollution and damages — Opus
Strategy (B): cumulative fossil CO$_2$ from the Global Carbon Budget (also used in B3); the mapping
from the fossil share of $\Xi$ to CO$_2$ mass; a carbon-cycle decay approximation expressed in the
model's form $\theta(P)=\theta_{\min}+(\theta_0-\theta_{\min})e^{-\theta_PP}$, fitted to a
standard impulse response and recorded as an approximation; a damage function from a standard
integrated-assessment model (DICE-2023 or the Barrage and Nordhaus update) giving $\kappa$, with
$\psi,\varphi$ for the utility channel set from the same source's split or to zero with the
reason. `P_0` at 1900. `notes/data/pollution.md` records strategy (A) and what it would need.

### B6. The 1850 backcast — Opus, only if B1 to B5 are complete with time left
Data plan §2b: fossil mass 1850–1900 from CDIAC; metals from Schmitz 1979 and Mitchell (tabulated
from the volumes if accessible, else MANUAL); biomass and construction minerals backcast with
population and the 1900–1950 elasticities, every row flagged reconstructed. Output: the B1 series
extended to 1850 in a separate file, never merged into the baseline.

## Phase C: calibration (Fable, one agent, sequential; after all of B and A3)

Reads every `data/interim/` file, `notes/data/*.md`, the identification table of
`quant_calibration.tex` and the identification map of the data plan §4. Produces
`data/processed/calibration.json` (schema of A3), `data/processed/series.csv` (the model-facing
series with provenance columns), `writing/quant/quant_data.tex` (the data appendix, one
subsection per target: source, what was taken, the transformation in words, the number; tables
generated by `data/build/appendix_tables.py` under the banner), and a decision file per block
where B did not already write one. Order:

- **C1 accounting** $\omega^j,\phi^I,\Omega^{N,S},\Omega^{D,S}$ from B1's flows by source and the
  in-use stock additions; the best-identified block.
- **C2 production and trends** $\beta,\mu_F,\delta$ from capital and material shares of gross
  output and $K/Y$; $\varsigma$ from the long-run price elasticity of material demand (B3 prices
  against B1 quantities); $(g_A,g_B)$ jointly from output growth and the decline of `Omega` on the
  model's definition, with the over-identification test reported: does one pair fit both series?
- **C3 extraction and exploration** $\mu_N$ as a range from the two channels of B3; $c_N$ level
  from the extraction share of GDP; $S_{\mathrm{ref}}$ a normalisation; $\mu_D,c_D$ from discoveries
  per exploration dollar; $\bar X_{\max}$ as the range of B3; $\kappa_N,\chi_N,\kappa_D,\chi_D$
  from the marginal-cost shape the sources support, with the convexity condition (C3) of the
  sufficiency appendix reported (the finite choke breaks joint convexity; say so, do not hide it).
- **C4 waste and recycling** $\mu$ from D3 ($\mu\mathcal W_{2015}$ equals the handled flow);
  $c^c,c_T,\chi_T,d^W$ from B4; the two ceiling cases $\bar a\in\{1,\bar a_H\}$ with $\bar a_H$ the
  mass-weighted maximum the recycling-rate evidence supports; $\xi$ as a range; the tail family
  `:exp` with `:power` as the sensitivity, and $\psi\le1$ if the power tail is used (concavity).
- **C5 preferences and damages** $\rho,\eta$ from the long-run real rate and the consumption–
  wealth ratio, then checked against the five conditions of `wellposed_report` at the C-cell rate
  and at the B-cell rates; if $\eta$ from the data violates the collapse ranking condition, report
  the conflict and choose the value the theory requires, recording the data value beside it.
  $\kappa,\psi,\varphi$ from B5.
- **C6 initial stocks** at 1900 from B1 to B5; `K0` reconstructed and flagged.
- **C7 checks**: `check_params`, `convexity_report`, `wellposed_report` on the calibrated set,
  outputs quoted in the appendix; the metals-only bound as a second JSON.

Acceptance: `calibrated_params("data/processed/calibration.json")` loads; every parameter has a
`source`; the appendix has one subsection per target; no number appears in prose that is also in
a table; `notes/data/` has a file for every decision area named in this plan.

## Phase D: simulation (after C and all of A)

### D1. The calibrated baseline — Fable
Run `experiment_taxonomy` on the baseline and the metals bound. Report the horizon reached,
`check_path`, `tvc_report`, `wellposed_report`, `classify_longrun` with its margins, and the
market–planner residual gap. If `solve_long` stops before the path has settled (the criterion of
`quant_solution.tex` §*Horizon*: the window of interest moves by more than $10^{-3}$ when $T$ is
extended), report it as the horizon wall biting and do not proceed to D2 to D5 on that
calibration; instead characterise what would be needed (a reformulated extraction cost near
$S=0$ is a model change and is not made here). Run `scripts/run_sufficiency.jl` on the baseline.

### D2. E2, E4 — Opus, after D1
`experiment_circularity` on the grids of `cases`; `experiment_gatefee`. Report the tables and
anything that looks wrong.

### D3. E3 — Opus, after D1, parallel with D2
`experiment_instruments`. Report every corner's classification; any corner whose state differs
from the planner's is the headline and gets its own paragraph in the report, with the survival
ratio at that corner.

### D4. E5 — Opus, after D2 and D3
`experiment_surface` over the $\bar R$ grid and both ceiling cases, with the budget set so that it
finishes; report the grid actually completed.

## Phase E: review and write-up (after D)

### E1. Adversarial review — Fable
Reads everything phases B to D produced. Checks: every number in `calibration.json` traces to a
source through `notes/data/` or the appendix; units are consistent with D5 throughout; the
processed series satisfy the ledger identity where the data allow (extraction plus secondary
input equals waste plus stock additions, within the sources' own closure error, reported);
`Omega` on the model's definition is consistent with the published intensity; the classification
of D1 is consistent with the theory (a state C path has $a\varpi\to1$, a state A path has a
shutdown date); signs of the gate fee and of $\zeta$ match Appendix B's readings for the state
reached; the E3 headline, if any, survives a perturbation of the two least-identified parameters
($\mu_N$, $\xi$) across their ranges. Writes `notes/review_calibration.md` with findings ranked,
and fixes nothing itself.

### E2. Write-up — Fable, after E1
`writing/quant/quant_results.tex`, a new section after *Calibration and experiments*, one
subsection per experiment, prose that says what the tables show and cites them (`docs_style.md`
§2 and §4: table inputs on their own line, notes in `threeparttable`, no number repeated in
prose). `quant_model.tex` updated for D2 and D5. `main.tex` inputs the two new files. The review's
findings that change a claim are applied; those that need data are listed in `notes/TODO.md`.

### E3. Docs and logs — Opus, after E2
`model/README.md` (file map, how to run the experiments, what is verified, limitations),
`model/SYMBOLS.md` (any new identifier), `data/SOURCES.md` complete, `notes/TODO.md` (close 5,
6, 7, 8 as applicable; add what E1 found), one entry in each `RESEARCH_LOG.md`. Leave the branch
unmerged and Overleaf untouched.

## What is not in this plan
The paper. A multi-material model. Reformulating the extraction cost to remove the horizon wall.
Strategy (A) for pollution beyond recording it. Anything the data plan lists as commercial.
