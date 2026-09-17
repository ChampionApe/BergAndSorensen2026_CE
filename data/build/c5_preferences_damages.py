"""C5: preferences and damages -- rho, eta, psi_v, kappa, theta0, theta_min, thetaP;
the state P0.

Inputs : data/raw/pwt1001/pwt1001.xlsx (the internal rate of return), b2_macro_block.csv
         (world output), b5_pollution_block.csv (the damage arithmetic, the decay fits,
         the 1900 stock), b3_resource_block.csv (fossil masses by fuel),
         b1_material_block.csv (the fossil share of the outflow),
         data/processed/c2_production_trends.csv (delta, the shares)
Outputs: data/processed/calibration.json (params and state of this block)
         data/processed/c5_preferences_damages.csv

Preferences.  On a balanced path the Euler equation reads r = rho + eta g, and the
consumption-wealth ratio is r - g whatever the preferences, so the two moments of the
identification table pin one combination.  Time variation separates the two: the
decade means of the PWT world real return on capital are regressed on the decade
means of world output growth over 1950-2019, eta the slope and rho the intercept.
The collapse ranking condition (1-delta)^(1-eta) < 1+rho is then checked; if the
data value of eta fails it, the largest eta that passes at the data rho is used and
the data value is recorded beside it (ruling 9).

Damages (decision D4, ruling 7).  P is the stock of material that has reached the
environment, in gigatonnes.  The damage per gigatonne is the DICE-2023 marginal loss
per GtCO2 at the 3 degree reference stock, from block B5, times the GtCO2 released
per Gt of Xi at the 2000-2015 composition of the outflow: the fossil share of DPO
times the CO2 mass per tonne of fuel at the 2000-2015 fuel mix.  The utility channel
is off, psi_v = 0, because DICE carries no separate non-market loss (notes/data/
pollution.md); varphi is then undefined and is not written.  Decay is constant at the
rate that drives the observed emission path to the impulse-response stock in 2024,
with the pulse fit as the range's lower end; theta0 = theta_min, thetaP = 0, since the
state dependence is not identified.  P0 is the 1900 atmospheric excess stock of B5
converted at the 1900 composition.

Run from the repository root with PYTHONUTF8=1.
"""

import math
import os
import sys
from collections import OrderedDict

import numpy as np
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import (PROCESSED, Record, b1_by_category, b2_series, entry, load_block,  # noqa: E402
                      load_calibration, pwt_world, save_calibration, set_params)

SRC_PREF = "quant_data.tex, Preferences; notes/data/calibration.md"
SRC_DMG = "quant_data.tex, Damages and decay; notes/data/pollution.md"
YEARS = (1950, 2019)
WINDOW = (2000, 2015)
MARGIN = 0.99   # the fraction of the collapse bound used when eta has to be reduced


def b5(block, series):
    d = block[block["series"] == series]
    d = d[d["year"].isna()] if d["year"].isna().any() else d
    if len(d) != 1:
        raise KeyError(f"b5 {series}: {len(d)} rows")
    return float(d["value"].iloc[0])


def c2_value(name):
    d = pd.read_csv(os.path.join(PROCESSED, "c2_production_trends.csv")).set_index("name")["value"]
    return float(d[name])


