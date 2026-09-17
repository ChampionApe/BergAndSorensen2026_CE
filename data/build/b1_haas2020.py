"""Haas, Krausmann, Wiedenhofer, Heinz and Pichler (2020), Resources,
Conservation and Recycling 163, 105076, the update of Haas et al. (2015).

Reads Supporting Material Table S1, the data behind the paper's Sankey
diagrams, which carries a closed annual ledger 1900-2015 for each of the four
material groups: extraction, secondary materials, processed materials, the use
split, gross additions to stock, demolition, total outflows and the
decomposition of those outflows into water vapour, emissions and solid and
liquid residues.

Run from the repository root:  python data/build/b1_haas2020.py
"""

import zipfile

import openpyxl

from b1_common import INTERIM, RAW, check_header, find_year_row, number, sheet_rows, write_long

SOURCE = "haas2020"
ARCHIVE = RAW / SOURCE / "1-s2.0-S0921344920303931-mmc1.zip"
WORKBOOK = RAW / SOURCE / "Supporting Material Table S1 RCR.xlsx"

# One sheet per material group; the column order is identical across them.
GROUP_SHEETS = {
    "1 fossil materials": "fossil",
    "2 biomass": "biomass",
    "3 metals": "metals",
    "4 non-metallic minerals": "non_metallic_minerals",
}
# Column index -> series name. `N`, `RR` and `R` are the model's symbols;
# `W` is total outflow from use, which the sheet calls interim outputs.
GROUP_COLUMNS = {
    1: "N",
    2: "RR",
    3: "R",
    4: "use_energy",
    5: "use_material",
    6: "stock_additions_gross",
    7: "out_dissipative_and_processing",
    8: "out_demolition",
    9: "W",
    10: "out_water_vapour",
    11: "out_emissions",
    12: "out_solid_liquid",
}
GROUP_HEADER = {1: "extraction", 2: "secondary materials", 3: "processed materials", 9: "interim outputs"}

# The circularity sheet, reported for the world as a whole.
CYCLING_SHEET = "5 circular&non-circular flows"
CYCLING_COLUMNS = {
    1: "in_socioeconomic_cycling",
    2: "in_ecological_cycling",
    3: "in_cycling_total",
    4: "in_net_additions_to_stock",
    5: "in_not_recycled",
    6: "in_non_renewable_biomass",
    7: "in_combusted_fossil",
    8: "in_processed_materials",
    9: "out_socioeconomic_cycling",
    10: "out_ecological_cycling",
    11: "out_cycling_total",
    12: "out_not_recycled",
    13: "out_non_renewable_biomass",
    14: "out_combusted_fossil",
    15: "out_interim_outputs",
}
CYCLING_HEADER = {1: "socio-economic cyling", 4: "net additions to stocks", 15: "interim outputs"}


def ensure_workbook():
    """The supplement ships as a zip holding a single workbook; unpack once."""
    if not WORKBOOK.exists():
        with zipfile.ZipFile(ARCHIVE) as archive:
            archive.extractall(WORKBOOK.parent)


def main():
    ensure_workbook()
    book = openpyxl.load_workbook(WORKBOOK, read_only=True, data_only=True)
    rows = []

    for sheet_name, category in GROUP_SHEETS.items():
        sheet = sheet_rows(book, sheet_name)
        first = find_year_row(sheet, 1900)
        check_header(sheet, first - 1, GROUP_HEADER)
        for row in sheet[first:]:
            year = number(row[0])
            if year is None:
                break
            for col, series in GROUP_COLUMNS.items():
                rows.append(
                    dict(year=int(year), series=series, category=category, value=number(row[col]),
                         unit="Gt/yr", source=SOURCE, method="observed")
                )

    sheet = sheet_rows(book, CYCLING_SHEET)
    first = find_year_row(sheet, 1900)
    check_header(sheet, first - 1, CYCLING_HEADER)
    for row in sheet[first:]:
        year = number(row[0])
        if year is None:
            break
        for col, series in CYCLING_COLUMNS.items():
            rows.append(
                dict(year=int(year), series=series, category="total", value=number(row[col]),
                     unit="Gt/yr", source=SOURCE, method="observed")
            )

    write_long(rows, INTERIM / "b1_haas2020.csv")


if __name__ == "__main__":
    main()
