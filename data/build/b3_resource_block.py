"""B3: the resource block the calibration reads.

Joins the six per-source interim files into data/interim/b3_resource_block.csv,
in the same long format (year, series, commodity, value, unit, source, method),
where `commodity` carries a material category for the aggregate rows.  It
produces, in order:

  1. real price indices, each rebased to 1900 = 100: Jacks's own Metals group
     (nine base metals) and the broader metal-ores set (those nine plus gold,
     silver, platinum, bauxite and iron ore), each unweighted and weighted by
     world production mass; and a mass-weighted aggregate over all twenty
     commodities for which a world production mass series exists.  Weights are
     documented below and emitted as rows so they can be inspected.
  2. fossil extraction mass by fuel, 1900-2020 (and to 2024 where the data run),
     from b3_gcb_fossil.py.
  3. cumulative extraction by commodity and by category since 1900.
  4. reserves by category at the latest year, in gigatonnes.
  5. the constructed S0 and X0 by category at 1900.
  6. an ultimately-recoverable-resource range, low / central / high, by category.

Three things it does NOT do, because the data do not support them and the plan
forbids a stand-in:
  * Biomass appears nowhere.  No source in this block measures it; it is block
    B1's.  Every category total is therefore partial and says so in `method`.
  * Metal reserves and metal world production are on a CONTAINED-METAL basis,
    while iron ore and bauxite are on a GROSS-ORE basis and the material-flow
    accounts that decision D1 rests on are gross mass throughout.  The two are
    not added; they are reported side by side, and the bridge between them is
    the ore grade, which is the evidence of b3_oregrades.py.
  * Construction minerals -- crushed stone, sand and gravel -- have no world
    production series in USGS Data Series 140 and no world reserve figure in the
    Mineral Commodity Summaries.  The non-metallic-minerals category is
    consequently a small fraction of the real thing.

S0 and X0.  The model's S is the known in-ground stock and X cumulative
discoveries, with X_t - S_t equal to cumulative extraction.  At the 1900 base
year of decision D2 that gives
    S0 = cumulative extraction 1900 to T  +  reserves at T
    X0 = cumulative extraction over all covered years  +  reserves at T
so that X0 - S0 is extraction before 1900, which this block covers for fossil
fuels (the Global Carbon Budget runs from 1750) and not for metals (Data Series
140 starts in 1900), where X0 therefore equals S0 and understates X0.  The
literal reading of the task brief -- cumulative extraction plus reserves less
extraction to date -- collapses to reserves alone; it is emitted as
`S0_literal_reading` beside the constructed value so the difference is visible.

Run from the repository root:  python data/build/b3_resource_block.py
"""

import os

import pandas as pd

INTERIM = os.path.join("data", "interim")
OUT = os.path.join(INTERIM, "b3_resource_block.csv")
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

BASE_YEAR = 1900
WEIGHT_WINDOW = (1900, 2015)  # the window the task fixes for the weights
# Vintage of the reserve estimate each category is matched to.
RESERVE_VINTAGE = {"fossil_fuels": 2005}
# Jacks's own "Metals" group, the nine base metals.
JACKS_METALS_GROUP = (
    "aluminum", "chromium", "copper", "lead", "manganese", "nickel", "steel",
    "tin", "zinc",
)

