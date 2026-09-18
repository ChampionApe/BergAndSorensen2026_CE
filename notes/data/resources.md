# The resource side: decisions, and what the evidence can and cannot bear

Decision note for block B3 of `notes/plan_calibration_experiments.md`. Written
2026-09-17. Provenance is in `data/SOURCES.md`, block B3; the transformations
are in `data/build/b3_*.py` and are not restated here. What is here is why this
rather than that, and where the block is thin.

Scripts: `b3_jacks.py`, `b3_usgs_ds140.py`, `b3_usgs_mcs.py`, `b3_gcb_fossil.py`,
`b3_oregrades.py`, `b3_urr.py`, `b3_exploration.py`, assembled by
`b3_resource_block.py` into `data/interim/b3_resource_block.csv`.

## 1. The identification problem for `mu_N`

`mu_N` is the elasticity of the marginal extraction cost to the remaining stock.
It is the parameter that, by the balanced-path solution of the theory note,
selects between growth, a constant consumption level and decline in the floorless
benchmark, so the calibration hangs on it. It is also the one parameter in the
model that history cannot identify without an assumption, for the reason the data
plan §2d states: over a century and a half, depletion has pushed extraction costs
up and technical progress has pushed them down, and only the sum is observed.

Written as a cost that falls with technology and rises with depletion,
`C^N_t = c_N(t) (S_ref/S_t)^{mu_N}`, an observed real price or unit cost gives

    d log cost = d log c_N(t)  -  mu_N * d log S_t ,

one equation in two unknowns for every period. Every route below is an
assumption about the first term, not a measurement of the second.

### Channel A: real prices against cumulative extraction

Jacks (2019) is the best long price series there is: 42 commodities, consistently
deflated, 1850-2025, each indexed to 1900 = 100. What it shows, on the indices
this block builds (`price_index_*` in `b3_resource_block.csv`):

- Jacks's own **Metals** group -- the nine base metals, equal weights -- stands at
  89 in 2025 against 100 in 1900, having been at 70 in 1950 and 49 in 2000; at 98
  when the nine are weighted by world production mass;
- the broader **metal ores** set, those nine plus gold, silver, platinum, bauxite
  and iron ore, stands at 118 unweighted and 82 production-weighted: the gap is
  the three precious metals, whose real prices rose (gold at 421 in 2025 against
  100 in 1900, silver 155, platinum 171) while every base metal's fell, and which
  carry three fourteenths of the unweighted index and essentially none of the
  weighted one;
- the **mass-weighted aggregate** over all twenty commodities for which a world
  production series exists stands at 184, because mass weighting is a weighting
  by coal, oil and gas (see §3).

So the metals half of the aggregate is roughly flat to falling over 125 years and
the energy half is not. Taken naively, a flat real price with cumulative
extraction up by two orders of magnitude implies `mu_N` near zero, which is the
answer the resource-economics literature has been arguing about since Barnett and
Morse. It is not a measurement of the stock effect; it is a measurement of the
stock effect net of a century of technical progress in mining, and by itself it
bounds the **difference**, not either term.

What the price channel is good for is the over-identification check of task C2 --
the long-run price elasticity of material demand, `varsigma` -- and as an upper
bound on `mu_N` net of progress. It should not deliver the point estimate.

### Channel B: ore grades and energy per tonne

The data plan says to prefer this channel, and the reason is exactly the
decomposition above: energy per tonne of metal is a physical quantity that
responds to grade without passing through the price of capital or the rate of
technical progress in the same way, so the depletion term can be seen on its own.
What the three sources actually supply:

- **Calvo and others (2016)** give, for 35 mines, average electricity per tonne
  of ore and diesel per tonne of rock over stated periods (Table 1); average
  total energy per tonne of metal of 28.2 GJ/t for copper, 11.03 GJ/t for zinc
  and 145,888 GJ/t for gold; and the fall in the weighted-average copper grade
  across their mines of about 25 percent between 2003 and 2013, from an average
  of 1.48 percent against the 1.67 percent Cox and Singer report for about 1990.
  Their grade **time series** exist only as figures. Nothing was read off them.
- **Mudd (2010)** gives the one fitted relation in the literature assembled here
  that is printed rather than drawn: unit energy consumption in gold mining
  against ore grade, `E = 167487 * g^{-0.2848}` with `R^2 = 0.1962` (Figure 8,
  p. 107). An elasticity of energy to grade of **-0.285** is a direct, if noisy
  and gold-specific, handle on the curvature of the extraction cost in the
  physical state. He also gives cumulative Australian production by mineral
  (Table 1) and Australian economic resources against production (Table 2), which
  is the one place in this block where an extraction series and a reserve series
  are on the same basis and the same boundary.
