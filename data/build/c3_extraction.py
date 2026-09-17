"""C3: extraction and exploration -- the composition of S and X, mu_N, cN(t), kap_N,
chi_N, Sref, mu_D, cD(t), kap_D, chi_D, Xmax, Xref; the states S0 and X0; the case
range muN_range.

Inputs : data/interim/b1_material_block.csv (N by category), b3_resource_block.csv
         (S0, X0, URR, price indices, fossil masses), b3_usgs_ds140.csv (world
         production by commodity), b3_exploration.csv (MinEx discovery costs),
         data/processed/c2_production_trends.csv (cost share, value share, Y),
         data/raw/wdi (resource rents)
Outputs: data/processed/calibration.json (params and states of this block)
         data/processed/c3_extraction.csv

The composition of S (ruling 6).  The reserve and the discovery ceiling are measured
for the exhaustible categories, fossil fuels and metal ores; the model draws its one
reserve down by total extraction N, three quarters of which is biomass and
construction minerals.  Putting those flows into N but not into S cannot be done
inside the one-material Params, so the composition chosen is the one that makes the
stock effect on the aggregate match the exhaustible categories' own relative
depletion: S0 = S0_ex / s_ex, where s_ex is the exhaustible share of cumulative
extraction 1900-2015.  Then S_t / S0 = 1 - (sum N)/S0 = 1 - (sum N_ex)/S0_ex when the
share is constant, so (Sref/S)^mu_N on the aggregate is what it would be on the
exhaustible stock.  What is lost: the renewable three quarters of N inherit a stock
effect they do not have, and the level of S is a bookkeeping quantity.  X0 and Xmax
are scaled the same way.  Metal ores enter on the gross-ore basis; the USGS gross-ore
commodities are scaled up to the material-flow total by the ratio of cumulative
extraction in the two sources.

mu_N (the price channel).  With c_N(t) held to absorb the flow-scale effect of the
effort cost, the trend of the real material price over 1900-2015 is the stock effect:
mu_N = -ln(p_2015/p_1900) / ln(S_2015/S_1900) on the mass-weighted Jacks aggregate.
The range is the same construction at the low and high reserve figures and, at the
bottom, the metals-only price channel.

chi_N.  For a cost sc (kap N + N^(1+chi)/(1+chi)) the ratio of production cost to
production value at the margin is (kap + N/(1+chi))/(kap + N), so chi_N is the value
share over the cost share less one, an upper reading because the Hotelling rent is
also in the value.  kap_N is a tenth of 1900 extraction, a judgement and not
a reading: at that value the choke price kap_N is 0.22 of the 1900 marginal cost
kap_N + N_1900^chi_N, not a tenth of it.  Sref = S0.

c_N(t).  The implied series c_N,t = MC_2015 (p_t/p_2015) (S_t/S0)^mu_N / (kap_N +
N_t^chi_N), with MC_2015 from the extraction cost share of GDP, falls by a factor of
about three over the century with no sign of flattening, so the convergent form
c_inf + (c_0 - c_inf) e^(-g t) is pinned at both ends and fitted in the middle:
c_0 is the 1900-1909 mean, c_inf the 2006-2015 mean (no progress after the sample,
the conservative reading), and g is the least-squares rate in logs.

Exploration.  mu_D from the MinEx tripling of the average cost of a discovery
between 1975-2005 and 2011-2020 against the shrinking room below the contained-metal
URR; cD from the exploration margin at replacement: marginal discovery cost equals
the resource rent per tonne when discoveries equal extraction.  chi_D = 1 by
convention, kap_D a tenth of 1900 extraction, Xref = X0.

Run from the repository root with PYTHONUTF8=1.
"""

import json
import math
import os
import sys
from collections import OrderedDict

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import (EXHAUSTIBLE, PROCESSED, RAW, Record, b1_by_category, entry,  # noqa: E402
                      load_block, load_calibration, macro_series, save_calibration,
                      set_params)

SRC = "quant_data.tex, Extraction and exploration; notes/data/resources.md; notes/data/calibration.md"
GROSS_ORE_COMMODITIES = ["iron_ore", "bauxite_alumina__bauxite", "chromium",
                         "titanium_minerals__ilmenite_and_slag",
                         "titanium_minerals__natural_&_synthetic_rutile"]
