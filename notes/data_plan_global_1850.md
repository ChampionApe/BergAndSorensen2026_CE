# Data plan: calibrating the quantitative model to the global economy from ~1850

Working note. Purpose: say exactly which observables the quantitative model of
`writing/quant/quant_*.tex` needs, where each comes from, what has to be constructed, and in
what order to do the work. Nothing here is settled; it is a plan with fallbacks.

## 0. The short version

Five things drive everything else, and they are not equally hard:

| | What we need | Difficulty | Why |
|---|---|---|---|
| 1 | Global material extraction and waste flows, by broad material class, 1850–present | **Medium** | Solid 1900–2015 (Krausmann et al.); 1850–1900 must be backcast |
| 2 | Global in-use material stock `M^K` and the post-discard stock `𝒲` | **Hard** | `M^K` exists (Krausmann 2017); `𝒲` depends on an interpretation choice, see §5 |
| 3 | Real material prices against cumulative extraction, 1850–present | **Medium** | Jacks (2019) covers it; separating depletion from technical progress is the hard part |
| 4 | Reserves `S₀`, cumulative discoveries `X₀`, and the ceiling `X̄_max` | **Hard** | Reserves are an economic, not geological, concept; `X̄_max` is a judgement |
| 5 | Recycling yields and the cost gradient of pushing them higher | **Hard** | Aggregate recycling rates exist; the *gradient* is what identifies `ξ` and is thinly evidenced |

Two parameters are **not identifiable from history at all** — the material floor `R̄` and whether
the yield ceiling `ā` is hard or soft — and the docs already treat them as case dimensions rather
than as estimates. That is deliberate and should not be quietly reversed by a clever
identification scheme.

## 1. Mapping model objects to observables

The model's advantage is that most of its material block is measured in tonnes and material flow
accounting reports tonnes. The mapping is direct, with three places where it is not.

| Model object | Observable counterpart | Standard MFA term |
|---|---|---|
| `N` virgin extraction (t/yr) | used domestic extraction, global | **DE (used)** |
| `Ω^{N,S}·N` overburden displaced | unused extraction / hidden flows | **UDE**, "unused domestic extraction" |
| `R = N + R^R` material input to production | DE + recycled input | DMI-like, but net of imports (global = closed) |
| `R^R` secondary material | end-of-life recycled input | **EOL-RIR** numerator |
| `W` waste generation | total outflows from the socioeconomic system | ≈ **DPO + waste to stock** |
| `H = μ𝒲` handled flow | collected + processed waste | waste "managed" |
| `ϖ` treated share of handled flow | share not openly dumped/burned | 1 − open-dumping share |
| `Ξ` emissions to environment | dissipative + landfilled-with-leakage outflows | **DPO** |
| `M^K` material in capital | in-use socioeconomic material stock | **in-use stock** |
| `𝒲` waste stock | see §5 — interpretation choice | (no standard series) |
| `Ω` material intensity | DMI per unit GDP | material intensity |
| `Y`, `C`, `I`, `K` | global GDP, consumption, investment, capital stock | national accounts |
| `P` pollution stock | see §6 — proxy choice | — |

Three mismatches to keep visible:

- **Trade.** All MFA series are national or regional; the model is global and closed. Global
  aggregation removes the trade problem entirely, which is one of the better reasons to calibrate
  globally rather than to a single economy. But the *global* aggregates in the databases are
  themselves sums of national accounts with known inconsistencies at the RMC level; use DE-based
  aggregates, not consumption-based ones.
- **`Y` is a composite.** The model's final good is the whole economy's output, and material
  intensities `ω^j` differ by use. Mapping requires splitting global GDP into the five uses
  (production overhead, extraction, exploration, waste handling, consumption) plus gross capital
  formation. Extraction and exploration are small shares of GDP and their `ω` are near-irrelevant;
  the split that matters is consumption vs gross capital formation, which national accounts give.
- **Fossil fuels.** They are ~a quarter of global DE by mass and are dissipated by construction —
  `a = 0` for them. A single-material calibration that includes them mechanically caps circularity.
  See §7 on the aggregation decision.

## 2. Sources, block by block

### 2a. Material flows and stocks (the core)

Priority order for acquisition:

1. **Krausmann, Wiedenhofer, Lauk, Haas, Tanikawa, Fishman, Miatto, Schandl, Haberl (2017),
   "Global socioeconomic material stocks rise 23-fold over the 20th century", PNAS 114(8).**
   Gives in-use stocks 1900–2010 by material group. This is `M^K`.
