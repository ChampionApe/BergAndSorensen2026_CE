"""C4: waste handling and recycling -- mu_h, cc0, cc_inf, gcc, cT0, cT_inf, gcT, chi_T,
dW, abar, xi, tail, psi_a; the state W0; the cases abar and xi_range.

Inputs : data/interim/b1_material_block.csv, b1_haas2020.csv (the outflow
         decomposition), b4_waste_block.csv (treatment shares, the cost ladder, the
         metals recycling rate), b4_xi_literature.csv (the EPA capital outlay)
Outputs: data/processed/calibration.json (params, state and cases of this block)
         data/processed/c4_waste.csv

The stock and the handling share (decision D3, ruling 3).  The waste stock is the
cumulative disposal of fossil, metal and non-metallic mineral outflows since 1900,
Wcum_disposal of block B1 without biomass, whose residues cycle ecologically and are
not stockpiled.  mu_h is set so that mu_h * W_2015 equals the handled flow, B1's
outflow of those three categories to disposal in 2015; the reading that adds the
same year's recovered flow to the handled flow is the range's upper end.

The treated share is not a parameter.  Two readings are recorded as the check on
the solved path: recycling over recycling plus disposal on B1, and the municipal
treated share of B4.

Costs (ruling 8).  cc is the collection charge at a low treated share, the
low-income collection and transfer range of Kaza et al. (2018); cT is the marginal
treatment cost at full treatment, the high-income controlled-to-sanitary landfill
range.  Midpoints are the points, the ranges the ranges, US$/t converted at 0.001
trillion $/Gt; the price base of both sources is not stated and no deflation is
applied.  chi_T in [0.5, 3] with the midpoint; dW = 0.15 in [0.05, 0.30].

The ceiling and the tail.  abar = 1 is the baseline, with the metals-only
mass-weighted end-of-life recycling rate of B4 as the hard-ceiling case.  xi is set
so that the exponential yield passes through the observed point: the yield
a = RR / (varpi H) on B1's non-biomass flows at the municipal treated share, and
the slope a'(x) from the EPA (2024) capital outlay per tonne of added annual
recovery, whence xi = a' / (abar - a).  The tail is exponential; psi_a = 1 is the
power-tail sensitivity, the largest exponent that keeps the yield concave.

Run from the repository root with PYTHONUTF8=1.
"""

import os
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from c_common import (USD_PER_T_TO_TN_PER_GT, Record, b1_series, entry, load_block,  # noqa: E402
                      load_calibration, save_calibration, set_params)

SRC = "quant_data.tex, Waste handling and recycling; notes/data/waste_stock.md; notes/data/waste_recycling.md"
STOCKPILED = ["fossil", "metals", "non_metallic_minerals"]
CHI_T = (0.5, 1.75, 3.0)
DW = (0.05, 0.15, 0.30)
PSI_A = 1.0


def b4(block, series, region=None, year=None):
    d = block[block["series"] == series]
    if region is not None:
        d = d[d["region_or_material"] == region]
    if year is not None:
        d = d[d["year"] == year]
    if len(d) != 1:
        raise KeyError(f"b4 {series}/{region}/{year}: {len(d)} rows")
    return float(d["value"].iloc[0])


