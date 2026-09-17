"""C2: production and trends -- beta_s, mu_F, sigma_s, delta, A0, gA, B0, gB.

Inputs : data/raw/pwt1001/pwt1001.xlsx (labour share), data/interim/b2_macro_block.csv
         (depreciation, Y, K), b1_material_block.csv (R, N by category),
         b2_omega.csv (Omega on the model's definition, rebuilt with the C1 weights),
         b3_resource_block.csv (fossil masses by fuel, the Jacks price indices),
         b3_usgs_ds140.csv (unit values), data/raw/worldbank_cmo (fossil prices),
         data/raw/wdi (agriculture value added, resource rents, nominal GDP)
Outputs: data/processed/calibration.json (params of this block)
         data/processed/c2_production_trends.csv

The shares.  The fixed factor 1 - mu_F stands in for labour, so mu_F is one minus
the PWT labour share.  The material elasticity gamma = mu_F (1 - beta_s) is the value
of primary material input over GDP in the calibration years: fossil masses at the
World Bank commodity prices, metal ores and non-metallic minerals at the USGS unit
values, and biomass at the value added of agriculture, forestry and fishing, each
over nominal world GDP.  beta_s follows.  The extraction cost share, which C3 needs,
is the same value share less the World Bank's natural resource rents, which are
defined as revenue less production cost.

Substitution.  sigma_s = 1 is held: under Cobb-Douglas the material value share is
constant and the intensity R/Y falls one for one with the real material price, and
the century's numbers are written out as the test of that.

Trends.  Under sigma_s = 1 only gA + gamma gB enters any path (A B^gamma is one
constant), so the composite is what growth accounting identifies:
composite = g_Y - beta_K g_K - gamma g_R over the window.  The split is a
convention: gB = 0, gA = composite.  A0 is set so that the production function
reproduces 1900 output at the 1900 stocks; B0 = 1.

Run from the repository root with PYTHONUTF8=1.
"""

import json
import math
import os
import sys
from collections import OrderedDict

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import (RAW, Record, b1_by_category, b1_series, b2_series, entry,  # noqa: E402
                      load_block, load_calibration, macro_series, pwt_world,
                      save_calibration, set_params)
from b3_gcb_fossil import FACTORS  # noqa: E402  NCV in GJ/t, IPCC (2006) Table 1.2

SRC = "quant_data.tex, Production and trends; notes/data/calibration.md"

BBL_PER_T_OIL = 7.33        # Rogner et al. (2012), GEA ch. 7, footnote 5: 1 t = 42 GJ = 7.33 bbl
GJ_PER_MMBTU = 1.05506      # unit definition
VALUE_YEARS = (2011, 2015)  # the dollar base year and the last year of the material block
WINDOWS = ((1900, 2015), (1950, 2015))


def pink_sheet(year):
    """Nominal prices of the fossil fuels in US$ per tonne of fuel."""
    x = pd.read_excel(os.path.join(RAW, "worldbank_cmo", "CMO-Historical-Data-Annual.xlsx"),
                      sheet_name="Annual Prices (Nominal)", header=None)
    hdr = x.index[x.iloc[:, 1].astype(str).str.startswith("Crude oil, average")][0]
    names = x.iloc[hdr].tolist()
    body = x.iloc[hdr + 2:].copy()
    body.columns = names
    body = body.set_index(body.columns[0])
    row = body.loc[[i for i in body.index if str(i).startswith(str(year))][0]]
    oil = float(row["Crude oil, average"]) * BBL_PER_T_OIL
    coal = float(row["Coal, Australian"])
    gas_mmbtu = pd.Series([row["Natural gas, US"], row["Natural gas, Europe"],
                           row["Liquefied natural gas, Japan"]]).astype(float).mean()
    gas = gas_mmbtu / GJ_PER_MMBTU * FACTORS["Gas"]["central"][1]
    return OrderedDict(oil=oil, coal=coal, gas=gas)


def wdi(code, year):
    with open(os.path.join(RAW, "wdi", f"WLD_{code}.json"), encoding="utf-8") as f:
        d = json.load(f)
    return float({r["date"]: r["value"] for r in d[1]}[str(year)])


def ds140_unit_value(ds, commodity, year):
    d = ds[(ds["series"] == "unit_value_nominal") & (ds["commodity"] == commodity)]
    return float(d.set_index("year")["value"].loc[year])


