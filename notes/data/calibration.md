# Calibration: the judgements of phase C

Decision record for tasks C1 to C8 of `notes/plan_calibration_experiments.md`. What each number
is and how it is reproduced is in `writing/quant/quant_data.tex` and its generated tables; the
transformations are in `data/build/c1_accounting.py` to `c6_states.py`, `c0_series.py`,
`c_metals.py`, `c7_checks.jl`, `c8_smoke.jl`; provenance for the three downloads phase C added is
in `data/sources/C_calibration.md`. This file records the judgements the rulings did not cover,
why this rather than that, and where the calibration is weak. The five block notes carry the
decisions that belong to their area; this file points at them rather than repeating them.

Written 2026-09-17.

## The rulings, applied

The ten rulings of the phase C brief are applied as written. Where one left a choice, the choice is
below under the block it belongs to. Two rulings changed a number a block had proposed: the
pre-1950 use split is at the perpetual-inventory investment share for both `K` and `G` (ruling 5;
`macro.md` records the two shares B2 carried side by side), and `theta` is the emissions-driven
rate with the pulse rate as the range (ruling 7; `pollution.md` had recommended exactly that).

## C1 accounting

- **`phiI` on the cumulative stock addition.** The stored share `NAS_gross/R` rises from a sixth in
  1900 to a half in 2015, and a constant coefficient cannot follow it. The cumulative ratio over
  1900-2015 reproduces the century's total addition to the in-use stock, which is what `MK_2015`
  depends on; the 1900 and 2015 readings are the range. The cost is a 1900 stored share about three
  times the observed one. The alternative, the 1900 reading, would get the base year right and
  understate the stock by 2015 by roughly half.
- **`omega^j = 1`.** No source splits waste by generating use. The Krausmann (2018) split by type
  gives `omC/omY` of about two if emissions are left unattributed and anything from one to four
  depending on where emissions go; a common intensity is the reading the evidence does not
  contradict, and the wedges depend only on `Omega * omega^j`. E1 should perturb it.
- **`OmNS` from the EEA (2001) EU-15 table.** Schandl et al. (2018) and the Wuppertal global TMR
  papers are paywalled (Wiley refused the download; Unpaywall lists no open copy). The EEA
  technical report is the one published unused-to-used table obtained, by category, EU-15 domestic
  extraction in 1995. Applying EU domestic ratios to the world composition is the weakness: the
  EU's metal ore ratio is on the low side of world mining (its imports carry a ratio seventeen
  times higher), which is why the high end of the range uses that figure. Marked weak.
- **`OmDS` is a judgement**: one hundredth of `OmNS`, range zero to a tenth. No source measures mass
  displaced per tonne discovered; drilling and trenching move little rock per tonne of deposit.

## C2 production and trends

- **`mu_F` from the labour share** is the cleanest reading of "the fixed factor stands in for
  labour". The PWT labour share is of GDP, so `mu_F` is a gross share and `beta_K + gamma = mu_F`.
- **The material value share** is built from prices the blocks did not have: the World Bank Pink
  Sheet for fossil fuels (oil at 7.33 barrels per tonne, the factor Rogner et al. (2012) state in
  their footnote 5), USGS DS140 unit values for minerals and ores, and agriculture value added for
  biomass. Two approximations to note: every tonne of metal ore is priced at the iron ore unit
  value (iron ore is most of the gross-ore mass, but copper ore is worth more per tonne of ore),
  and biomass is valued at the sector's value added rather than a harvest value. The share is
  computed in nominal terms in 2011 and 2015 and averaged; 2011 was a commodity price peak and
  2015 a trough, which is the range the two years span.
- **`sigma_s = 1` is held.** The long-run price elasticity of material demand the identification
  table names cannot be read off a century in which income growth dominates: the naive elasticity
  of intensity to the real price is about minus two against the Cobb-Douglas minus one, but the
  metals price fell while the aggregate rose, and one elasticity is not identified from two
  trends. Holding unity keeps the C-cell growth formula and the essential-material reading.
