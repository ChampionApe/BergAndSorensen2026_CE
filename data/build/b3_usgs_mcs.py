"""B3, source 3: USGS Mineral Commodity Summaries 2026, reserves and world mine
production at the latest year.

The 2026 data release (https://doi.org/10.5066/P1WKQ63T) is a bulk CSV set on
ScienceBase, which refuses automated requests from this machine (HTTP 403,
Cloudflare); data/SOURCES.md, block B3, records that as MANUAL.  What is used
here instead is the published report, data/raw/usgs_mcs/mcs2026.pdf, which
carries the same numbers.  The "World total (rounded)" line of each commodity's
"World Mine Production and Reserves" table is transcribed below with the printed
page it stands on, so that any figure can be checked against the PDF.  Nothing
is computed from the PDF at run time: pypdf is not in the project's Python
dependencies, and a literal table is what "method = transcribed" means.

Units are the ones the report states for that commodity, on the commodity's own
basis (contained metal, gross weight, K2O, usable ore).  They are NOT
comparable across commodities and are converted downstream only where the basis
allows it.

Run from the repository root:  python data/build/b3_usgs_mcs.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b3_usgs_mcs.csv")
SOURCE = "usgs_mcs2026"
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

# commodity -> (printed page, unit of the table, world mine production 2024,
#               world mine production 2025 estimate, reserves, reserves note)
# "reserves" is None where the report gives no number ("NA", "Large").
# Values are in the unit named, exactly as the "World total (rounded)" line
# prints them.  A leading ">" in the report is recorded in the note, not in the
# number.
MCS = {
    "bauxite": dict(
        page=51, unit="thousand_t_dry_gross_weight", prod2024=428000, prod2025=440000,
        reserves=29000000, note="bauxite mine production and reserves; the first "
        "two numbers on the printed line are alumina refinery production"),
    "chromium": dict(
        page=67, unit="thousand_t_chromium_content", prod2024=49600,
        prod2025=51000, reserves=None,
        note="production is chromium content; the two reserve columns are ore "
             "and Cr2O3 content and are recorded as separate commodities"),
    "chromium_ore": dict(
        page=67, unit="thousand_t_chromite_ore", prod2024=None, prod2025=None,
        reserves=1200000, note="reserves reported as '>1,200,000' ore"),
    "chromium_cr2o3": dict(
        page=67, unit="thousand_t_cr2o3_content", prod2024=None, prod2025=None,
        reserves=540000, note="reserves reported as '>540,000' Cr2O3 content"),
    "cobalt": dict(
        page=71, unit="t_cobalt_content", prod2024=302000, prod2025=310000,
        reserves=12000000, note=""),
    "copper": dict(
        page=73, unit="thousand_t_copper_content", prod2024=23000, prod2025=23000,
        reserves=980000, note="mine production; refinery production 27,600/29,000"),
    "gold": dict(
        page=91, unit="t_gold_content", prod2024=3280, prod2025=3300,
        reserves=66000, note=""),
    "iron_ore_usable": dict(
        page=109, unit="thousand_t_usable_ore", prod2024=2600000, prod2025=2600000,
        reserves=200000, note="reserves column is crude ore in MILLION tonnes, "
        "i.e. 200,000 Mt; production is thousand tonnes of usable ore"),
    "iron_ore_iron_content": dict(
        page=109, unit="thousand_t_iron_content", prod2024=1600000, prod2025=1600000,
        reserves=87000, note="reserves column is iron content in MILLION tonnes, "
        "i.e. 87,000 Mt"),
    "lead": dict(
        page=115, unit="thousand_t_lead_content", prod2024=4600, prod2025=4500,
        reserves=95000, note=""),
    "lithium": dict(
        page=119, unit="t_lithium_content", prod2024=222000, prod2025=290000,
        reserves=37000000, note="production excludes US output"),
    "manganese": dict(
        page=125, unit="thousand_t_manganese_content", prod2024=18700, prod2025=20000,
        reserves=1800000, note="reserves are gross weight of manganese ore"),
    "molybdenum": dict(
        page=131, unit="t_molybdenum_content", prod2024=256000, prod2025=260000,
        reserves=17000000,
        note="reserve column sub-header reads 'thousand metric tons'; the printed "
             "17,000 is thousand tonnes, converted here to tonnes"),
    "nickel": dict(
        page=133, unit="t_nickel_content", prod2024=3710000, prod2025=3900000,
        reserves=140000000, note="reserves reported as '>140,000,000'"),
    "phosphate_rock": dict(
        page=143, unit="thousand_t_marketable_rock", prod2024=239000, prod2025=250000,
        reserves=73000000, note=""),
    "platinum_group_metals": dict(
        page=145, unit="kg_pgm_content", prod2024=217000, prod2025=190000,
        reserves=76000000, note="mine production; reserves reported as "
        "'>76,000,000' kg"),
    "potash": dict(
        page=147, unit="thousand_t_k2o_equivalent", prod2024=46700, prod2025=49000,
        reserves=5900000,
        note="the K2O reserve column, reported as '>5,900,000'; the other "
             "reserve column, '>10,000,000', is recoverable ore"),
    "potash_ore": dict(
        page=147, unit="thousand_t_recoverable_ore", prod2024=None, prod2025=None,
        reserves=10000000, note="reserves reported as '>10,000,000' recoverable ore"),
    "rare_earths": dict(
        page=153, unit="t_reo_equivalent", prod2024=380000, prod2025=390000,
        reserves=75000000, note="reserves reported as '>75,000,000'"),
    "silver": dict(
        page=173, unit="t_silver_content", prod2024=25300, prod2025=26000,
        reserves=610000, note=""),
    "soda_ash_natural": dict(
        page=175, unit="thousand_t_gross_weight", prod2024=18400, prod2025=19000,
        reserves=25000000, note="natural soda ash only; synthetic production was "
        "52,200/52,000 with no reserve concept"),
    "tin": dict(
        page=195, unit="t_tin_content", prod2024=294000, prod2025=290000,
        reserves=6000000, note="reserves reported as '>6,000,000'"),
    "titanium_ilmenite_rutile": dict(
        page=199, unit="thousand_t_gross_weight", prod2024=9680, prod2025=9800,
        reserves=540000, note="ilmenite plus rutile; reserves reported as "
        "'>540,000'"),
    "tungsten": dict(
        page=201, unit="t_tungsten_content", prod2024=82000, prod2025=85000,
        reserves=4700000, note="reserves reported as '>4,700,000'"),
    "vanadium": dict(
        page=203, unit="t_vanadium_content", prod2024=118000, prod2025=110000,
        reserves=21000000,
        note="reserve column sub-header reads 'thousand metric tons'; the printed "
             "21,000 is thousand tonnes, converted here to tonnes"),
    "zinc": dict(
        page=213, unit="thousand_t_zinc_content", prod2024=11900, prod2025=13000,
        reserves=240000, note=""),
    # Commodities whose world table reports production but no reserve figure.
    "cement": dict(
        page=63, unit="thousand_t_gross_weight", prod2024=3900000, prod2025=3800000,
        reserves=None, note="no world reserve figure; the report refers to the "
        "Lime and Crushed Stone chapters for raw-material resources"),
    "gypsum": dict(
        page=95, unit="thousand_t_gross_weight", prod2024=162000, prod2025=160000,
        reserves=None, note="world reserves printed as 'Large'"),
    "lime": dict(
        page=117, unit="thousand_t_gross_weight", prod2024=421000, prod2025=420000,
        reserves=None, note="no world reserve column"),
    "salt": dict(
        page=161, unit="thousand_t_gross_weight", prod2024=275000, prod2025=270000,
        reserves=None, note="no world reserve column"),
    "sulfur": dict(
        page=183, unit="thousand_t_sulfur_content", prod2024=83900, prod2025=84000,
        reserves=None, note="no world reserve column"),
    "sand_and_gravel_construction": dict(
        page=163, unit="million_t_gross_weight", prod2024=None, prod2025=None,
        reserves=None, note="world total printed as NA for both production and "
        "reserves"),
    "stone_crushed": dict(
        page=177, unit="million_t_gross_weight", prod2024=None, prod2025=None,
        reserves=None, note="world total printed as NA for both production and "
        "reserves"),
}

# "World Resources" statements, transcribed from the same pages.  These are the
# identified-plus-undiscovered figures the URR table draws on.
RESOURCES = {
    "copper": dict(page=73, unit="t_copper_content", identified=2.1e9,
                   undiscovered=3.5e9,
                   note="USGS global assessment as of 2015: identified resources "
                        "1.5 billion t unextracted, 2.1 billion t including past "
                        "production of 600 million t; undiscovered 3.5 billion t "
                        "(Hammarstrom and others, 2019, USGS SIR 2018-5160)"),
    "nickel": dict(page=133, unit="t_nickel_content", identified=350e6,
                   undiscovered=None, note="'more than 350 million tons'"),
    "zinc": dict(page=213, unit="t_zinc_content", identified=1.9e9,
                 undiscovered=None, note="identified world resources"),
    "lead": dict(page=115, unit="t_lead_content", identified=2.0e9,
                 undiscovered=None, note="'more than 2 billion tons'"),
    "bauxite": dict(page=51, unit="t_gross_weight", identified=55e9,
                    undiscovered=None,
                    note="resources reported as a range 55-75 billion t; the low "
                         "end is recorded here and the high end in b3_urr.py"),
    "chromium": dict(page=67, unit="t_shipping_grade_chromite", identified=12e9,
                     undiscovered=None, note="'greater than 12 billion tons'"),
    "iron_ore": dict(page=109, unit="t_gross_weight", identified=900e9,
                     undiscovered=None,
                     note="'greater than 900 billion tons of iron ore containing "
                          "more than 260 billion tons of iron'"),
    "manganese_us": dict(page=125, unit="share", identified=0.70,
                         undiscovered=None,
                         note="South Africa an estimated 70% of world resources; "
                              "no world tonnage given"),
    "molybdenum": dict(page=131, unit="t_molybdenum_content", identified=25.4e6,
                       undiscovered=None,
                       note="5.4 million t United States plus about 20 million t "
                            "rest of world"),
    "titanium": dict(page=199, unit="t_gross_weight", identified=2e9,
                     undiscovered=None,
                     note="anatase, ilmenite and rutile, 'more than 2 billion "
                          "tons'"),
    "lithium": dict(page=119, unit="t_lithium_content", identified=150e6,
                    undiscovered=None,
                    note="measured and indicated resources about 150 million t"),
    "platinum_group_metals": dict(page=145, unit="kg_pgm_content", identified=100e6,
                                  undiscovered=None,
                                  note="'more than 100 million kilograms'"),
    "vanadium": dict(page=203, unit="t_vanadium_content", identified=63e6,
                     undiscovered=None, note="'exceed 63 million tons'"),
    "sulfur": dict(page=183, unit="t_sulfur_content", identified=5e9,
                   undiscovered=None,
                   note="elemental sulfur in evaporite and volcanic deposits and "
                        "sulfur in gas, petroleum, tar sands and metal sulfides, "
                        "about 5 billion t; a further 600 billion t is contained "
                        "in coal, oil shale and organic-rich shale"),
    "soda_ash": dict(page=175, unit="t_gross_weight", identified=47e9,
                     undiscovered=None,
                     note="about 47 billion t recoverable from the Green River "
                          "Basin trona deposit"),
}

# The 2024 and 2025 columns of the world table.
PRODUCTION_YEARS = {"prod2024": 2024, "prod2025": 2025}
RESERVE_YEAR = 2025  # reserves in MCS 2026 are stated as of the end of 2025


def main():
    rows = []
    for commodity, rec in MCS.items():
        # Molybdenum and vanadium reserves are printed in thousand tonnes under a
        # tonnes heading; the dictionary already carries the converted value.
        for key, year in PRODUCTION_YEARS.items():
            if rec[key] is None:
                continue
            rows.append(
                dict(year=year, series="world_mine_production",
                     commodity=commodity, value=float(rec[key]), unit=rec["unit"],
                     source="{}:p{}".format(SOURCE, rec["page"]),
                     method="transcribed")
            )
        if rec["reserves"] is not None:
            unit = rec["unit"]
            if commodity in ("iron_ore_usable", "iron_ore_iron_content"):
                unit = unit.replace("thousand_t", "million_t")
            rows.append(
                dict(year=RESERVE_YEAR, series="reserves", commodity=commodity,
                     value=float(rec["reserves"]), unit=unit,
                     source="{}:p{}".format(SOURCE, rec["page"]),
                     method="transcribed")
            )
    for commodity, rec in RESOURCES.items():
        for key, series in (("identified", "identified_resources"),
                            ("undiscovered", "undiscovered_resources")):
            if rec[key] is None:
                continue
            rows.append(
                dict(year=RESERVE_YEAR, series=series, commodity=commodity,
                     value=float(rec[key]), unit=rec["unit"],
                     source="{}:p{}".format(SOURCE, rec["page"]),
                     method="transcribed")
            )
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["series", "commodity", "year"]
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    notes = os.path.join("data", "interim", "b3_usgs_mcs_notes.csv")
    pd.DataFrame(
        [
            dict(commodity=c, page=r["page"], unit=r["unit"], note=r["note"])
            for c, r in MCS.items()
        ]
        + [
            dict(commodity=c + " (resources)", page=r["page"], unit=r["unit"],
                 note=r["note"])
            for c, r in RESOURCES.items()
        ]
    ).to_csv(notes, index=False)
    print(
        "b3_usgs_mcs: {} rows for {} commodities, reserves for {}, transcribed "
        "from mcs2026.pdf -> {} (+ {})".format(
            len(out),
            out["commodity"].nunique(),
            int((out["series"] == "reserves").sum()),
            OUT,
            notes,
        )
    )


if __name__ == "__main__":
    main()
