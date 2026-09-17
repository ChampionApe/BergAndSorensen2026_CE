"""The metals-only bound, data/processed/calibration_metals.json (decision D1).

Inputs : data/processed/calibration.json (the baseline), data/interim/b1_material_block.csv,
         b3_resource_block.csv, data/processed/c3_extraction.csv, c4_waste.csv
Output : data/processed/calibration_metals.json

The bound keeps every parameter of the baseline and replaces what the metals evidence
identifies on its own: the ceiling abar at the mass-weighted end-of-life recycling
rate of metals; mu_N at the metals price channel, floored at zero because the real
price of metals fell over the century while their reserve was drawn down; the
reserve, the discovery ceiling and their reference points on the gross-ore basis
without the exhaustible-share scaling, since here the one material is metal ore and
the whole of N would be metal ore.  The initial states that are flows of the whole
economy (K0, P0, MK0, W0) stay at the baseline, and so does the extraction level,
which is a share of GDP and not a metals number: the bound is a bound on the
recycling and reserve side, not a metals-only economy.  Ruling 1 records that the
two available measurements of metal-ore extraction differ by about half; the S0
range carries that gap as the low end.

Run from the repository root with PYTHONUTF8=1, after c1 to c6.
"""

import json
import os
import sys
from collections import OrderedDict

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import PROCESSED, entry, load_calibration  # noqa: E402

OUT = os.path.join(PROCESSED, "calibration_metals.json")
SRC = "quant_data.tex, The metals-only bound; notes/data/calibration.md"
IRP_GAP = 0.48   # notes/data/material_flows.md: IRP metal ores about half again as large


def c(csv, name):
    d = pd.read_csv(os.path.join(PROCESSED, csv)).set_index("name")["value"]
    return float(d[name])


def main():
    cal = load_calibration()
    m = json.loads(json.dumps(cal), object_pairs_hook=OrderedDict)
    m["meta"]["built_by"] = "data/build/c_metals.py"
    m["meta"]["note"] = ("The metals-only bound of decision D1: the baseline with the ceiling, the "
                         "stock-effect elasticity and the reserve side replaced by the metals evidence.")

    a_mid, a_lo, a_hi = (c("c4_waste.csv", k) for k in ("abar_metals", "abar_metals_low", "abar_metals_high"))
    m["params"]["abar"] = entry(a_mid, SRC, low=a_lo, high=a_hi)
    mu_met = c("c3_extraction.csv", "mu_N_price_channel_metals_only")
    m["params"]["mu_N"] = entry(max(0.0, mu_met), SRC, low=0.0, high=cal["params"]["mu_N"]["value"])

    S0m = c("c3_extraction.csv", "S0_metal_ores_gross_scaled")
    urr_lo = c("c3_extraction.csv", "URR_metal_ores_gross_scaled_low")
    urr_hi = c("c3_extraction.csv", "URR_metal_ores_gross_scaled_high")
    urr_c = c("c3_extraction.csv", "URR_metal_ores_gross_scaled_central")
    m["states"]["S0"] = entry(S0m, SRC, low=S0m / (1 + IRP_GAP), high=S0m)
    m["states"]["X0"] = entry(S0m, SRC, low=S0m / (1 + IRP_GAP), high=S0m)
    m["params"]["Sref"] = entry(S0m, SRC)
    m["params"]["Xref"] = entry(S0m, SRC)
    m["params"]["Xmax"] = entry(urr_c, SRC, low=urr_lo, high=urr_hi)
    m["cases"]["abar"] = [a_mid]
    m["cases"]["muN_range"] = [0.0, cal["params"]["mu_N"]["value"]]

    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, indent=2)
        f.write("\n")
    print(f"c_metals: abar = {a_mid:.3f} [{a_lo:.3f}, {a_hi:.3f}], mu_N = {max(0.0, mu_met):.3f} "
          f"(price channel {mu_met:.3f}), S0 = X0 = {S0m:.0f} Gt, Xmax = {urr_c:.0f} [{urr_lo:.0f}, {urr_hi:.0f}] -> {OUT}")


if __name__ == "__main__":
    main()
