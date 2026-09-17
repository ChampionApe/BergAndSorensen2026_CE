"""C6: the initial stocks at 1900 -- K0, S0, X0, P0, MK0, W0 -- and the fields of
Params that are not data: dt, Rbar and its grid, the four policy dials.

Inputs : data/interim/b2_macro_block.csv (K), b1_material_block.csv (the in-use stock,
         R), data/processed/calibration.json (S0, X0 from C3; W0 from C4; P0 from C5)
Outputs: data/processed/calibration.json (states complete; dt, Rbar, dials; Rbar_grid)
         data/processed/c6_states.csv

K0 is block B2's perpetual-inventory stock, reconstructed and flagged as such.  MK0 is
the in-use stock of manufactured capital in 1900 of Krausmann et al. (2018).  The
other four are written by the block that identifies them and are checked here.

Rbar is not identified by history (quant_calibration.tex, "The two parameters that
history cannot identify"); the baseline is Rbar = 0 and the surface of experiment E5
runs over a grid expressed as fractions of 2015 material input.  The dials are at
the planner corner; the experiments move them.

Run from the repository root with PYTHONUTF8=1.
"""

import os
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import (Record, b1_series, b2_series, entry, load_block,  # noqa: E402
                      load_calibration, save_calibration, set_params)

SRC = "quant_data.tex, Initial stocks; notes/data/calibration.md"
RBAR_FRACTIONS = (0.0, 0.1, 0.25, 0.5)


def main():
    rec = Record("c6_states")
    b1 = load_block("b1_material_block")
    b2 = load_block("b2_macro_block")
    cal = load_calibration()

    K0 = b2_series(b2, "K").loc[1900]
    MK0 = b1_series(b1, "MK", "total").loc[1900]
    R2015 = b1_series(b1, "R", "total").loc[2015]
    rec.add("K0", K0, "trillion 2011 intl $", "B2, perpetual inventory anchored at 1950; reconstructed")
    rec.add("MK0", MK0, "Gt", "Krausmann et al. (2018), in-use stock of manufactured capital, 1900")
    cal["states"]["K0"] = entry(K0, SRC)
    cal["states"]["MK0"] = entry(MK0, SRC)
    for k, note in (("S0", "C3"), ("X0", "C3"), ("P0", "C5"), ("W0", "C4")):
        if k not in cal["states"]:
            raise SystemExit(f"c6_states: {k} has not been written by {note}; run it first")
        e = cal["states"][k]
        rec.add(k, e["value"], "Gt", f"written by {note}; range [{e.get('low', e['value']):.4g}, "
                                     f"{e.get('high', e['value']):.4g}]")
    order = ["K0", "S0", "X0", "P0", "MK0", "W0"]
    cal["states"] = OrderedDict((k, cal["states"][k]) for k in order)

    block = OrderedDict()
    block["dt"] = entry(1.0, "decision D5: one period is one year")
    block["Rbar"] = entry(0.0, "quant_calibration.tex, The two parameters that history cannot identify")
    for d in ("phiW", "phiz", "phiP", "phiX"):
        block[d] = entry(1.0, "the planner corner; the experiments move the dials")
    set_params(cal, block)
    grid = [round(f * R2015, 3) for f in RBAR_FRACTIONS]
    cal["cases"]["Rbar_grid"] = grid
    rec.add("R_2015", R2015, "Gt/yr", "the reference for the Rbar grid")
    for f, g in zip(RBAR_FRACTIONS, grid):
        rec.add(f"Rbar_grid_{f}", g, "Gt/yr", "fraction of 2015 material input")

    # keep the JSON in the order of Params (model/src/parameters.jl) for readability
    order = ["dt", "rho", "eta", "psi_v", "A0", "gA", "B0", "gB", "beta_s", "mu_F", "sigma_s",
             "kappa", "delta", "Rbar", "abar", "xi", "tail", "psi_a",
             "cN0", "cN_inf", "gcN", "mu_N", "kap_N", "chi_N", "Sref",
             "cD0", "cD_inf", "gcD", "mu_D", "kap_D", "chi_D", "Xmax", "Xref",
             "mu_h", "cc0", "cc_inf", "gcc", "cT0", "cT_inf", "gcT", "chi_T", "dW",
             "theta0", "theta_min", "thetaP",
             "omY", "omN", "omD", "omW", "omC", "phiI", "OmNS", "OmDS",
             "phiW", "phiz", "phiP", "phiX"]
    missing = [k for k in order if k not in cal["params"]]
    if missing:
        raise SystemExit(f"c6_states: params missing {missing}")
    extra = [k for k in cal["params"] if k not in order]
    if extra:
        raise SystemExit(f"c6_states: params has unexpected keys {extra}")
    cal["params"] = OrderedDict((k, cal["params"][k]) for k in order)
    cal["cases"] = OrderedDict((k, cal["cases"][k]) for k in
                               ["abar", "Rbar_grid", "xi_range", "muN_range", "abar_H_range"])
    cal["meta"]["note"] = ("varphi is not written: psi_v = 0 switches the utility channel off and "
                           "the exponent is then undefined (notes/data/pollution.md).")
    save_calibration(cal)
    path = rec.write()
    print(f"c6: states K0 {K0:.2f}, S0 {cal['states']['S0']['value']:.0f}, X0 {cal['states']['X0']['value']:.0f}, "
          f"P0 {cal['states']['P0']['value']:.1f}, MK0 {MK0:.1f}, W0 {cal['states']['W0']['value']:.1f}; "
          f"Rbar grid {grid} -> {path}")


if __name__ == "__main__":
    main()