- **West (2011)** could not be obtained. Its argument -- that falling copper
  grades are the result of innovation converting worthless rock into ore, not of
  depletion -- is the direct counter to reading a grade decline as `mu_N > 0`,
  and it is precisely the confound this channel was supposed to avoid. Not having
  it does not change the numbers; it does mean the note cannot cite the strongest
  statement of the objection.

**What this supports.** A *range* for `mu_N`, not a point, built from the grade-
energy elasticity with an explicit assumption about the rate of technical
progress in extraction, and checked against the price channel. It does not
support a point estimate, and phase C should not produce one. The honest form of
the result is: the physical channel says energy per tonne rises as grade falls
with an elasticity of order 0.3 in gold; the price channel says the net of that
and technical progress has been roughly zero for metals since 1900; the gap
between them is the rate of technical progress, which is therefore what the
calibration is really assuming when it picks `mu_N`.

### Exploration, which is the same problem for `mu_D`

Schodde's MinEx series is the public evidence for `C^D_X > 0`, and it is
cleaner than the extraction case because the quantity is a count, not a price.
Between 1975-2005 the average cost of a discovery was about US$65m; over
2011-2020 it was about US$218m in the same constant dollars, a tripling, while
the number of discoveries roughly halved and world exploration spend over
2012-2021 of US$196b generated an estimated US$135b of value. The same
depletion-versus-technology caveat applies -- deposits found later are deeper and
under cover, but search technology also improved -- and the regional table of
slide 22 gives the cross-sectional spread that bounds it.

## 2. `S0`, `X0`, and why reserves are an economic concept

**Reserves are not a geological quantity.** A reserve is the part of a
demonstrated resource that can be extracted economically at present prices with
present technology, which is why USGS reserve figures move with the copper price
and are revised country by country from company reports each year. This is
awkward for a stock the model treats as physical, and convenient for a model in
which `S` is the *known and economically available* stock and grows by
exploration: the USGS concept is closer to the model's `S` than any geological
number would be. It also means `S0` in 1900 is not observable and has to be
constructed.

**The construction.** The model has `X_t - S_t` equal to cumulative extraction,
so at the 1900 base year of decision D2

    S0 = cumulative extraction 1900 to T  +  reserves at T
    X0 = cumulative extraction over all covered years  +  reserves at T

with `X0 - S0` the extraction before 1900. This is the data plan §2e route --
`X` as an accounting object -- and it is the only defensible one. It assumes that
what is counted as a reserve today was, in the relevant physical sense, there in
1900; it therefore attributes the whole of a century's reserve growth to
discovery rather than to price and technology, which overstates `S0` and
understates the discovery flow. The alternative -- treating reserve growth as
revaluation of a fixed `X` -- would understate `S0` instead. The note records the
choice; phase C should treat the level of `S0` as a calibration target with a
wide band, not as data.

The task brief's literal formula, cumulative extraction plus reserves *less*
extraction to date, collapses to reserves alone. That reading is emitted as
`S0_literal_reading` beside the constructed value so that the difference is
visible rather than buried: 1805 against 1398 Gt for fossil fuels at the low
reserve bound, 324 against 231 Gt for metal ores on a gross basis, 6.3 against
3.4 Gt on a contained-metal basis, and 147 against 108 Gt for non-metallic
minerals.

**Coverage.** Extraction before 1900 is covered for fossil fuels only, where the
Global Carbon Budget runs from 1750 and adds 17.6 Gt. Data Series 140 begins in
1900, so for metals and non-metallic minerals `X0` equals `S0` and is a lower
bound. Closing that gap is task B6's Schmitz and Mitchell work, and until it is
done the metals `X0` should be read as "at least".

## 3. The aggregation to a mass basis, and where it breaks

Decision D1 puts the baseline on a mass basis across all four material-flow
categories. This block cannot deliver that aggregate on its own, and the reason
is worth being explicit about because it is the single largest limitation here.

- **Biomass is absent.** No source in B3 measures it. It is block B1's, and every
  category total in `b3_resource_block.csv` carries
  `method = derived_partial_coverage` for that reason.
- **Construction minerals are effectively absent.** Crushed stone and
  construction sand and gravel are the largest flows by mass in the material-flow
  accounts, and neither has a world production series in Data Series 140 (the
  construction sand and gravel workbook has world production for 1968-1975 only)
  nor a world reserve figure in the Mineral Commodity Summaries, which print
  "NA" for both. The non-metallic-minerals total here -- 38.7 Gt cumulative since
  1900, from salt, phosphate rock, gypsum, sulfur, soda ash and potash -- is a
  small fraction of the real thing.
- **Metals are on two incompatible bases.** USGS world production and reserves
  for copper, zinc, nickel and the rest are *contained metal*; for iron ore,
  bauxite, chromite and titanium minerals they are *gross ore*; the material-flow
  accounts are gross throughout. Cumulative extraction since 1900 is 2.8 Gt of
  contained metal and, separately, 93.2 Gt of gross ore, and the two are **not
  added** anywhere in the pipeline. The bridge between them is the ore grade,
  which is the evidence of §1's channel B, and turning contained metal into gross
  ore would require a grade series this block does not have -- another reason the
  metals-only bound of D1 should be reported on a contained-metal basis and
  labelled as such.
