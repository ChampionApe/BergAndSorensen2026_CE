"""B4: the recovery-cost gradient evidence for xi -> data/interim/b4_xi_literature.csv.

xi is the rate at which the yield approaches its ceiling in a(x) = abar(1 - exp(-xi x)),
with x recycling capital per treated tonne.  Identifying it needs cost or energy per
tonne recovered *as a function of the recovery rate achieved*.  No public study found
states that function for a single stream.  What exists is assembled here: every
quantitative relation between recovery and its cost or energy that a downloadable
source states in words or in a numbered table.  Each row names the source and the page.

The table is deliberately heterogeneous - energy ratios, capital per annual tonne of
added recovery, cost per tonne of output at successive depths of sorting, break-even
recovery rates - because that heterogeneity is the finding.  What is *not* here, and
why, is recorded in notes/data/waste_recycling.md and in the `gap_*` rows below.

Run from the repository root:  python data/build/b4_xi_literature.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b4_xi_literature.csv")

CULLEN = ("Cullen 2017, J. Ind. Ecol. 21(3):483-486, table 1 "
          "(accepted version, Cambridge Apollo)")
RECK = "Reck and Graedel 2012, Science 337:690-695"
EPA = ("US EPA 2024, An Assessment of the U.S. Recycling System: Financial Estimates "
       "to Improve Recycling Infrastructure")
VANCAMP = "Van Camp et al. 2024, Waste Management 189:300-313"
LI = "Li, Ward, Lin and Tukker 2024, Nature Communications 15:7527"
FK = "Fullerton and Kinnaman 2024, NBER working paper 32981"
GWMO = "UNEP 2024, Global Waste Management Outlook 2024, annex 3, p. 61"
IP = "Ip, Testa, Raymond, Graves and Gutowski 2018, Resour. Conserv. Recycl. 131:192-205"

# Cullen 2017 table 1.  alpha = recovered EOL material / total material demand,
# beta = 1 - (energy to recover / energy for primary production), CI = alpha*beta.
# The table's own arithmetic reproduces alpha, beta and CI from the mass and energy
# rows to the printed precision, which is how it was checked on transcription.
CULLEN_T1 = {
    #            recovered  demand   E_recover  E_primary  alpha  beta   CI
    "steel":     (298.0,    1500.0,  6.7,       21.7,      0.20,  0.69,  0.14),
    "concrete":  (660.0,    32800.0, 3.4,       3.4,       0.02,  0.00,  0.00),
    "plastic":   (28.0,     299.0,   9.6,       38.4,      0.09,  0.75,  0.07),
    "paper":     (156.0,    408.0,   23.4,      26.2,      0.38,  0.11,  0.04),
    "aluminium": (11.0,     54.0,    7.6,       174.0,     0.21,  0.96,  0.20),
}
CULLEN_FIELDS = [
    ("recovered_eol_material", "Mt_per_year"),
    ("total_material_demand", "Mt_per_year"),
    ("energy_to_recover_material", "MJ_per_kg"),
    ("energy_for_primary_production", "MJ_per_kg"),
    ("cullen_alpha_quantity_circularity", "ratio"),
    ("cullen_beta_quality_circularity", "ratio"),
    ("cullen_circularity_index", "ratio"),
]

# (series, material, value, unit, source, method)
ROWS = [
    # --- energy ratio between secondary and primary production -----------------
    ("energy_saving_factor_recycling_vs_mine_low", "metals", 10.0, "ratio", RECK + ", p. 691",
     "transcribed"),
    ("energy_saving_factor_recycling_vs_mine_high", "metals", 20.0, "ratio", RECK + ", p. 691",
     "transcribed"),
    ("sorting_electricity_per_tonne_recycled", "MSW", 39.0, "kWh_per_tonne",
     GWMO, "transcribed"),
    ("sorting_transport_per_tonne_recycled", "MSW", 50.0, "tonne_km_per_tonne",
     GWMO, "transcribed"),

    # --- capital outlay against an achieved rise in the recovery rate ----------
    # Two EPA estimates with different scopes.  They are NOT nested increments of one
    # margin (the larger covers organics as well as packaging), so no difference
    # between them is taken here.
    ("epa_packaging_investment_low", "US_residential_packaging", 22.0e9, "USD",
     EPA + ", section 2.1", "transcribed"),
    ("epa_packaging_investment_high", "US_residential_packaging", 28.0e9, "USD",
     EPA + ", section 2.1", "transcribed"),
    ("epa_packaging_added_recovery_low", "US_residential_packaging", 38.0e6,
     "tonnes_per_year", EPA + ", section 2.1", "transcribed"),
    ("epa_packaging_added_recovery_high", "US_residential_packaging", 45.0e6,
     "tonnes_per_year", EPA + ", section 2.1", "transcribed"),
    ("epa_packaging_rate_from", "US_residential_packaging", 32.0, "percent",
     EPA + ", section 2.1", "transcribed"),
    ("epa_packaging_rate_to_low", "US_residential_packaging", 45.0, "percent",
     EPA + ", section 2.1", "transcribed"),
    ("epa_packaging_rate_to_high", "US_residential_packaging", 47.0, "percent",
     EPA + ", section 2.1", "transcribed"),
    ("epa_all_investment_low", "US_residential_packaging_and_organics", 36.0e9, "USD",
     EPA + ", executive summary, p. ES-2", "transcribed"),
    ("epa_all_investment_high", "US_residential_packaging_and_organics", 43.0e9, "USD",
     EPA + ", executive summary, p. ES-2", "transcribed"),
    ("epa_all_added_recovery_low", "US_residential_packaging_and_organics", 82.0e6,
     "tonnes_per_year", EPA + ", executive summary, p. ES-2", "transcribed"),
    ("epa_all_added_recovery_high", "US_residential_packaging_and_organics", 89.0e6,
     "tonnes_per_year", EPA + ", executive summary, p. ES-2", "transcribed"),
    ("epa_all_rate_from", "US_residential_packaging_and_organics", 32.0, "percent",
     EPA + ", executive summary, p. ES-2", "transcribed"),
    ("epa_all_rate_to", "US_residential_packaging_and_organics", 61.0, "percent",
     EPA + ", executive summary, p. ES-2", "transcribed"),
    ("us_average_landfill_tipping_fee", "US_MSW", 53.72, "USD_per_ton",
     EPA + ", section 5", "transcribed"),
    ("us_regional_landfill_tipping_fee_low", "US_MSW_South_Central", 39.66,
     "USD_per_ton", EPA + ", section 5", "transcribed"),
    ("us_regional_landfill_tipping_fee_high", "US_MSW_Northeast", 72.03,
     "USD_per_ton", EPA + ", section 5", "transcribed"),

    # --- cost per tonne at successive depths of sorting -------------------------
    ("cost_initial_sorting_low", "plastics_flexibles", 110.08, "EUR_per_tonne_output",
     VANCAMP + ", abstract and section 4", "transcribed"),
    ("cost_initial_sorting_high", "plastics_flexibles", 122.53, "EUR_per_tonne_output",
     VANCAMP + ", abstract and section 4", "transcribed"),
    ("cost_additional_sorting_and_improved_recycling_low", "plastics_rPE_flex", 566.26,
     "EUR_per_tonne_output", VANCAMP + ", abstract and section 4", "transcribed"),
    ("cost_additional_sorting_and_improved_recycling_high", "plastics_rPP_film", 735.47,
     "EUR_per_tonne_output", VANCAMP + ", abstract and section 4", "transcribed"),
    ("cost_reduction_from_rationalisation_low", "plastics_flexibles", 15.0, "percent",
     VANCAMP + ", abstract", "transcribed"),
    ("cost_reduction_from_rationalisation_high", "plastics_flexibles", 26.0, "percent",
     VANCAMP + ", abstract", "transcribed"),

    # --- break-even recovery rates ---------------------------------------------
    ("required_recycling_rate_to_break_even_mean", "imported_plastic_waste", 63.0,
     "percent", LI + ", abstract and results", "transcribed"),
    ("observed_domestic_recycling_rate_mean", "imported_plastic_waste", 23.0,
     "percent", LI + ", abstract and results", "transcribed"),
    ("required_recycling_rate_to_break_even_PVC", "plastic_PVC", 83.0, "percent",
     LI + ", results", "transcribed"),
    ("labour_cost_per_kg_germany", "plastic_waste", 0.26, "USD_per_kg", LI + ", results",
     "transcribed"),
    ("labour_cost_per_kg_thailand", "plastic_waste", 0.052, "USD_per_kg",
     LI + ", results", "transcribed"),

    # --- plateau and ceiling evidence -------------------------------------------
    ("times_a_unit_of_metal_is_reused_low", "iron_copper_nickel", 2.0, "count",
     RECK + ", p. 692", "transcribed"),
    ("times_a_unit_of_metal_is_reused_high", "iron_copper_nickel", 3.0, "count",
     RECK + ", p. 692", "transcribed"),
    ("eolrr_best_attainable", "platinum_group_metals", 60.0, "percent",
     RECK + ", p. 691", "transcribed"),
    ("eolrr_nickel_life_cycle_efficiency", "nickel", 52.0, "percent",
     RECK + ", p. 692, figure 2B caption", "transcribed_figure_caption"),
]

# Qualitative findings that carry no number but decide how the numbers are read.
QUALITATIVE = [
    ("plateau_of_aggregate_recycling_rates", FK + ", abstract",
     "OECD aggregate recycling rates have plateaued in recent decades"),
    ("economies_of_scale_in_sorting", FK + ", section on heterogeneity",
     "capital-intensive sense-and-sort methods reach a lower cost per additional "
     "tonne recycled but require a high fixed outlay, so unit cost falls with scale "
     "before it rises with the rate"),
    ("recovery_grade_trade_off", IP + ", section 4",
     "an MRF network-flow model in which profit rises with the recovery rate but not "
     "with grade beyond the concentration requirement; the cost-against-recovery "
     "results are shown only in figures 5 and 6 and are therefore not transcribed"),
    ("mass_retention_raises_unit_cost", VANCAMP + ", section 4.1",
     "lower mass retention leaves less output to bear the same incurred cost and adds "
     "a disposal fee, so the cost per tonne of product rises as yield falls"),
    ("quality_ceiling_is_material_specific", CULLEN,
     "trace copper in scrap steel, fibre shortening in paper, silicon in aluminium and "
     "the aggregate fraction limit in concrete each cap the share of a stream that can "
     "re-enter its original use"),
]

# What was looked for and not found, or found but not obtainable.
GAPS = [
    ("gap_no_explicit_cost_function_of_recovery_rate",
     "No public study found gives cost or energy per tonne recovered as an explicit "
     "function of the recovery rate achieved for a single material stream. The "
     "assembled evidence is either a two-point ladder (initial versus deep sorting), "
     "a break-even rate, or an aggregate capital outlay for a stated rise in a "
     "national rate."),
    ("gap_mrf_cost_curve_in_figures_only",
     "Ip et al. 2018 models exactly the required object but reports the cost against "
     "recovery and the sensitivity to separation efficiency in figures 5 and 6 only; "
     "reading a figure is not permitted here."),
    ("manual_kinnaman_shinkuma_yamamoto_2014",
     "MANUAL: Kinnaman, Shinkuma and Yamamoto (2014), The socially optimal recycling "
     "rate: evidence from Japan, J. Environ. Econ. Manage. 68(1):54-70, "
     "doi 10.1016/j.jeem.2014.01.004. Estimates average social cost of municipal waste "
     "management as a function of the recycling rate, which is the single closest "
     "published object to the treatment-cost gradient. Paywalled at Elsevier."),
    ("manual_graedel_et_al_2011_jie",
     "MANUAL: Graedel et al. (2011), What do we know about metal recycling rates?, "
     "J. Ind. Ecol. 15(3):355-366, doi 10.1111/j.1530-9290.2011.00342.x. Paywalled at "
     "Wiley; the USGS repository copy returns 403. Its content is the journal version "
     "of UNEP IRP (2011), which is downloaded, so nothing is lost but the citation."),
]


def main():
    rows = []
    for material, vals in CULLEN_T1.items():
        for (name, unit), v in zip(CULLEN_FIELDS, vals):
            rows.append(dict(year=2017, series=name, region_or_material=material,
                             value=v, unit=unit, source=CULLEN, method="transcribed"))
    for series, material, value, unit, source, method in ROWS:
        rows.append(dict(year=None, series=series, region_or_material=material,
                         value=value, unit=unit, source=source, method=method))
    for series, source, text in QUALITATIVE:
        rows.append(dict(year=None, series=series, region_or_material="n/a", value=None,
                         unit=text, source=source, method="qualitative"))
    for series, text in GAPS:
        rows.append(dict(year=None, series=series, region_or_material="n/a", value=None,
                         unit=text, source="B4 literature search, 2026-09-17",
                         method="not_found"))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print("b4_xi_literature: %d rows -> %s (%d quantitative, %d qualitative, %d gaps)"
          % (len(out), OUT, out.value.notna().sum(),
             (out.method == "qualitative").sum(), (out.method == "not_found").sum()))


if __name__ == "__main__":
    main()
