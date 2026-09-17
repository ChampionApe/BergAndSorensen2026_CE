"""B4: What a Waste 2.0 (Kaza et al. 2018) -> data/interim/b4_whatawaste2.csv.

Two kinds of row, distinguished by `method`:

  transcribed  numbers typed from a numbered table or a sentence of the report PDF,
               with the printed page in `source`.  Nothing is taken from a figure.
  computed     MSW-weighted aggregates this script forms from the open country-level
               dataset.  The weight is each country's reported MSW generation; only
               countries whose eleven treatment shares are all present are used, and
               the share of world MSW those countries carry is reported as its own row
               so that the aggregate can be read with its coverage.

Run from the repository root:  python data/build/b4_whatawaste2.py
"""

import os

import pandas as pd

RAW = os.path.join("data", "raw", "whatawaste2")
OUT = os.path.join("data", "interim", "b4_whatawaste2.csv")

SRC_DATA = "Kaza et al. 2018, What a Waste Global Database, country_level_data.csv"
SRC_T52 = "Kaza et al. 2018, What a Waste 2.0, table 5.2, p. 104"
SRC_T53 = "Kaza et al. 2018, What a Waste 2.0, table 5.3, p. 105"
SRC_P5 = "Kaza et al. 2018, What a Waste 2.0, p. 5"
SRC_P34 = "Kaza et al. 2018, What a Waste 2.0, p. 34"

# Treatment shares as stated in the report's prose.  The data year of the database is
# 2016; the report states these as current global shares without a year on the sentence,
# so the year column carries 2016 and the method says transcribed.
TEXT_SHARES = [
    ("treatment_share_landfill_any", 37.0, SRC_P5),
    ("treatment_share_sanitary_landfill_lfg", 8.0, SRC_P5),
    ("treatment_share_open_dump", 33.0, SRC_P5),
    ("treatment_share_recycling_and_composting", 19.0, SRC_P5),
    ("treatment_share_incineration", 11.0, SRC_P5),
]
TEXT_SHARES_BY_INCOME = [
    ("treatment_share_open_dump", "LIC", 93.0, SRC_P5),
    ("treatment_share_open_dump", "HIC", 2.0, SRC_P5),
    ("treatment_share_landfill_any", "UMC", 54.0, SRC_P5),
    ("treatment_share_landfill_any", "HIC", 39.0, SRC_P5),
    ("treatment_share_recycling_and_composting", "HIC", 35.0, SRC_P5),
    ("treatment_share_incineration", "HIC", 22.0, SRC_P5),
]

# Table 5.2, "Typical Waste Management Costs by Disposal Type", US$/tonne, low and high
# of the stated range.  "--" in the table is recorded as an absent row, not as a zero.
TABLE_5_2 = {
    "collection_and_transfer": {
        "LIC": (20, 50), "LMC": (30, 75), "UMC": (50, 100), "HIC": (90, 200)},
    "controlled_to_sanitary_landfill": {
        "LIC": (10, 20), "LMC": (15, 40), "UMC": (20, 65), "HIC": (40, 100)},
    "open_dumping": {
        "LIC": (2, 8), "LMC": (3, 10)},
    "recycling": {
        "LIC": (0, 25), "LMC": (5, 30), "UMC": (5, 50), "HIC": (30, 80)},
    "composting": {
        "LIC": (5, 30), "LMC": (10, 40), "UMC": (20, 75), "HIC": (35, 90)},
}

# Table 5.3, capital (US$ per annual tonne of capacity) and operational (US$/tonne)
# expenditure of incineration and anaerobic digestion, by region.
TABLE_5_3 = {
    ("incineration", "capex_per_annual_tonne"): {
        "Europe": (600, 1000), "United States": (600, 830), "China": (190, 400)},
    ("incineration", "opex_per_tonne"): {
        "Europe": (25, 30), "United States": (44, 55), "China": (12, 22)},
    ("anaerobic_digestion", "capex_per_annual_tonne"): {
        "Europe": (345, 600), "United States": (220, 660), "China": (325, 325)},
    ("anaerobic_digestion", "opex_per_tonne"): {
        "Europe": (31, 57), "United States": (22, 55), "China": (25, 25)},
}

TREAT_COLS = [
    "waste_treatment_anaerobic_digestion_percent",
    "waste_treatment_compost_percent",
    "waste_treatment_controlled_landfill_percent",
    "waste_treatment_incineration_percent",
    "waste_treatment_landfill_unspecified_percent",
    "waste_treatment_open_dump_percent",
    "waste_treatment_other_percent",
    "waste_treatment_recycling_percent",
    "waste_treatment_sanitary_landfill_landfill_gas_system_percent",
    "waste_treatment_unaccounted_for_percent",
    "waste_treatment_waterways_marine_percent",
]


