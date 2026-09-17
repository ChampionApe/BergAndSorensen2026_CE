"""Material intensity: the observed R/Y and the model's R / (D + phiI G).

Inputs  : data/interim/b1_material_block.csv (block B1), data/interim/b2_macro_block.csv
Output  : data/interim/b2_omega.csv   (year, series, value, unit, source, method)

The model's material intensity is not material input over GDP.  It is material input over the
activity aggregate that actually draws material, `D + phiI * G` in the identifiers of
model/SYMBOLS.md, where `D` is the omega-weighted sum of the non-investment uses and `phiI` is the
durables coefficient on gross capital formation.  The two differ by exactly the reweighting that
decision C1 of notes/plan_calibration_experiments.md is about, so both are written out: the
observed intensity is a fact, the model intensity is a fact conditional on weights.

If data/interim/b1_material_block.csv is absent the script says so and exits without writing.

Run from the repository root.  Idempotent.
"""

import os

import pandas as pd

# ---------------------------------------------------------------------------------------------
# PLACEHOLDER WEIGHTS -- inputs for phase C to replace.
#
# `D` is approximated here as omY * Y + omC * C, which is the two-use reduction of the model's
# `D`: everything drawn by production overhead, scaled by omY, plus consumption, scaled by omC.
# Extraction, exploration and waste handling are left out, which the data plan Section 1 licenses
# ("extraction and exploration are small shares of GDP and their omega are near-irrelevant").
#
# All three numbers below are placeholders of 1.0.  They are NOT estimates and NOT defaults.
# They exist so that the join runs end to end before C1 has identified anything; C1 replaces
# them from B1's waste generation by source and its stock additions.  A number taken from this
# file before C1 has run is a number with no source.
# ---------------------------------------------------------------------------------------------
WEIGHTS = {
    "omY": 1.0,    # relative waste intensity of production overhead   -> C1
    "omC": 1.0,    # relative waste intensity of consumption           -> C1
    "phiI": 1.0,   # durables coefficient on gross capital formation   -> C1
}

# C1 has run when data/processed/c1_weights.json exists; its weights replace the
# placeholders and the output's method column says so.  Written by
# data/build/c1_accounting.py.
C1_WEIGHTS = "data/processed/c1_weights.json"
if os.path.exists(C1_WEIGHTS):
    import json
    with open(C1_WEIGHTS, encoding="utf-8") as _f:
        _w = json.load(_f)
    WEIGHTS = {k: float(_w[k]) for k in WEIGHTS}
    WEIGHTS_ARE_PLACEHOLDERS = False
else:
    WEIGHTS_ARE_PLACEHOLDERS = True

B1 = "data/interim/b1_material_block.csv"
B2 = "data/interim/b2_macro_block.csv"
OUT = "data/interim/b2_omega.csv"

R_SERIES = "R"
R_CATEGORY = "total"
SRC = "krausmann+maddison2023+pwt1001"
U_INT = "Gt per trillion 2011 intl USD"
U_GDP = "trillion 2011 intl USD"


def load_R():
    d = pd.read_csv(B1)
    d = d[d["series"] == R_SERIES]
    if "category" in d.columns and R_CATEGORY in set(d["category"]):
        d = d[d["category"] == R_CATEGORY]
    if d.empty:
        raise SystemExit(f"b2_omega_join: no '{R_SERIES}' rows in {B1}")
    return d.set_index("year")["value"].sort_index(), str(d["unit"].iloc[0])


def main():
    if not os.path.exists(B1):
        print(f"b2_omega_join: {B1} not present (block B1 has not run) -- nothing written. "
              f"Re-run this script once it exists.")
        return

    R, r_unit = load_R()
    m = pd.read_csv(B2).pivot_table(index="year", columns="series", values="value")

    years = sorted(set(R.index) & set(m.index))
    R = R.loc[years]
    Y, C, G = m.loc[years, "Y"], m.loc[years, "C"], m.loc[years, "G"]

    D = WEIGHTS["omY"] * Y + WEIGHTS["omC"] * C
    activity = D + WEIGHTS["phiI"] * G

    rows = []

    def add(series, values, unit, method):
        for y, v in values.items():
            if pd.notna(v):
                rows.append((int(y), series, float(v), unit, SRC, method))

    add("R", R, r_unit, "observed")
    add("Y", Y, U_GDP, "aggregated")
    add("activity_aggregate", activity, U_GDP, "reconstructed")
    add("Omega_observed", R / Y, U_INT, "aggregated")
    add("Omega_model", R / activity, U_INT,
        "placeholder_weights" if WEIGHTS_ARE_PLACEHOLDERS else "reconstructed")

    out = pd.DataFrame(rows, columns=["year", "series", "value", "unit", "source", "method"])
    out = out.sort_values(["series", "year"]).reset_index(drop=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False, lineterminator="\n")

    y0, y1 = years[0], years[-1]
    w = ", ".join(f"{k}={v}" for k, v in WEIGHTS.items())
    tag = "PLACEHOLDER" if WEIGHTS_ARE_PLACEHOLDERS else "C1"
    print(f"b2_omega_join: {len(out)} rows, {y0}-{y1}; {tag} weights ({w}); "
          f"R/Y {R.loc[y0] / Y.loc[y0]:.3f} -> {R.loc[y1] / Y.loc[y1]:.3f}, "
          f"R/(D+phiI G) {R.loc[y0] / activity.loc[y0]:.3f} -> {R.loc[y1] / activity.loc[y1]:.3f} "
          f"{U_INT} -> {OUT}")


if __name__ == "__main__":
    main()
