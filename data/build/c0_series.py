"""The model-facing annual series, data/processed/series.csv, 1900-2020.

Inputs : data/interim/b1_material_block.csv, b1_haas2020.csv, b2_macro_block.csv,
         b5_pollution_block.csv, data/processed/c1_weights.json, c3_extraction.csv,
         c5_preferences_damages.csv, calibration.json
Output : data/processed/series.csv  (year, series, value, unit, source, method)

Long format like the interim blocks, one row per year and series, with the source
and the method the row rests on.  `observed` and `aggregated` are the blocks'
own labels; `reconstructed` marks a value built on an assumption (the pre-1950 use
split at the perpetual-inventory share, ruling 5; the composed reserve path of C3;
the pollution stock converted at a fixed composition).  Every series stops where its
source stops: the material block at 2015, the macro block at 2020.  No cell is
filled by extrapolation.

Run from the repository root with PYTHONUTF8=1.
"""

import json
import os
import sys

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import (CATEGORIES, PROCESSED, b1_by_category, b1_series, b2_series,  # noqa: E402
                      load_block, load_calibration, macro_series)

OUT = os.path.join(PROCESSED, "series.csv")
STOCKPILED = ["fossil", "metals", "non_metallic_minerals"]
U_G = "trillion 2011 intl USD"


def c_value(csv, name):
    d = pd.read_csv(os.path.join(PROCESSED, csv)).set_index("name")["value"]
    return float(d[name])


def main():
    b1 = load_block("b1_material_block")
    haas = load_block("b1_haas2020")
    b2 = load_block("b2_macro_block")
    p5 = load_block("b5_pollution_block")
    cal = load_calibration()
    macro = macro_series().loc[1900:2020]
    rows = []

    def add(series, s, unit, source, method):
        for y, v in s.items():
            if pd.notna(v):
                rows.append((int(y), series, float(v), unit, source, method))

    # --- macro ------------------------------------------------------------------
    for k in ("Y", "C", "G", "K"):
        for y, v in macro[k].items():
            if pd.notna(v):
                # Y carries B2's own label (its pre-1950 interpolation is B2's business);
                # C and G before 1950 rest on the PIM split, K before 1950 on the PIM itself.
                recon = k != "Y" and y < 1950
                rows.append((int(y), k, float(v), U_G, "maddison2023+pwt1001",
                             "reconstructed" if recon else "aggregated"))
    add("POP", b2_series(b2, "POP").loc[1900:2020], "million persons", "maddison2023", "aggregated")

    # --- material flows ------------------------------------------------------------
    for k, src in (("N", "krausmann2018"), ("R", "haas2020"), ("RR", "haas2020"), ("W", "haas2020"),
                   ("DPO", "haas2020")):
        add(k, b1_series(b1, k, "total", src), "Gt/yr", src, "observed")
        cat = b1_by_category(b1, k, source=src)
        for c in CATEGORIES:
            add(f"{k}_{c}", cat[c], "Gt/yr", src, "observed")
    add("MK", b1_series(b1, "MK", "total"), "Gt", "krausmann2018", "observed")
    wc = sum(b1_series(b1, "Wcum_disposal", c) for c in STOCKPILED)
    add("Wstock", wc, "Gt", "haas2020", "reconstructed")
    sl = haas[haas["series"] == "out_solid_liquid"].pivot_table(index="year", columns="category",
                                                                 values="value")
    add("H_disposal", sl[STOCKPILED].sum(axis=1), "Gt/yr", "haas2020", "observed")

    # --- intensities at the C1 weights ------------------------------------------
    with open(os.path.join(PROCESSED, "c1_weights.json"), encoding="utf-8") as f:
        w = json.load(f)
    R = b1_series(b1, "R", "total")
    yrs = R.index.intersection(macro.index)
    D = w["omY"] * macro.loc[yrs, "Y"] + w["omC"] * macro.loc[yrs, "C"]
    act = D + w["phiI"] * macro.loc[yrs, "G"]
    add("Omega_observed", R.loc[yrs] / macro.loc[yrs, "Y"], "Gt per " + U_G,
        "haas2020+maddison2023", "aggregated")
    add("Omega_model", R.loc[yrs] / act, "Gt per " + U_G, "haas2020+maddison2023+pwt1001+C1",
        "reconstructed")

    # --- the composed reserve and the pollution stock ------------------------------
    N = b1_series(b1, "N", "total", "krausmann2018")
    S0 = cal["states"]["S0"]["value"]
    S = S0 - N.cumsum().shift(1).fillna(0.0)
    add("S", S, "Gt", "C3 composition", "reconstructed")
    add("X", pd.Series(cal["states"]["X0"]["value"], index=S.index), "Gt", "C3 composition",
        "reconstructed")
    atm = p5[p5["series"] == "atm_excess_co2_fossil_irf"].set_index("year")["value"].loc[1900:2020]
    add("P_GtCO2", atm, "GtCO2", "gcb2025v15+joos2013", "reconstructed")
    conv = c_value("c5_preferences_damages.csv", "GtCO2_per_Gt_of_Xi_2000_2015")
    add("P", atm / conv, "Gt", "gcb2025v15+joos2013+C5", "reconstructed")

    out = pd.DataFrame(rows, columns=["year", "series", "value", "unit", "source", "method"])
    out = out.sort_values(["series", "year"]).reset_index(drop=True)
    out.to_csv(OUT, index=False, lineterminator="\n")
    print(f"c0_series: {len(out)} rows, {out.series.nunique()} series, "
          f"{out.year.min()}-{out.year.max()} -> {OUT}")


if __name__ == "__main__":
    main()
