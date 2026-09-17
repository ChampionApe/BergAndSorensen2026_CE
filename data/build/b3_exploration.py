"""B3, source 7: exploration spend, discoveries and cost per discovery.

Schodde, R., 2023, "Exploration: Australia vs the World": MinEx Consulting,
presentation to the International Mining and Resource Conference, Sydney,
31 October 2023.  The slides print their key numbers as labels on the charts;
those labels are transcribed here with the slide number.  The underlying annual
series are drawn but not printed, so only the printed values are recorded --
nothing is read off a chart.  File: data/raw/minex/schodde_imarc_2023.pdf.

S&P Global Market Intelligence, World Exploration Trends, is commercial.  Its
public summary was not obtained and it is recorded MANUAL in
data/sources/B3_resources.md.  MinEx's own expenditure series is built partly
from S&P data, which is the closest public substitute.

What this identifies: the model's exploration cost function C^D with C^D_X > 0.
The direct empirical content is the average cost per discovery, which rose from
about $65m over 1975-2005 to about $218m over 2011-2020 in constant 2023
dollars, while the discovery rate roughly halved.

Run from the repository root:  python data/build/b3_exploration.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b3_exploration.csv")
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

MINEX = "schodde2023_minex_imarc"

# Slide 4: world exploration expenditure, labelled peaks and troughs, in
# June 2023 US$ billion, all metals including bulk minerals.
SPEND = [
    (1981, 9.4), (1988, 9.7), (1997, 10.0), (2002, 3.8),
    (2008, 28.2), (2012, 42.1), (2016, 13.3), (2022, 16.1),
]
# Slide 13: average discovery cost, in 2023 US$ million per discovery of a
# deposit at least "Moderate" in size.  Period averages, dated at the midpoint.
DISCOVERY_COST = [
    (1990, 65.0, "1975-2005"),
    (2015, 218.0, "2011-2020"),
]
# Slides 14, 29, 30: decade totals and rates.
DECADE = [
    (2017, "discoveries_per_year", 50.0, "deposits_per_year",
     "slide 29, current world rate, deposits at least Moderate in size"),
    (2017, "discoveries_decade", 737.0, "deposits",
     "slide 14, world, 2012 to 2021, including 126 in Australia"),
    (2017, "exploration_spend_decade", 196.0, "june_2023_usd_billion",
     "slide 30, world, 2012 to 2021"),
    (2017, "discovery_value_decade", 135.0, "june_2023_usd_billion",
     "slide 30, world, 2012 to 2021, notional valuation by deposit tier"),
    (2017, "bang_per_buck_decade", 0.69, "ratio",
     "slide 30, value created divided by exploration spend, world, 2012 to 2021"),
]
# Slide 22: discovery performance by region, two decades.  Columns as printed:
# spend (US$b), number of discoveries, number of significant discoveries,
# $m per discovery, bang-per-buck.
REGION = [
    ("australia", 21.6, 24.4, 294, 153, 42.2, 29.1, 1.96, 1.19),
    ("canada", 27.1, 25.7, 124, 110, 24.4, 20.1, 0.90, 0.78),
    ("united_states", 12.2, 13.4, 36, 41, 12.6, 7.3, 1.03, 0.54),
    ("latin_america", 32.0, 40.2, 253, 102, 38.1, 16.7, 1.19, 0.42),
    ("africa", 20.0, 22.5, 324, 194, 46.6, 26.7, 2.33, 1.19),
    ("pacific_se_asia", 7.5, 8.2, 73, 20, 9.6, 5.2, 1.28, 0.63),
    ("western_europe", 3.4, 4.8, 42, 30, 2.6, 3.4, 0.77, 0.70),
    ("eastern_europe", 2.4, 2.2, 23, 8, 4.1, 3.2, 1.70, 1.46),
    ("fsu", 10.5, 11.0, 73, 38, 7.8, 3.1, 0.75, None),
]
REGION_PERIODS = ((2006, "2002-2011"), (2016, "2012-2021"))


def main():
    rows = []
    for year, value in SPEND:
        rows.append(dict(year=year, series="world_exploration_spend",
                         commodity="all_metals", value=value,
                         unit="june_2023_usd_billion",
                         source=MINEX + ":slide4", method="transcribed"))
    for year, value, period in DISCOVERY_COST:
        rows.append(dict(year=year, series="average_discovery_cost",
                         commodity="all_metals", value=value,
                         unit="2023_usd_million_per_discovery (period {})".format(
                             period),
                         source=MINEX + ":slide13", method="transcribed"))
    for year, series, value, unit, where in DECADE:
        rows.append(dict(year=year, series=series, commodity="all_metals",
                         value=value, unit="{} [{}]".format(unit, where),
                         source=MINEX, method="transcribed"))
    for (region, spend1, spend2, disc1, disc2, cost1, cost2, bpb1,
         bpb2) in REGION:
        for (year, period), spend, disc, cost, bpb in (
            (REGION_PERIODS[0], spend1, disc1, cost1, bpb1),
            (REGION_PERIODS[1], spend2, disc2, cost2, bpb2),
        ):
            for series, value, unit in (
                ("regional_exploration_spend", spend, "june_2023_usd_billion"),
                ("regional_discoveries", disc, "deposits"),
                ("regional_cost_per_discovery", cost,
                 "june_2023_usd_million_per_discovery"),
                ("regional_bang_per_buck", bpb, "ratio"),
            ):
                if value is None:
                    continue
                rows.append(dict(
                    year=year, series=series, commodity=region,
                    value=float(value),
                    unit="{} (period {})".format(unit, period),
                    source=MINEX + ":slide22", method="transcribed"))
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["series", "commodity", "year"]
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print(
        "b3_exploration: {} rows from Schodde (2023, MinEx) slides 4, 13, 14, 22, "
        "29 and 30; S&P World Exploration Trends MANUAL -> {}".format(
            len(out), OUT
        )
    )


if __name__ == "__main__":
    main()