- **The trend split is a convention.** Under `sigma_s = 1` only `gA + gamma gB` enters any path.
  The composite is identified by growth accounting; the split is `gB = 0`. The over-identification
  test the plan asks for is reported as two facts: the century is on no balanced path (material
  input grew throughout; `g_Y / (-g_Omega)` is about 3.5 against 1 on a circular path), and the
  1950-2015 composite is a third higher than the 1900-2015 one. The point is the full window,
  because the model's base year is 1900.
- **`A0` neglects the damage factor at 1900**, which is a twentieth of a percent.

## C3 extraction and exploration

- **The composition of `S` (ruling 6).** Recorded in the appendix and in the script's docstring:
  `S0 = S0_ex / s_ex` with `s_ex` the exhaustible share of cumulative 1900-2015 extraction, so the
  aggregate's relative depletion tracks the exhaustibles'. The unscaled alternative is inadmissible
  (the century's own extraction would exhaust it). What is lost is that biomass and construction
  minerals inherit a stock effect. `resources.md` records the reserve-concept problem underneath.
- **Metal ores on the gross basis, scaled by coverage.** The USGS gross-ore commodities (iron ore,
  bauxite, chromite, titanium minerals) cover about half of the material flow accounts' metal
  ores; their reserves and resources are scaled by the cumulative-extraction ratio (2.26). The
  contained-metal commodities' reserves are thereby assumed to bear the same ratio to their
  extraction as the gross ones. Reserves are a tenth of the fossil figure, so `S0` is not sensitive
  to this; `Xmax`'s metals component is a fifth of the fossil central figure.
- **`Xmax` at the central URR** is six times `X0`; at the low URR the room for discovery is a
  quarter of `X0`. This range is the coal and unconventional gas resources of Rogner et al. (2012),
  and it is the largest single uncertainty on the resource side. The conventional-plus-coal variant
  is in the table.
- **`mu_N` from the price channel with `c_N(t)` absorbing the flow effect.** This is the
  identifying assumption `resources.md` says has to be made explicitly: technical progress in
  extraction exactly offset the scale effect of a twelvefold rise in the flow, so the trend of the
  real price is the stock effect. The mass-weighted aggregate (coal, oil, gas) rose two thirds in
  real terms over 1900-2015 while the composed reserve fell by a quarter; the point is 1.84. The
  metals price fell, which gives a negative elasticity, floored at zero as the range's bottom. The
  physical channel (Mudd's gold energy-grade elasticity of 0.28) sits near the metals reading.
  With `mu_N` above one the B cell exists at the point; below about 0.87 it does not.
- **`chi_N` from the rent share** is the one data-based reading of the flow curvature: cost over
  value at the margin is `1/(1+chi)` for the workhorse form, so `chi_N = value/cost - 1 = 0.48`.
  It is an upper reading (the Hotelling rent is inside the value). `chi_D = 1` by convention.
- **`kap_N`, `kap_D` at a tenth of 1900 extraction**: the choke price at a tenth of the 1900
  marginal cost. A judgement; zero would remove the choke and the possibility of stranding.
- **`c_N(t)` pinned at both ends.** The implied series is volatile (the price index carries the
  commodity cycles) and falls by a factor of about three with no flattening; the three-parameter
  fit returned a negative floor. The 1900s mean and the 2006-2015 mean are the two levels, the
  convergence rate is fitted, and the log RMSE (0.27) is reported. The floor at the end-of-sample
  level means no progress after 2015, the conservative reading; half of it is the range.
- **`mu_D` from MinEx cost per discovery** is large (5 to 9) because the room below the
  contained-metal URR shrank little while the cost tripled. Deposits are counted, not tonnes.
- **`c_D` from the exploration margin at replacement.** No discovery is needed before the reserve
  vintage by the D7 construction, so history says nothing about the level. Marginal discovery cost
  equals the WDI resource rent per tonne when `D = N_2015`. The implied total exploration cost at
  replacement (1.3 trillion) is thirty times the world's metals exploration spend; oil and gas
  exploration, the larger part, was not downloaded.

## C4 waste and recycling

- **The handled flow is the disposal outflow** (ruling 3, literally); counting the same year's
  recovered flow as handled gives `mu` a third higher and is the range. `waste_stock.md` has the D3
  tension.
- **Municipal costs applied to the whole handled flow.** The ruling fixes the mapping; B4's caution
  stands. The C8 smoke test shows the consequence: at these charges the planner treats nothing,
  and at a tenth of them the treated share is interior. The level of `cc0` and `cT0` is the first
  thing phase D has to settle, and this note is where that decision should be recorded when made.
- **`xi` through a point on the yield function.** The observed yield uses the municipal treated
  share on the non-biomass handled flow, which is a measurement of three percent of that flow
  applied to all of it; the slope uses the EPA packaging capital outlay. The implied recycling
  capital is six tenths of a percent of the world capital stock, which is at least the right
  order. Range: an order of magnitude.
- **`W0` flow-consistent**: the stock that gives the 1900 disposal flow at the calibrated `mu`, on
  the analogy of B2's steady-state initialisation of `K`. The 1900 residue alone is the low end.

## C5 preferences and damages

- **`rho`, `eta` from decade variation.** The two moments of the identification table coincide on a
  balanced path (the consumption-wealth ratio is `r - g` for any preferences), so the Euler
  equation is fitted across the seven decades of 1950-2019 instead. The fit is good (R2 0.83) and
  `eta = 1.41` passes the collapse condition (bound 1.96). `rho = 3.7 percent` is high by the
  integrated-assessment standard because the return fitted is the PWT internal rate of return on
  capital, not a risk-free rate. The alternative, fixing `eta` from the literature and backing out
  `rho` from the mean return, was not taken because it needs a number from memory.
- **`kappa` at the 3 degree anchor, marginal match** (ruling 7 left the anchor open): DICE's
  function is calibrated there, and the pollution price turns on the marginal loss. The today's
  stock anchor is in the table as the alternative. The bridge multiplies by the fossil share of DPO
  (a quarter) and the CO2 per tonne of fuel (2.7), so `kappa` per gigatonne of material is seven
  tenths of `kappa` per GtCO2.
- **`P0` at the 1900 composition** is 79 Gt of material for 27.5 GtCO2, because in 1900 the fossil
  share of the outflow was a seventh. The stock the model then carries is large relative to the
  1900 flow to the environment; `P` is a bookkeeping quantity under D4 and its level does not enter
  the damage except through `kappa P`, which at 1900 is a twentieth of a percent of output.

## C6 initial stocks

- **The `Rbar` grid** is fractions of 2015 material input (0, 0.1, 0.25, 0.5). A judgement about
  where the floor might bite; phase D can move it.
- **`varphi` is not written** (undefined at `psi_v = 0`); `Params` keeps its default, which nothing
  reads.

## The metals-only bound

Kept deliberately narrow: the ceiling, the stock-effect elasticity and the reserve side are the
metals evidence; the states that are flows of the whole economy and the extraction level stay at
the baseline. It is a bound on the recycling and reserve side, not a metals-only economy, and the
appendix says so. With `mu_N` at zero it has no state B.

## What the checks found

`check_params` clean; `wellposed_report` holds at both cells; `convexity_report` fails the same
four conditions as the illustrative set, with the two cost conditions failing also through
`chi < mu`, which the data put there. The smoke test (`data/processed/c8_smoke.txt`) stalls at
`|F| = 1.3e-4` on the last smoothing steps with the treated share at its lower corner throughout;
the rescaled set stalls at the same place, so it is not scale; with handling charges at a tenth it
converges to `4e-12` with the treated share interior (`c8_smoke_cheap_handling.txt`). On the
guess path the reserve never reaches two percent of `S0` within 2000 periods at a constant
material target, and reaches it at year 2390 with the target growing at the circular rate, so the
horizon wall of `model/README.md` is far out on this calibration.
