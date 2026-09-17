"""Shared helpers for the B1 material-flow build scripts.

Long-format conventions of the calibration plan: one row per
(year, series, category, value, unit, source, method).
"""

from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"
INTERIM = ROOT / "data" / "interim"

COLUMNS = ["year", "series", "category", "value", "unit", "source", "method"]

# The four material-flow-accounting categories the model aggregates over, plus
# the total. Every source is mapped onto these names; where a source's own
# grouping does not match (Krausmann 2009), the native name is kept instead and
# notes/data/material_flows.md says why.
CATEGORIES = ["biomass", "fossil", "metals", "non_metallic_minerals", "total"]


def write_long(rows, path):
    """Write `rows` (list of dicts) as a long-format CSV and report one line."""
    frame = pd.DataFrame(rows, columns=COLUMNS)
    frame = frame.dropna(subset=["value"])
    frame = frame.sort_values(["series", "category", "year"]).reset_index(drop=True)
    path.parent.mkdir(parents=True, exist_ok=True)
    frame.to_csv(path, index=False, float_format="%.10g")
    years = (int(frame["year"].min()), int(frame["year"].max()))
    print(
        "{}: {} rows, {} series, years {}-{} -> {}".format(
            path.stem,
            len(frame),
            frame["series"].nunique(),
            years[0],
            years[1],
            path.relative_to(ROOT).as_posix(),
        )
    )
    return frame


def sheet_rows(workbook, name):
    """Rows of a worksheet as a list of tuples, matching on the stripped name."""
    for sheet in workbook.worksheets:
        if sheet.title.strip() == name:
            return [tuple(r) for r in sheet.iter_rows(values_only=True)]
    raise KeyError("sheet {!r} not found; have {}".format(name, [s.title for s in workbook.worksheets]))


def find_year_row(rows, year, column=0):
    """Index of the first row whose `column` holds `year` (as int or as text)."""
    for i, row in enumerate(rows):
        cell = row[column] if column < len(row) else None
        if cell is None:
            continue
        try:
            if int(float(str(cell).strip())) == year:
                return i
        except (TypeError, ValueError):
            continue
    raise ValueError("year {} not found in column {}".format(year, column))


def check_header(rows, row_index, expected):
    """Assert that `expected` {column index: label prefix} holds on a header row."""
    header = rows[row_index]
    for col, label in expected.items():
        got = "" if header[col] is None else str(header[col]).strip()
        if not got.lower().startswith(label.lower()):
            raise AssertionError(
                "header column {} is {!r}, expected it to start with {!r}".format(col, got, label)
            )


def number(cell):
    """Numeric value of a cell, or None. Text zeros appear in these workbooks."""
    if cell is None or cell == "":
        return None
    if isinstance(cell, (int, float)):
        return float(cell)
    try:
        return float(str(cell).strip().replace(",", ""))
    except ValueError:
        return None
