"""Krausmann, Gingrich, Eisenmenger, Erb, Haberl and Fischer-Kowalski (2009),
Ecological Economics 68, in the authors' 2011 update covering 1900-2009.

The cross-check on global used extraction. Its material grouping is not the
one Krausmann et al. (2018) use: ores travel with industrial minerals here and
the mineral remainder is construction minerals, so only biomass, fossil energy
carriers and the total are comparable across the two. The native names are
kept; notes/data/material_flows.md records the regrouping.

The file is distributed as a BIFF8 workbook, which pandas cannot read without
xlrd. A converted copy sits beside it in data/raw/ and is what this script
reads; data/sources/B1_material_flows.md gives the conversion command.

Run from the repository root:  python data/build/b1_krausmann2009.py
"""

import openpyxl

from b1_common import INTERIM, RAW, check_header, find_year_row, number, sheet_rows, write_long

SOURCE = "krausmann2009"
WORKBOOK = RAW / SOURCE / "Online_data_global_flows_update_2011_converted.xlsx"

EXTRACTION = {
    1: "biomass",
    2: "fossil",
    3: "ores_and_industrial_minerals",
    4: "construction_minerals",
    5: "total",
}
EXTRACTION_HEADER = {
    1: "Biomass",
    2: "Fossil energy carriers",
    3: "Ores and industrial minerals",
    4: "Construction minerals",
    5: "Total",
}
THOUSAND_TONNES_PER_GT = 1e6


def main():
    book = openpyxl.load_workbook(WORKBOOK, read_only=True, data_only=True)
    sheet = sheet_rows(book, "Material flow data")
    first = find_year_row(sheet, 1900)
    check_header(sheet, first - 1, EXTRACTION_HEADER)

    rows = []
    for row in sheet[first:]:
        year = number(row[0])
        if year is None:
            break
        for col, category in EXTRACTION.items():
            value = number(row[col])
            rows.append(
                dict(year=int(year), series="N", category=category,
                     value=None if value is None else value / THOUSAND_TONNES_PER_GT,
                     unit="Gt/yr", source=SOURCE, method="observed")
            )

    write_long(rows, INTERIM / "b1_krausmann2009.csv")


if __name__ == "__main__":
    main()
