"""The B1 core material block: the model's material series, global, annual.

Joins the four per-source interim files into one long-format table on the
model's own names, keeping every source that measures a series rather than
choosing between them, and writes two diagnostic files beside it: the pairwise
discrepancies above five percent, and the ledger residuals.

Series written, by the four material categories and in total where the source
allows: `N` used extraction, `RR` secondary input, `R = N + RR` material
input, `W` waste generation (all outflows from use, before recovery), `DPO`
emissions and residues reaching the environment, `MK` the in-use stock, and
`Wcum_disposal`, the cumulated solid and liquid residues that decision D3 of
notes/plan_calibration_experiments.md turns into the waste stock. Unused
extraction is not carried by any source obtained; see the report in
notes/data/material_flows.md.

Run from the repository root:  python data/build/b1_material_block.py
"""

import pandas as pd

from b1_common import INTERIM, write_long

FIRST_YEAR, LAST_YEAR = 1900, 2020
DISCREPANCY_THRESHOLD = 0.05

SOURCES = ["krausmann2018", "haas2020", "krausmann2009", "unep_irp"]
# Krausmann et al. (2009) group ores with industrial minerals and put the rest
# of the minerals in construction minerals, which is not the 2018 split, so
# only the two comparable categories and the total travel into the block.
KRAUSMANN2009_CATEGORIES = ["biomass", "fossil", "total"]
# The in-use stock is reported by stock category, not by material group. Only
# metals maps one to one. Bricks, concrete and aggregates are all non-metallic
# minerals but leave out the glass inside "wood, glass and plastics" and the
# mineral fraction of asphalt, so that sum is a partial regrouping.
MK_NON_METALLIC = ["bricks", "concrete", "aggregates"]


def load():
    frames = {}
    for source in SOURCES:
        frames[source] = pd.read_csv(INTERIM / "b1_{}.csv".format(source))
    return frames


def pick(frame, series, categories=None):
    out = frame[frame["series"] == series]
    if categories is not None:
        out = out[out["category"].isin(categories)]
    return out.copy()


def relabel(frame, series):
    out = frame.copy()
    out["series"] = series
    return out


def cumulate(frame, series):
    """Cumulative sum from the first year of the frame, per category."""
    out = frame.sort_values(["category", "year"]).copy()
    out["value"] = out.groupby("category")["value"].cumsum()
    out["series"] = series
    out["unit"] = "Gt"
    return out


def build_block(frames):
    k18, haas, k09, irp = (frames[s] for s in SOURCES)
    parts = []

    # Used extraction, from every source that reports it.
    parts.append(pick(k18, "N"))
    parts.append(pick(k09, "N", KRAUSMANN2009_CATEGORIES))
    parts.append(pick(irp, "N"))

    # Extraction, secondary input, total material input and waste generation
    # from the one closed ledger in the block. It reports no total, so the four
    # material groups are summed.
    for series in ["N", "RR", "R", "W"]:
        part = pick(haas, series)
        total = part.groupby("year", as_index=False)["value"].sum()
        total = total.assign(series=series, category="total", unit="Gt/yr", source="haas2020",
                             method="observed")
        parts.append(part)
        parts.append(total)

    # Emissions and residues reaching the environment. By category this is the
    # sum of the three output columns of Haas et al. (2020), which is the DPO*
    # convention: balancing oxygen and water are excluded. Krausmann et al.
    # (2018) reports both conventions, in total only; its DPO* travels under
    # the model's name and the balancing convention under a name of its own.
    dpo = haas[haas["series"].isin(["out_water_vapour", "out_emissions", "out_solid_liquid"])]
    dpo = dpo[dpo["category"] != "total"]
    dpo = dpo.groupby(["year", "category"], as_index=False)["value"].sum()
    dpo = dpo.assign(series="DPO", unit="Gt/yr", source="haas2020", method="observed")
    parts.append(dpo)
    parts.append(dpo.groupby("year", as_index=False)["value"].sum().assign(
        series="DPO", category="total", unit="Gt/yr", source="haas2020", method="observed"))
    parts.append(relabel(pick(k18, "DPOstar"), "DPO"))
    parts.append(relabel(pick(k18, "DPO"), "DPO_incl_balancing"))

    # Gross additions to stock and demolition, the two flows the model's
    # capital block needs beside the net figure Krausmann et al. (2018) give.
    parts.append(relabel(pick(haas, "stock_additions_gross"), "NAS_gross"))
    parts.append(relabel(pick(haas, "out_demolition"), "NAS_demolition"))
    parts.append(relabel(pick(k18, "NAS", ["manufactured_capital"]).assign(category="total"), "NAS"))

    # The in-use stock. Metals is exact; the non-metallic sum is partial.
    parts.append(pick(k18, "MK", ["metals"]))
    mk_min = pick(k18, "MK", MK_NON_METALLIC).groupby("year", as_index=False)["value"].sum()
    parts.append(mk_min.assign(series="MK", category="non_metallic_minerals", unit="Gt",
                               source="krausmann2018", method="reconstructed"))
    parts.append(pick(k18, "MK", ["manufactured_capital"]).assign(category="total"))

    # Tailings, the only flow in these sources that is material moved and not
    # used. It is not overburden and does not measure Omega^{N,S}.
    parts.append(relabel(pick(k18, "use_tailings"), "N_tailings"))

    # The raw material for the broad-reading waste stock: residues that leave
    # use as solids or liquids, already net of the recovery of the same year,
    # cumulated from 1900. Recovery out of the accumulated stock is not
    # reported by any source and is taken to be nil, which is the reading of
    # data plan section 5.
    solid = pick(haas, "out_solid_liquid")
    solid_total = solid.groupby("year", as_index=False)["value"].sum().assign(
        category="total", series="out_solid_liquid", unit="Gt/yr", source="haas2020", method="observed")
    parts.append(cumulate(pd.concat([solid, solid_total]), "Wcum_disposal"))
    parts.append(cumulate(pick(k18, "dpo_eol_waste"), "Wcum_eol_waste"))

    block = pd.concat(parts, ignore_index=True)
    block = block[(block["year"] >= FIRST_YEAR) & (block["year"] <= LAST_YEAR)]
    return block