2. **Krausmann, Lauk, Haas, Wiedenhofer (2018), "From resource extraction to outflows of wastes
   and emissions: the socioeconomic metabolism of the global economy, 1900–2015",
   Global Environmental Change 52.** The single most useful paper for this project: extraction,
   stock build-up, outflows, recycling, DPO, all globally consistent, all 1900–2015. Supplementary
   material carries the annual series.
3. **Krausmann, Gingrich, Eisenmenger, Erb, Haberl, Fischer-Kowalski (2009), "Growth in global
   materials use, GDP and population during the 20th century", Ecological Economics 68.**
   Extraction 1900–2005, four material categories. Useful cross-check and longer commodity detail.
4. **Haas, Krausmann, Wiedenhofer, Heinz (2015), "How circular is the global economy?",
   J. Industrial Ecology 19(5)**, and the 2020 update. Gives the EOL recycling share of material
   input — the direct empirical counterpart of `a·ϖ` in the ledger.
5. **UN IRP Global Material Flows Database** (materialflows.net / UNEP IRP). 1970–2024,
   by country and material, DE/DMC/RMC/RMI. Free download, annual updates. Use for the recent end
   and for consistency checks against (2).
6. **Wiedenhofer, Fishman, Lauk, Haas, Krausmann (2019)**, and the **MISO2** stock-flow model
   (Wiedenhofer et al., 2024) if the code/output is public — a dynamic stock-flow-service model
   for global material cycles. If accessible, this is the closest existing empirical analogue of
   the model's material block and worth reconciling against directly.

Access notes: (1)–(4) are journal articles with data in supplementary files; expect XLSX. (5) is a
web database with bulk CSV. None require licences.

### 2b. Extending back to 1850

Nothing in §2a starts before 1900. Three routes, to be used together:

- **Fossil fuels 1850–1900.** Global Carbon Budget / CDIAC fossil-fuel CO₂ back to 1751 converts
  to fossil mass with standard carbon contents. Also Etemad & Luciani, *World Energy Production
  1800–1985*. This block is genuinely good back to 1850.
- **Metals 1850–1900.** Schmitz, *World Non-Ferrous Metal Production and Prices 1700–1976* (1979)
  is the standard source. Mitchell, *International Historical Statistics* (three volumes) gives
  national production of pig iron, coal, copper, lead, tin back to the 18th century. USGS
  *Historical Statistics for Mineral and Material Commodities in the United States* (Kelly & Matos,
  Data Series 140) has some series from the 1800s. Sum national series to a world total, accepting
  coverage gaps in the periphery.
- **Biomass and construction minerals 1850–1900.** No direct series exists. Backcast, and be
  explicit that it is a backcast: biomass roughly with population (Krausmann's own long-run
  reconstruction of biomass use is the reference); construction minerals with a
  population × urbanisation × income elasticity relation estimated on 1900–1950 and extrapolated.
  Report the 1850–1900 window as reconstructed rather than observed, and check that no headline
  result depends on it. Given that the model's cumulative bounds are what matter, an error in the
  first fifty years of a 1.5-century sample is second-order for `M^K₀` but not for `X₀`.

**Fallback if the backcast proves unstable:** start the model in 1900, where the data are real,
and treat 1850 as a robustness variant. The model does not need 1850; the paper's narrative does.
Do not let the narrative drive the base year.

### 2c. Macro aggregates

- **Maddison Project Database 2023** (Bolt & van Zanden, Groningen). Global GDP and population,
  1820–2022. Free.
- **Penn World Table 10.01** for capital stocks and investment shares, 1950–2019.
- **Capital stock 1850–1950:** perpetual inventory from Maddison GDP and historical investment
  shares; cross-check against Piketty & Zucman (2014) national wealth–income ratios for the major
  economies. Expect wide bands; the model's `K₀` in 1850 is small relative to later values and the
  path is not sensitive to it.

### 2d. Prices and the extraction cost function

The parameter `μ_N` — the stock-effect elasticity of extraction costs — is by
`eq:app:wh:bdp-solution` the parameter that selects between growth, a constant consumption level
and decline in the floorless benchmark. It is identified by the response of real material prices
to cumulative depletion, holding extraction technology fixed, and the identification problem is the
classic one: observed real commodity prices have been roughly flat-to-falling for 150 years
because technical progress in extraction has run against depletion.

- **Jacks (2019), "From boom to bust: a typology of real commodity prices in the long run",
  Cliometrica** — real prices for ~40 commodities, 1850–2015, deflated consistently. The primary
  source. Jacks maintains the dataset publicly.
