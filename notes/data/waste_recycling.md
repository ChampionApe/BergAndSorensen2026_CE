# Waste handling and recycling: the decisions behind the B4 block

Decision record for task B4 of `notes/plan_calibration_experiments.md`. Provenance is in
`data/SOURCES.md`, block B4; the transformations are in `data/build/b4_*.py`; the numbers
that go into the calibration are in `data/interim/b4_waste_block.csv`. Nothing here repeats any of
those.

Written 2026-09-17.

The block answers to five objects of the theory note's planner setup: the treated share `varpi`, the
collection charge `c^c` per treated tonne, the treatment cost `c^T(varpi) = c_T varpi^(1+chi_T)/(1+chi_T)`,
the leakage share `d^W` of the treated stream's residue, and the yield ceiling `abar` of
`a(x) = abar(1 - exp(-xi x))` with its tail rate `xi`.

## The scale problem, and it is the whole problem

Every cost number, every treatment share and every collection rate in this block is **municipal
solid waste**. The model's `H` is the whole handled flow. The two differ by a factor of thirty:
global MSW generation is 2.07 Gt/yr (2016, `b4_whatawaste2`) against 63.75 Gt/yr of waste generation
in B1's ledger (2015, `b1_material_block`), so MSW is 3.3 per cent of the flow the model handles.
The other 96.7 per cent is construction and demolition debris, mine and quarry residue, agricultural
residue and the fossil carbon that leaves as CO2 - streams whose handling costs, treatment shares
and leakage are not what the World Bank and UNEP measure.

This is the caution the data plan's Section *Waste handling, treatment and costs* raises, made
quantitative. Three consequences run through everything below.

1. **`varpi_0` does not come from here.** The MSW treated share - 67 per cent in 2016 on Kaza et al.,
   62 per cent in 2020 on UNEP - is a sanity check on the aggregate, not a measurement of it. The
   aggregate has to come from B1's outflow decomposition, as the data plan says, and C4 should take
   it from `b1_material_block.csv` and use the B4 numbers only to ask whether the answer is of the
   right order.
2. **The cost levels are MSW cost levels.** A tonne of demolition concrete is not collected in a rear
   loader. If C4 applies `c^c` measured on MSW to the whole of `H`, the collection bill is too high
   by an unknown factor; if it applies it only to the MSW share, `c^W H` is too small. Neither is
   right and the appendix should say which was chosen.
3. **What survives the scale problem is the *shape*, not the level.** The cross-section of unit cost
   against the treated share, and the ranking of routes by cost per tonne, are properties of the
   handling technology that are more likely to carry across streams than any level is. That is what
   the block is built to deliver, and it is why `chi_T` is better served here than `c^c` is.

## Global treatment shares: two sources that disagree, both kept

| | Kaza et al. (2018), 2016 | UNEP (2024), 2020 |
|---|---|---|
| openly dumped or burned | 33 % | 38 % |
| treated (the complement) | 67 % | 62 % |
| collected | 84 % (population-weighted, from the open dataset) | 89 % (table 2B.1.1) |
| MSW generated | 2.07 Gt/yr (computed from the dataset) | 2.1 Gt/yr |

The later source has the *higher* dumping share. That is not a revision of 2016: UNEP's
"uncontrolled" counts waste that is collected and then dumped or burned at its final destination,
which Kaza's "open dump" treatment category partly does not. Both readings are in
`b4_waste_block.csv` under `global_openly_dumped_or_burned_share`, with the year and the source, and
C4 should choose the UNEP definition if `varpi` is read as *treated*, because that is the definition
that excludes collected-then-dumped tonnes from the treated flow. The gap between collected
(89 per cent) and controlled (62 per cent) is itself the measurement of how much collection is not
treatment: 27 points of MSW.

A third reading is computed rather than transcribed: weighting the 167 countries whose treatment
shares are complete by their own MSW generation gives 24.3 per cent open dumping, not 33. Those 167
countries carry 76 per cent of world MSW and the missing quarter is disproportionately low-income, so
the computed figure is biased down and the report's own 33 per cent is the one to use. The computed
version is kept because it is the only source of the *composition* of the treated stream, which
`d^W` needs.

## The cost-to-parameter mapping proposed

