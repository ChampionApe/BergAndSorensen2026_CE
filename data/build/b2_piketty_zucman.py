"""US wealth-income ratios 1870-2010, from Piketty and Zucman (2014), as a cross-check.

Raw input : data/raw/piketty_zucman2014/USA.xlsx, sheet TableUS6a
Output    : data/interim/b2_piketty_zucman.csv   (year, series, value, unit, source, method)

Used by `b2_macro_block.py` to sanity-check the perpetual-inventory world capital stock over
1900-1950, the half-century for which no world capital stock is observed.

Two caveats travel with the comparison and are restated in notes/data/macro.md.  First, the
denominator is *national income* (net of depreciation and of net foreign factor income), not GDP,
so a PZ ratio is mechanically the larger of the two for the same numerator.  Second, PZ national
wealth is the market value of all assets net of liabilities -- it includes agricultural and urban
land, and net foreign assets -- whereas the perpetual-inventory stock and PWT's `cn` are produced
fixed assets only.  The cross-check is therefore a check on order of magnitude and on the shape of
the 1900-1950 path, not a level identity.

Only the United States is covered.  Piketty and Zucman publish the other seven countries as legacy
.xls workbooks, which pandas cannot open here because `xlrd` is not installed; they are recorded
as MANUAL in data/SOURCES.md, block B2.

Run from the repository root.  Idempotent.
"""

import os

import pandas as pd

RAW = "data/raw/piketty_zucman2014/USA.xlsx"
OUT = "data/interim/b2_piketty_zucman.csv"
SOURCE = "piketty_zucman2014"

# TableUS6a: row 9 holds the symbol row (Wt, Kpt, ..., Wnt); the year index starts at row 10.
COLUMNS = {1: "private_wealth_over_national_income_usa",
           5: "government_wealth_over_national_income_usa",
           9: "national_wealth_over_national_income_usa"}


def main():
    d = pd.read_excel(RAW, sheet_name="TableUS6a", header=None)
    body = d.iloc[10:, :].copy()
    body = body[pd.to_numeric(body[0], errors="coerce").notna()]
    body[0] = body[0].astype(int)

    rows = []
    for col, name in COLUMNS.items():
        v = pd.to_numeric(body[col], errors="coerce")
        for y, x in zip(body[0], v):
            if pd.notna(x):
                rows.append((int(y), name, float(x), "ratio to national income", SOURCE, "observed"))

    out = pd.DataFrame(rows, columns=["year", "series", "value", "unit", "source", "method"])
    out = out.sort_values(["series", "year"]).reset_index(drop=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False, lineterminator="\n")

    nw = out[out["series"] == "national_wealth_over_national_income_usa"]
    print(f"b2_piketty_zucman: {len(out)} rows, {out['series'].nunique()} series, "
          f"{int(out['year'].min())}-{int(out['year'].max())}; US national wealth/national income "
          f"{float(nw[nw.year == 1900].value.iloc[0]):.2f} in 1900, "
          f"{float(nw[nw.year == 1950].value.iloc[0]):.2f} in 1950 -> {OUT}")


if __name__ == "__main__":
    main()
