# Macro aggregates and the GDP use split

Decision area B2 of `notes/plan_calibration_experiments.md`. Why the world `Y`, `POP`, `C`, `G` and
`K` of `data/interim/b2_macro_block.csv` are built the way they are. What the scripts do is in the
scripts; provenance is in `data/SOURCES.md`, block B2; the numbers a reader needs go in the
quantitative note's data appendix, not here (`docs_style.md` §5).

Written 2026-09-17.

## The shape of the problem

Two sources cover the century and neither covers it alone. Maddison runs 1820-2022 but carries only
GDP per capita and population — no capital, no use split. Penn World Table carries capital and the
use split but starts in 1950, and is denominated in 2017 US dollars where decision D5 asks for 2011
international dollars.

The split adopted: **Maddison carries every level, PWT carries every ratio.** The capital-output
ratio, the investment share and the depreciation rate are dimensionless and survive the change of
base year untouched; multiplying them into Maddison's GDP puts everything in D5 units without ever
constructing a 2017-to-2011 deflator that no result would depend on. The alternative — rebasing
PWT's levels and using them directly — was rejected for that reason and because it would then take
a second decision about how to reconcile two different world GDP levels (122.5 against 124.9
trillion in 2019) that differ for reasons of price base, not of measurement.

## Maddison: which aggregation, and what it covers

`b2_maddison.py`. Three choices.

**Composite entities.** The MPD reports Former USSR, Czechoslovakia and Former Yugoslavia over the
whole period *and* their twenty-three successor states from 1950, so a naive country sum double
counts 8 per cent of world population in 1950, falling to 5 per cent by 2000. The successors are
dropped through 1990 and the composites from 1991. That is the MPD's own convention, and the test
that it is: the resulting population sum equals the MPD's published world population exactly in
1950, 2000, 2010 and 2015-2022, and to within 0.04 per cent in 1960, 1970, 1980 and 1990.

**1950-2022 is a country sum.** Coverage is 99.6 per cent of world population or better, so the
scale-up from the covered countries to the world is immaterial; the largest gap between the result
and the MPD's own world GDP at a benchmark year is 0.30 per cent.

**1900-1949 is not.** This is the one place a plausible method had to be abandoned. The MPD's
country sample before 1950 is not a panel: the number of countries with both GDP per capita and
population swings between 36 and 68 from one year to the next, population coverage swings between
61 and 99 per cent, and the implied world GDP per capita jumps by as much as 37 per cent between
adjacent years from composition alone. Three routes were tried.

1. *Naive country sum.* Unusable, for the reason just given.
2. *Chain-linking* the growth of the sample common to each adjacent pair of years, anchored at 1950.
   This is the standard repair and here it fails badly: run back from 1950 it puts world GDP per
   capita in 1900 at 1727 against the MPD's own 2265, a 24 per cent gap, because the countries that
   enter the sample later are systematically poorer and the common sample is sometimes only a few
   dozen countries wide.
3. *Benchmark plus indicator*, which is what the pipeline does. The MPD publishes its own world GDP
   per capita and population at 1900, 1920, 1940 and 1950; those carry the level. The annual
   movement between them comes from a balanced panel of the 32 countries observed in every year of
   1900-1950 — 73 per cent of covered world GDP in 1900, 46 per cent of world population — with the
   discrepancy against the benchmarks spread log-linearly within each interval. Population is
   interpolated between the same benchmarks without an indicator, since it is smooth and an
   indicator would add noise rather than information.

Every 1900-1949 row is flagged `interpolated`. What this costs is the annual business cycle in the
first half of the century: the level in 1900, 1920, 1940 and 1950 is the MPD's, and the years
between carry a 32-country cycle scaled to fit, not the world's. Base year 1900 (D2) is a benchmark
year, so the model's initial condition is not affected. A result that turned on the shape of the
1914-18 or 1929-33 contraction in the world aggregate would be resting on something this series does
not contain, and should say so.

## Penn World Table: the price concept, and what it covers

`b2_pwt.py`. PWT carries two capital stocks and only one of them can be summed across countries:
`rnna` is at constant 2017 *national* prices, so its units differ by country, while `cn` is at
current PPPs. `cn` is used, with `cgdpo` (output-side real GDP at current PPPs) as its denominator,
which is the pairing PWT is constructed to support. The use shares `csh_*` are shares of the same
`cgdpo`.

Coverage is the caveat. PWT has 183 countries but only 55 of them in 1950, covering 52 per cent of
world population; 86 per cent by 1960, 92 per cent by 1980, effectively complete from 2000. The
world aggregates are sums over whatever is observed in each year, and `pwt_population_coverage` in
the block records the share so that phase C can see how thin 1950 is. The 1950 observation matters
more than the others, because it is the anchor for the capital reconstruction.

## The use split

`C` is household *plus* government consumption, `G` is gross capital formation. The model has one
consumption good and no public sector; putting government consumption into `G` would count it as
capital formation, which it is not. Net exports and PWT's residual trade and statistical
discrepancy have no counterpart in a closed world economy and are dropped, the shares being
renormalised on consumption plus gross capital formation. They are small — between -1.7 and +1.7
per cent of world GDP over the whole sample — and are written out as
`share_net_exports_and_residual` in `b2_pwt.csv` so the size stays visible rather than being
asserted here.