# Jacks price column -> (USGS DS140 world-production commodity or GCB fuel,
#                        category, basis)
# basis: "metal" contained metal, "gross" gross ore or gross weight, "fuel".
PRICE_TO_MASS = {
    "aluminum": ("ds140:aluminum", "metal_ores", "metal"),
    "chromium": ("ds140:chromium", "metal_ores", "metal"),
    "copper": ("ds140:copper", "metal_ores", "metal"),
    "lead": ("ds140:lead", "metal_ores", "metal"),
    "manganese": ("ds140:manganese", "metal_ores", "metal"),
    "nickel": ("ds140:nickel", "metal_ores", "metal"),
    "steel": ("ds140:iron_steel__pig_iron", "metal_ores", "metal"),
    "tin": ("ds140:tin", "metal_ores", "metal"),
    "zinc": ("ds140:zinc", "metal_ores", "metal"),
    "gold": ("ds140:gold", "metal_ores", "metal"),
    "silver": ("ds140:silver", "metal_ores", "metal"),
    "platinum": ("ds140:platinum__platinum_group_metals", "metal_ores", "metal"),
    "bauxite": ("ds140:bauxite_alumina__bauxite", "metal_ores", "gross"),
    "iron_ore": ("ds140:iron_ore", "metal_ores", "gross"),
    "phosphate": ("ds140:phosphate__phosphate_rock", "non_metallic_minerals",
                  "gross"),
    "potash": ("ds140:potash", "non_metallic_minerals", "gross"),
    "sulfur": ("ds140:sulfur", "non_metallic_minerals", "gross"),
    "coal": ("gcb:coal", "fossil_fuels", "fuel"),
    "natural_gas": ("gcb:gas", "fossil_fuels", "fuel"),
    "petroleum": ("gcb:oil", "fossil_fuels", "fuel"),
}
# Extraction series with no Jacks price, included in the cumulative totals only.
EXTRA_MASS = {
    "ds140:salt": ("non_metallic_minerals", "gross"),
    "ds140:gypsum": ("non_metallic_minerals", "gross"),
    "ds140:soda_ash": ("non_metallic_minerals", "gross"),
    "ds140:cobalt": ("metal_ores", "metal"),
    "ds140:molybdenum": ("metal_ores", "metal"),
    "ds140:tungsten": ("metal_ores", "metal"),
    "ds140:titanium_minerals__ilmenite_and_slag": ("metal_ores", "gross"),
}
# MCS reserve rows -> (category, basis, factor to gigatonnes).
# thousand t -> 1e-6 Gt; t -> 1e-9 Gt; million t -> 1e-3 Gt; kg -> 1e-12 Gt.
TO_GT = {
    "thousand_t": 1e-6, "t": 1e-9, "million_t": 1e-3, "kg": 1e-12,
}
RESERVE_CATEGORY = {
    "bauxite": ("metal_ores", "gross"),
    "chromium_ore": ("metal_ores", "gross"),
    "iron_ore_usable": ("metal_ores", "gross"),
    "titanium_ilmenite_rutile": ("metal_ores", "gross"),
    "cobalt": ("metal_ores", "metal"),
    "copper": ("metal_ores", "metal"),
    "gold": ("metal_ores", "metal"),
    "lead": ("metal_ores", "metal"),
    "lithium": ("metal_ores", "metal"),
    "manganese": ("metal_ores", "metal"),
    "molybdenum": ("metal_ores", "metal"),
    "nickel": ("metal_ores", "metal"),
    "platinum_group_metals": ("metal_ores", "metal"),
    "rare_earths": ("metal_ores", "metal"),
    "silver": ("metal_ores", "metal"),
    "tin": ("metal_ores", "metal"),
    "tungsten": ("metal_ores", "metal"),
    "vanadium": ("metal_ores", "metal"),
    "zinc": ("metal_ores", "metal"),
    "phosphate_rock": ("non_metallic_minerals", "gross"),
    "potash_ore": ("non_metallic_minerals", "gross"),
    "soda_ash_natural": ("non_metallic_minerals", "gross"),
}
# Reserve rows deliberately left out of the category totals to avoid double
# counting a commodity already present on another basis.
RESERVE_EXCLUDED = {"chromium_cr2o3", "iron_ore_iron_content", "potash"}
# Series that measure a refined or smelted product rather than extraction.  They
# are legitimate mass weights for the price of that product, and they are not
# extraction, so they are kept out of every cumulative-extraction total: bauxite
# and iron ore already stand for the same material at the mine.
NOT_EXTRACTION = {
    "ds140:aluminum", "ds140:iron_steel__pig_iron", "ds140:iron_steel__steel",
    "ds140:bauxite_alumina__alumina", "ds140:cement", "ds140:lime",
}


def gt_factor(unit):
    for prefix, factor in sorted(TO_GT.items(), key=lambda kv: -len(kv[0])):
        if unit.startswith(prefix + "_") or unit == prefix:
            return factor
    return None


def load():
    frames = {}
    for name in ("jacks", "usgs_ds140", "usgs_mcs", "gcb_fossil", "urr",
                 "exploration", "oregrades"):
        path = os.path.join(INTERIM, "b3_{}.csv".format(name))
        frames[name] = pd.read_csv(path)
    return frames