def main():
    rec = Record("c2_production_trends")
    b1 = load_block("b1_material_block")
    b2 = load_block("b2_macro_block")
    b3 = load_block("b3_resource_block")
    ds = load_block("b3_usgs_ds140")
    om = load_block("b2_omega")
    macro = macro_series()

    # --- depreciation and the labour share ---------------------------------
    dep = b2_series(b2, "depreciation_rate").loc[1950:2019]
    delta = dep.mean()
    rec.add("delta", delta, "per year", "PWT cn-weighted world depreciation, mean 1950-2019")
    rec.add("delta_1950", dep.loc[1950], "per year", "")
    rec.add("delta_2019", dep.loc[2019], "per year", "")
    pw = pwt_world().loc[1950:2019]
    labsh = pw["labsh"].mean()
    mu_F = 1 - labsh
    rec.add("labour_share", labsh, "share", "PWT cgdpo-weighted world labour share, mean 1950-2019")
    rec.add("labour_share_min_decade", pw["labsh"].groupby(pw.index // 10).mean().min(), "share", "")
    rec.add("labour_share_max_decade", pw["labsh"].groupby(pw.index // 10).mean().max(), "share", "")
    rec.add("mu_F", mu_F, "exponent", "1 - labour share")

    # --- the material value share --------------------------------------------
    N = b1_by_category(b1, "N", source="krausmann2018")
    fm = b3[b3["series"] == "fossil_extraction_mass"].pivot_table(
        index="year", columns="commodity", values="value")
    shares, cost_shares = [], []
    for y in VALUE_YEARS:
        gdp = wdi("NY.GDP.MKTP.CD", y) / 1e12
        px = pink_sheet(y)
        fossil = sum(fm.loc[y, f] * px[f] for f in ("coal", "oil", "gas")) / 1e3  # Gt * $/t / 1e3 = tn$
        stone = 0.5 * (ds140_unit_value(ds, "crushed_stone", y)
                       + ds140_unit_value(ds, "construction_sand_and_gravel", y))
        minerals = N.loc[y, "non_metallic_minerals"] * stone / 1e3
        metals = N.loc[y, "metals"] * ds140_unit_value(ds, "iron_ore", y) / 1e3
        agri = wdi("NV.AGR.TOTL.ZS", y) / 100 * gdp
        rents = wdi("NY.GDP.TOTL.RT.ZS", y) / 100 * gdp
        value = fossil + minerals + metals + agri
        for k, v in (("fossil", fossil), ("non_metallic_minerals", minerals), ("metals", metals),
                     ("biomass_agriculture_value_added", agri), ("total", value),
                     ("resource_rents", rents), ("nominal_gdp", gdp)):
            rec.add(f"value_{k}_{y}", v, "trillion current US$", "")
        for f in ("coal", "oil", "gas"):
            rec.add(f"price_{f}_{y}", px[f], "US$/t", "World Bank Pink Sheet, nominal")
        rec.add(f"unit_value_stone_{y}", stone, "US$/t", "USGS DS140, crushed stone and sand-gravel mean")
        rec.add(f"unit_value_iron_ore_{y}", ds140_unit_value(ds, "iron_ore", y), "US$/t", "USGS DS140")
        shares.append(value / gdp)
        cost_shares.append((value - rents) / gdp)
        rec.add(f"material_value_share_{y}", value / gdp, "share of GDP", "")
        rec.add(f"extraction_cost_share_{y}", (value - rents) / gdp, "share of GDP",
                "value less resource rents")
    gamma = sum(shares) / len(shares)
    cost_share = sum(cost_shares) / len(cost_shares)
    rec.add("gamma_R", gamma, "elasticity", "material value share, mean of the two years")
    rec.add("extraction_cost_share", cost_share, "share of GDP", "mean of the two years; used by C3")
    beta_s = 1 - gamma / mu_F
    beta_K = mu_F * beta_s
    rec.add("beta_s", beta_s, "share", "1 - gamma / mu_F")
    rec.add("beta_K", beta_K, "elasticity", "mu_F beta_s")

    # --- the Cobb-Douglas test: intensity against the real price ------------
    Y = macro["Y"]
    K = macro["K"]
    R = b1_series(b1, "R", "total")
    Om_obs = b2_series(om, "Omega_observed")
    Om_mod = b2_series(om, "Omega_model")
    p_agg = b3[b3["series"] == "price_index_mass_weighted_aggregate"].set_index("year")["value"]
    p_met = b3[b3["series"] == "price_index_metals_production_weighted"].set_index("year")["value"]
    g = lambda s, a, b: math.log(s.loc[b] / s.loc[a]) / (b - a)  # noqa: E731
    for (a, b) in WINDOWS:
        tag = f"{a}_{b}"
        rec.add(f"g_Y_{tag}", g(Y, a, b), "per year", "Maddison world GDP")
        rec.add(f"g_K_{tag}", g(K, a, b), "per year", "B2 capital stock")
        rec.add(f"g_R_{tag}", g(R, a, b), "per year", "Haas et al. (2020) material input")
        rec.add(f"g_Omega_observed_{tag}", g(Om_obs, a, b), "per year", "R/Y")
        rec.add(f"g_Omega_model_{tag}", g(Om_mod, a, b), "per year", "R/(D + phiI G) at the C1 weights")
        rec.add(f"g_price_mass_weighted_{tag}", g(p_agg, a, b), "per year",
                "Jacks (2019) real index, B3 mass weights")
        rec.add(f"g_price_metals_{tag}", g(p_met, a, b), "per year", "Jacks (2019), metals, production weights")
        rec.add(f"cd_test_intensity_elasticity_{tag}", g(Om_obs, a, b) / g(p_agg, a, b), "elasticity",
                "d ln(R/Y) / d ln p; Cobb-Douglas predicts -1")

    # --- growth accounting and the trends ------------------------------------
    comps = OrderedDict()
    for (a, b) in WINDOWS:
        comps[(a, b)] = g(Y, a, b) - beta_K * g(K, a, b) - gamma * g(R, a, b)
        rec.add(f"composite_gA_plus_gamma_gB_{a}_{b}", comps[(a, b)], "per year",
                "g_Y - beta_K g_K - gamma g_R")
    composite = comps[WINDOWS[0]]
    gA, gB = composite, 0.0
    rec.add("gA", gA, "per year", "the composite; gB = 0 by convention")
    rec.add("gB", gB, "per year", "convention: observationally equivalent to any split at sigma_s = 1")
    g_C = composite / (1 - beta_K)
    rec.add("cbgp_growth_implied", g_C, "per year", "(gA + gamma gB)/(1 - beta_K), the C-cell rate")
    rec.add("balanced_test_gY_over_minus_gOmega_model_1900_2015",
            g(Y, 1900, 2015) / (-g(Om_mod, 1900, 2015)), "ratio",
            "1 on a circular path, (mu_N - 1)/mu_N on a balanced dematerialization path")

    # --- the level ------------------------------------------------------------
    K0, R0, Y0 = K.loc[1900], R.loc[1900], Y.loc[1900]
    Q = K0 ** beta_s * R0 ** (1 - beta_s)
    A0 = Y0 / Q ** mu_F
    rec.add("K_1900", K0, "trillion 2011 intl $", "B2, reconstructed")
    rec.add("R_1900", R0, "Gt/yr", "Haas et al. (2020)")
    rec.add("Y_1900", Y0, "trillion 2011 intl $", "Maddison")
    rec.add("A0", A0, "level", "Y0 / Q^mu_F at B0 = 1; the damage factor at 1900 is neglected")

    cal = load_calibration()
    lo_c = min(comps.values())
    hi_c = max(comps.values())
    block = OrderedDict()
    block["A0"] = entry(A0, SRC)
    block["gA"] = entry(gA, SRC, low=lo_c, high=hi_c)
    block["B0"] = entry(1.0, SRC)
    block["gB"] = entry(gB, SRC)
    block["beta_s"] = entry(beta_s, SRC)
    block["mu_F"] = entry(mu_F, SRC, low=1 - pw["labsh"].groupby(pw.index // 10).mean().max(),
                          high=1 - pw["labsh"].groupby(pw.index // 10).mean().min())
    block["sigma_s"] = entry(1.0, SRC)
    block["delta"] = entry(delta, SRC, low=dep.loc[1950], high=dep.loc[2019])
    set_params(cal, block)
    save_calibration(cal)
    path = rec.write()
    print(f"c2: mu_F = {mu_F:.3f}, gamma = {gamma:.4f}, beta_s = {beta_s:.3f}, delta = {delta:.4f}, "
          f"composite = {composite:.4f} (windows {[round(v, 4) for v in comps.values()]}), "
          f"g_C = {g_C:.4f}, A0 = {A0:.4f}, cost share = {cost_share:.4f} -> {path}")


if __name__ == "__main__":
    main()