- **Harvey, Kellard, Madsen, Wohar (2010)** for very long-run (1650–2005) relative primary
  commodity prices, for the trend question.
- **Grilli & Yang (1988)** with the **Pfaffenzeller, Newbold & Rayner (2007)** update, for the
  standard index.
- **USGS Data Series 140** for commodity-specific real prices and US production, long series.
- **Ore grades:** Mudd (2010, *Resources Policy*) on Australian mining; Calvo, Mudd, Valero &
  Valero (2016) on declining ore grades and rising energy per tonne; West (2011). Declining grade
  at rising energy intensity is the physical mechanism behind `C^N_S < 0` and is the most direct
  evidence on `μ_N` that does not go through prices. **Prefer this channel**: energy per tonne of
  metal against cumulative extraction identifies the stock effect without the price/technology
  confound, and technical progress can then be estimated as the residual.

### 2e. Reserves, discoveries and the exploration frontier

- **USGS Mineral Commodity Summaries** (annual, free): reserves and reserve base by commodity.
  Note that "reserves" is an economic concept that moves with price — the model's `S` is closer to
  it than to a geological quantity, which is convenient, but it means `S₀` in 1850 is not
  observable and must be constructed as (cumulative extraction since 1850) + (reserves today) +
  (an assumption about what was known then).
- **`X₀` cumulative discoveries:** construct as cumulative extraction plus current reserves.
  This is the only defensible route and it makes `X` an accounting object.
- **`X̄_max`:** the ultimately recoverable resource. For fossil fuels, Rogner et al. (2012, GEA
  Chapter 7) and BGR's annual *Energy Study*. For metals, crustal-abundance-based estimates
  (Skinner's "mineralogical barrier"; Rankin, *Minerals, Metals and Sustainability*, 2011) and the
  USGS Global Mineral Resource Assessment. **This is a judgement parameter and should be reported
  as a range, with the results shown as a function of it.**
- **Exploration expenditure and discovery:** S&P Global Market Intelligence *World Exploration
  Trends* (nonferrous exploration budgets, 1975–present) and Richard Schodde's MinEx Consulting
  long-run series on discovery rates and cost per discovery. These identify `C^D` and `μ_D`
  directly: falling discoveries per exploration dollar is the empirical content of `C^D_X > 0`.
  S&P data are commercial; Schodde's presentations are public and contain the key charts and often
  the underlying numbers.

### 2f. Waste handling, treatment and costs

- **Kaza, Yao, Bhada-Tata, Van Woerden (2018), *What a Waste 2.0*, World Bank.** MSW generation,
  composition, collection coverage, treatment shares and **unit costs of collection and disposal
  by income group**. The cost numbers are what identify `c^c` and the level of `c_T`. Free.
- **UNEP Global Waste Management Outlook 2024** for updated treatment and open-dumping shares.
- **OECD Environment Statistics** and **Eurostat waste statistics** for the treatment-cost gradient
  in high-coverage economies — i.e. what it costs to push `ϖ` from 0.8 to 0.95, which is what
  identifies `χ_T`.
- `ϖ` globally: roughly 1 − (open dumping + uncontrolled burning share). *What a Waste 2.0* puts
  open dumping at about a third of global MSW; note that MSW is a small share of total material
  outflow, so this cannot be applied to the aggregate without adjustment. Use the MFA outflow
  decomposition in Krausmann et al. (2018) instead, with the MSW numbers as a sanity check.
- `d^W` (share of treated-stream material that still leaks): weakly evidenced. Set from landfill
  leakage and process-loss estimates and treat as a sensitivity dimension.

### 2g. Recycling yields and the cost gradient

- **UNEP IRP (2011), *Recycling Rates of Metals: A Status Report*** (Graedel et al.) — the standard
  source for end-of-life recycling rates by metal. Gives the cross-sectional spread that a
  single-material model has to aggregate over.
- **Graedel et al. (2011), "What do we know about metal recycling rates?", J. Ind. Ecol.**
- **Reck & Graedel (2012), "Challenges in metal recycling", Science** — on why yields plateau.
- **Cullen (2017), "Circular economy: theoretical benchmark or perpetual motion machine?",
  J. Ind. Ecol.** — thermodynamic limits on recovery; directly relevant to the hard/soft ceiling
  distinction and already cited in the docs.
- **Circularity Gap Report** (Circle Economy, annual) for the headline global circularity metric,
  useful as a target for `a·ϖ` in the aggregate but constructed on a mass basis that includes
  fossil fuels and should not be used uncritically.

The **gradient** `ξ` is the thin spot. What is needed is cost or energy per tonne recovered as a
function of the recovery rate achieved — i.e. the marginal cost of the last few percent. Candidate
routes: (i) engineering process-cost studies for specific streams (aluminium, steel, e-waste,
plastics sorting); (ii) the observed spread between recovery rates and unit costs across countries
and streams, treated as a cross-section identifying the curve; (iii) sorting-technology cost
curves from the materials-recovery-facility literature. Expect to end with a range, not a number.

### 2h. Pollution and damages

The model's `P` is a generic pollution stock fed by `Ξ` (tonnes of material reaching the
environment) with regeneration `θ(P)`. Two calibration strategies, and the choice should be
explicit:

