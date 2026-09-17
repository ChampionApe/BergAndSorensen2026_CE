# Pollution and damages

Decision area B5 of `notes/plan_calibration_experiments.md`. Why `P`, `theta(P)`, `kappa` and
`psi` of `data/interim/b5_pollution_block.csv` are built the way they are. What the scripts do is
in the scripts (`data/build/b5_gcb.py`, `b5_joos2013.py`, `b5_dice2023.py`, `b5_ipcc_ar6.py`,
`b5_pollution_block.py`); provenance is in `data/sources/B5_pollution.md`; the numbers a reader
needs to reproduce a result go in the quantitative note's data appendix, not here
(`docs_style.md` §5).

Written 2026-09-17.

## (B) rather than (A)

Decision D4 fixes strategy **(B)**: `P` is cumulative fossil CO2, `Xi` reaches it through the
fossil share of the outflow, and damages come from a conventional integrated-assessment loss. The
data plan §2h gives the reasoning and it is not reopened here. In short: (B) is well evidenced and
comparable to the literature, and it prices only one component of the outflow; (A),
materials-as-pollution, is internally consistent with the ledger but rests on damage evidence that
is thin and has no counterpart at all for `theta(P)`. The plan's own judgement is that the
pollution block is the least tightly identified part of the model and the one the paper's results
depend on least, because the taxonomy of the long run turns on the material block.

Two things the choice costs, which the appendix should say out loud rather than bury.

**`theta(P)` becomes the carbon cycle, and the model's form is the wrong shape for it.** The
workhorse has `theta' < 0`: a larger stock regenerates more slowly, which is the sink saturation a
carbon-cycle model does display. But `theta(0) = theta_0` is the *fastest* rate, so the model
removes slowly while the stock is large and faster as it shrinks, and it always removes everything
in the end. The carbon cycle does the opposite: it removes a third of a pulse within a decade and
then almost nothing, and about a fifth never leaves. A one-stock regeneration floor is not a carbon
cycle, and no choice of the three parameters makes it one. The section below measures how badly.

**The TCRE is a map from cumulative *total* anthropogenic CO2 to temperature, and `P` is
cumulative *fossil* CO2.** Over 1750-2024 the fossil share of cumulative anthropogenic CO2 is 0.64
(Global Carbon Budget 2025, Table 8), so the temperature the TCRE assigns to the fossil stock alone
in 2024 is 0.83 degrees against the 1.36 degrees of human-induced warming the same budget reports.
Phase C has to close that gap deliberately: either scale `P` by the fossil share, or read `P` as
total anthropogenic CO2 with `Xi` covering only the fossil part of it and the rest exogenous. The
block reports the fossil share so the choice can be made on the number, not by default.

## `P_0` at 1900, under two readings

`P` is fed by `Xi` and drained by `theta(P) P`, so "cumulative emissions" and "the stock" are the
same object only when `theta = 0`. Stocks dated `t` are measured at the beginning of period `t`
(theory note, *Time*), so `P_1900` is what emissions through 1899 leave behind. Both readings are
in the block file and neither is chosen here:

| reading | `P_0` at 1900, GtCO2 |
|---|---|
| cumulative fossil CO2 since 1750 | 43.14 |
| the same with the carbonate process emissions removed | 43.13 |
| atmospheric excess stock, Joos impulse response applied to the pre-1900 path | 27.54 |
| the model's own transition at the driven `theta` below | 30.70 |

The impulse-response reading applies a response function fitted to a 100 GtC pulse on a 389 ppm
present-day background to nineteenth-century emissions on a preindustrial background, where the
sinks were less saturated. It is an approximation and it errs towards too much retention, so the
27.54 is an upper bound on what that reading would give with a background-consistent response.

A consistency check that the block reports: cumulative fossil CO2 1750-2024 from the flat file is
1849.1 GtCO2, against 1833.3 GtCO2 (500 GtC) in the paper's Table 8, which includes the cement
carbonation sink the flat file does not net out. The 16 GtCO2 gap is that sink.

## Fitting `theta(P)`, and what the fit says

`b5_pollution_block.py` runs the model's transition with `Xi = 0` from a stock the size of
cumulative fossil CO2 to date (1849.1 GtCO2) and fits `(theta_0, theta_min, theta_P)` to the Joos
et al. (2013) multi-model mean impulse response over 0 to 300 years by least squares on the
retained share. Method is `fitted`. The result:

