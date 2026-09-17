# Core material flows and stocks: the decisions behind the B1 block

Decision record for task B1 of `notes/plan_calibration_experiments.md`. Provenance is in
`data/sources/B1_material_flows.md`; the transformations are in `data/build/b1_*.py`; the numbers
that go into the calibration are in `data/interim/b1_material_block.csv`. Nothing here repeats any
of those.

Written 2026-09-17.

## What the block delivers

`data/build/b1_material_block.py` joins the four per-source interim files onto the model's own names
and writes two diagnostics beside the block: `data/interim/b1_discrepancies.csv`, every pair of
sources measuring the same cell that differ by more than five percent, and
`data/interim/b1_closure.csv`, the ledger residuals.

| model object | series | years | source chosen |
|---|---|---|---|
| `N` used extraction | `N` | 1900-2015 | Krausmann et al. (2018), with three other sources kept beside it |
| `R^R` secondary input | `RR` | 1900-2015 | Haas et al. (2020) |
| `R = N + R^R` | `R` | 1900-2015 | Haas et al. (2020) |
| `W` waste generation | `W` | 1900-2015 | Haas et al. (2020) |
| `Xi` to the environment | `DPO` | 1900-2015 | Haas et al. (2020) by category, Krausmann et al. (2018) in total |
| `M^K` in-use stock | `MK` | 1900-2015 | Krausmann et al. (2018) |
| stock flows | `NAS`, `NAS_gross`, `NAS_demolition` | 1900-2015 | Krausmann et al. (2018) net, Haas et al. (2020) gross and demolition |
| raw material for `W` (D3) | `Wcum_disposal`, `Wcum_eol_waste` | 1900-2015 | Haas et al. (2020), Krausmann et al. (2018) |
| `Omega^{N,S}` | none | | not obtained, see *Gaps* |

## Why these sources for these series

**Extraction.** Krausmann et al. (2018) is the block's spine: it is the only source obtained that
covers 1900 to 2015 annually on one consistent accounting, and it is the update the two other
Krausmann-family sources feed into. The three others are kept in the block rather than discarded,
each for its own reason: Haas et al. (2020) because the rest of its ledger is used and its extraction
column has to be visible beside the ledger it belongs to; Krausmann et al. (2009) as the plan's
cross-check; the IRP database because it is the independent compilation and the only one that reaches
past 2015. The `source` column separates them and phase C chooses.

**Recycling, input and outflow.** Only Haas et al. (2020) reports secondary material input, and it
reports it annually by material group for 1900-2015, which is more than the plan expected from Haas
et al. (2015). It is also the only closed ledger in the block: extraction plus secondary input equals
outflow plus the net addition to stock, by material group, every year. That ledger is what makes `W`
available as a category-level series rather than a residual.

**The in-use stock.** Krausmann et al. (2017) was to be the source of `M^K`. It could not be
downloaded and was not needed: Krausmann et al. (2018) carries the same MISO model five years
further, to 2015, which is what the block uses. The two are not independent, so nothing is lost
beyond a cross-check that would not have been one.

**`Xi`.** Domestic processed output is reported on two conventions, with and without the balancing
oxygen and water that combustion and respiration draw from the atmosphere. The model's `Xi` is a mass
of material leaving the economy, not a mass of atmospheric oxygen returning to it, so the block
carries the excluding convention under the name `DPO` and the including one as
`DPO_incl_balancing`. The two differ by roughly a factor of two.

## Categories and regroupings

The four categories are those of material flow accounting: biomass, fossil energy carriers, metal
ores, non-metallic minerals. Krausmann et al. (2018) and Haas et al. (2020) use exactly this split
and their extraction columns agree to six parts in a thousand or better. Two regroupings are not
clean and are flagged where they occur.

**Krausmann et al. (2009).** Its minerals split is ores *and industrial minerals* against
*construction* minerals, which is not the later split. Only biomass, fossil energy carriers and the
total travel into the block; the two mineral categories stay in
`data/interim/b1_krausmann2009.csv` under their own names.

**The in-use stock.** It is reported by stock category, not by material group. Metals maps one to
one. Bricks, concrete and aggregates are all non-metallic minerals, but their sum leaves out the
glass inside "wood, glass and plastics" and the mineral fraction of asphalt, so the block carries it
as `MK` for non-metallic minerals with `method = reconstructed`. Biomass and fossil `M^K` cannot be
separated at all: wood, glass and plastics is one column spanning three material groups, and asphalt
is bitumen mixed with aggregate. The block therefore has no `MK` for biomass or for fossil, and the
per-stock-category series stay in `data/interim/b1_krausmann2018.csv` for whoever wants to split
them on an assumption.

The two sources can be checked against each other here: cumulating the gross stock additions less
demolition of Haas et al. (2020) for metals from the 1900 level of Krausmann et al. (2018)
reproduces the latter's metal stock path to three parts in ten million. They are the same model.

## The waste stock of decision D3

D3 reads `W` broadly, as everything ever discarded and not recovered. `Wcum_disposal` cumulates the
solid and liquid residues leaving use, by category, from 1900. Three things about it:

- It is already net of recovery within the year, because the source subtracts secondary materials
  before reporting the residue. Recovery *out of* the accumulated stock is not reported by any source
  in this block and is taken to be nil, which is the reading the data plan section 5 recommends.
