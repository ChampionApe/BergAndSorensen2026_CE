"""B4: the waste-handling and recycling block -> data/interim/b4_waste_block.csv.

Joins the six per-source files into the one table phase C reads.  Five parts:

  1. global treatment shares - collected, treated, openly dumped or burned - with the
     year and the source of each, from Kaza et al. (2018) and UNEP (2024).  The two
     disagree and both are kept; the discrepancy is the finding, not an error.
  2. unit costs of collection and of disposal or treatment by income group, US dollars
     per tonne.  The price base is carried inside `unit`, because neither source states
     one and pretending otherwise would be the worse error.
  3. a cross-section of the treated share against unit cost.  Two of them: the
     four-point income-group ladder, which is the cleanest, and the country-year panel
     from OECD treatment shares against Eurostat waste-management expenditure, which is
     wide but whose numerator covers all waste, not municipal waste alone.
  4. end-of-life recycling rates by metal, and the mass-weighted aggregates over them,
     weighted by USGS world mine production on a contained-metal basis.
  5. the recovery-cost gradient table for xi, carried through unchanged.

Run from the repository root:  python data/build/b4_waste_block.py
Depends on the six b4_*.py scripts having been run, and reads data/interim/b3_usgs_mcs.csv
for the production weights; if that file is absent the metal aggregates are written with
an empty value and a method that says the weights await B3.
"""

import os

import pandas as pd

INTERIM = os.path.join("data", "interim")
OUT = os.path.join(INTERIM, "b4_waste_block.csv")
COLS = ["year", "series", "region_or_material", "value", "unit", "source", "method"]

# UNEP IRP metal symbol -> the commodity name B3 uses in b3_usgs_mcs.csv, for metals
# whose USGS world-production row is on a contained-metal basis.  Bauxite and
# ilmenite/rutile are gross weight of ore, not contained aluminium or titanium, so
# aluminium and titanium are deliberately absent: converting ore to metal here would
# be a number from nowhere.
WEIGHT_MAP = {
    "Fe": ("iron_ore_iron_content", 1e3), "Cr": ("chromium", 1e3),
    "Cu": ("copper", 1e3), "Mn": ("manganese", 1e3), "Zn": ("zinc", 1e3),
    "Pb": ("lead", 1e3), "Ni": ("nickel", 1.0), "Sn": ("tin", 1.0),
    "Mo": ("molybdenum", 1.0), "Co": ("cobalt", 1.0), "V": ("vanadium", 1.0),
    "W": ("tungsten", 1.0), "Li": ("lithium", 1.0), "Ag": ("silver", 1.0),
    "Au": ("gold", 1.0),
}
NO_WEIGHT_NOTE = ("aluminium and titanium are excluded: the USGS world-production rows "
                  "for bauxite and for ilmenite-rutile are gross weight of ore, not "
                  "contained metal")


def read(name):
    p = os.path.join(INTERIM, name)
    return pd.read_csv(p) if os.path.exists(p) else None


def take(df, series, region=None, rename=None):
    """Rows of `df` with this series (and region), renamed, ready to concatenate."""
    s = df[df.series == series]
    if region is not None:
        s = s[s.region_or_material == region]
    s = s.copy()
    if rename:
        s["series"] = rename
    return s[COLS]


