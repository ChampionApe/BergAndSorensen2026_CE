"""B4: UNEP IRP 2011, Recycling Rates of Metals -> data/interim/b4_unep_irp2011.csv.

End-of-life recycling rates (EOL-RR), recycled content (RC) and old-scrap ratio (OSR)
by metal, typed from appendix tables C1 (ferrous, p. 30), D1 (non-ferrous, p. 31),
E2 (precious, p. 33) and F1 (specialty, pp. 36-37).  The report's headline display,
figure 4, is a periodic table of bins and is deliberately not used.

Each cell of those tables holds one or more estimates, each carrying a footnote letter
that names its source.  Every estimate becomes its own row, with the footnote resolved
to the citation, so that nothing is averaged before the calibration sees it.  A cell
entry that is a range ("58-63", "35-60") becomes a low row and a high row; an entry
written "<1" or ">50" becomes a row whose `method` says it is a bound.

Run from the repository root:  python data/build/b4_unep_irp2011.py
"""

import os
import re

import pandas as pd

OUT = os.path.join("data", "interim", "b4_unep_irp2011.csv")

# table -> (page, {footnote letter: citation})
TABLES = {
    "C1": ("UNEP IRP 2011, Recycling Rates of Metals, table C1, p. 30", {
        "a": "working group consensus", "b": "Worldsteel (2009)",
        "c": "Fenton, USGS (2004)", "d": "Wang et al. (2007)", "e": "Birat (2001)",
        "f": "Steel Recycling Institute (2007)", "h": "Johnson et al. (2006)",
        "i": "Papp, USGS (2004)", "j": "Jones, USGS (2004)",
        "k": "Blossom, USGS (2004)", "l": "Cunningham, USGS (2004a)",
        "m": "Reck et al. (2008a)", "n": "Goonan, USGS (2009)",
        "o": "Reck and Graedel (2010)"}),
    "D1": ("UNEP IRP 2011, Recycling Rates of Metals, table D1, p. 31", {
        "a": "Plunkert, USGS (2006)", "b": "Zheng (2009)", "c": "IAI (2009)",
        "d": "Shedd, USGS (2004)", "e": "Goonan, USGS (2010a)",
        "f": "Graedel et al. (2004)", "g": "Risopatron (2009)",
        "h": "Kramer, USGS (2004)", "i": "Smith, USGS (2004)", "j": "Mao et al. (2008)",
        "k": "Wilson and White (2009)", "l": "Carlin, USGS (2004)",
        "m": "Goonan, USGS (2010b)", "n": "Plachy, USGS (2004)",
        "o": "Graedel et al. (2005)", "p": "Sempels (2009)"}),
    "E2": ("UNEP IRP 2011, Recycling Rates of Metals, table E2, p. 33", {
        "a": "Amey, USGS (2006)", "b": "GFMS (2009a)", "c": "Hilliard, USGS (2003)",
        "d": "Johnson et al. (2005)", "e": "Silver Institute (2009) and GFMS (2009b)",
        "f": "Hilliard, USGS (2004)", "g": "van Oss (2009)"}),
    "F1": ("UNEP IRP 2011, Recycling Rates of Metals, table F1, pp. 36-37", {
        "a": "Carlin (2006)", "b": "Roskill (2007)", "c": "Civic (2009)",
        "d": "Plachy (2003)", "e": "Buchert (2009)", "f": "Jorgenson (2006)",
        "g": "Brooks and Matos (2005)", "h": "Cunningham (2004b)",
        "i": "Shedd (2005)", "j": "Morrow (2009)", "k": "Cunningham (2004c)"}),
}

