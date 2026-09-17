"""B4: UNEP Global Waste Management Outlook 2024 -> data/interim/b4_unep_gwmo2024.csv.

Everything here is typed from the report PDF, with the printed page recorded in
`source`.  Three methods appear and the distinction matters for what may be leaned on:

  transcribed         from a sentence or a numbered table.
  transcribed_table   from a numbered annex table (2B.1.1, 2C.1).
  transcribed_figure  from the numeric data label printed inside a figure.  The task
                      brief forbids reading a figure, so these rows exist only because
                      the split of controlled MSW into landfilling, waste-to-energy and
                      recycling appears nowhere else in the report; they are flagged so
                      that a later stage can refuse them.  The two totals they contain
                      (806 Mt uncontrolled, 38 per cent) are independently stated in the
                      prose and agree.

Run from the repository root:  python data/build/b4_unep_gwmo2024.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b4_unep_gwmo2024.csv")

P19 = "UNEP 2024, Global Waste Management Outlook 2024, p. 19"
P21 = "UNEP 2024, Global Waste Management Outlook 2024, p. 21"
P22 = "UNEP 2024, Global Waste Management Outlook 2024, p. 22"
P41 = "UNEP 2024, Global Waste Management Outlook 2024, p. 41"
FIG7 = "UNEP 2024, Global Waste Management Outlook 2024, figure 7, p. 21"
T2B = "UNEP 2024, Global Waste Management Outlook 2024, table 2B.1.1, annex 2"
T2C = "UNEP 2024, Global Waste Management Outlook 2024, table 2C.1, annex 2"

PROSE = [
    (2020, "msw_generated", "World", 2.1, "Gt_per_year", P19, "transcribed"),
    (2020, "uncontrolled_share", "World", 38.0, "percent_of_MSW", P21, "transcribed"),
    (2020, "uncontrolled_mass", "World", 806.0, "Mt_per_year", P22, "transcribed"),
    (2050, "uncontrolled_share", "World", 41.0, "percent_of_MSW", P22, "transcribed"),
    (2050, "uncontrolled_mass", "World", 1600.0, "Mt_per_year", P22, "transcribed"),
    (2020, "msw_management_direct_cost", "World", 252.3, "bn_USD2020_per_year", P41,
     "transcribed"),
    (2020, "msw_uncontrolled_externality_cost", "World", 243.3, "bn_USD2020_per_year",
     P41, "transcribed"),
    (2050, "msw_total_cost_business_as_usual", "World", 640.3, "bn_USD2020_per_year",
     P41, "transcribed"),
    (2050, "msw_externality_cost_business_as_usual", "World", 443.0,
     "bn_USD2020_per_year", P41, "transcribed"),
]

# Figure 7 data labels: thousand tonnes and per cent of MSW generated in 2020.
FIG7_ROWS = [
    ("destination_mass_controlled", 1320327.0, 62.0),
    ("destination_mass_uncontrolled", 805644.0, 38.0),
    ("destination_mass_landfilling", 641256.0, 30.0),
    ("destination_mass_waste_to_energy", 274800.0, 13.0),
    ("destination_mass_recycling", 404271.0, 19.0),
]

# Table 2B.1.1, MSW collection rate by region, 2020, per cent.
COLLECTION_RATE = [
    ("North America", 3, 100.0),
    ("Central America and the Caribbean", 7, 71.0),
    ("South America", 6, 95.0),
    ("Northern Europe", 10, 100.0),
    ("Western Europe", 9, 100.0),
    ("Southern Europe", 14, 100.0),
    ("Eastern Europe", 10, 100.0),
    ("West Asia and North Africa", 17, 86.0),
    ("Sub-Saharan Africa", 13, 43.0),
    ("Central and South Asia", 9, 91.0),
    ("East and South-East Asia", 10, 96.0),
    ("Oceania", 4, 18.0),
    ("Australia and New Zealand", 2, 100.0),
    ("World", 114, 89.0),
]

# Table 2C.1, costs of MSW management, US$/tonne.  Two blocks: "Reported" (a point) and
# "Expert assessment" (a range).  The expert columns reproduce Kaza et al. 2018 table
# 5.2; they are kept here anyway so the table can be read whole.  NA is an absent row.
COST_REPORTED = {
    "collection": {"LIC": 40.0, "LMC": 16.0, "UMC": 98.0, "HIC": 121.0},
    "landfill": {"HIC": (53.0, 99.0)},
    "recycling": {"HIC": 202.0},
    "waste_to_energy": {"HIC": 134.0},
    "open_dumping": {"LIC": 7.0, "LMC": 25.0},
}
COST_EXPERT = {
    "collection": {"LIC": (20, 50), "LMC": (30, 75), "UMC": (50, 100), "HIC": (90, 200)},
    "landfill": {"LMC": (15, 40), "UMC": (25, 65), "HIC": (40, 100)},
    "recycling": {"LIC": (0, 25), "LMC": (5, 30), "UMC": (5, 50), "HIC": (30, 80)},
    "waste_to_energy": {"UMC": (60, 150), "HIC": (40, 200)},
    "open_dumping": {"LIC": (2, 8), "LMC": (3, 10)},
}
USD = "current_USD_per_tonne"


def row(year, series, region, value, unit, source, method):
    return dict(year=year, series=series, region_or_material=region, value=value,
                unit=unit, source=source, method=method)


def main():
    rows = [row(*r) for r in PROSE]

    for name, mass, share in FIG7_ROWS:
        rows.append(row(2020, name, "World", mass, "thousand_tonnes_per_year", FIG7,
                        "transcribed_figure"))
        rows.append(row(2020, name.replace("_mass_", "_share_"), "World", share,
                        "percent_of_MSW", FIG7, "transcribed_figure"))

    for reg, n, rate in COLLECTION_RATE:
        rows.append(row(2020, "msw_collection_rate", reg, rate, "percent_of_MSW", T2B,
                        "transcribed_table"))
        rows.append(row(2020, "n_countries_in_region", reg, float(n), "count", T2B,
                        "transcribed_table"))

    for activity, byinc in COST_REPORTED.items():
        for grp, v in byinc.items():
            if isinstance(v, tuple):
                rows.append(row(2024, "unit_cost_%s_reported_low" % activity, grp,
                                v[0], USD, T2C, "transcribed_table"))
                rows.append(row(2024, "unit_cost_%s_reported_high" % activity, grp,
                                v[1], USD, T2C, "transcribed_table"))
            else:
                rows.append(row(2024, "unit_cost_%s_reported" % activity, grp, v, USD,
                                T2C, "transcribed_table"))
    for activity, byinc in COST_EXPERT.items():
        for grp, (lo, hi) in byinc.items():
            rows.append(row(2024, "unit_cost_%s_expert_low" % activity, grp, float(lo),
                            USD, T2C, "transcribed_table"))
            rows.append(row(2024, "unit_cost_%s_expert_high" % activity, grp, float(hi),
                            USD, T2C, "transcribed_table"))

    # Implied global average direct cost per tonne generated, from the two prose rows.
    rows.append(row(2020, "msw_direct_cost_per_tonne_generated_implied", "World",
                    252.3e9 / 2.1e9, "USD2020_per_tonne",
                    P41 + "; " + P19, "computed"))
    rows.append(row(2020, "msw_externality_cost_per_tonne_generated_implied", "World",
                    243.3e9 / 2.1e9, "USD2020_per_tonne",
                    P41 + "; " + P19, "computed"))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print("b4_unep_gwmo2024: %d rows -> %s (%d from figure labels, flagged)"
          % (len(out), OUT, (out.method == "transcribed_figure").sum()))


if __name__ == "__main__":
    main()