- It begins at 1900 by construction, so it omits whatever was in the ground before 1900. For
  minerals and metals that is small; for biomass it is meaningless, because the pre-1900 residue has
  long since decomposed.
- Biomass dominates it and should probably not be in it. Biomass residues cycle ecologically rather
  than sit in a landfill, and the source counts that flow separately as ecological cycling
  (`in_ecological_cycling` in `data/interim/b1_haas2020.csv`). The category rows are there so that
  phase C can take the sum it wants; the block does not take that decision.

`Wcum_eol_waste` is the narrower alternative: the cumulated end-of-life waste flow of Krausmann et
al. (2018), in total only, which excludes processing waste and dissipative use. Phase C has both.

The specification tension D3 records, between the model's geometric draw on `W` and the strongly
age-dependent recovery in the data, belongs in `notes/data/waste_stock.md` and is not restated here.

## Discrepancies above five percent

All of them are between the IRP database and the Krausmann family, except the one between the two
Krausmann vintages, and all are listed cell by cell in `data/interim/b1_discrepancies.csv`. Each
appears twice there wherever Haas et al. (2020) is one side of it, because its extraction column is
the extraction column of Krausmann et al. (2018).

**Metal ores, IRP against Krausmann et al. (2018), 1970-2015, every year.** The IRP figure is about
half again as large, a median gap of 48 percent and a maximum of 55. This is the block's largest
discrepancy by far and it matters: decision D1 reports a metals-only bound, and that bound would be
computed on a series whose two available measurements differ by half. The likely cause is the
treatment of gross ore against crude ore: Krausmann et al. (2018) extrapolate gross ore from metal
content and average global ore grades, and the two compilations need not draw the boundary at the
same point. Neither source was preferred; both are in the block.

**Non-metallic minerals, the same pair, 1970-2014.** The IRP figure is about 10 percent lower, and
the gap runs the other way from metals, so the two largely offset.

**Biomass, the same pair, 1970-2015.** The IRP figure is about 8 percent higher throughout.

**Totals.** Because the category gaps offset, used extraction in total agrees to within 3.6 percent
in every year, a median of 1.3 percent. The composition, not the aggregate, is where the two
compilations disagree.

**Krausmann et al. (2018) against Krausmann et al. (2009), total, 1949-2009.** The 2018 figure is
higher, by 2 percent in 1900, 6 percent in 1950 and 10 percent in 2009, with a maximum of 15 percent.
Biomass and fossil energy carriers agree to within 4 and 2 percent respectively, so the gap is
entirely in the minerals, which is what the 2018 update added to: sand and gravel for sub-base and
base-course layers, clay for bricks, silica sand for glass. The two are not independent measurements
and the later one supersedes the earlier.

## Closure

The ledger identity of phase E holds by construction inside each source, so it is not a test:
`data/interim/b1_closure.csv` shows extraction plus secondary input against outflow plus net
additions to stock closing to machine precision within Haas et al. (2020), and used extraction
against domestic processed output plus net additions to stock closing to machine precision within
Krausmann et al. (2018). The informative check is the cross-source one, extraction from Krausmann et
al. (2018) plus secondary input from Haas et al. (2020) against the latter's outflow and the
former's net addition to stock: the residual is between minus 0.062 and plus 0.009 percent of the
input in every year from 1900 to 2015.

## Gaps

**Unused extraction.** No source in this block reports it, so `Omega^{N,S}` has no observed
counterpart from B1. The nearest thing available is tailings, which Krausmann et al. (2018) carries
as a use type and the block as `N_tailings`: it is the ore that never becomes product, not the
overburden moved to reach the ore, and it is inside used extraction rather than beside it. It should
not be pressed into service as `Omega^{N,S}` without a source that measures the overburden. B3 or a
later pass will need one, and the IRP technical annex describes unused extraction as a module of the
accounts that the published database does not carry.

**2016 to 2020.** Only the IRP database reaches past 2015, and the vintage obtained stops at 2019.
Everything else in the block ends in 2015. The current IRP vintage runs to 2024 and is recorded as
MANUAL in `data/sources/B1_material_flows.md`.

**Before 1900.** Out of scope here; task B6 if it runs.

## Alternatives not taken

The MISO2 stock-flow model of Wiedenhofer et al. (2024), which the data plan section 2a names as the
closest existing empirical analogue of the model's material block, is public as the MAT_STOCKS
database, <https://zenodo.org/records/12794253>. It was not used: it is country-level and large, and
the B1 sources already deliver the global aggregates at the resolution the model needs. It is the
place to go if the block ever needs a disposal split by treatment route, which none of the four
sources here provides.

## Phase C: what the calibration took from this block (2026-09-17)

Ruling 1 of the phase C brief makes Krausmann et al. (2018) and Haas et al. (2020) the baseline
series throughout; the IRP series enters only as the alternative measurement of metal-ore
extraction, and the metals-only bound (`data/processed/calibration_metals.json`) carries the gap
of about half as the low end of its reserve. `Xi`'s counterpart is `DPO` excluding balancing
oxygen and water (ruling 2). The waste stock of D3 is the cumulative disposal of the three
non-biomass categories; `notes/data/waste_stock.md` is the decision record. The accounting block
(`data/build/c1_accounting.py`) reads `phiI` off gross additions to stock and holds the relative
intensities at one; the EEA (2001) TMR ratios stand in for the unused extraction this block could
not obtain (`notes/data/calibration.md`).