| | value |
|---|---|
| `theta_min` | 0.006523 per year |
| `theta_0` | 0.4730 per year, **not identified** |
| `theta_P` | 0.09104 per GtCO2, **not identified** |
| RMSE of the retained share | 0.1534 |
| largest absolute error | 0.2811 |
| retained share at 100 yr, model against Joos | 0.5197 against 0.4094 |
| retained share at 300 yr, model against Joos | 0.1404 against 0.3221 |

Three readings of that table.

**The state dependence buys nothing.** The best constant `theta` over the same horizon is 0.006523
per year with the same RMSE to twelve decimal places. The fit drives `theta_P` high enough that
`exp(-theta_P P)` is numerically zero over the whole path, which switches the exponential term off
and leaves `theta_0` free. That is not an optimiser failure: `theta' < 0` can only *raise* the
removal rate as the stock shrinks, and the target wants the rate to fall, so the term's best
contribution is none at all.

**`theta_0` is therefore a reported value and not an estimate.** A decay experiment over 300 years
starting from a large stock never visits the region where `theta_0` acts, so any value fits equally
well and the sufficient no-tipping condition of the workhorse appendix,
`rho + theta_min >= (theta_0 - theta_min)/e`, is a restriction on what to report rather than a test
the data can fail. At `rho = 0.015` the unconstrained optimum has margin **-0.150 per year and
fails the condition**, purely because 0.473 is an arbitrary point in a flat direction. The ceiling
the condition imposes is `theta_0 <= theta_min + e(rho + theta_min) = 0.06503` per year, and any
`theta_0` below it fits exactly as well. The recommendation to phase C is to report
`theta_0 = theta_min`, `theta_P = 0`, which is the constant-decay corner the illustrative set of
`model/src/calibration.jl` already uses, and to say in the appendix that the pollution stock's
state dependence is not identified by this evidence.

**The pulse fit and the historical record give different rates.** Run the observed emission path
through the model's own transition with a constant `theta` and ask which rate leaves the stock the
impulse response says is there in 2024 (1080.7 GtCO2): the answer is **0.01816 per year**, nearly
three times the pulse fit's 0.006523. The two disagree because a least-squares fit to a pulse over
300 years splits the difference between a fast decade and a slow century, while the driven fit is
dominated by the last fifty years of emissions, which have not yet been through the slow sinks. The
driven rate reproduces an observed stock and the pulse rate reproduces a textbook response; phase C
should take the driven rate for the baseline, report the pulse rate beside it, and treat the gap as
the honest width of this parameter. Both are in the block file.

## `kappa`: the ingredients and the arithmetic, not the choice

The model loses output by `e^{-kappa P}`. Three published ingredients turn that into a number, and
the arithmetic is written out here for phase C to carry out, per the task's instruction not to
choose `kappa` in this block.

| ingredient | value | source |
|---|---|---|
| `pi2`, the DICE-2023 damage share per degree squared | 0.003444 | Barrage and Nordhaus (2024), §3.3, backed out of 3.1 per cent of output at 3 degrees; the 4.5 degree point over-identifies it and misses by 0.025 percentage points of output |
| `pi1`, the linear damage term | 0 | the same two points |
| the Howard and Sterner alternative `pi2` | 0.01 | Barrage and Nordhaus (2024), §4.6, 9 per cent of output at 3 degrees |
| TCRE, best estimate | 0.00045 degC per GtCO2 | IPCC AR6 WGI, ch. 5, §5.5.1.4 (1.65 degC per 1000 PgC) |
| TCRE, likely range | 0.00027 to 0.00063 | the same (1.0 to 2.3 degC per 1000 PgC) |

DICE loses the share `Omega = pi2 T^2` of gross output and the TCRE makes `T = tcre * P`, so
equating the two at a reference stock `P_ref` gives either

    kappa_level    = -ln(1 - pi2 (tcre P_ref)^2) / P_ref
    kappa_marginal = 2 pi2 tcre^2 P_ref / (1 - pi2 (tcre P_ref)^2)

according to whether the model is asked to lose the same output at `P_ref` or to lose it at the
same rate there. The two differ because the model's loss is exponential in `P` and DICE's is
quadratic, so they can agree at one stock and nowhere else; which one matters depends on whether
the experiment turns on the level of damages or on the marginal damage that prices `Xi`. For E3 and
E4, which turn on the gate fee and the pollution price, it is the marginal match.