def part_shares(waw, gwmo):
    out = []
    # Kaza et al. 2018: the prose shares, restated under the block's names.
    for src_series, name in [
            ("treatment_share_open_dump", "openly_dumped_or_burned_share"),
            ("treatment_share_recycling_and_composting", "recovered_share"),
            ("treatment_share_incineration", "incinerated_share"),
            ("treatment_share_landfill_any", "landfilled_share")]:
        out.append(take(waw, src_series, "World", "global_" + name))
    # Treated, on the model's reading: everything that is not openly dumped or burned.
    dumped = waw[(waw.series == "treatment_share_open_dump") &
                 (waw.region_or_material == "World") &
                 (waw.method == "transcribed")].value.iloc[0]
    out.append(pd.DataFrame([dict(
        year=2016, series="global_treated_share", region_or_material="World",
        value=100.0 - dumped, unit="percent_of_MSW",
        source="Kaza et al. 2018, What a Waste 2.0, p. 5",
        method="computed_as_100_minus_open_dump")]))
    out.append(take(waw, "collection_coverage_population_weighted", "World",
                    "global_collected_share_population_weighted"))
    out.append(take(waw, "msw_generated", "World", "global_msw_generated"))

    # UNEP 2024: uncontrolled is dumping and open burning, at generation or at the
    # final destination, so its complement is the treated share on the same reading.
    out.append(take(gwmo, "uncontrolled_share", "World",
                    "global_openly_dumped_or_burned_share"))
    unc = gwmo[(gwmo.series == "uncontrolled_share") &
               (gwmo.year == 2020)].value.iloc[0]
    out.append(pd.DataFrame([dict(
        year=2020, series="global_treated_share", region_or_material="World",
        value=100.0 - unc, unit="percent_of_MSW",
        source="UNEP 2024, Global Waste Management Outlook 2024, p. 21",
        method="computed_as_100_minus_uncontrolled")]))
    out.append(take(gwmo, "msw_collection_rate", "World", "global_collected_share"))
    out.append(take(gwmo, "msw_generated", "World", "global_msw_generated"))
    return out


def part_costs(waw, gwmo):
    out = []
    base = "_price_base_not_stated"
    for df, tag, note in ((waw, "kaza2018", "report published 2018, data year 2016"),
                          (gwmo, "unep2024", "report published 2024, table sourced to "
                                             "Kaza et al. 2018")):
        s = df[df.series.str.startswith("unit_cost_")].copy()
        s = s[s.unit == "current_USD_per_tonne"]
        s["series"] = s.series + "__" + tag
        s["unit"] = "current_USD_per_tonne" + base + " (" + note + ")"
        out.append(s[COLS])
    return out