KAP_SHARE_OF_1900 = 0.1
CHI_D = 1.0
MINEX_PERIODS = ((1975, 2005, 65.0), (2011, 2020, 218.0))   # from b3_exploration.csv


def c2_value(name):
    d = pd.read_csv(os.path.join(PROCESSED, "c2_production_trends.csv")).set_index("name")["value"]
    return float(d[name])


def wdi(code, year):
    with open(os.path.join(RAW, "wdi", f"WLD_{code}.json"), encoding="utf-8") as f:
        d = json.load(f)
    return float({r["date"]: r["value"] for r in d[1]}[str(year)])


def b3_scalar(b3, series, commodity, unit_startswith):
    d = b3[(b3["series"] == series) & (b3["commodity"] == commodity)
           & b3["unit"].str.startswith(unit_startswith)]
    if len(d) != 1:
        raise KeyError(f"{series}/{commodity}/{unit_startswith}: {len(d)} rows")
    return float(d["value"].iloc[0])


def fit_convergence(t, c, c_0, c_inf):
    """Least-squares rate g in logs of c_t on c_inf + (c_0 - c_inf) e^(-g t), the
    two levels given, over a grid of g."""
    import numpy as np
    t = np.asarray(t, float)
    c = np.asarray(c, float)
    best = None
    for g in np.linspace(0.0, 0.2, 4001):
        fit = c_inf + (c_0 - c_inf) * np.exp(-g * t)
        sse = float(((np.log(fit) - np.log(c)) ** 2).sum())
        if best is None or sse < best[0]:
            best = (sse, g)
    sse, g = best
    return g, math.sqrt(sse / len(t))