At the best-estimate TCRE, with the range over the TCRE in the block file:

| reference stock | output loss there | `kappa_level` | `kappa_marginal` |
|---|---|---|---|
| 1849.1 GtCO2, cumulative fossil CO2 to 2024 | 0.24 per cent | 1.29e-06 | 2.59e-06 |
| 6666.7 GtCO2, the stock the TCRE puts at 3 degrees | 3.1 per cent | 4.72e-06 | 9.60e-06 |

Both are per GtCO2. The spread between the two rows is the whole question of where to anchor, and
it is a factor of four; the spread across the TCRE range at a fixed anchor is a further factor of
about six, from `kappa_level` 1.68e-06 to 9.40e-06 at the 3 degree anchor. The first row's loss of
a quarter of a per cent is small because the fossil-only stock carries only 0.83 degrees under the
TCRE, which is the fossil-share gap of the first section, not a damage estimate.

The illustrative set of `model/src/calibration.jl` uses `kappa = 0.02`, which is four orders of
magnitude above any of these. That is a units statement, not a disagreement: the illustrative model
is not denominated in gigatonnes CO2. It does mean the calibrated `kappa P` term will be small at
1900 and phase C should check that the pollution price has not silently become numerical noise.

## `psi = 0`, and what a positive `psi` would take

DICE-2023 has no utility damage channel. Damages enter once, as the share `Omega` of gross output
in `Q = [1 - Lambda][1 - Omega] A K^gamma L^(1-gamma)`; there is no separate term in the felicity
function and none of the three components of the damage estimate (the literature synthesis, the
tipping-point study, the judgemental adjustment for excluded impacts) is carved out as non-market.
Taking `kappa` from that source and also switching on `v(P) = psi P^{1+varphi}/(1+varphi)` would
count the same damages twice. So **`psi = 0`**, and `varphi` is then undefined and is written as
missing rather than as a number.

This is a corner. The workhorse appendix specifies `psi > 0` and `varphi > 0`, so the calibrated
baseline sits on the boundary of the stated parameter space, and the appendix has to say so. The
model's welfare comparisons are unaffected in kind, since `kappa` already makes pollution costly;
what is lost is the channel through which pollution hurts at the margin even when output does not
respond, which is the channel a non-market damage estimate would speak to.

A positive `psi` would need a source that splits damages into market and non-market components
rather than a single output loss. The candidates, none of them downloaded: the mortality and
morbidity valuations that sit under the OECD welfare-cost estimates in the strategy (A) list of
`data/sources/B5_pollution.md`, which are willingness-to-pay figures and belong in utility rather
than in output; or an integrated-assessment damage function that carries an explicit non-market
share. Whichever is used, `varphi` is a curvature that no aggregate study identifies, so it would
be a range and a sensitivity, not an estimate.

## What strategy (A) would need

Recorded, not built. `P` would be the accumulated dissipative material outflow, which the B1 ledger
already produces as domestic processed output, so the inflow side is free and is arguably a better
match to `Xi` than the fossil share is. What is missing is everything else.

1. **A damage function in tonnes.** The Global Burden of Disease attributable burdens give deaths
   and DALYs by risk factor, and the OECD welfare costs give a monetary value per death; together
   they give a cost of the *exposure*, not of the *stock of accumulated waste*, and the step from
   one to the other is a dispersion model this project has no business building. The honest
   reduced form would be a loss per tonne of dissipative outflow per year, calibrated so that the
   total matches the OECD welfare cost in a recent year, which makes damages a flow cost on `Xi`
   rather than a stock cost on `P`, and so changes the model rather than its calibration.
2. **A regeneration function.** `theta(P)` has no counterpart. Heavy metals and persistent organics
   do not regenerate on any horizon the model runs over, which argues for `theta_min` near zero,
   and the assimilative capacity that does exist is local rather than global. Setting `theta = 0`
   makes `P` cumulative, which is defensible and removes the parameter, at the cost of the
   regeneration floor that the long-run section's assumptions lean on.
3. **`kappa` in the model's units,** which would follow from 1 once a reference stock existed.

The reason to hold (A) open is that it is the version in which the paper's own mechanism, recycling
diverting material from the environment, prices the whole outflow rather than its fossil quarter.
The reason it is a variant is that steps 1 and 2 are research projects, not calibration steps.