def discrepancies(block):
    """Every pair of sources measuring the same cell that differ by more than
    the threshold, as a share of the mean of the two."""
    rows = []
    keys = ["year", "series", "category"]
    for key, group in block.groupby(keys):
        group = group.drop_duplicates(subset=["source"])
        if len(group) < 2:
            continue
        records = group[["source", "value"]].to_dict("records")
        for i, left in enumerate(records):
            for right in records[i + 1:]:
                mean = (abs(left["value"]) + abs(right["value"])) / 2
                if mean == 0:
                    continue
                deviation = abs(left["value"] - right["value"]) / mean
                if deviation > DISCREPANCY_THRESHOLD:
                    rows.append(dict(zip(keys, key)) | dict(
                        source_a=left["source"], value_a=left["value"],
                        source_b=right["source"], value_b=right["value"],
                        rel_diff=deviation))
    return pd.DataFrame(rows, columns=["year", "series", "category", "source_a", "value_a",
                                       "source_b", "value_b", "rel_diff"])


def closure(frames, block):
    """The ledger identities the data allow, as residual shares of the input."""
    k18, haas = frames["krausmann2018"], frames["haas2020"]

    def wide(frame, series, category="total"):
        part = frame[(frame["series"] == series) & (frame["category"] == category)]
        return part.set_index("year")["value"]

    rows = []

    # Within Haas et al. (2020), by category: input equals outflow plus the
    # net addition to stock.
    for category in ["biomass", "fossil", "metals", "non_metallic_minerals"]:
        inflow = wide(haas, "N", category) + wide(haas, "RR", category)
        outflow = (wide(haas, "W", category) + wide(haas, "stock_additions_gross", category)
                   - wide(haas, "out_demolition", category))
        rows.append(pd.DataFrame(dict(year=inflow.index, check="haas2020_input_equals_output",
                                      category=category, inflow=inflow.values,
                                      outflow=outflow.values)))

    # Within Krausmann et al. (2018): used extraction equals domestic
    # processed output excluding balancing items plus the net addition to
    # stock. Recycling cancels out of this form of the identity.
    inflow = wide(k18, "N")
    outflow = wide(k18, "DPOstar") + wide(k18, "NAS", "total")
    rows.append(pd.DataFrame(dict(year=inflow.index, check="krausmann2018_extraction_equals_dpo_plus_nas",
                                  category="total", inflow=inflow.values, outflow=outflow.values)))

    # Across the two sources: extraction from Krausmann et al. (2018) plus the
    # secondary input of Haas et al. (2020) against the latter's outflow and
    # the former's net addition to stock.
    rr = block[(block["series"] == "RR") & (block["category"] == "total")].set_index("year")["value"]
    w = block[(block["series"] == "W") & (block["category"] == "total")].set_index("year")["value"]
    inflow = wide(k18, "N") + rr
    outflow = w + wide(k18, "NAS", "total")
    rows.append(pd.DataFrame(dict(year=inflow.index, check="cross_source_input_equals_output",
                                  category="total", inflow=inflow.values, outflow=outflow.values)))

    out = pd.concat(rows, ignore_index=True)
    out["residual"] = out["inflow"] - out["outflow"]
    out["residual_share"] = out["residual"] / out["inflow"]
    return out


def main():
    frames = load()
    block = build_block(frames)
    write_long(block.to_dict("records"), INTERIM / "b1_material_block.csv")

    gaps = discrepancies(block)
    gaps.to_csv(INTERIM / "b1_discrepancies.csv", index=False, float_format="%.10g")
    print("b1_discrepancies: {} cells above {:.0%}, {} series".format(
        len(gaps), DISCREPANCY_THRESHOLD, gaps["series"].nunique()))

    residuals = closure(frames, block)
    residuals.to_csv(INTERIM / "b1_closure.csv", index=False, float_format="%.10g")
    worst = residuals.loc[residuals["residual_share"].abs().idxmax()]
    print("b1_closure: {} rows, largest residual {:.3%} ({}, {}, {})".format(
        len(residuals), worst["residual_share"], worst["check"], worst["category"],
        int(worst["year"])))


if __name__ == "__main__":
    main()