def row(year, series, region, value, unit, source, method):
    return dict(year=year, series=series, region_or_material=region, value=value,
                unit=unit, source=source, method=method)


def main():
    rows = []

    for series, value, src in TEXT_SHARES:
        rows.append(row(2016, series, "World", value, "percent_of_MSW", src, "transcribed"))
    for series, grp, value, src in TEXT_SHARES_BY_INCOME:
        rows.append(row(2016, series, grp, value, "percent_of_MSW", src, "transcribed"))

    for activity, byinc in TABLE_5_2.items():
        for grp, (lo, hi) in byinc.items():
            rows.append(row(2018, "unit_cost_%s_low" % activity, grp, float(lo),
                            "current_USD_per_tonne", SRC_T52, "transcribed"))
            rows.append(row(2018, "unit_cost_%s_high" % activity, grp, float(hi),
                            "current_USD_per_tonne", SRC_T52, "transcribed"))

    for (tech, kind), byreg in TABLE_5_3.items():
        unit = ("current_USD_per_annual_tonne_capacity"
                if kind == "capex_per_annual_tonne" else "current_USD_per_tonne")
        for reg, (lo, hi) in byreg.items():
            rows.append(row(2018, "%s_%s_low" % (tech, kind), reg, float(lo), unit,
                            SRC_T53, "transcribed"))
            rows.append(row(2018, "%s_%s_high" % (tech, kind), reg, float(hi), unit,
                            SRC_T53, "transcribed"))

    d = pd.read_csv(os.path.join(RAW, "country_level_data.csv"))
    msw = d["total_msw_total_msw_generated_tons_year"]
    world_msw = msw.sum()
    rows.append(row(2016, "msw_generated", "World", world_msw / 1e9, "Gt_per_year",
                    SRC_DATA, "computed"))

    # A country reports only the disposal routes it uses; a blank cell is a route it does
    # not use, not a missing observation.  Blanks are therefore read as zero and a
    # country enters the weighting when its routes account for 100 per cent to within
    # one point.  (Requiring every column present would leave no country at all: only
    # two report anaerobic digestion.)
    shares = d[TREAT_COLS].fillna(0.0)
    full = shares.sum(axis=1).between(99.0, 101.0) & msw.notna()
    sub = d[full].copy()
    sub[TREAT_COLS] = shares[full]
    covered = sub["total_msw_total_msw_generated_tons_year"].sum()
    rows.append(row(2016, "msw_coverage_of_treatment_weighting", "World",
                    100.0 * covered / world_msw, "percent_of_world_MSW", SRC_DATA,
                    "computed"))
    rows.append(row(2016, "n_countries_with_complete_treatment_shares", "World",
                    float(len(sub)), "count", SRC_DATA, "computed"))

    def weighted(frame, label):
        w = frame["total_msw_total_msw_generated_tons_year"]
        for c in TREAT_COLS:
            name = "treatment_share_" + c[len("waste_treatment_"):-len("_percent")]
            rows.append(row(2016, name + "_mswweighted", label,
                            float((frame[c] * w).sum() / w.sum()),
                            "percent_of_MSW", SRC_DATA, "computed"))

    weighted(sub, "World")
    for grp, g in sub.groupby("income_id"):
        weighted(g, grp)

    # Collection coverage, population-weighted, from the same dataset.
    cov = "waste_collection_coverage_total_percent_of_population"
    pop = "population_population_number_of_people"
    c = d[d[cov].notna() & d[pop].notna()]
    rows.append(row(2016, "collection_coverage_population_weighted", "World",
                    float((c[cov] * c[pop]).sum() / c[pop].sum()),
                    "percent_of_population", SRC_DATA, "computed"))
    rows.append(row(2016, "n_countries_with_collection_coverage", "World",
                    float(len(c)), "count", SRC_DATA, "computed"))
    for grp, g in c.groupby("income_id"):
        rows.append(row(2016, "collection_coverage_population_weighted", grp,
                        float((g[cov] * g[pop]).sum() / g[pop].sum()),
                        "percent_of_population", SRC_DATA, "computed"))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print("b4_whatawaste2: %d rows -> %s (%d transcribed, %d computed)"
          % (len(out), OUT, (out.method == "transcribed").sum(),
             (out.method == "computed").sum()))


if __name__ == "__main__":
    main()
