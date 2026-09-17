"""C1: the accounting block -- omY, omN, omD, omW, omC, phiI, OmNS, OmDS.

Inputs : data/interim/b1_material_block.csv, b1_krausmann2018.csv, b2_macro_block.csv,
         data/raw/eea_tmr2001/eea_technical_report_55_tmr_eu.pdf (Table 3, transcribed below)
Outputs: data/processed/calibration.json (params of this block)
         data/processed/c1_accounting.csv (the numbers behind Tables/Data_accounting.tex)
         data/processed/c1_weights.json (read by data/build/b2_omega_join.py)

The durables coefficient.  The model stores Omega * phiI * G tonnes of each year's
material input in durables and draws the rest, Omega * D, through the non-investment
uses, so the stored share is sigma = phiI G / (D + phiI G).  Its observed counterpart
is gross additions to stock over total material input, NAS_gross / R, from Haas et
al. (2020).  phiI is set so that the century's cumulative gross additions to stock are
reproduced: phiI = [sum NAS_gross / sum (R - NAS_gross)] * [sum D / sum G] over
1900-2015, with D the omega-weighted non-investment base at the weights below.

The relative intensities.  No source in B1 reports waste generation by generating
use; the outflow is reported by material category and, in Krausmann et al. (2018),
by type of outflow.  The types map onto uses only coarsely (processing waste to
production, excrements and dissipative use to consumption, emissions to both), so
the five omega are set to a common intensity of one, and the type split is written
out as the evidence that this is coarse rather than wrong.  Only the products
Omega * omega^j enter the wedges (quant_calibration.tex, "The accounting weights
matter less than they look").

Unused extraction.  The ratio of unused to used extraction is not in B1.  The EEA
(2001) Table 3 gives it for EU-15 domestic extraction in 1995 by category; the world
figure is the category ratios weighted by the world composition of used extraction
over 2000-2015.  OmDS, mass displaced per tonne discovered, has no source and is a
judgement: one hundredth of OmNS, since exploration moves drill core and trenches,
not overburden.

Run from the repository root with PYTHONUTF8=1.
"""

import json
import os
from collections import OrderedDict

from c_common import (CATEGORIES, PROCESSED, Record, WINDOW, b1_by_category,
                      b1_series, entry, load_block, load_calibration,
                      macro_series, save_calibration, set_params)

SRC = "quant_data.tex, Accounting; notes/data/calibration.md"

# EEA (2001), Technical report No 55, Table 3, p. 22: ratios of hidden flows to
# commodities for EU-15 in 1995, domestic extraction column.  Transcribed.
EEA_TABLE3_DOMESTIC = OrderedDict([
    ("fossil", 3.44),
    ("metals", 0.94),
    ("non_metallic_minerals", 0.22),
    ("biomass", 0.62),
])
EEA_TABLE3_DOMESTIC_TOTAL = 0.92
EEA_TABLE3_TOTAL_METALS = 11.33   # the "total" column for metals, dominated by imports

OMEGA = OrderedDict(omY=1.0, omN=1.0, omD=1.0, omW=1.0, omC=1.0)
OMDS_OVER_OMNS = 0.01