def mass_series(frames):
    """Annual world extraction mass in tonnes, keyed as in PRICE_TO_MASS."""
    ds140 = frames["usgs_ds140"]
    world = ds140[ds140["series"].isin(["world_production", "world_mine_production"])]
    out = {}
    for commodity, group in world.groupby("commodity"):
        out["ds140:" + commodity] = group.set_index("year")["value"].sort_index()
    gcb = frames["gcb_fossil"]
    fossil = gcb[gcb["series"] == "fossil_mass_central"]
    for fuel, group in fossil.groupby("commodity"):
        # the GCB rows are already in gigatonnes; the DS140 rows are in tonnes
        out["gcb:" + fuel] = group.set_index("year")["value"].sort_index() * 1e9
    return out


def price_indices(frames, masses):
    jacks = frames["jacks"]
    prices = jacks[jacks["series"].str.startswith("real_price_")]
    wide = prices.pivot_table(index="year", columns="commodity", values="value")
    lo, hi = WEIGHT_WINDOW
    rows = []

    weights = {}
    for name, (key, category, basis) in PRICE_TO_MASS.items():
        if name not in wide.columns or key not in masses:
            continue
        window = masses[key].loc[lo:hi]
        if window.empty:
            continue
        weights[name] = float(window.mean())
        rows.append(dict(
            year=hi, series="price_index_weight", commodity=name,
            value=weights[name], unit="t_per_year (mean {}-{}, basis {})".format(
                lo, hi, basis),
            source="usgs_ds140|gcb2025v15", method="derived"))

    def weighted(cols, series_name, use_weights):
        cols = [c for c in cols if c in wide.columns]
        if not cols:
            return
        sub = wide[cols].dropna(how="all")
        if use_weights:
            w = pd.Series({c: weights.get(c, 0.0) for c in cols})
        else:
            w = pd.Series({c: 1.0 for c in cols})
        w = w[w > 0]
        if w.empty:
            return
        sub = sub[w.index]
        num = (sub * w).sum(axis=1, min_count=1)
        den = sub.notna().mul(w, axis=1).sum(axis=1)
        index = num / den.replace(0.0, float("nan"))
        index = index / index.loc[BASE_YEAR] * 100.0
        for year, value in index.dropna().items():
            rows.append(dict(
                year=int(year), series=series_name, commodity="index",
                value=float(value), unit="index_{}=100".format(BASE_YEAR),
                source="jacks2019" + ("|usgs_ds140|gcb2025v15" if use_weights
                                      else ""),
                method="derived"))

    # Two readings of "metals".  The narrow one is Jacks's own Metals group, the
    # nine base metals; the broad one is everything this block classes as a metal
    # ore, which adds the three precious metals and the two ores, bauxite and
    # iron ore, that Jacks files under Minerals.
    jacks_metals = sorted(
        c for c in JACKS_METALS_GROUP if c in wide.columns
    )
    metal_ores = sorted(
        c for c, (_, cat, _) in PRICE_TO_MASS.items()
        if cat == "metal_ores" and c in wide.columns
    )
    weighted(jacks_metals, "price_index_jacks_metals_group_unweighted", False)
    weighted(jacks_metals, "price_index_jacks_metals_group_weighted", True)
    weighted(metal_ores, "price_index_metals_unweighted", False)
    weighted(metal_ores, "price_index_metals_production_weighted", True)
    weighted(sorted(weights), "price_index_mass_weighted_aggregate", True)
    return rows