All four mappings are proposals for C4, not calibrations. `c^W(varpi) = c^c varpi + c_T varpi^(1+chi_T)/(1+chi_T)`
is a cost per tonne of *handled* waste, so the cost per tonne *treated* is
`c^c + c_T varpi^chi_T/(1+chi_T)`: a constant plus a term rising in the treated share. The evidence
is a four-point ladder across World Bank income groups, and every proposal below is a way of reading
that ladder.

**`c^c`, the collection charge.** Kaza et al. table 5.2 gives collection and transfer at 20-50,
30-75, 50-100 and 90-200 US dollars per tonne for the four income groups; UNEP table 2C.1 adds a
single *reported* figure of 40, 16, 98 and 121. Take `c^c` as the intercept of the ladder at a low
treated share, i.e. the low-income figure, around 20-50 US$/t. The reported low-income value of 40
sits inside that range; the reported lower-middle value of 16 sits below its own expert range and
looks wrong, and is reported as looking wrong rather than dropped.

**`c_T`, the level of treatment cost.** In the workhorse form the marginal treatment cost at
`varpi = 1` is exactly `c_T`, so `c_T` is what the last tonne costs *above* collection when
everything is treated. From table 5.2 the disposal or treatment routes cost 10-20 (controlled to
sanitary landfill, low income) to 40-100 (high income), with recycling 0-25 to 30-80 and composting
5-30 to 35-90. A high-income marginal treatment cost of 40-100 US$/t above collection is the
defensible reading, and UNEP's reported high-income values - landfill 53-99, recycling 202,
waste-to-energy 134 - bracket it from above.

