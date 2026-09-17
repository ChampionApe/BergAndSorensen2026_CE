# The waste stock: what decision D3 reads it as, and the tension it leaves

Decision D3 of `notes/plan_calibration_experiments.md` reads the model's waste stock `W` broadly:
cumulative outflows to controlled and uncontrolled disposal, less cumulative recovery, with the
handling share `mu` set so that `mu * W` reproduces the observed handled flow. This file records
how that reading is implemented (task C4, ruling 3 of the phase C brief), what is excluded, and the
specification tension the data plan section 5 names. The numbers are in
`writing/quant/quant_data.tex`, Section *Waste handling and recycling*; the transformation is
`data/build/c4_waste.py`; the source series are those of `notes/data/material_flows.md`.

Written 2026-09-17.

## What is in the stock

Cumulative disposal from 1900 of the solid and liquid residues leaving use, by material category,
from Haas et al. (2020), already net of the same year's recovery (the source subtracts secondary
materials before reporting the residue). Three categories are counted: fossil (ash, plastics,
bitumen), metal ores (slag, tailings, scrap not recovered) and non-metallic minerals (demolition
debris, quarry residue). These are the outflows that are landfilled or stockpiled, and they are
what a recovery margin drawing on a stock can reach.

**Biomass is excluded.** Its residues, the largest category by mass, cycle ecologically rather than
sit in a landfill; Haas et al. (2020) count that flow separately as ecological cycling, and
cumulating it would treat a century of decomposed crop residue and manure as a stockpile. The
appendix table shows the size of what is excluded. The choice is consistent with the model's
reading of untreated waste as flowing to the environment, `Xi`, since that is where biomass
residue goes.

**Recovery out of the accumulated stock is nil.** No source reports it; the data plan section 5
recommends this reading; `material_flows.md` records it as the source's convention.

## The handled flow and `mu`

Ruling 3 sets `mu` so that `mu * W_2015` equals the outflow of the three categories to disposal in
2015, not municipal solid waste, which is three percent of it. That gives a handling share of
about 3.5 percent and a mean residence of about thirty years. Reading the handled flow as disposal
plus the same year's recovered flow, on the ground that recovered material also passes through
handling in the model, raises `mu` by a third; that reading is the range's upper end.

## The tension D3 records

The model draws a geometric sample of the stock each period: `H = mu W`, every tonne in the stock
equally likely to be handled whatever its age. The data are the opposite. Recovery is strongly
age-dependent: end-of-life scrap is recovered when a product is discarded, within the year, and
material that has been landfilled for a decade is essentially never recovered. So the observed
"handled flow" is a flow of *this year's* discards, and the stock it is drawn from is not the
century's cumulative stockpile but the stock of products reaching end of life. Calibrating `mu`
as the ratio of the one to the other therefore makes `mu` a residence time of the landfill, not of
the discard stream, and the model's `H` in any year is the cumulative stockpile times that share,
which is a different object from the year's discards.

Two consequences follow, neither papered over.

1. **The model's recovery draws on a stock the data say is inaccessible.** Along a solved path
   the recycling margin can recover material that has been in the stockpile for decades, because
   the geometric draw does not know its age. The observed yield the calibration of `xi` uses is
   recovery over the year's treated discards; the model's `a` applies to a draw from the whole
   stock.
2. **The 1900 stock is a construction.** Cumulative disposal begins at 1900 by construction, so
   `W0` is set to the stock consistent with the 1900 disposal flow at the calibrated `mu`, on the
   analogy of B2's steady-state initialisation of the capital stock; the 1900 residue alone is
   the low end of the range.

The narrow alternative, `W` as the stock of products reaching end of life with `mu` near one (the
one-period buffer that `check_params` admits, `mu = 1`), would match the age structure of recovery
and lose the landfill as a resource, which is the object the paper's gate-fee experiment (E4) is
about. D3 chose the broad reading for that reason, and `cases` carries no `mu` grid; if E4's
sign-change date turns out to hinge on `mu`, this is the file that says why it might.

## What would resolve it

A disposal series split by treatment route (landfill, incineration, recovery) with a vintage
structure. The MISO2 database of Wiedenhofer et al. (2024), which `material_flows.md` names, is
the place to look; nothing in the four B1 sources provides it.