def extraction(frames, masses):
    rows = []
    category_of = {k: v[1] for k, v in PRICE_TO_MASS.items()}
    keyed = {v[0]: (v[1], v[2]) for v in PRICE_TO_MASS.values()}
    keyed.update(EXTRA_MASS)
    cumulative = {}
    for key, (category, basis) in keyed.items():
        if key not in masses:
            continue
        series = masses[key].dropna()
        since = series.loc[BASE_YEAR:]
        if since.empty:
            continue
        name = key.split(":", 1)[1]
        if key in NOT_EXTRACTION:
            continue
        if key.startswith("gcb:"):
            for year, value in since.items():
                rows.append(dict(
                    year=int(year), series="fossil_extraction_mass",
                    commodity=name, value=float(value) / 1e9, unit="Gt",
                    source="gcb2025v15+ipcc2006_v2_ch1", method="derived"))
        cum = float(since.sum()) / 1e9
        rows.append(dict(
            year=int(since.index.max()), series="cumulative_extraction_since_1900",
            commodity=name, value=cum,
            unit="Gt ({} basis, {}-{})".format(basis, int(since.index.min()),
                                               int(since.index.max())),
            source="usgs_ds140" if key.startswith("ds140") else
            "gcb2025v15+ipcc2006_v2_ch1",
            method="derived"))
        cumulative.setdefault((category, basis), 0.0)
        cumulative[(category, basis)] += cum
        # total extraction over every covered year, for X0
        full = float(series.sum()) / 1e9
        cumulative.setdefault((category, basis, "full"), 0.0)
        cumulative[(category, basis, "full")] += full
        # S0 and X0 must cumulate extraction only up to the vintage of the
        # reserve estimate they are added to; the Global Energy Assessment's
        # fossil reserves are as of 2005, the Mineral Commodity Summaries' are
        # current.
        cutoff = RESERVE_VINTAGE.get(category, int(series.index.max()))
        cumulative.setdefault((category, basis, "to_vintage"), 0.0)
        cumulative[(category, basis, "to_vintage")] += (
            float(since.loc[:cutoff].sum()) / 1e9
        )
        cumulative.setdefault((category, basis, "full_to_vintage"), 0.0)
        cumulative[(category, basis, "full_to_vintage")] += (
            float(series.loc[:cutoff].sum()) / 1e9
        )
    for key, value in sorted(cumulative.items()):
        if len(key) == 3:
            continue
        category, basis = key
        rows.append(dict(
            year=2020, series="cumulative_extraction_since_1900_category",
            commodity=category, value=value,
            unit="Gt ({} basis)".format(basis),
            source="usgs_ds140|gcb2025v15", method="derived_partial_coverage"))
    return rows, cumulative


def reserves(frames):
    mcs = frames["usgs_mcs"]
    res = mcs[mcs["series"] == "reserves"]
    rows = []
    totals = {}
    for _, r in res.iterrows():
        if r["commodity"] in RESERVE_EXCLUDED:
            continue
        mapping = RESERVE_CATEGORY.get(r["commodity"])
        if mapping is None:
            continue
        category, basis = mapping
        factor = gt_factor(r["unit"])
        if factor is None:
            continue
        gt = float(r["value"]) * factor
        rows.append(dict(
            year=int(r["year"]), series="reserves_gt", commodity=r["commodity"],
            value=gt, unit="Gt ({} basis)".format(basis), source=r["source"],
            method="transcribed"))
        totals.setdefault((category, basis), 0.0)
        totals[(category, basis)] += gt
    # Fossil reserves come from the Global Energy Assessment, not from the MCS.
    urr = frames["urr"]
    fossil = urr[urr["unit"] == "Gt"]
    conventional = ["conventional_oil", "conventional_gas", "coal"]
    for bound in ("low", "high"):
        rows_b = fossil[fossil["series"] == "reserves_{}_mass".format(bound)]
        value = float(rows_b["value"].sum())
        conv = float(rows_b[rows_b["commodity"].isin(conventional)]["value"].sum())
        rows.append(dict(
            year=2005, series="reserves_gt_category_{}".format(bound),
            commodity="fossil_fuels", value=value, unit="Gt (fuel basis)",
            source="rogner2012_gea_ch7:table7.1_p431+ipcc2006_v2_ch1",
            method="derived"))
        rows.append(dict(
            year=2005, series="reserves_gt_category_{}".format(bound),
            commodity="fossil_fuels_conventional_and_coal", value=conv,
            unit="Gt (fuel basis; conventional oil and gas plus coal)",
            source="rogner2012_gea_ch7:table7.1_p431+ipcc2006_v2_ch1",
            method="derived"))
        totals[("fossil_fuels", "fuel", bound)] = value
    for key, value in sorted(totals.items()):
        if len(key) == 3:
            continue
        category, basis = key
        rows.append(dict(
            year=2025, series="reserves_gt_category", commodity=category,
            value=value, unit="Gt ({} basis)".format(basis),
            source="usgs_mcs2026", method="derived_partial_coverage"))
    return rows, totals


