"""B3, source 1: Jacks (2019) real commodity prices, 1850-2025.

Raw: data/raw/jacks2019/Real-commodity-prices-1850-2025.xlsx (three sheets:
Commodities, Indices, Sub-indices).  Every series in the workbook is an index
with 1900 = 100; the commodity columns are grouped by the header row into
Animal products, Energy, Grains, Metals, Minerals, Precious Metals and Softs.
The group is carried into the series name because the resource block needs the
Metals and Minerals groups separately from the rest.

Run from the repository root:  python data/build/b3_jacks.py
"""

import os

import pandas as pd

RAW = os.path.join("data", "raw", "jacks2019", "Real-commodity-prices-1850-2025.xlsx")
OUT = os.path.join("data", "interim", "b3_jacks.csv")
SOURCE = "jacks2019"
UNIT = "index_1900=100"
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]


def _slug(text):
    keep = [c.lower() if c.isalnum() else "_" for c in str(text).strip()]
    out = "".join(keep)
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("_")


def read_commodities():
    """Row 0 holds the group, row 1 the commodity name, row 2 onwards the data."""
    raw = pd.read_excel(RAW, sheet_name="Commodities", header=None)
    groups = {}
    current = None
    for col in range(1, raw.shape[1]):
        label = raw.iloc[0, col]
        if isinstance(label, str) and label.strip():
            current = _slug(label)
        groups[col] = current
    rows = []
    for col in range(1, raw.shape[1]):
        name = raw.iloc[1, col]
        if not isinstance(name, str):
            continue
        years = pd.to_numeric(raw.iloc[2:, 0], errors="coerce")
        values = pd.to_numeric(raw.iloc[2:, col], errors="coerce")
        for year, value in zip(years, values):
            if pd.isna(year) or pd.isna(value):
                continue
            rows.append(
                {
                    "year": int(year),
                    "series": "real_price_" + groups[col],
                    "commodity": _slug(name),
                    "value": float(value),
                    "unit": UNIT,
                    "source": SOURCE,
                    "method": "observed",
                }
            )
    return rows


def read_index_sheet(sheet, series, names):
    """Indices and Sub-indices: row 0/1 carry a two-line header, then the data."""
    raw = pd.read_excel(RAW, sheet_name=sheet, header=None)
    header_rows = 2 if sheet == "Indices" else 1
    rows = []
    for col, name in names.items():
        years = pd.to_numeric(raw.iloc[header_rows:, 0], errors="coerce")
        values = pd.to_numeric(raw.iloc[header_rows:, col], errors="coerce")
        for year, value in zip(years, values):
            if pd.isna(year) or pd.isna(value):
                continue
            rows.append(
                {
                    "year": int(year),
                    "series": series,
                    "commodity": name,
                    "value": float(value),
                    "unit": UNIT,
                    "source": SOURCE,
                    "method": "observed",
                }
            )
    return rows


def main():
    rows = read_commodities()
    rows += read_index_sheet(
        "Indices",
        "jacks_aggregate_index",
        {
            1: "value_of_production_weights_1975_shares",
            2: "value_of_production_weights_2019_shares",
            3: "equal_weights_42_commodities",
        },
    )
    rows += read_index_sheet(
        "Sub-indices",
        "jacks_subindex",
        {
            1: "commodities_to_be_grown",
            2: "commodities_in_the_ground",
            3: "in_the_ground_ex_energy",
        },
    )
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["series", "commodity", "year"]
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print(
        "b3_jacks: {} rows, {} series, {} commodities, {}-{} -> {}".format(
            len(out),
            out["series"].nunique(),
            out["commodity"].nunique(),
            int(out["year"].min()),
            int(out["year"].max()),
            OUT,
        )
    )


if __name__ == "__main__":
    main()