**`chi_T`, the curvature.** This is where the block is worth something and where it is also most
fragile. Adding the midpoints of collection and of controlled-to-sanitary landfill gives roughly 50,
80, 118 and 215 US$/t for the four income groups, against treated shares that rise from 7 per cent
(low income, on the report's own 93 per cent dumping) to 98 per cent (high income). Fitting
`c^c + c_T varpi^chi_T/(1+chi_T)` to four points would give a `chi_T`, and it would be worth very
little: income raises the treated share and the wage bill at once, so the cross-section confounds
the gradient in `varpi` with a level shift in the price of the labour and capital that do the
handling. C4 should either deflate the cost by GDP per head before fitting, or treat the fit as an
upper bound on `chi_T` and carry a range. A range of roughly 0.5 to 3 is what four confounded points
support; the workhorse needs only `chi_T > 0`.

The country-year panel in the block - Eurostat treated share against Eurostat waste-management
expenditure per tonne, 148 country-years - was built as the second reading and does **not** work as
one. Eurostat publishes no unit cost of waste management services; the nearest thing is national
expenditure on environmental purpose CEP0401, whose numerator covers all waste while the only
available denominator is municipal waste. The resulting levels, 190 to 2200 euro per tonne, are the
scale problem of the first section in miniature and vary across countries mostly with the
industrial-waste share. The rows are kept, labelled
`numerator_covers_all_waste`, so that nobody rediscovers them and believes them. The OECD treated
shares are kept beside them with no cost column at all.

**`d^W`, leakage from the treated stream.** The theory puts `d^W` on the *residue* of treatment,
`(1-a) varpi H`: the part of the treated flow that is neither recovered nor contained. Nothing
measures it. The best anchor available is the composition of the treated stream itself, from the
MSW-weighted computed shares: of the 76 per cent of MSW that is treated, 30 per cent goes to
landfill of unspecified type, 12 per cent to sanitary landfill with gas collection, 6 per cent to
controlled landfill, 13 per cent to incineration, 28 per cent to recycling and composting and
11 per cent to "other" or unaccounted. Reading unspecified landfill as weakly contained and
sanitary and controlled landfill as contained puts `d^W` at roughly 0.3 at the top and something
near 0.05 at the bottom, if the containment of modern landfill is taken seriously. The data plan
already calls `d^W` weakly evidenced and asks for it as a sensitivity dimension; that is the right
answer and a range of 0.05 to 0.30 with 0.15 as a midpoint is what this block supports.

## The ceiling `abar`

The evidence is metals evidence, and it says two things.

**The metals-only bound is computable and is 71 per cent.** The UNEP IRP appendix tables give
end-of-life recycling rates for 59 metals as one or more cited estimates each. Taking each metal's
range across its estimates and weighting by USGS world mine production on a contained-metal basis
(B3's `b3_usgs_mcs.csv`, 2024) gives a mass-weighted end-of-life recycling rate of
**70.8 per cent, between 52.7 and 88.9**. Two things must be said about that number.

- It is iron. Iron is 93 per cent of the weight, so the aggregate is essentially the iron and steel
  figure, and the IRP's own prose - an EOL-RR of 70-90 per cent for iron and steel - brackets it.
  Everything below iron moves the aggregate by less than a point.
- Aluminium and titanium are **excluded** from the weighting, because the USGS world-production rows
  B3 transcribed are gross weight of bauxite and of ilmenite-rutile, not contained metal, and
  converting ore to metal here would be a number from nowhere. Aluminium's EOL-RR estimates
  (42, 60, 70 per cent) straddle the aggregate, so including it would not move it much, but the
  exclusion is recorded in the `method` column of the aggregate rows rather than quietly fixed.

**The all-materials ceiling is not identified, and `abar_H = 0.71` is the honest tighter case.**
Task C4 asks for `abar_H` as "the mass-weighted maximum the recycling-rate evidence supports". On a
mass basis across all four B1 categories there is no such evidence: construction minerals, which
dominate the tonnage, can be crushed and returned as aggregate at a mass yield near one, but Cullen
(2017) shows that doing so consumes as much cement as using virgin aggregate, so the *quality* yield
is zero while the mass yield is high - and the model's `a` is a mass yield. A mass-weighted `abar`
would therefore be closer to one than to the metals figure, which is the wrong direction for a
bound. The recommendation is to take `abar_H` from the metals evidence, 0.71, precisely because it
is the only ceiling the evidence supports, and to say in the appendix that on a mass basis across
all materials it is conservative rather than tight. The two cases of the plan then read
`abar` in {1, 0.71} with 0.53 and 0.89 as the sensitivity ends.

The aggregate target for `a varpi` has two candidate readings, which should both be reported:
Circle Economy's Circularity Metric, 6.9 per cent in 2021 (7.2 in 2018), whose denominator includes
the fossil fuels burnt for energy and can therefore never be cycled; and B1's own secondary input
over waste generation, 6.11 over 63.75 Gt, which is 9.6 per cent in 2015. The second is the one on
the model's definition. The first is carried in the block under `aggregate__` with its caveat welded
into the `unit` column.

## `xi`, which is the thin spot

`xi` is the rate at which the yield approaches its ceiling in recycling capital per treated tonne.
Identifying it needs cost or energy per tonne recovered **as a function of the recovery rate
achieved**. After a full search: no public study states that function for any single stream -
aluminium, steel, copper, e-waste or plastics sorting. Ip et al. (2018) build exactly the object, a
network-flow model of a materials-recovery facility whose net profit and plant efficiency are traced
against separation efficiency - and report it only in figures 5 and 6, which this block may not
read.

What was found is assembled in `data/interim/b4_xi_literature.csv`, and its heterogeneity is the
finding. Four kinds of evidence, none of them the curve:

- **Energy ratios between secondary and primary production.** Cullen (2017) table 1 gives, for five
  materials, the energy to recover and the energy for primary production, and hence his `beta`:
  aluminium 0.96, plastic 0.75, steel 0.69, paper 0.11, concrete 0.00. Reck and Graedel (2012) put
  the saving at a factor of 10 to 20 for metals. UNEP (2024) allocates 39 kWh of electricity per
  tonne of recycled material to sorting. These fix the *level* of the recovery cost, not its
  gradient in the rate.
- **Capital outlay for a stated rise in a national recycling rate.** EPA (2024) costs raising the
  US residential packaging recycling rate from 32 to 45-47 per cent at 22-28 billion dollars for
  38-45 Mt of added annual recovery, and a wider programme including organics at 36-43 billion for
  82-89 Mt and a rate of 61 per cent. This is the closest thing to a point on the curve in the
  model's own units - capital per annual tonne of added recovery. The two estimates are **not**
  nested increments of one margin (the second covers organics as well as packaging) and no
  difference between them is taken; as stated they do not exhibit a rising marginal cost, which is
  worth saying because the model assumes one.
- **Cost per tonne at successive depths of sorting.** Van Camp et al. (2024) cost initial sorting of
  flexibles at 110-123 euro per tonne of output and the additional sorting and improved recycling
  that follows at 566-735 euro per tonne. A factor of five for the deeper pass is the clearest
  gradient-shaped fact in the whole assembly, and it is two points, not a curve.
- **Break-even recovery rates.** Li et al. (2024) find that at least 63 per cent of imported plastic
  waste must be recycled to break even, against an observed domestic rate of 23 per cent, and
  83 per cent for PVC. A break-even rate is a statement about where the cost curve crosses the
  revenue line and constrains the curve without tracing it.

Two things bound the answer from the other side. Fullerton and Kinnaman (2024) record that OECD
aggregate recycling rates have plateaued, and note that capital-intensive sorting reaches a lower
cost per additional tonne but needs a high fixed outlay - so unit cost falls with scale before it
rises with the rate, which is the opposite of what `xi` assumes at small `x`. Reck and Graedel
(2012) find that a unit of iron, copper or nickel is reused only two or three times before it is
lost, and that platinum-group end-of-life recycling is "at best on the order of 60 per cent".

**The recommendation is therefore a range and an admission.** `xi` should be set so that the yield
reaches its observed level at the observed recycling capital per treated tonne - that is, calibrated
to a point on `a(x)` rather than to a gradient - and then varied over at least an order of magnitude
in the sensitivity analysis. Task E1 of the plan already names `xi` as one of the two parameters
whose perturbation any headline result must survive; this note is the reason.

One download would change this. **Kinnaman, Shinkuma and Yamamoto (2014)** estimate the average
social cost of municipal waste management as a function of the recycling rate, which is `c^W(varpi)`
and the recovery cost together. It is paywalled and recorded as MANUAL in
`data/SOURCES.md`, block B4. It is the highest-value single download left in this block.

## What is not here

- Graedel et al. (2011), the journal version of the IRP report, is MANUAL; nothing is lost but the
  citation, because the report itself is downloaded and carries the same estimates.
- The What a Waste city-level cost fields are unusable: the open dataset gives them no unit and no
  currency, and they mix per-tonne figures with annual totals. Nothing is taken from them.
- Figure 4 of the IRP report and figure 7 of the UNEP outlook are figures. The IRP's appendix tables
  carry the same evidence as numbers and are used instead. UNEP's figure 7 has no textual
  counterpart for the split of controlled MSW into landfilling, waste-to-energy and recycling, so
  those five rows are carried with `method = transcribed_figure` and should be refused by C4 unless
  it decides otherwise; the two totals they contain agree with the prose on pages 21 and 22.

## Phase C: what was taken (2026-09-17)

Ruling 8 of the phase C brief fixes the mappings this note proposed: `c^c` at the low-income
collection midpoint, `c_T` at the high-income sanitary-landfill midpoint, no deflation (price base
unknown, recorded as such), `chi_T` at the midpoint of [0.5, 3], `d^W = 0.15` in [0.05, 0.30],
`abar` in {1, 0.71} with [0.53, 0.89] as the sensitivity ends, and `xi` through a point on the
yield function as the note recommends, with the EPA capital outlay supplying the slope
(`data/build/c4_waste.py`). The scale problem of the first section is now measurable: the C8 smoke
test (`data/processed/c8_smoke.txt`) finds that at municipal charges applied to the whole handled
flow the planner treats nothing, and at a tenth of them the treated share is interior. The level
of the charges is the open item this note hands to phase D.

## Phase D: the level (2026-09-17)

The smoke test's reading was a horizon effect: at `T = 60` the year 2015 is outside the solve, and
the planner at the municipal midpoints begins treating at t = 59. Task D0b holds the ladder's
ratio `cT/cc` and fits the common level to the 2015 treated share of the material flow accounts;
the factor comes out at 1.24 on the midpoints, inside the ladder's own range, so the first
section's fear that the municipal level is wrong by a large factor for the aggregate is not what
the model says: the level is of the right order, and what it decides is the date treatment begins.
The reasoning and the numbers are in `calibration.md` under C4 and in the data appendix; the
recycled share the fitted path gives is more than twice the observed one, for reasons that belong
to `xi` and to the stockpile reading of `waste_stock.md`, not to the charges.
