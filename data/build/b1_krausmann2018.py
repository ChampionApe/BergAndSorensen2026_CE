"""Krausmann, Lauk, Haas and Wiedenhofer (2018), Global Environmental Change 52.

Reads the authors' companion workbook (BOKU data download, version 1.1) and
writes the three blocks it carries as a long-format interim file: global
extraction by material group and by use type, in-use stocks and net additions
to stock by stock category, and domestic processed output by flow.

Run from the repository root:  python data/build/b1_krausmann2018.py
"""

import openpyxl

from b1_common import INTERIM, RAW, check_header, find_year_row, number, sheet_rows, write_long

SOURCE = "krausmann2018"
WORKBOOK = RAW / SOURCE / "Online_data_Krausmann_et_al_2018.xlsx"

# Extraction sheet: column index -> (series, category). Units are Gt/yr except
# the two context columns, which the sheet reports in persons and 1990 dollars.
EXTRACTION = {
    4: ("N", "biomass"),
    5: ("N", "fossil"),
    6: ("N", "metals"),
    7: ("N", "non_metallic_minerals"),
    8: ("N", "total"),
    10: ("use_food", "total"),
    11: ("use_feed", "total"),
    12: ("use_technical_energy", "total"),
    13: ("use_other_dissipative", "total"),
    14: ("use_stock_building", "total"),
    15: ("use_tailings", "total"),
    16: ("use_all", "total"),
}
EXTRACTION_HEADER = {
    1: "Population",
    4: "Biomass",
    5: "Fossil energy carriers",
    6: "Ores",
    7: "Non-metallic minerals",
    10: "Food",
    14: "Stock building",
    15: "Tailings",
}

# Stock sheet: the level block and the net-addition block repeat the same
# eleven labels, so both are read by offset from the same header row.
STOCK_CATEGORIES = [
    "humans",
    "livestock",
    "humans_and_livestock",
    "wood_glass_plastics",
    "metals",
    "bricks",
    "asphalt",
    "concrete",
    "aggregates",
    "manufactured_capital",
    "total",
]
STOCK_HEADER = {1: "Humans", 5: "Metals", 11: "Total stocks", 13: "Humans", 17: "Metals"}

# Domestic processed output: the actual-outflow block (including balancing
# oxygen and water) and the DPO* block that excludes those balancing items.
DPO_FLOWS = ["eol_waste", "processing_waste", "dissipative_use", "water_vapor", "emissions", "excrements"]
DPO_HEADER = {1: "End of life waste", 7: "Total", 9: "End of life waste", 15: "Total DPO excl"}


def main():
    book = openpyxl.load_workbook(WORKBOOK, read_only=True, data_only=True)
    rows = []

    sheet = sheet_rows(book, "Material extraction & use")
    first = find_year_row(sheet, 1900)
    check_header(sheet, first - 1, EXTRACTION_HEADER)
    for row in sheet[first:]:
        year = number(row[0])
        if year is None:
            break
        rows.append(
            dict(year=int(year), series="population", category="total", value=number(row[1]) * 1e3,
                 unit="persons", source=SOURCE, method="observed")
        )
        rows.append(
            dict(year=int(year), series="gdp", category="total", value=number(row[2]) / 1e6,
                 unit="trillion 1990 international dollars", source=SOURCE, method="observed")
        )
        for col, (series, category) in EXTRACTION.items():
            rows.append(
                dict(year=int(year), series=series, category=category, value=number(row[col]),
                     unit="Gt/yr", source=SOURCE, method="observed")
            )

    sheet = sheet_rows(book, "Stocks & net addition to stock")
    first = find_year_row(sheet, 1900)
    check_header(sheet, first - 1, STOCK_HEADER)
    for row in sheet[first:]:
        year = number(row[0])
        if year is None:
            break
        for i, category in enumerate(STOCK_CATEGORIES):
            rows.append(
                dict(year=int(year), series="MK", category=category, value=number(row[1 + i]),
                     unit="Gt", source=SOURCE, method="observed")
            )
            rows.append(
                dict(year=int(year), series="NAS", category=category, value=number(row[13 + i]),
                     unit="Gt/yr", source=SOURCE, method="observed")
            )

    sheet = sheet_rows(book, "Domestic processed output")
    first = find_year_row(sheet, 1900)
    check_header(sheet, first - 1, DPO_HEADER)
    for row in sheet[first:]:
        year = number(row[0])
        if year is None:
            break
        for i, flow in enumerate(DPO_FLOWS):
            rows.append(
                dict(year=int(year), series="dpo_" + flow, category="total", value=number(row[1 + i]),
                     unit="Gt/yr", source=SOURCE, method="observed")
            )
            rows.append(
                dict(year=int(year), series="dpostar_" + flow, category="total", value=number(row[9 + i]),
                     unit="Gt/yr", source=SOURCE, method="observed")
            )
        rows.append(
            dict(year=int(year), series="DPO", category="total", value=number(row[7]),
                 unit="Gt/yr", source=SOURCE, method="observed")
        )
        rows.append(
            dict(year=int(year), series="DPOstar", category="total", value=number(row[15]),
                 unit="Gt/yr", source=SOURCE, method="observed")
        )
        rows.append(
            dict(year=int(year), series="balancing_o2", category="total", value=number(row[16]),
                 unit="Gt/yr", source=SOURCE, method="observed")
        )
        rows.append(
            dict(year=int(year), series="balancing_h2o", category="total", value=number(row[17]),
                 unit="Gt/yr", source=SOURCE, method="observed")
        )

    write_long(rows, INTERIM / "b1_krausmann2018.csv")


if __name__ == "__main__":
    main()