def part_cross_section(waw, gwmo, oecd, euro):
    """Treated share against unit cost, two ways."""
    out = []

    # (a) the income-group ladder.  Treated share from the Kaza et al. prose shares by
    # income group (100 less open dumping); collection cost from the UNEP table's
    # "Reported" column, which is a point rather than a range.
    dump = {r.region_or_material: r.value for _, r in waw[
        (waw.series == "treatment_share_open_dump") &
        (waw.method == "transcribed") &
        (waw.region_or_material.isin(["LIC", "HIC"]))].iterrows()}
    cost = {r.region_or_material: r.value for _, r in gwmo[
        gwmo.series == "unit_cost_collection_reported"].iterrows()}
    for grp in ["LIC", "LMC", "UMC", "HIC"]:
        if grp in cost:
            out.append(pd.DataFrame([dict(
                year=2020, series="xsection_income_group_collection_cost",
                region_or_material=grp, value=cost[grp],
                unit="current_USD_per_tonne",
                source="UNEP 2024, Global Waste Management Outlook 2024, table 2C.1",
                method="transcribed_table")]))
        if grp in dump:
            out.append(pd.DataFrame([dict(
                year=2016, series="xsection_income_group_treated_share",
                region_or_material=grp, value=100.0 - dump[grp],
                unit="percent_of_MSW",
                source="Kaza et al. 2018, What a Waste 2.0, p. 5",
                method="computed_as_100_minus_open_dump")]))
    # The prose gives open dumping by income group for LIC and HIC only, so the ladder
    # is completed from the MSW-weighted shares this pipeline computes from the open
    # country-level dataset.  Both versions are kept, under different series names.
    for _, r in waw[(waw.series == "treatment_share_open_dump_mswweighted") &
                    (waw.region_or_material != "World")].iterrows():
        out.append(pd.DataFrame([dict(
            year=2016, series="xsection_income_group_treated_share_mswweighted",
            region_or_material=r.region_or_material, value=100.0 - r.value,
            unit="percent_of_MSW", source=r.source,
            method="computed_as_100_minus_open_dump")]))

    # The upper ends of the collection cost range, which exist for all four groups.
    for grp in ["LIC", "LMC", "UMC", "HIC"]:
        for end in ["low", "high"]:
            r = waw[(waw.series == "unit_cost_collection_and_transfer_%s" % end) &
                    (waw.region_or_material == grp)]
            if len(r):
                out.append(pd.DataFrame([dict(
                    year=2018,
                    series="xsection_income_group_collection_cost_%s" % end,
                    region_or_material=grp, value=float(r.value.iloc[0]),
                    unit="current_USD_per_tonne",
                    source="Kaza et al. 2018, What a Waste 2.0, table 5.2, p. 104",
                    method="transcribed")]))

    # (b) the country-year panel.  OECD treated share, Eurostat expenditure per tonne.
    # Treated shares above 105 per cent are dropped: a few countries report treating
    # more than they generate, which the sources do not explain.
    if oecd is None or euro is None:
        return out
    t = oecd[oecd.series == "treated_share_of_generated"][
        ["year", "region_or_material", "value"]].rename(columns={"value": "share"})
    t = t[t.share.between(0.0, 105.0)]
    c = euro[euro.series == "waste_expenditure_per_tonne_msw"][
        ["year", "region_or_material", "value"]].rename(columns={"value": "cost"})
    # OECD uses ISO3, Eurostat ISO2; join on the country-year pairs that match after
    # mapping the Eurostat code through the OECD reference-area list is not possible
    # here, so the panel is built on Eurostat's own treated share instead, keeping the
    # two columns on one code system.
    te = euro[euro.series == "treated_share_of_generated"][
        ["year", "region_or_material", "value"]].rename(columns={"value": "share"})
    te = te[te.share.between(0.0, 105.0)]
    j = te.merge(c, on=["year", "region_or_material"])
    for _, r in j.iterrows():
        key = "%s_%d" % (r.region_or_material, int(r.year))
        out.append(pd.DataFrame([
            dict(year=int(r.year), series="xsection_country_treated_share",
                 region_or_material=key, value=float(r.share),
                 unit="percent_of_generated_MSW", source="Eurostat env_wasmun",
                 method="computed"),
            dict(year=int(r.year), series="xsection_country_unit_cost",
                 region_or_material=key, value=float(r.cost),
                 unit="current_EUR_per_tonne_MSW_generated_numerator_covers_all_waste",
                 source="Eurostat env_epea_neep CEP0401 and env_wasmun",
                 method="computed")]))
    # The OECD panel is kept as the treated share alone, for the countries Eurostat
    # does not cover; it has no cost column.
    for _, r in t.iterrows():
        out.append(pd.DataFrame([dict(
            year=int(r.year), series="xsection_country_treated_share_oecd_no_cost",
            region_or_material="%s_%d" % (r.region_or_material, int(r.year)),
            value=float(r.share), unit="percent_of_generated_MSW",
            source="OECD Environment Statistics, DSD_MUNW@DF_MUNW",
            method="computed")]))
    return out