def main():
    rec = Record("c5_preferences_damages")
    p5 = load_block("b5_pollution_block")
    b1 = load_block("b1_material_block")
    b2 = load_block("b2_macro_block")
    b3 = load_block("b3_resource_block")

    # --- preferences ----------------------------------------------------------
    pw = pwt_world().loc[YEARS[0]:YEARS[1]]
    Y = b2_series(b2, "Y")
    gY = np.log(Y).diff().loc[YEARS[0] + 1:YEARS[1]]
    dec = pd.DataFrame({"r": pw["irr"], "g": gY}).dropna()
    dec = dec.groupby(dec.index // 10 * 10).mean()
    for d, row in dec.iterrows():
        rec.add(f"decade_{d}_real_return", row["r"], "per year", "PWT irr, cn-weighted world mean")
        rec.add(f"decade_{d}_output_growth", row["g"], "per year", "Maddison world GDP, log growth")
    X = np.column_stack([np.ones(len(dec)), dec["g"].values])
    coef, *_ = np.linalg.lstsq(X, dec["r"].values, rcond=None)
    rho_data, eta_data = float(coef[0]), float(coef[1])
    fit = X @ coef
    r2 = 1 - ((dec["r"].values - fit) ** 2).sum() / ((dec["r"].values - dec["r"].mean()) ** 2).sum()
    rec.add("rho_data", rho_data, "per year", "intercept of r on g across decades")
    rec.add("eta_data", eta_data, "elasticity", "slope of r on g across decades")
    rec.add("euler_regression_r2", r2, "", f"{len(dec)} decades")
    rec.add("mean_real_return_1950_2019", pw["irr"].mean(), "per year", "")
    rec.add("mean_output_growth_1950_2019", gY.mean(), "per year", "")
    delta = c2_value("delta")
    rho = rho_data
    bound = 1 + math.log(1 + rho) / (-math.log(1 - delta))      # the largest eta that passes
    rec.add("eta_collapse_bound", bound, "elasticity", "(1-delta)^(1-eta) < 1+rho at the data rho")
    if eta_data < bound:
        eta = eta_data
        rec.add("eta", eta, "elasticity", "the data value passes the collapse condition")
    else:
        eta = MARGIN * bound if MARGIN * bound > 1 else bound
        rec.add("eta", eta, "elasticity", "the data value fails; the largest passing value is used")
    rec.add("rho", rho, "per year", "")
    g_C = c2_value("cbgp_growth_implied")
    rec.add("implied_real_rate_on_C_path", (1 + rho) * math.exp(eta * g_C) - 1, "per year",
            "(1+rho) e^(eta g) - 1 at the C-cell rate")
    rec.add("consumption_wealth_ratio_2015", b2_series(b2, "C").loc[2015] / b2_series(b2, "K").loc[2015],
            "per year", "C/K, B2; r - g on a balanced path")

    # --- damages ---------------------------------------------------------------
    kco2 = OrderedDict(best=b5(p5, "kappa_marginal_at_3degC_under_best_tcre_tcre_best"),
                       low=b5(p5, "kappa_marginal_at_3degC_under_best_tcre_tcre_low"),
                       high=b5(p5, "kappa_marginal_at_3degC_under_best_tcre_tcre_high"))
    for k, v in kco2.items():
        rec.add(f"kappa_per_GtCO2_marginal_3degC_{k}", v, "per GtCO2", "B5, DICE-2023 with the AR6 TCRE")
    rec.add("kappa_per_GtCO2_marginal_today_anchor",
            b5(p5, "kappa_marginal_at_latest_cumulative_fossil_co2_tcre_best"), "per GtCO2",
            "the alternative anchor, not used")
    co2 = p5[p5["series"].isin(["co2_fossil_coal", "co2_fossil_oil", "co2_fossil_gas"])]
    co2 = co2.pivot_table(index="year", columns="series", values="value")
    fm = b3[b3["series"] == "fossil_extraction_mass"].pivot_table(index="year", columns="commodity",
                                                                  values="value")
    dpo = b1_by_category(b1, "DPO")

    def ratio(y0, y1):
        c = co2.loc[y0:y1].sum().sum()
        m = fm.loc[y0:y1].sum().sum()
        share = dpo.loc[y0:y1, "fossil"].sum() / dpo.loc[y0:y1].sum().sum()
        return c / m, share, share * c / m

    tco2, share, conv = ratio(*WINDOW)
    rec.add("co2_per_tonne_of_fuel_2000_2015", tco2, "tCO2/t", "GCB CO2 over B3 fuel mass")
    rec.add("fossil_share_of_DPO_2000_2015", share, "share", "Haas et al. (2020)")
    rec.add("GtCO2_per_Gt_of_Xi_2000_2015", conv, "GtCO2/Gt", "the product")
    kappa = OrderedDict((k, v * conv) for k, v in kco2.items())
    for k, v in kappa.items():
        rec.add(f"kappa_{k}", v, "per Gt of P", "")
    tco2_0, share_0, conv_0 = ratio(1900, 1900)
    rec.add("co2_per_tonne_of_fuel_1900", tco2_0, "tCO2/t", "")
    rec.add("fossil_share_of_DPO_1900", share_0, "share", "")
    P0co2 = b5(p5, "P0_1900_irf_excess_stock")
    P0 = P0co2 / conv_0
    rec.add("P0_GtCO2", P0co2, "GtCO2", "B5, atmospheric excess stock in 1900")
    rec.add("P0", P0, "Gt of material", "converted at the 1900 composition")

    th_driven = b5(p5, "theta_constant_driven_to_irf_stock")
    th_pulse = b5(p5, "theta_constant_benchmark")
    rec.add("theta_driven", th_driven, "per year", "B5, the emissions-driven fit")
    rec.add("theta_pulse", th_pulse, "per year", "B5, the pulse fit")
    theta = th_driven
    rec.add("notipping_condition", "vacuous at thetaP = 0", "", "")
    Y0 = Y.loc[1900]
    r0 = (1 + rho) * math.exp(eta * g_C) - 1
    pP0 = kappa["best"] * Y0 / (r0 + theta)
    rec.add("damage_share_1900", 1 - math.exp(-kappa["best"] * P0), "share of output", "1 - e^(-kappa P0)")
    rec.add("pollution_price_1900_rough", pP0, "trillion $/Gt",
            "kappa Y0 / (r + theta): the scale the pollution costate should show at 1900")

    # --- write ------------------------------------------------------------------
    cal = load_calibration()
    block = OrderedDict()
    block["rho"] = entry(rho, SRC_PREF)
    block["eta"] = entry(eta, SRC_PREF, low=min(eta, eta_data), high=max(eta, eta_data))
    block["psi_v"] = entry(0.0, SRC_DMG)
    block["kappa"] = entry(kappa["best"], SRC_DMG, low=kappa["low"], high=kappa["high"])
    block["theta0"] = entry(theta, SRC_DMG, low=th_pulse, high=th_driven)
    block["theta_min"] = entry(theta, SRC_DMG, low=th_pulse, high=th_driven)
    block["thetaP"] = entry(0.0, SRC_DMG)
    set_params(cal, block)
    cal["states"]["P0"] = entry(P0, SRC_DMG)
    save_calibration(cal)
    path = rec.write()
    print(f"c5: rho = {rho:.4f}, eta = {eta:.3f} (data {eta_data:.3f}, bound {bound:.3f}, R2 {r2:.2f}), "
          f"kappa = {kappa['best']:.3e} [{kappa['low']:.3e}, {kappa['high']:.3e}] per Gt, conv = {conv:.3f}, "
          f"P0 = {P0:.1f} Gt, theta = {theta:.5f}, pP0 ~ {pP0:.2e} -> {path}")


if __name__ == "__main__":
    main()