# (table, metal, OSR cell, RC cell, EOL-RR cell) exactly as printed.  "" is a blank cell.
CELLS = [
    ("C1", "V", "", "", "<1a"),
    ("C1", "Cr", "60h, 72i", "20i, 18h", "87i, 93h"),
    ("C1", "Mn", "33a, 67j", "37j", "53j"),
    ("C1", "Fe", "54a, 52b, 66c, 65d", "28d, 41c, 52b", "52c, 67d, 78e, 90f"),
    ("C1", "Ni", "66-70m, 66-70o, 88n", "29m, 41n", "57n, 58-63m, 58-63o"),
    ("C1", "Nb", "44a, 56l", "22l", "50l, 56a"),
    ("C1", "Mo", "33a, 67k", "33k", "30k"),
    ("D1", "Mg", "42h", "33h", "39h"),
    ("D1", "Al", "40a, 50b", "34c, 36a, 36b", "42a, 60c, 70b"),
    ("D1", "Ti", "11m", "52m", "91m"),
    ("D1", "Co", "50d", "32d", "68d"),
    ("D1", "Cu", "24e, 78f", "20f, 30e, 37g, 37n", "43e, 53f"),
    ("D1", "Zn", "19n, 35-40p, 71o", "18o, 27n", "19n, 35-60p, 52o"),
    ("D1", "Sn", "50l", "22l", "75l"),
    ("D1", "Pb", "95i, 96j", "63i, 42k, 51j", "95i, 52k, 68j"),
    ("E2", "Ru", "<20", "50-60", "5-15"),
    ("E2", "Rh", ">80", "40", "50-60"),
    ("E2", "Pd", ">80", "50", "60-70"),
    ("E2", "Ag", "76c, 77d, >80", "20e, 30d, 32c", "58d, 97c, 30-50"),
    ("E2", "Os", "<1g", "<1g", "<1g"),
    ("E2", "Ir", ">80", "15-20", "20-30"),
    ("E2", "Pt", "58f, >80", "16f, 50", "76f, 60-70"),
    ("E2", "Au", "75a, >80", "29a, 31b", "40b, 96a, 15-20"),
    ("F1", "Li", "<1", "<1", "<1"),
    ("F1", "Be", "14k, 75c", "10k, 25c", "7k, <1c"),
    ("F1", "B", "", "", "<1"),
    ("F1", "Sc", "", "", "<1"),
    ("F1", "Ga", "<1", "25-50e", "<1"),
    ("F1", "Ge", "40f, 0", "50f, 35, 50f", "76f, <1"),
    ("F1", "As", "<1", "<1", "<1"),
    ("F1", "Se", "", "1-10", "<5"),
    ("F1", "Sr", "", "", "<1"),
    ("F1", "Y", "0", "0", "0"),
    ("F1", "Zr", "", "1-10", "<1"),
    ("F1", "Cd", "76d", "25j, 32d, 50-75", "15d"),
    ("F1", "In", "1", "25-50", "<1"),
    ("F1", "Sb", "80a, <10", "20a, 10-25b, <10", "89a, <5"),
    ("F1", "Te", "", "", "<1"),
    ("F1", "La", "", "1-10", "<1"),
    ("F1", "Ce", "", "1-10", "<1"),
    ("F1", "Pr", "", "1-10", "<1"),
    ("F1", "Nd", "", "1-10", "<1"),
    ("F1", "Sm", "", "<1", "<1"),
    ("F1", "Eu", "", "<1", "<1"),
    ("F1", "Gd", "", "1-10", "<1"),
    ("F1", "Tb", "", "<1", "<1"),
    ("F1", "Dy", "", "1-10", "<1"),
    ("F1", "Ho", "", "<1", "<1"),
    ("F1", "Er", "", "<1", "<1"),
    ("F1", "Tm", "", "<1", "<1"),
    ("F1", "Yb", "", "<1", "<1"),
    ("F1", "Lu", "", "<1", "<1"),
    ("F1", "Hf", "", "", "<1"),
    ("F1", "Ta", "1-10, 43h", "10-25, 21h", "<1, 35h"),
    ("F1", "W", "80i", "46i", "10-25, 66i"),
    ("F1", "Re", "~50", "10-25", ">50"),
    ("F1", "Hg", "97g", "25-50", "1-10, 62g"),
    ("F1", "Tl", "0", "0", "0"),
    ("F1", "Bi", "<1", "", "<1"),
]

# Prose statements worth carrying beside the tables.
PROSE = [
    ("eolrr_iron_and_steel_low", "Fe", 70.0,
     "UNEP IRP 2011, Recycling Rates of Metals, appendix C, p. 30"),
    ("eolrr_iron_and_steel_high", "Fe", 90.0,
     "UNEP IRP 2011, Recycling Rates of Metals, appendix C, p. 30"),
    ("n_metals_studied", "all", 60.0,
     "UNEP IRP 2011, Recycling Rates of Metals, p. 17"),
    ("n_metals_eolrr_above_50pc", "all", 18.0,
     "UNEP IRP 2011, Recycling Rates of Metals, p. 17"),
    ("n_metals_eolrr_25_to_50pc", "all", 3.0,
     "UNEP IRP 2011, Recycling Rates of Metals, p. 17"),
    ("n_metals_eolrr_10_to_25pc", "all", 3.0,
     "UNEP IRP 2011, Recycling Rates of Metals, p. 17"),
]

# The eighteen metals the executive summary names as having EOL-RR above 50 per cent.
ABOVE_50 = ["Al", "Co", "Cr", "Cu", "Au", "Fe", "Pb", "Mn", "Nb", "Ni", "Pd", "Pt",
            "Re", "Rh", "Ag", "Sn", "Ti", "Zn"]

ENTRY = re.compile(r"^([<>~]?)\s*([0-9.]+)(?:-([0-9.]+))?\s*([a-z]?)$")


def parse_cell(cell, footnotes):
    """Yield (value, bound, citation) for each estimate printed in one table cell."""
    if not cell.strip():
        return
    for part in cell.split(","):
        m = ENTRY.match(part.strip())
        if not m:
            raise ValueError("unparsed table entry %r" % part)
        prefix, lo, hi, letter = m.groups()
        cite = footnotes.get(letter, "working group expert opinion")
        bound = {"<": "upper_bound", ">": "lower_bound", "~": "approximate",
                 "": "point"}[prefix]
        if hi is None:
            yield float(lo), bound, cite
        else:
            yield float(lo), "range_low", cite
            yield float(hi), "range_high", cite


def main():
    rows = []
    for table, metal, osr, rc, eol in CELLS:
        page, footnotes = TABLES[table]
        for name, cell in (("osr", osr), ("rc", rc), ("eolrr", eol)):
            for value, bound, cite in parse_cell(cell, footnotes):
                rows.append(dict(
                    year=2011, series=name, region_or_material=metal, value=value,
                    unit="percent", source="%s; estimate from %s" % (page, cite),
                    method="transcribed_table_%s" % bound))

    for series, metal, value, page in PROSE:
        rows.append(dict(year=2011, series=series, region_or_material=metal,
                         value=value, unit="percent" if series.startswith("eolrr")
                         else "count", source=page, method="transcribed"))

    for metal in ABOVE_50:
        rows.append(dict(year=2011, series="eolrr_bin_above_50pc",
                         region_or_material=metal, value=50.0, unit="percent",
                         source="UNEP IRP 2011, Recycling Rates of Metals, p. 17",
                         method="transcribed_lower_bound"))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    n_metals = out[out.series == "eolrr"].region_or_material.nunique()
    print("b4_unep_irp2011: %d rows -> %s (EOL-RR estimates for %d metals)"
          % (len(out), OUT, n_metals))


if __name__ == "__main__":
    main()