def main():
    rec = Record("c4_waste")
    b1 = load_block("b1_material_block")
    haas = load_block("b1_haas2020")
    w4 = load_block("b4_waste_block")
    xl = load_block("b4_xi_literature")

    # --- the stock and the handling share -----------------------------------
    W2015 = sum(b1_series(b1, "Wcum_disposal", c).loc[2015] for c in STOCKPILED)
    Wbio = b1_series(b1, "Wcum_disposal", "biomass").loc[2015]
    rec.add("Wstock_2015", W2015, "Gt", "cumulative disposal 1900-2015, fossil, metals, minerals")
    rec.add("Wstock_2015_biomass_excluded", Wbio, "Gt", "the biomass residue not counted")
    sl = haas[haas["series"] == "out_solid_liquid"].pivot_table(index="year", columns="category",
                                                                 values="value")
    disp = sl.loc[2015, STOCKPILED].sum()
    disp1900 = sl.loc[1900, STOCKPILED].sum()
    RR = sum(b1_series(b1, "RR", c).loc[2015] for c in STOCKPILED)
    rec.add("disposal_outflow_2015", disp, "Gt/yr", "Haas et al. (2020), solid and liquid residues")
    rec.add("recycled_2015", RR, "Gt/yr", "Haas et al. (2020), secondary input, the same categories")
    rec.add("disposal_outflow_1900", disp1900, "Gt/yr", "")
    mu = disp / W2015
    mu_hi = (disp + RR) / W2015
    rec.add("mu_h", mu, "per year", "disposal outflow over the stock")
    rec.add("mu_h_including_recovery", mu_hi, "per year", "handled flow read as disposal plus recovery")
    rec.add("residence_time", 1 / mu, "years", "1/mu_h")

    # --- the treated share, a check and not a parameter ----------------------
    rec.add("treated_share_recycling_only", RR / (RR + disp), "share", "B1, non-biomass")
    rec.add("treated_share_msw_unep2020", b4(w4, "global_treated_share", "World", 2020) / 100, "share",
            "UNEP (2024)")
    rec.add("treated_share_msw_kaza2016", b4(w4, "global_treated_share", "World", 2016) / 100, "share",
            "Kaza et al. (2018)")

    # --- costs ----------------------------------------------------------------
    cc_lo = b4(w4, "unit_cost_collection_and_transfer_low__kaza2018", "LIC")
    cc_hi = b4(w4, "unit_cost_collection_and_transfer_high__kaza2018", "LIC")
    cT_lo = b4(w4, "unit_cost_controlled_to_sanitary_landfill_low__kaza2018", "HIC")
    cT_hi = b4(w4, "unit_cost_controlled_to_sanitary_landfill_high__kaza2018", "HIC")
    rec.add("cc_usd_low", cc_lo, "US$/t", "Kaza et al. (2018) table 5.2, low income, collection")
    rec.add("cc_usd_high", cc_hi, "US$/t", "")
    rec.add("cT_usd_low", cT_lo, "US$/t", "Kaza et al. (2018) table 5.2, high income, sanitary landfill")
    rec.add("cT_usd_high", cT_hi, "US$/t", "")
    cc = 0.5 * (cc_lo + cc_hi) * USD_PER_T_TO_TN_PER_GT
    cT = 0.5 * (cT_lo + cT_hi) * USD_PER_T_TO_TN_PER_GT
    rec.add("cc0", cc, "trillion $/Gt", "midpoint; price base not stated")
    rec.add("cT0", cT, "trillion $/Gt", "midpoint; price base not stated")
    H = disp + RR
    vw = b4(w4, "global_treated_share", "World", 2020) / 100
    CW = (cc * vw + cT * vw ** (1 + CHI_T[1]) / (1 + CHI_T[1])) * H
    rec.add("CW_2015_at_msw_share", CW, "trillion $", "c^W(varpi) H at the UNEP treated share, chi_T midpoint")

    # --- the ceiling ----------------------------------------------------------
    a_mid = b4(w4, "eolrr_massweighted_mid", "metals_only") / 100
    a_lo = b4(w4, "eolrr_massweighted_min", "metals_only") / 100
    a_hi = b4(w4, "eolrr_massweighted_max", "metals_only") / 100
    rec.add("abar_metals", a_mid, "share", "UNEP IRP (2011) mass-weighted end-of-life recycling rate")
    rec.add("abar_metals_low", a_lo, "share", "")
    rec.add("abar_metals_high", a_hi, "share", "")

    # --- the tail rate --------------------------------------------------------
    a_obs = RR / (vw * H)
    rec.add("yield_observed_2015", a_obs, "share", "RR / (varpi H), non-biomass, UNEP treated share")
    epa = xl.set_index("series")["value"]
    cap = [(epa["epa_packaging_investment_low"] / epa["epa_packaging_added_recovery_low"]),
           (epa["epa_packaging_investment_high"] / epa["epa_packaging_added_recovery_high"])]
    cap_all = [(epa["epa_all_investment_low"] / epa["epa_all_added_recovery_low"]),
               (epa["epa_all_investment_high"] / epa["epa_all_added_recovery_high"])]
    kpt = 0.5 * sum(cap) * USD_PER_T_TO_TN_PER_GT           # trillion $ per Gt/yr
    kpt_all = 0.5 * sum(cap_all) * USD_PER_T_TO_TN_PER_GT
    rec.add("capital_per_added_tonne_packaging", kpt, "trillion $ per Gt/yr", "US EPA (2024), packaging")
    rec.add("capital_per_added_tonne_all", kpt_all, "trillion $ per Gt/yr", "US EPA (2024), with organics")
    ap = 1 / kpt
    xi = ap / (1.0 - a_obs)
    xi_all = (1 / kpt_all) / (1.0 - a_obs)
    rec.add("aprime_observed", ap, "Gt per trillion $", "1 / capital per added tonne")
    rec.add("xi", xi, "Gt per trillion $", "a' / (abar - a) at abar = 1")
    rec.add("xi_with_organics", xi_all, "Gt per trillion $", "the same on the wider programme")
    xi_lo, xi_hi = xi / 3, xi * 3
    rec.add("xi_low", xi_lo, "Gt per trillion $", "an order of magnitude around the point")
    rec.add("xi_high", xi_hi, "Gt per trillion $", "")
    import math
    x_obs = -math.log(1 - a_obs) / xi
    KR = x_obs * vw * H
    rec.add("x_implied_2015", x_obs, "trillion $/Gt", "recycling capital per treated tonne")
    rec.add("KR_implied_2015", KR, "trillion $", "x times the treated flow")

    # --- W0 --------------------------------------------------------------------
    W0 = disp1900 / mu
    rec.add("W0", W0, "Gt", "the stock consistent with the 1900 disposal flow at mu_h")
    rec.add("W0_own_year_only", sum(b1_series(b1, "Wcum_disposal", c).loc[1900] for c in STOCKPILED),
            "Gt", "the 1900 residue alone, the lower end")

    # --- write ------------------------------------------------------------------
    cal = load_calibration()
    block = OrderedDict()
    block["abar"] = entry(1.0, SRC)
    block["xi"] = entry(xi, SRC, low=xi_lo, high=xi_hi)
    block["tail"] = OrderedDict([("value", "exp"), ("source", SRC)])
    block["psi_a"] = entry(PSI_A, SRC)
    block["mu_h"] = entry(mu, SRC, low=mu, high=mu_hi)
    block["cc0"] = entry(cc, SRC, low=cc_lo * USD_PER_T_TO_TN_PER_GT, high=cc_hi * USD_PER_T_TO_TN_PER_GT)
    block["cc_inf"] = entry(cc, SRC)
    block["gcc"] = entry(0.0, SRC)
    block["cT0"] = entry(cT, SRC, low=cT_lo * USD_PER_T_TO_TN_PER_GT, high=cT_hi * USD_PER_T_TO_TN_PER_GT)
    block["cT_inf"] = entry(cT, SRC)
    block["gcT"] = entry(0.0, SRC)
    block["chi_T"] = entry(CHI_T[1], SRC, low=CHI_T[0], high=CHI_T[2])
    block["dW"] = entry(DW[1], SRC, low=DW[0], high=DW[2])
    set_params(cal, block)
    cal["states"]["W0"] = entry(W0, SRC, low=rec.rows[-1]["value"], high=W0)
    cal["cases"]["abar"] = [1.0, round(a_mid, 4)]
    cal["cases"]["xi_range"] = [xi_lo, xi_hi]
    cal["cases"]["abar_H_range"] = [a_lo, a_hi]
    save_calibration(cal)
    path = rec.write()
    print(f"c4: W_2015 = {W2015:.0f} Gt, mu_h = {mu:.4f} [{mu:.4f}, {mu_hi:.4f}], cc = {cc:.3f}, cT = {cT:.3f}, "
          f"a_obs = {a_obs:.3f}, xi = {xi:.2f} [{xi_lo:.2f}, {xi_hi:.2f}], KR = {KR:.2f}, W0 = {W0:.1f} -> {path}")


if __name__ == "__main__":
    main()