def stocks(cumulative, reserve_totals):
    """S0 and X0 at 1900, by category and basis."""
    rows = []
    keys = {(k[0], k[1]) for k in cumulative}
    for category, basis in sorted(keys):
        since = cumulative.get((category, basis, "to_vintage"))
        full = cumulative.get((category, basis, "full_to_vintage"))
        if since is None:
            continue
        if category == "fossil_fuels":
            reserve = reserve_totals.get((category, basis, "low"))
            reserve_hi = reserve_totals.get((category, basis, "high"))
            source = "rogner2012_gea_ch7+gcb2025v15"
        else:
            reserve = reserve_totals.get((category, basis))
            reserve_hi = reserve
            source = "usgs_mcs2026+usgs_ds140"
        if reserve is None:
            continue
        # Pre-1900 extraction is covered only for fossil fuels, where the Global
        # Carbon Budget runs from 1750; Data Series 140 starts in 1900, so for
        # metals and minerals X0 equals S0 and is a lower bound on X0.
        x_method = ("derived_partial_coverage" if category == "fossil_fuels"
                    else "derived_no_pre1900_coverage")
        for label, res in (("low", reserve), ("high", reserve_hi)):
            rows.append(dict(
                year=BASE_YEAR, series="S0_{}".format(label), commodity=category,
                value=since + res, unit="Gt ({} basis)".format(basis),
                source=source, method="derived_partial_coverage"))
            rows.append(dict(
                year=BASE_YEAR, series="X0_{}".format(label), commodity=category,
                value=full + res, unit="Gt ({} basis)".format(basis),
                source=source, method=x_method))
        rows.append(dict(
            year=BASE_YEAR, series="S0_literal_reading", commodity=category,
            value=reserve, unit="Gt ({} basis)".format(basis), source=source,
            method="derived_partial_coverage"))
        rows.append(dict(
            year=BASE_YEAR, series="X0_minus_S0_extraction_before_1900",
            commodity=category, value=full - since,
            unit="Gt ({} basis)".format(basis), source=source,
            method="derived_partial_coverage"))
    return rows