- **(A) Materials-as-pollution.** `P` = accumulated dissipative material outflows; damages
  calibrated to health and ecosystem costs of waste and pollution (Global Burden of Disease
  attributable burdens; OECD estimates of the welfare cost of air pollution). Internally
  consistent with the ledger, but the damage evidence is thin and the regeneration function
  `θ(P)` has no natural counterpart.
- **(B) CO₂-as-indicator.** `P` = cumulative CO₂, `Ξ` proportional to the fossil share of `Ξ`;
  damages from a standard integrated-assessment damage function. Well-evidenced and comparable to
  the literature, but it prices only one component of the outflow and makes `θ(P)` the carbon-cycle
  decay function, which is not a regeneration floor of the assumed form.

**Recommendation:** run (B) as the baseline because it is defensible and comparable, run (A) as a
variant, and be explicit that the pollution block is the least tightly identified part of the model
and the one on which the paper's results depend least — the taxonomy of the long-run section turns
on the material block, not on damages.

## 3. Series to construct (not download)

1. **Global `R` series:** DE (used) + estimated secondary input, 1850–present.
2. **Global `Ω` series:** `R` divided by the model's activity aggregate `𝒟 + φ^I·G`, which requires
   the GDP-use split. This is the series that over-identifies `(g_A, g_B)` and it deserves care.
3. **`M^K` back to 1850:** extend Krausmann (2017) by perpetual inventory on the constructed
   pre-1900 flows.
4. **`𝒲₀` and the `𝒲` path:** see §5.
5. **`S₀`, `X₀`:** as in §2e, from cumulative extraction plus reserves.
6. **A cumulative-extraction index per material class**, to run against real prices and ore grades
   for the `μ_N` identification.

## 4. Identification map (what pins what)

| Parameter | Identified by | Confidence |
|---|---|---|
| `ρ, η` | long-run real interest rate; consumption–wealth ratio | standard |
| `β, μ_F, δ` | capital and material shares of gross output; K/Y; depreciation | standard |
| `ς` | long-run price elasticity of material demand | medium |
| `g_A, g_B` | jointly from output growth **and** the decline in `Ω` | **good** — the model over-identifies these |
| `μ_N, c_N(t)` | real price and/or energy-per-tonne against cumulative extraction | **weak** — the central identification problem |
| `μ_D, c_D(t), X̄_max` | discoveries per exploration dollar over time; URR estimates | weak |
| `ā` | not identified; case dimension | — |
| `ξ` | cost/energy gradient of recovery at high recovery rates | weak |
| `μ` | mean residence time in the post-discard stock — see §5 | depends on interpretation |
| `c^c, c_T, χ_T` | unit collection/disposal costs and their gradient in coverage | medium |
| `d^W, ϖ₀` | open-dumping share; leakage from treated streams | medium |
| `ω^j, φ^I` | waste generation by source; material embodied in construction and durables | **good** |
| `Ω^{N,S}, Ω^{D,S}` | unused domestic extraction / overburden ratios; stripping ratios | **good** |
| `R̄` | not identified; the object of the exercise | — |
| `κ, ψ, φ` | damage function assumption, §2h | weak |

The pattern is worth noting because it is favourable in an unusual way: the **accounting**
parameters, which a conventional model would have to assume, are the best identified here, while
the **resource-side** parameters, which a conventional model would take from the resource
literature, are the weak ones. That is the right way round for this paper, whose contribution is
the accounting.

## 5. The interpretation of `𝒲` — decide this early

`𝒲` is defined in the docs as the stock of waste held within the economy: landfills, stockpiles,
discarded durables. Two readings give calibrations that differ by orders of magnitude:

- **Narrow (pipeline) reading.** `𝒲` is waste after discard and before handling. Empirically this
  is small — most discarded material is collected within months — so `μ` is near 1 and `𝒲` is
  roughly one year's waste flow. Since 2026-09-17 the theory admits `μ = 1` as the one-period
  buffer and every result holds there, so the narrow reading is a legitimate corner; what it loses
  is the stockpile as a stock distinct from the flow, and with it the "last mine" content.
