"""B4: Circle Economy, Circularity Gap Report 2025 -> data/interim/b4_circularity_gap.csv.

The headline Circularity Metric and the rest of the Circularity Indicator Set, typed
from tables one and two (pp. 23-24) and from the prose of figure three's accompanying
text (p. 24), which restates every rate and so cross-checks the tables.  The data year
is 2021 with 2018 as the comparison year; the report itself is dated 2025.

What the metric is, and why it cannot be used as $a\\varpi$ without adjustment, belongs
in notes/data/waste_recycling.md, not here: the denominator is total processed material
including fossil fuels burnt for energy, which by construction can never be cycled.

Run from the repository root:  python data/build/b4_circularity_gap.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b4_circularity_gap.csv")

T1 = "Circle Economy 2025, Circularity Gap Report 2025, table one, p. 23"
T2 = "Circle Economy 2025, Circularity Gap Report 2025, table two, p. 24"
F3 = "Circle Economy 2025, Circularity Gap Report 2025, figure three text, p. 24"

# (series, 2018 rate, 2018 Gt, 2021 rate, 2021 Gt)
INPUT_SIDE = [
    ("circularity_metric_input_technical_cycling", 7.2, 7.1, 6.9, 7.3),
    ("input_carbon_neutral_biomass", 21.6, 21.5, 21.5, 22.8),
    ("input_non_carbon_neutral_biomass", 2.6, 2.6, 2.2, 2.3),
    ("input_other_virgin_non_renewable", 18.0, 17.9, 18.1, 19.2),
    ("input_fossil_fuels_for_energy", 13.9, 13.9, 13.3, 14.1),
]
OUTPUT_SIDE = [
    ("output_waste_destined_for_recycling", 11.1, 7.1, 11.2, 7.3),
    ("output_waste_and_emissions_carbon_neutral_biomass", 34.5, 22.1, 35.3, 23.2),
    ("output_waste_and_emissions_non_carbon_neutral_biomass", 4.1, 2.6, 3.4, 2.2),
    ("output_waste_disposed_without_recovery", 28.3, 18.1, 28.6, 18.8),
    ("output_emissions_and_waste_fossil_fuels", 22.0, 14.1, 21.6, 14.2),
]
# Sankey totals stated in the figure-three text, gigatonnes, 2021.
TOTALS = [
    ("total_material_use", 106.1), ("material_extraction", 98.8),
    ("domestic_material_use", 67.2), ("secondary_materials", 7.3),
    ("gross_addition_to_stocks", 62.6), ("net_addition_to_stocks", 40.4),
    ("demolition_and_discard", 22.2), ("short_lived_materials", 6.9),
    ("solid_and_liquid_waste", 19.1), ("emissions_to_air", 43.5),
    ("output_to_environment", 62.6), ("total_processed_output", 65.7),
    ("net_stock_build_up_rate_denominator_check", 36.6),
]


def row(year, series, value, unit, source):
    return dict(year=year, series=series, region_or_material="World", value=value,
                unit=unit, source=source, method="transcribed")


def main():
    rows = []
    for table, block in ((T1, INPUT_SIDE), (T2, OUTPUT_SIDE)):
        for name, r18, s18, r21, s21 in block:
            rows.append(row(2018, name + "_rate", r18, "percent", table))
            rows.append(row(2018, name + "_scale", s18, "Gt_per_year", table))
            rows.append(row(2021, name + "_rate", r21, "percent", table))
            rows.append(row(2021, name + "_scale", s21, "Gt_per_year", table))
    for name, v in TOTALS:
        rows.append(row(2021, name, v, "Gt_per_year", F3))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    cm = out[(out.series == "circularity_metric_input_technical_cycling_rate") &
             (out.year == 2021)].value.iloc[0]
    print("b4_circularity_gap: %d rows -> %s (Circularity Metric 2021 = %.1f%%)"
          % (len(out), OUT, cm))


if __name__ == "__main__":
    main()
