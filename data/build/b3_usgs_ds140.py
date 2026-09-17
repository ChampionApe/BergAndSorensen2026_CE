"""B3, source 2: USGS Data Series 140, historical mineral and material statistics.

Raw: data/raw/usgs_ds140/ds140-<commodity>-<year>.xlsx, one workbook per
commodity, 32 of the ~90 commodities downloaded (the metals, and the
non-metallic minerals that carry mass).  Each worksheet has four lines of
preamble, then a header row beginning "Year", then one row per year from 1900.

Three things are taken: world production (the only long global mass series in
the block, used for the production weights of the aggregate price index and for
cumulative extraction since 1900), US production, and the unit value in constant
1998 dollars (a second, commodity-specific real price series independent of
Jacks).  The reporting basis -- contained metal or gross weight -- is read from
the workbook's own preamble line and carried in the unit column, because the
two cannot be added together.

Run from the repository root:  python data/build/b3_usgs_ds140.py
"""

import glob
import os
import re
import warnings

import pandas as pd

RAWDIR = os.path.join("data", "raw", "usgs_ds140")
OUT = os.path.join("data", "interim", "b3_usgs_ds140.csv")
SOURCE = "usgs_ds140"
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

# Column header in the workbook -> series name in the interim file.
WANTED = {
    "world production": "world_production",
    "world mine production": "world_mine_production",
    "world refinery production": "world_refinery_production",
    "production": "us_production",
    "primary production": "us_primary_production",
    "unit value ($/t)": "unit_value_nominal",
    "unit value (98$/t)": "unit_value_1998usd",
}
# Series measured in dollars per tonne rather than tonnes.
PRICE_SERIES = {"unit_value_nominal", "unit_value_1998usd"}


def commodity_from_filename(path):
    name = os.path.basename(path)
    name = re.sub(r"^ds140[-_]", "", name)
    name = re.sub(r"[-_]?\d{4}\.xlsx$", "", name)
    name = name.replace("%20", "_").replace("-", "_").replace(" ", "_")
    while "__" in name:
        name = name.replace("__", "_")
    return name.strip("_").lower()


def basis_from_preamble(sheet):
    """The workbook states its own basis on the third preamble line."""
    text = " ".join(
        str(v) for v in sheet.iloc[:4, 0].tolist() if isinstance(v, str)
    ).lower()
    if "content" in text:
        match = re.search(r"\(t\)\s*([a-z0-9 ]*?)content", text)
        what = match.group(1).strip() if match else ""
        return "t_{}_content".format(what.replace(" ", "_")) if what else "t_content"
    if "gross weight" in text:
        return "t_gross_weight"
    if "k2o" in text:
        return "t_k2o_equivalent"
    return "t"


def header_row(sheet):
    for i in range(min(12, len(sheet))):
        if str(sheet.iloc[i, 0]).strip() == "Year":
            return i
    return None


def read_sheet(path, sheet_name, sheet, commodity):
    hrow = header_row(sheet)
    if hrow is None:
        return []
    basis = basis_from_preamble(sheet)
    headers = [str(v).strip() for v in sheet.iloc[hrow]]
    body = sheet.iloc[hrow + 1 :]
    years = pd.to_numeric(body.iloc[:, 0], errors="coerce")
    # Workbooks with several sheets (iron and steel, nickel, clays, ...) carry a
    # different product on each; the sheet name distinguishes them.
    suffix = ""
    if sheet_name.strip().lower().replace(" ", "_") not in (commodity, ""):
        suffix = "__" + sheet_name.strip().lower().replace(" ", "_").replace("-", "_")
    rows = []
    for col, head in enumerate(headers):
        series = WANTED.get(head.lower())
        if series is None:
            continue
        unit = "1998_usd_per_t" if series in PRICE_SERIES else basis
        if series == "unit_value_nominal":
            unit = "current_usd_per_t"
        values = pd.to_numeric(body.iloc[:, col], errors="coerce")
        for year, value in zip(years, values):
            if pd.isna(year) or pd.isna(value):
                continue
            rows.append(
                {
                    "year": int(year),
                    "series": series,
                    "commodity": commodity + suffix,
                    "value": float(value),
                    "unit": unit,
                    "source": SOURCE,
                    "method": "observed",
                }
            )
    return rows


def main():
    warnings.filterwarnings("ignore", category=UserWarning, module="openpyxl")
    rows = []
    for path in sorted(glob.glob(os.path.join(RAWDIR, "*.xlsx"))):
        commodity = commodity_from_filename(path)
        book = pd.ExcelFile(path)
        for sheet_name in book.sheet_names:
            sheet = pd.read_excel(path, sheet_name=sheet_name, header=None)
            rows += read_sheet(path, sheet_name, sheet, commodity)
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["commodity", "series", "year"]
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    world = out[out["series"].str.startswith("world")]
    print(
        "b3_usgs_ds140: {} rows, {} commodity-series, {}-{}, world production for "
        "{} commodities -> {}".format(
            len(out),
            out["commodity"].nunique(),
            int(out["year"].min()),
            int(out["year"].max()),
            world["commodity"].nunique(),
            OUT,
        )
    )


if __name__ == "__main__":
    main()