- **Refined products are not extraction.** Primary aluminium, pig iron and crude
  steel are in Data Series 140 with world production series, and they are used
  here as the mass weights for the aluminium and steel *prices*, because that is
  what those prices are prices of. They are excluded from every
  cumulative-extraction total, where bauxite and iron ore stand for the same
  material at the mine.

**The weights.** The mass-weighted aggregate price index uses fixed weights: mean
annual world production over 1900-2015, the window the task fixes. Fixed weights
rather than chained ones, because each Jacks series is already an index with
1900 = 100 and a weighted mean of indices with time-varying weights is not a
price index of anything. The consequence is that the aggregate is a coal-oil-gas
index: coal alone carries 2.38 Gt/yr of the weight, against 1.47 for petroleum,
0.67 for natural gas, 0.62 for iron ore and 0.006 for copper. That is what "mass basis" means, and it is the mechanical
reason D1 also asks for a metals-only bound.

## 4. The URR range, and why it is a range

`Xbar_max` is a judgement, and the data plan says to report it as one.

For **fossil fuels** the source is Rogner and others (2012), GEA Table 7.1, in EJ,
converted to mass with the same IPCC net calorific values used for the Global
Carbon Budget conversion. Three bounds are emitted: cumulative production to 2005
plus low reserves; plus midpoint reserves and resources; plus high reserves and
resources. Additional occurrences -- more than 1,000,000 EJ of unconventional gas
alone -- are reported separately and excluded from the high case, because they
are explicitly not judged recoverable. The totals are dominated by two cells:
unconventional gas reserves and coal resources. A conventional-plus-coal variant
is emitted beside each so that the driver is visible rather than implicit.

For **metals** the crustal-abundance route the data plan names (Rankin 2011) could
not be obtained. What stands in its place is the USGS Global Mineral Resource
Assessment as the Mineral Commodity Summaries report it commodity by commodity:
identified resources for seven metals, and an undiscovered estimate for copper
only (identified 2.1 Gt including past production, undiscovered 3.5 Gt). That is
a much narrower and much shallower basis than a crustal-abundance ceiling, and it
should be read as a floor on `Xbar_max` rather than as an estimate of it. The
gross-ore metals -- iron ore at more than 900 Gt of ore, bauxite at 55 to 75 Gt,
chromite at more than 12 Gt -- are reported separately on their own basis.

For **non-metallic minerals and biomass** no URR was constructed. For the former
the missing commodities are the ones that carry the mass; for the latter the
concept does not apply in the same way -- biomass is a flow with a regeneration
rate, not a stock with a ceiling, and forcing it into `Xbar_max` would be a
category error the model does not require.

## 5. What could not be obtained

| | why | effect |
|---|---|---|
| USGS MCS 2026 bulk CSV release | ScienceBase refuses automated requests (HTTP 403, Cloudflare) | none on the numbers: the published report carries the same figures and they are transcribed with page numbers. Re-download by hand would let the transcription be checked mechanically |
| BGR Energy Study (latest) | every BGR and mirror URL answers HTTP 400 or 404 | fossil reserves and resources rest on Rogner and others (2012) alone, vintage 2005. A second, more recent opinion is missing and the block says so |
| Rankin (2011) | paywalled monograph | no crustal-abundance ceiling for metals; the URR for metals is a floor, not an estimate |
| West (2011) | paywalled four-page commentary | the strongest published statement of the technology-not-depletion reading of falling grades cannot be cited |
| S&P Global, *World Exploration Trends* | commercial | none material: MinEx's series is built partly from the same data and is public |
| A global ore-grade time series | the three papers publish theirs as figures only | the `mu_N` grade channel rests on one printed regression (Mudd, gold) and a set of cross-sectional averages, not on a panel. This is the thinnest point in the block |

## 6. Phase C: how the range became a set of numbers (2026-09-17)

`data/build/c3_extraction.py` and `notes/data/calibration.md` record the choices; in short: the
one reserve is the exhaustible reserve divided by the exhaustible share of cumulative extraction
(ruling 6), so its relative depletion tracks fossil fuels and ores; `mu_N` is the price channel
with `c_N(t)` absorbing the flow-scale effect, the identifying assumption section 1 says has to be
stated, at 1.84 on the mass-weighted aggregate and zero on metals; `chi_N` is read off the rent
share; `Xmax` is the central URR with the low and high as the range and the conventional-plus-coal
variant recorded; `mu_D` is the MinEx cost-per-discovery elasticity against the contained-metal
resource, large because the room shrank little. The reserve-concept problem of section 2 is not
resolved by any of this; it is carried into the range of `S0`.