def main():
    rec = Record("c3_extraction")
    b1 = load_block("b1_material_block")
    b3 = load_block("b3_resource_block")
    ds = load_block("b3_usgs_ds140")
    macro = macro_series()
    years = list(range(1900, 2016))

    # --- composition ---------------------------------------------------------
    N = b1_by_category(b1, "N", source="krausmann2018").loc[years]
    Ntot = N.sum(axis=1)
    s_ex = N[EXHAUSTIBLE].sum().sum() / Ntot.sum()
    rec.add("exhaustible_share_of_cumulative_N_1900_2015", s_ex, "share", "fossil plus metal ores")
    rec.add("exhaustible_share_of_N_1900", N.loc[1900, EXHAUSTIBLE].sum() / Ntot.loc[1900], "share", "")
    rec.add("exhaustible_share_of_N_2015", N.loc[2015, EXHAUSTIBLE].sum() / Ntot.loc[2015], "share", "")

    gross = ds[(ds["series"] == "world_production") & (ds["unit"] == "t_gross_weight")
               & ds["commodity"].isin(GROSS_ORE_COMMODITIES)]
    gross = gross.pivot_table(index="year", columns="commodity", values="value").loc[1900:2015]
    cov = N.loc[years, "metals"].sum() / (gross.sum().sum() / 1e9)
    rec.add("metal_ore_coverage_scale", cov, "ratio",
            "cumulative metal ores 1900-2015, Krausmann et al. (2018) over USGS gross-ore commodities")

    S0f_lo = b3_scalar(b3, "S0_low", "fossil_fuels", "Gt (fuel")
    S0f_hi = b3_scalar(b3, "S0_high", "fossil_fuels", "Gt (fuel")
    S0m = b3_scalar(b3, "S0_low", "metal_ores", "Gt (gross")
    pre = b3_scalar(b3, "X0_minus_S0_extraction_before_1900", "fossil_fuels", "Gt (fuel")
    for k, v in (("S0_fossil_low", S0f_lo), ("S0_fossil_high", S0f_hi),
                 ("S0_metal_ores_gross_usgs", S0m), ("extraction_before_1900_fossil", pre)):
        rec.add(k, v, "Gt", "B3")
    S0m_all = S0m * cov
    rec.add("S0_metal_ores_gross_scaled", S0m_all, "Gt", "USGS figure times the coverage scale")
    S0_ex = OrderedDict(low=S0f_lo + S0m_all, mid=0.5 * (S0f_lo + S0f_hi) + S0m_all,
                        high=S0f_hi + S0m_all)
    for k, v in S0_ex.items():
        rec.add(f"S0_exhaustible_{k}", v, "Gt", "fossil plus scaled metal ores")
    S0 = OrderedDict((k, v / s_ex) for k, v in S0_ex.items())
    for k, v in S0.items():
        rec.add(f"S0_{k}", v, "Gt", "divided by the exhaustible share: the model's S0")
    X0 = OrderedDict((k, (S0_ex[k] + pre) / s_ex) for k in S0_ex)
    for k, v in X0.items():
        rec.add(f"X0_{k}", v, "Gt", "S0 plus pre-1900 extraction (fossil only; a lower bound)")

    urr_f = OrderedDict(low=b3_scalar(b3, "URR_low", "fossil_fuels", "Gt (cum"),
                        central=b3_scalar(b3, "URR_central", "fossil_fuels", "Gt (cum"),
                        high=b3_scalar(b3, "URR_high", "fossil_fuels", "Gt (cum"))
    urr_fc = OrderedDict(
        low=b3_scalar(b3, "URR_low", "fossil_fuels_conventional_and_coal", "Gt (cum"),
        central=b3_scalar(b3, "URR_central", "fossil_fuels_conventional_and_coal", "Gt (cum"),
        high=b3_scalar(b3, "URR_high", "fossil_fuels_conventional_and_coal", "Gt (cum"))
    urr_m = OrderedDict()
    for k, ser in (("low", "URR_low"), ("high", "URR_high")):
        urr_m[k] = sum(b3_scalar(b3, ser, c, "Gt (world") for c in
                       ("iron_ore_gross_ore", "bauxite_gross_ore", "chromium_ore_gross_ore",
                        "titanium_minerals_gross_ore")) * cov
    urr_m["central"] = 0.5 * (urr_m["low"] + urr_m["high"])
    for k in ("low", "central", "high"):
        rec.add(f"URR_fossil_{k}", urr_f[k], "Gt", "Rogner et al. (2012), B3")
        rec.add(f"URR_fossil_conventional_plus_coal_{k}", urr_fc[k], "Gt", "the variant")
        rec.add(f"URR_metal_ores_gross_scaled_{k}", urr_m[k], "Gt", "USGS world resources, scaled")
    Xmax = OrderedDict((k, (urr_f[k] + urr_m[k]) / s_ex) for k in ("low", "central", "high"))
    Xmax_c = OrderedDict((k, (urr_fc[k] + urr_m[k]) / s_ex) for k in ("low", "central", "high"))
    for k in Xmax:
        rec.add(f"Xmax_{k}", Xmax[k], "Gt", "the model's discovery ceiling")
        rec.add(f"Xmax_conventional_plus_coal_{k}", Xmax_c[k], "Gt", "the variant")

    # --- mu_N from the price channel ----------------------------------------
    p_agg = b3[b3["series"] == "price_index_mass_weighted_aggregate"].set_index("year")["value"]
    p_met = b3[b3["series"] == "price_index_metals_production_weighted"].set_index("year")["value"]
    cumN = Ntot.cumsum().shift(1).fillna(0.0)       # extraction before year t
    S_path = OrderedDict((k, S0[k] - cumN) for k in S0)
    muN = OrderedDict()
    for k in S0:
        muN[k] = -math.log(p_agg.loc[2015] / p_agg.loc[1900]) / math.log(S_path[k].loc[2015] / S0[k])
        rec.add(f"mu_N_price_channel_S0_{k}", muN[k], "elasticity", "mass-weighted aggregate index")
    rec.add("price_index_mass_weighted_2015", p_agg.loc[2015], "1900 = 100", "Jacks (2019), B3")
    rec.add("price_index_metals_2015", p_met.loc[2015], "1900 = 100", "Jacks (2019), B3")
    Sm0 = S0m_all
    Sm_path = Sm0 - N["metals"].cumsum().shift(1).fillna(0.0)
    muN_met = -math.log(p_met.loc[2015] / p_met.loc[1900]) / math.log(Sm_path.loc[2015] / Sm0)
    rec.add("mu_N_price_channel_metals_only", muN_met, "elasticity",
            "metals index against the metal-ore stock; negative means the price fell")
    rec.add("energy_grade_elasticity_gold", -0.2848, "elasticity", "Mudd (2010), B3: the physical channel")
    mu_N = muN["mid"]
    mu_lo = max(0.0, min(muN_met, muN["low"]))
    mu_hi = muN["high"]

    # --- chi_N, kap_N, Sref, and the cost path ------------------------------
    value_share = c2_value("gamma_R")
    cost_share = c2_value("extraction_cost_share")
    chi_N = value_share / cost_share - 1
    rec.add("chi_N", chi_N, "exponent", "value share over cost share less one")
    kap_N = KAP_SHARE_OF_1900 * Ntot.loc[1900]
    rec.add("kap_N", kap_N, "Gt/yr", "a tenth of 1900 extraction")
    Sref = S0["mid"]
    Y = macro["Y"]
    S_t = S_path["mid"]
    CN_2015 = cost_share * Y.loc[2015]
    eff = lambda n: kap_N * n + n ** (1 + chi_N) / (1 + chi_N)  # noqa: E731
    mc = lambda n: kap_N + n ** chi_N  # noqa: E731
    sc_2015 = CN_2015 / eff(Ntot.loc[2015])
    MC_2015 = sc_2015 * mc(Ntot.loc[2015])
    rec.add("CN_2015", CN_2015, "trillion $", "cost share times Y_2015")
    rec.add("MC_2015", MC_2015, "trillion $/Gt", "the marginal cost the form implies at N_2015")
    rec.add("MC_2015_usd_per_t", MC_2015 * 1000, "US$/t", "")
    cN_impl = pd.Series({t: MC_2015 * (p_agg.loc[t] / p_agg.loc[2015]) * (S_t.loc[t] / Sref) ** mu_N
                         / mc(Ntot.loc[t]) for t in years})
    cN0 = cN_impl.loc[1900:1909].mean()
    cN_inf = cN_impl.loc[2006:2015].mean()
    gcN, rmse = fit_convergence([t - 1900 for t in years], cN_impl.values, cN0, cN_inf)
    rec.add("cN_implied_1900", cN_impl.loc[1900], "trillion $/Gt^(1+chi_N)", "")
    rec.add("cN_implied_2015", cN_impl.loc[2015], "trillion $/Gt^(1+chi_N)", "")
    rec.add("cN0", cN0, "trillion $/Gt^(1+chi_N)", "mean of the implied series 1900-1909")
    rec.add("cN_inf", cN_inf, "trillion $/Gt^(1+chi_N)", "mean of the implied series 2006-2015")
    rec.add("gcN", gcN, "per year", "fitted in logs with both levels given")
    rec.add("cN_fit_rmse_log", rmse, "log points", "")
    rec.add("CN_over_Y_1900_at_fit", cN0 * eff(Ntot.loc[1900]) / Y.loc[1900], "share", "check")

    # --- exploration ----------------------------------------------------------
    # Contained-metal mine production; refined aluminium and sulfur are not ore extraction.
    metal = ds[(ds["series"] == "world_production") & ds["unit"].str.endswith("_content")
               & ~ds["commodity"].isin(["aluminum", "sulfur"])]
    metal = metal.pivot_table(index="year", columns="commodity", values="value").fillna(0.0)
    Xm = (metal.sum(axis=1).cumsum() / 1e9).loc[1900:2022]
    urr_cm = OrderedDict(low=b3_scalar(b3, "URR_low", "metal_ores_contained_metal", "Gt"),
                         central=b3_scalar(b3, "URR_central", "metal_ores_contained_metal", "Gt"),
                         high=b3_scalar(b3, "URR_high", "metal_ores_contained_metal", "Gt"))
    (a0, a1, cost0), (b0, b1, cost1) = MINEX_PERIODS
    t0, t1 = (a0 + a1) // 2, (b0 + b1) // 2
    rec.add("minex_cost_per_discovery_early", cost0, "2023 US$ million", f"{a0}-{a1}, B3")
    rec.add("minex_cost_per_discovery_late", cost1, "2023 US$ million", f"{b0}-{b1}, B3")
    rec.add("cumulative_contained_metal_early", Xm.loc[t0], "Gt", f"USGS DS140, 1900-{t0}")
    rec.add("cumulative_contained_metal_late", Xm.loc[t1], "Gt", f"USGS DS140, 1900-{t1}")
    muD = OrderedDict()
    for k, u in urr_cm.items():
        muD[k] = math.log(cost1 / cost0) / math.log((u - Xm.loc[t0]) / (u - Xm.loc[t1]))
        rec.add(f"mu_D_URR_{k}", muD[k], "elasticity", f"contained-metal URR {u:.2f} Gt")
    mu_D = muD["central"]
    rents = 0.5 * sum(wdi("NY.GDP.TOTL.RT.ZS", y) / 100 * wdi("NY.GDP.MKTP.CD", y) / 1e12
                      for y in (2011, 2015))
    rent_per_t = rents / (0.5 * (Ntot.loc[2011] + Ntot.loc[2015]))
    rec.add("resource_rents_mean_2011_2015", rents, "trillion current US$", "WDI")
    rec.add("rent_per_tonne_of_N", rent_per_t, "trillion $/Gt", "over total extraction")
    kap_D = KAP_SHARE_OF_1900 * Ntot.loc[1900]
    D_rep = Ntot.loc[2015]
    cD0 = rent_per_t / (kap_D + D_rep ** CHI_D)
    rec.add("kap_D", kap_D, "Gt/yr", "a tenth of 1900 extraction")
    rec.add("cD0", cD0, "trillion $/Gt^(1+chi_D)", "marginal discovery cost = rent per tonne at D = N_2015")
    CD_rep = cD0 * (kap_D * D_rep + D_rep ** (1 + CHI_D) / (1 + CHI_D))
    rec.add("CD_at_replacement_2015", CD_rep, "trillion $", "the form's total cost at D = N_2015")
    minex = load_block("b3_exploration")
    spend = minex[minex["series"] == "world_exploration_spend"].set_index("year")["value"]
    rec.add("minex_world_exploration_spend_2012", spend.loc[2012] / 1000, "trillion 2023 US$",
            "metals only; the check on the order of magnitude")

    # --- write ---------------------------------------------------------------
    cal = load_calibration()
    block = OrderedDict()
    block["cN0"] = entry(cN0, SRC)
    block["cN_inf"] = entry(cN_inf, SRC, low=0.5 * cN_inf, high=cN_inf)
    block["gcN"] = entry(gcN, SRC)
    block["mu_N"] = entry(mu_N, SRC, low=mu_lo, high=mu_hi)
    block["kap_N"] = entry(kap_N, SRC, low=0.0, high=Ntot.loc[1900])
    block["chi_N"] = entry(chi_N, SRC, low=0.5 * chi_N, high=1.0)
    block["Sref"] = entry(Sref, SRC)
    block["cD0"] = entry(cD0, SRC)
    block["cD_inf"] = entry(cD0, SRC)
    block["gcD"] = entry(0.0, SRC)
    block["mu_D"] = entry(mu_D, SRC, low=min(muD.values()), high=max(muD.values()))
    block["kap_D"] = entry(kap_D, SRC, low=0.0, high=Ntot.loc[1900])
    block["chi_D"] = entry(CHI_D, SRC)
    block["Xmax"] = entry(Xmax["central"], SRC, low=Xmax["low"], high=Xmax["high"])
    block["Xref"] = entry(X0["mid"], SRC)
    set_params(cal, block)
    cal["states"]["S0"] = entry(S0["mid"], SRC, low=S0["low"], high=S0["high"])
    cal["states"]["X0"] = entry(X0["mid"], SRC, low=X0["low"], high=X0["high"])
    cal["cases"]["muN_range"] = [mu_lo, mu_hi]
    save_calibration(cal)
    path = rec.write()
    print(f"c3: s_ex = {s_ex:.3f}, S0 = {S0['mid']:.0f} [{S0['low']:.0f}, {S0['high']:.0f}], "
          f"X0 = {X0['mid']:.0f}, Xmax = {Xmax['central']:.0f} [{Xmax['low']:.0f}, {Xmax['high']:.0f}], "
          f"mu_N = {mu_N:.3f} [{mu_lo:.3f}, {mu_hi:.3f}] (metals {muN_met:.3f}), chi_N = {chi_N:.3f}, "
          f"cN0 = {cN0:.3e}, cN_inf = {cN_inf:.3e}, gcN = {gcN:.4f} (rmse {rmse:.3f}), "
          f"mu_D = {mu_D:.2f} [{min(muD.values()):.2f}, {max(muD.values()):.2f}], cD0 = {cD0:.3e} -> {path}")


if __name__ == "__main__":
    main()