def urr_table(frames):
    """Low / central / high ultimately recoverable resource, by category."""
    urr = frames["urr"]
    gt = urr[urr["unit"] == "Gt"]

    conventional = ["conventional_oil", "conventional_gas", "coal"]

    def total(series, only=None):
        sub = gt[gt["series"] == series]
        if only is not None:
            sub = sub[sub["commodity"].isin(only)]
        return float(sub["value"].sum())

    hist = total("historical_production_to_2005_mass")
    res_lo, res_hi = total("reserves_low_mass"), total("reserves_high_mass")
    rsr_lo, rsr_hi = total("resources_low_mass"), total("resources_high_mass")
    occurrences = total("additional_occurrences_mass")
    citation = "rogner2012_gea_ch7:table7.1_p431+ipcc2006_v2_ch1"
    rows = [
        dict(year=2005, series="URR_low", commodity="fossil_fuels",
             value=hist + res_lo,
             unit="Gt (cumulative production to 2005 plus low reserves)",
             source=citation, method="derived"),
        dict(year=2005, series="URR_central", commodity="fossil_fuels",
             value=hist + 0.5 * (res_lo + res_hi) + 0.5 * (rsr_lo + rsr_hi),
             unit="Gt (cumulative production plus midpoint reserves and "
                  "resources)", source=citation, method="derived"),
        dict(year=2005, series="URR_high", commodity="fossil_fuels",
             value=hist + res_hi + rsr_hi,
             unit="Gt (cumulative production plus high reserves and resources; "
                  "additional occurrences excluded)",
             source=citation, method="derived"),
        dict(year=2005, series="URR_additional_occurrences",
             commodity="fossil_fuels", value=occurrences,
             unit="Gt (unconventional oil and gas only, not counted in URR_high)",
             source=citation, method="derived"),
    ]
    # The unconventional rows of Table 7.1 dominate every total above, and coal
    # resources dominate URR_high.  The same three bounds over conventional oil,
    # conventional gas and coal alone are emitted so that the driver is visible.
    hist_c = total("historical_production_to_2005_mass", conventional)
    res_lo_c = total("reserves_low_mass", conventional)
    res_hi_c = total("reserves_high_mass", conventional)
    rsr_lo_c = total("resources_low_mass", conventional)
    rsr_hi_c = total("resources_high_mass", conventional)
    rows += [
        dict(year=2005, series="URR_low",
             commodity="fossil_fuels_conventional_and_coal",
             value=hist_c + res_lo_c,
             unit="Gt (cumulative production to 2005 plus low reserves)",
             source=citation, method="derived"),
        dict(year=2005, series="URR_central",
             commodity="fossil_fuels_conventional_and_coal",
             value=hist_c + 0.5 * (res_lo_c + res_hi_c)
             + 0.5 * (rsr_lo_c + rsr_hi_c),
             unit="Gt (cumulative production plus midpoint reserves and "
                  "resources)", source=citation, method="derived"),
        dict(year=2005, series="URR_high",
             commodity="fossil_fuels_conventional_and_coal",
             value=hist_c + res_hi_c + rsr_hi_c,
             unit="Gt (cumulative production plus high reserves and resources)",
             source=citation, method="derived"),
    ]
    # Metals: the USGS assessment figures the MCS reports, contained metal.
    mcs = frames["usgs_mcs"]
    ident = mcs[mcs["series"] == "identified_resources"]
    undisc = mcs[mcs["series"] == "undiscovered_resources"]
    metal_commodities = {
        "copper": "t", "nickel": "t", "zinc": "t", "lead": "t",
        "molybdenum": "t", "lithium": "t", "vanadium": "t",
    }
    ident_total = 0.0
    undisc_total = 0.0
    for commodity, unit in metal_commodities.items():
        i = ident[ident["commodity"] == commodity]["value"].sum() * 1e-9
        u = undisc[undisc["commodity"] == commodity]["value"].sum() * 1e-9
        if i:
            rows.append(dict(
                year=2025, series="identified_resources_gt", commodity=commodity,
                value=float(i), unit="Gt (contained metal)",
                source=str(ident[ident["commodity"] == commodity]["source"]
                           .iloc[0]), method="transcribed"))
        if u:
            rows.append(dict(
                year=2025, series="undiscovered_resources_gt",
                commodity=commodity, value=float(u), unit="Gt (contained metal)",
                source=str(undisc[undisc["commodity"] == commodity]["source"]
                           .iloc[0]), method="transcribed"))
        ident_total += float(i)
        undisc_total += float(u)
    rows += [
        dict(year=2025, series="URR_low", commodity="metal_ores_contained_metal",
             value=ident_total,
             unit="Gt (identified resources of the seven metals the MCS reports "
                  "a world figure for)",
             source="usgs_mcs2026", method="derived_partial_coverage"),
        dict(year=2025, series="URR_central",
             commodity="metal_ores_contained_metal",
             value=ident_total + 0.5 * undisc_total,
             unit="Gt (identified plus half the undiscovered estimate, which "
                  "exists for copper only)",
             source="usgs_mcs2026", method="derived_partial_coverage"),
        dict(year=2025, series="URR_high",
             commodity="metal_ores_contained_metal",
             value=ident_total + undisc_total,
             unit="Gt (identified plus undiscovered)",
             source="usgs_mcs2026", method="derived_partial_coverage"),
    ]
    # Gross-ore metals whose resource figure the MCS states directly.
    for commodity, low, high, page in (
        ("iron_ore", 900.0, 900.0, 109), ("bauxite", 55.0, 75.0, 51),
        ("chromium_ore", 12.0, 12.0, 67), ("titanium_minerals", 2.0, 2.0, 199),
    ):
        rows.append(dict(
            year=2025, series="URR_low", commodity=commodity + "_gross_ore",
            value=low, unit="Gt (world resources as stated)",
            source="usgs_mcs2026:p{}".format(page), method="transcribed"))
        rows.append(dict(
            year=2025, series="URR_high", commodity=commodity + "_gross_ore",
            value=high, unit="Gt (world resources as stated)",
            source="usgs_mcs2026:p{}".format(page), method="transcribed"))
    return rows


def main():
    frames = load()
    masses = mass_series(frames)
    rows = price_indices(frames, masses)
    extraction_rows, cumulative = extraction(frames, masses)
    rows += extraction_rows
    reserve_rows, reserve_totals = reserves(frames)
    rows += reserve_rows
    rows += stocks(cumulative, reserve_totals)
    rows += urr_table(frames)
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["series", "commodity", "year"]
    )
    out.to_csv(OUT, index=False)
    print(
        "b3_resource_block: {} rows, {} series; price indices {}-{}; fossil mass "
        "by fuel {}-{}; S0/X0 and URR by category -> {}".format(
            len(out),
            out["series"].nunique(),
            int(out[out["series"].str.startswith("price_index_m")]["year"].min()),
            int(out[out["series"].str.startswith("price_index_m")]["year"].max()),
            int(out[out["series"] == "fossil_extraction_mass"]["year"].min()),
            int(out[out["series"] == "fossil_extraction_mass"]["year"].max()),
            OUT,
        )
    )


if __name__ == "__main__":
    main()