def main():
    rec = Record("c1_accounting")
    b1 = load_block("b1_material_block")
    k18 = load_block("b1_krausmann2018")
    macro = macro_series()

    y0, y1 = 1900, 2015
    years = list(range(y0, y1 + 1))

    # --- the stored share and phiI ------------------------------------------
    R = b1_series(b1, "R", "total")
    nas = b1_by_category(b1, "NAS_gross").sum(axis=1)
    sigma_year = (nas / R).loc[years]
    for y in (1900, 1950, 2000, 2015):
        rec.add(f"sigma_{y}", sigma_year.loc[y], "share", "NAS_gross / R, Haas et al. (2020)")
    sigma_cum = nas.loc[years].sum() / R.loc[years].sum()
    rec.add("sigma_cumulative_1900_2015", sigma_cum, "share",
            "sum NAS_gross / sum R over 1900-2015")

    Y, C, G = (macro.loc[years, k] for k in ("Y", "C", "G"))
    D = OMEGA["omY"] * Y + OMEGA["omC"] * C
    d_over_g = D.sum() / G.sum()
    rec.add("D_over_G_cumulative", d_over_g, "ratio",
            "sum (omY Y + omC C) / sum G over 1900-2015, pre-1950 split at the PIM share")
    phiI = (nas.loc[years].sum() / (R.loc[years] - nas.loc[years]).sum()) * d_over_g
    phiI_year = (nas / (R - nas)).loc[years] * (D / G)
    for y in (1900, 1950, 2000, 2015):
        rec.add(f"phiI_{y}", phiI_year.loc[y], "ratio", "year-by-year value of the same formula")
    rec.add("phiI", phiI, "ratio", "cumulative 1900-2015; the calibrated point")

    # --- the outflow by type, the evidence on the split ----------------------
    types = ["dpostar_processing_waste", "dpostar_emissions", "dpostar_dissipative_use",
             "dpostar_excrements", "dpostar_eol_waste", "dpostar_water_vapor"]
    for t in types:
        s = k18[(k18["series"] == t)].set_index("year")["value"]
        rec.add(t + "_2015", s.loc[2015], "Gt/yr", "Krausmann et al. (2018), DPO* by type")
    prod = k18[k18["series"] == "dpostar_processing_waste"].set_index("year")["value"].loc[2015]
    cons = (k18[k18["series"] == "dpostar_excrements"].set_index("year")["value"].loc[2015]
            + k18[k18["series"] == "dpostar_dissipative_use"].set_index("year")["value"].loc[2015])
    rec.add("omC_over_omY_excluding_emissions_2015",
            (cons / C.loc[2015]) / (prod / Y.loc[2015]), "ratio",
            "(excrements + dissipative use)/C over processing waste/Y, emissions unattributed")

    # --- unused extraction ---------------------------------------------------
    N = b1_by_category(b1, "N", source="krausmann2018")
    w = N.loc[WINDOW[0]:WINDOW[1]].sum()
    w = w / w.sum()
    for c in CATEGORIES:
        rec.add(f"N_share_{c}_2000_2015", w[c], "share", "Krausmann et al. (2018)")
        rec.add(f"eea_unused_per_used_{c}", EEA_TABLE3_DOMESTIC[c], "t/t",
                "EEA (2001) Table 3, EU-15 domestic extraction, 1995")
    rec.add("eea_unused_per_used_total_domestic", EEA_TABLE3_DOMESTIC_TOTAL, "t/t",
            "EEA (2001) Table 3, EU-15 domestic total")
    omns = sum(w[c] * EEA_TABLE3_DOMESTIC[c] for c in CATEGORIES)
    omns_low = sum(w[c] * EEA_TABLE3_DOMESTIC[c] for c in CATEGORIES if c != "biomass")
    omns_high = sum(w[c] * (EEA_TABLE3_TOTAL_METALS if c == "metals" else EEA_TABLE3_DOMESTIC[c])
                    for c in CATEGORIES)
    rec.add("OmNS", omns, "t/t", "EU ratios at the 2000-2015 world composition")
    rec.add("OmNS_low", omns_low, "t/t", "biomass erosion excluded from unused extraction")
    rec.add("OmNS_high", omns_high, "t/t",
            "metals at the EEA total ratio, which is dominated by imported ores")
    omds = OMDS_OVER_OMNS * omns
    rec.add("OmDS", omds, "t/t", "judgement: one hundredth of OmNS")

    # --- write ---------------------------------------------------------------
    cal = load_calibration()
    block = OrderedDict()
    for k, v in OMEGA.items():
        block[k] = entry(v, SRC)
    block["phiI"] = entry(phiI, SRC, low=phiI_year.loc[1900], high=phiI_year.loc[2015])
    block["OmNS"] = entry(omns, SRC, low=omns_low, high=omns_high)
    block["OmDS"] = entry(omds, SRC, low=0.0, high=10 * omds)
    set_params(cal, block)
    save_calibration(cal)
    path = rec.write()

    weights = OrderedDict([("omY", OMEGA["omY"]), ("omC", OMEGA["omC"]), ("phiI", phiI),
                           ("built_by", "data/build/c1_accounting.py")])
    with open(os.path.join(PROCESSED, "c1_weights.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(weights, f, indent=2)
        f.write("\n")

    print(f"c1_accounting: phiI = {phiI:.3f} (1900 {phiI_year.loc[1900]:.3f}, 2015 "
          f"{phiI_year.loc[2015]:.3f}), sigma_cum = {sigma_cum:.3f}, OmNS = {omns:.3f} "
          f"[{omns_low:.3f}, {omns_high:.3f}], OmDS = {omds:.4f} -> {path}")


if __name__ == "__main__":
    main()
