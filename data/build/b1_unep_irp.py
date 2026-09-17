"""UN IRP Global Material Flows Database, the world aggregate.

The vintage obtained covers 1970-2019 and is the mirror the sources file
records, the IRP's own portal serving the current vintage only through an
interactive application. Only the world rows are kept, and only the flows the
model uses: domestic extraction, which is the model's `N`, and domestic
material input, kept only as context. The world DMI row exceeds the world DE
row by world gross imports, because DMI adds imports without subtracting
exports; it is not a second measurement of the same quantity.

Run from the repository root:  python data/build/b1_unep_irp.py
"""

import pandas as pd

from b1_common import INTERIM, RAW, write_long

SOURCE = "unep_irp"
CSV = RAW / SOURCE / "global-material-flows-database.csv"

CATEGORIES = {
    "Biomass": "biomass",
    "Fossil fuels": "fossil",
    "Metal ores": "metals",
    "Non-metallic minerals": "non_metallic_minerals",
}
FLOWS = {"DE": "N", "DMI": "DMI"}
TONNES_PER_GT = 1e9


def main():
    frame = pd.read_csv(CSV)
    frame = frame[(frame["Country"] == "World") & (frame["Flow code"].isin(FLOWS))]
    if frame.empty:
        raise ValueError("no world rows found in {}".format(CSV))
    if set(frame["Flow unit"]) != {"t"}:
        raise ValueError("unexpected units: {}".format(set(frame["Flow unit"])))

    years = [c for c in frame.columns if c.isdigit()]
    rows = []
    for _, record in frame.iterrows():
        category = CATEGORIES.get(record["Category"])
        if category is None:
            continue
        series = FLOWS[record["Flow code"]]
        for year in years:
            value = record[year]
            if pd.isna(value):
                continue
            rows.append(
                dict(year=int(year), series=series, category=category, value=float(value) / TONNES_PER_GT,
                     unit="Gt/yr", source=SOURCE, method="observed")
            )

    # The database reports no world total row, so it is summed over the four
    # categories; the categories outside those four are empty at world level.
    totals = pd.DataFrame(rows).groupby(["year", "series", "unit"], as_index=False)["value"].sum()
    for _, record in totals.iterrows():
        rows.append(
            dict(year=int(record["year"]), series=record["series"], category="total",
                 value=float(record["value"]), unit=record["unit"], source=SOURCE, method="observed")
        )

    write_long(rows, INTERIM / "b1_unep_irp.csv")


if __name__ == "__main__":
    main()