def part_metals(irp, mcs):
    out = []
    eol = irp[irp.series == "eolrr"].copy()
    # Estimates that are points or endpoints of a printed range; the "<1" and ">50"
    # bounds are kept out of the aggregate and reported separately.
    usable = eol[eol.method.isin(["transcribed_table_point", "transcribed_table_range_low",
                                  "transcribed_table_range_high"])]
    g = usable.groupby("region_or_material").value.agg(["min", "max", "count"])
    g["mid"] = 0.5 * (g["min"] + g["max"])
    for metal, r in g.iterrows():
        for stat in ["min", "mid", "max"]:
            out.append(pd.DataFrame([dict(
                year=2011, series="eolrr_%s" % stat, region_or_material=metal,
                value=float(r[stat]), unit="percent",
                source="UNEP IRP 2011, Recycling Rates of Metals, appendix tables",
                method="computed_from_%d_transcribed_estimates" % int(r["count"]))]))

    if mcs is None:
        for stat in ["min", "mid", "max"]:
            out.append(pd.DataFrame([dict(
                year=2024, series="eolrr_massweighted_%s" % stat,
                region_or_material="metals_only", value=None, unit="percent",
                source="UNEP IRP 2011 with USGS Mineral Commodity Summaries weights",
                method="awaiting_B3_world_production_weights")]))
        return out

    prod = mcs[(mcs.series == "world_mine_production") & (mcs.year == 2024)]
    prod = {r.commodity: r.value for _, r in prod.iterrows()}
    weights, missing = {}, []
    for metal, (commodity, scale) in WEIGHT_MAP.items():
        if commodity in prod and metal in g.index:
            weights[metal] = prod[commodity] * scale
        else:
            missing.append(metal)
    tot = sum(weights.values())
    for metal, w in sorted(weights.items(), key=lambda kv: -kv[1]):
        out.append(pd.DataFrame([dict(
            year=2024, series="world_mine_production_weight",
            region_or_material=metal, value=w, unit="tonnes_contained_metal",
            source="USGS Mineral Commodity Summaries 2026 via data/interim/b3_usgs_mcs.csv",
            method="transcribed")]))
        out.append(pd.DataFrame([dict(
            year=2024, series="world_mine_production_share",
            region_or_material=metal, value=100.0 * w / tot, unit="percent",
            source="USGS Mineral Commodity Summaries 2026 via data/interim/b3_usgs_mcs.csv",
            method="computed")]))
    for stat in ["min", "mid", "max"]:
        agg = sum(weights[m] * g.loc[m, stat] for m in weights) / tot
        out.append(pd.DataFrame([dict(
            year=2024, series="eolrr_massweighted_%s" % stat,
            region_or_material="metals_only", value=float(agg), unit="percent",
            source=("UNEP IRP 2011 appendix tables, weighted by USGS Mineral Commodity "
                    "Summaries 2026 world mine production 2024"),
            method="computed_over_%d_metals; %s" % (len(weights), NO_WEIGHT_NOTE))]))
    return out


def part_gradient(xi):
    s = xi[xi.method != "not_found"].copy()
    s["series"] = "gradient__" + s.series
    return [s[COLS]]


def main():
    waw = read("b4_whatawaste2.csv")
    gwmo = read("b4_unep_gwmo2024.csv")
    irp = read("b4_unep_irp2011.csv")
    oecd = read("b4_oecd_waste.csv")
    euro = read("b4_eurostat_waste.csv")
    cgr = read("b4_circularity_gap.csv")
    xi = read("b4_xi_literature.csv")
    mcs = read("b3_usgs_mcs.csv")
    for name, df in [("b4_whatawaste2", waw), ("b4_unep_gwmo2024", gwmo),
                     ("b4_unep_irp2011", irp), ("b4_circularity_gap", cgr),
                     ("b4_xi_literature", xi)]:
        if df is None:
            raise SystemExit("missing %s.csv; run data/build/%s.py first" % (name, name))

    parts = []
    parts += part_shares(waw, gwmo)
    parts += part_costs(waw, gwmo)
    parts += part_cross_section(waw, gwmo, oecd, euro)
    parts += part_metals(irp, mcs)
    parts += part_gradient(xi)
    # The aggregate circularity target, carried whole with its caveat in the unit.
    cm = cgr[cgr.series.str.startswith("circularity_metric")].copy()
    cm["series"] = "aggregate__" + cm.series
    cm["unit"] = cm.unit + "_denominator_includes_fossil_fuels_burnt_for_energy"
    parts.append(cm[COLS])

    out = pd.concat(parts, ignore_index=True)[COLS]
    out.to_csv(OUT, index=False)
    agg = out[out.series == "eolrr_massweighted_mid"]
    got = "n/a (awaiting B3)" if agg.empty or pd.isna(agg.value.iloc[0]) \
        else "%.1f%%" % agg.value.iloc[0]
    print("b4_waste_block: %d rows -> %s (metals-only mass-weighted EOL-RR %s)"
          % (len(out), OUT, got))


if __name__ == "__main__":
    main()