Before 1950 the split is held at the 1950 world split and flagged `reconstructed`, per the task
brief. After 2019, where PWT ends, it is held at 2019, also flagged.

## The capital stock before 1950, and the one thing that did not work

`b2_macro_block.py`. From 1950 `K` is PWT's world `cn/cgdpo` on Maddison's GDP. Before 1950 it is a
perpetual inventory, `K_{t+1} = (1-delta) K_t + s Y_t`, with `delta` PWT's cn-weighted world
depreciation rate in 1950 and the 1900 stock at its steady-state value `s Y_1900 / (g + delta)`,
`g` being the trend growth of `Y` over 1900-1913 — the pre-war window, chosen because it is the one
stretch of the pre-1950 period without a war or a depression in it. The recursion is linear and
homogeneous of degree one in `s` given that initialisation, so requiring it to reproduce the 1950
anchor pins `s` in closed form; there is no search and no tuning.

**It does not pin `s` at the 1950 investment share, and it cannot.** Holding the 1950 share of
0.210 back to 1900 accumulates about a fifth more capital by 1950 than the 1950 stock holds; run
the other way, solving for the 1900 stock at that share, gives a *negative* initial capital stock.
The anchored share is 0.175. That is the expected direction and it has an obvious reading: the
share has to absorb both genuinely lower pre-war investment rates and the capital destroyed in two
world wars, which a recursion with no destruction term has no other way to represent.

This leaves the block with two investment shares before 1950 — `investment_share` at the 1950 value,
which is what the use split asks for, and `investment_share_pim` at 0.175, which is what the capital
stock needs. They are carried side by side rather than reconciled. Reconciling them means choosing
which of the two things to give up: a `G` series consistent with the 1950 split, or a `K` series
consistent with the 1950 stock. Phase C should make that choice knowingly, and record it; the
pipeline will not make it silently.

A cheap robustness check, worth recording because it came out well: initialising the recursion by
assuming the world capital-output ratio in 1900 equalled its 1950 value gives 12.63 trillion against
the steady-state initialisation's 12.76, a 1 per cent difference. The 1900 stock is not sensitive to
which of the two conventions is used.

## The Piketty-Zucman cross-check, and why it is weak

The reconstructed world capital-output ratio runs 3.03 (1900), 3.58 (1920), 3.31 (1940), 3.60
(1950). The United States national wealth to national income ratio of Piketty and Zucman (2014) runs
4.93, 3.71, 4.58, 3.80 at the same dates. The orders of magnitude agree and the mid-century level
agrees closely; the 1900 levels do not, and the paths point in opposite directions over the half
century.

Both differences are what the concepts predict, which is why this is a sanity check and not a
validation. Piketty and Zucman's denominator is national income, net of depreciation, which is
smaller than GDP by something on the order of a tenth; their numerator is the market value of all
assets net of liabilities, which includes agricultural and urban land and net foreign assets, where
the perpetual inventory and PWT's `cn` are produced fixed assets only. Land was a large share of US
wealth in 1900 and a small one by 1950, so a falling wealth-income ratio against a rising
capital-output ratio over that window is the expected pattern, not a contradiction. And the
comparison is one rich country against the world.

The check that would actually bite — produced capital against produced capital, for a set of
countries covering a decent share of 1900 world output — needs the other eight Piketty-Zucman
workbooks and their land decomposition. Those workbooks are in the legacy `.xls` format, which
cannot be opened without `xlrd`, which is not installed. It is recorded as MANUAL in
`data/SOURCES.md`, block B2. Until it is done, `K` before 1950 should be read as an
order-of-magnitude reconstruction with an anchored endpoint, not as a measurement.

## The material intensity join

`b2_omega_join.py` puts B1's material input `R` over two denominators: world GDP, which is the
intensity the material-flow literature publishes, and the model's activity aggregate
`D + phiI * G`, which is the one the model's own equations use. The weights in `D` are placeholders
of 1.0 in a marked block at the top of the script, and are the business of phase C1 — they are not
estimates, and a number read off `Omega_model` before C1 has run has no source. The observed
intensity is the fact; the model intensity is a fact conditional on weights, and the two are kept
apart for that reason.

## Phase C: the choice between the two shares (2026-09-17)

Ruling 5 of the phase C brief resolves the two pre-1950 investment shares this note left side by
side: the perpetual-inventory share (0.175) is used for both `K` and `G` before 1950, so the
reconstructed capital stock and the reconstructed gross formation rest on one share. The cost is a
pre-1950 consumption share above the 1950 split; the alternative, the 1950 split for `G` with the
PIM share for `K`, is what `b2_macro_block.csv` still carries and what `b2_omega_join.py` uses.
The split is applied in `data/build/c_common.py` (`macro_series`) and flows into
`data/processed/series.csv` and the accounting weights of C1. `b2_omega.csv` is rebuilt with the
C1 weights, which `b2_omega_join.py` now reads from `data/processed/c1_weights.json` when it
exists. Phase C also aggregated two PWT rates this block did not extract, the internal rate of
return and the labour share (`c_common.py`, `pwt_world`), for the preference and production
blocks.