- **Broad (landfill-as-reserve) reading.** `𝒲` includes accumulated landfilled and stockpiled
  material, i.e. everything ever discarded and not recovered. Then `𝒲` is enormous — a century of
  outflows — and `μ` is small, a few percent per year at most, since only a tiny fraction of the
  accumulated stock is ever mined.

The broad reading is the one the theory is built for: it is what makes the stockpile a genuine
asset, gives the "waste is the last mine" result content, and makes the survival condition
`μ·ℬ > R̄` a real constraint. It is also what the extension "handling share `μ` as a control"
(landfill mining) presumes. **Recommend the broad reading**, and note that the two readings are
partially reconciled by the residence-time formula `𝒯 = 1/μ + σ/δ` of the circular-growth section:
what the model's long run actually depends on is the *total* time a tonne spends immobile, which
is measurable in either reading.

Construction: `𝒲_t` = cumulative outflows to controlled and uncontrolled disposal, minus cumulative
recovery from those stocks (which is close to zero historically). Krausmann et al. (2018) provides
the outflow series to cumulate. `μ` is then calibrated so that `μ·𝒲` matches the observed
processed-waste flow — which will yield a small `μ`, as expected.

**Caution:** under the broad reading, `μ·𝒲` should reproduce the observed handled flow, and the
observed handled flow is dominated by *recent* discards, not by landfill mining. The model's
geometric residence assumption spreads handling evenly over the stock and will not match that
composition. This is a genuine specification tension between the theory's tractable geometric
draw and the data's strongly age-dependent recovery. Record it; the honest fixes are either a
two-stock version (pipeline plus landfill, different `μ`) or the endogenous-`μ` extension already
listed in the docs. Do not paper over it in the calibration.

## 6. Practical sequencing

**Phase 1 — get the model running on plausible numbers (no data work).**
Hand-set a parameter vector from the ranges above, verify the solver, the identities and the
planner/market equivalence. This is a prerequisite for knowing which parameters the results are
actually sensitive to, and therefore for allocating the data effort.

**Phase 2 — the core material block.**
Krausmann (2017, 2018), Haas (2015/2020), UN IRP database. Build `R`, `W`, `M^K`, `𝒲`, `Ω`
for 1900–2020. This is the block the paper's contribution rests on and it is the block where the
data are good.

**Phase 3 — macro and the GDP-use split.**
Maddison, PWT, national accounts split. Produces `Ω` on the model's own definition and hence the
`(g_A, g_B)` identification.

**Phase 4 — the resource side.**
Jacks prices, ore grades, reserves, exploration. Deliver `μ_N` as a *range* with an explicit
statement of the depletion/technology identification problem, not as a point estimate.

**Phase 5 — the 1850–1900 backcast**, and only if Phase 2–4 results turn out to depend on it.

**Phase 6 — recycling gradient and waste costs**, which is a literature-assembly exercise more than
a data-download one.

## 7. Two decisions to take before any downloading

1. **Which materials.** Options: (a) all four MFA categories on a mass basis (dominated by
   construction minerals and fossil fuels, mechanically low circularity); (b) metals only
   (high circularity, small mass share, but the material for which the "last mine" story is real);
   (c) all-but-fossil. The docs commit to reporting (a) as the baseline and (b) as a bound.
   **Take this decision before building series**, because it determines every aggregate.
2. **Base year.** 1850 with a backcast, or 1900 with real data. See §2b. The cost of 1850 is a
   reconstructed half-century; the benefit is covering the industrial transition. Decide against
   the criterion "does any headline result move", which requires Phase 1 first.

## 8. Repository conventions for `data/`

```
data/
  raw/            # exactly as downloaded, never edited; one subdir per source
    krausmann2018/
    unep_irp/
    maddison2023/
    jacks2019/
    ...
    SOURCES.md    # one entry per source: full citation, URL, access date, licence, file list
  interim/        # per-source tidy long-format parquet/csv, one row per (year, series, value)
  processed/      # the model-facing series, with units and provenance columns
  build/          # scripts; python, one script per arrow raw -> interim -> processed
```

Rules: raw files are immutable and committed only if small and licence-permitting (otherwise
recorded in `SOURCES.md` with a download script); every processed series carries a `source` and
`method` column distinguishing observed from reconstructed values; every backcast is flagged at
the row level so that "reconstructed" never silently becomes "observed" downstream.
