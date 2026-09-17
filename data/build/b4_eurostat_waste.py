"""B4: Eurostat waste and expenditure -> data/interim/b4_eurostat_waste.csv.

Three bulk TSV downloads:

  env_wasmun      municipal waste by management operation, thousand tonnes, 1995-.
  env_wastrt      treatment of all waste by operation, kilogrammes per head, biennial.
  env_epea_neep   national expenditure on environmental protection by purpose; the
                  purpose taken here is CEP0401, "Waste management" (CEP04 is "Waste,
                  materials recovery and savings"; CEP0301 is wastewater, not waste),
                  sector S1 (total economy), million euro.

From the first and the third this script forms the two columns the treatment-cost
gradient needs, per country and year:

  treated_share_of_generated   (TRT / GEN) x 100, the share of generated municipal
                               waste entering a recorded treatment operation, and
  waste_expenditure_per_tonne_msw
                               national waste-management expenditure divided by
                               municipal waste generated.

The second of those is a ratio of two things that do not cover the same waste: the
numerator is expenditure on all waste management, the denominator municipal waste only.
It is therefore a level that is too high by the ratio of total to municipal waste, and
useful for the *gradient* across countries rather than for the level.  The series name
says per tonne of MSW so that this cannot be forgotten downstream.

Run from the repository root:  python data/build/b4_eurostat_waste.py
"""

import os

import pandas as pd

RAW = os.path.join("data", "raw", "eurostat_waste")
OUT = os.path.join("data", "interim", "b4_eurostat_waste.csv")

SRC_MUN = "Eurostat env_wasmun, municipal waste by waste management operations"
SRC_TRT = ("Eurostat env_wastrt, treatment of waste by waste category, hazardousness "
           "and waste management operations")
SRC_EXP = ("Eurostat env_epea_neep, national expenditure on environmental protection "
           "by institutional sector and environmental purpose, CEP0401 waste "
           "management, sector S1")

MUN_OPS = ["GEN", "TRT", "RCY", "RCY_M", "RCY_C_D", "RCV_E", "DSP_I", "DSP_I_RCV_E",
           "DSP_L_OTH", "PRP_REU"]


def read_tsv(name, dims):
    """Read one Eurostat bulk TSV into long form with the key split into `dims`."""
    d = pd.read_csv(os.path.join(RAW, name), sep="\t")
    key = d.columns[0]
    parts = d[key].str.split(",", expand=True)
    parts.columns = dims
    d = pd.concat([parts, d.drop(columns=[key])], axis=1)
    d = d.melt(id_vars=dims, var_name="year", value_name="raw")
    d["year"] = d.year.str.strip().astype(int)
    # Eurostat writes ": " for missing and appends a status flag to the number.
    v = d.raw.astype(str).str.strip().str.replace(r"\s*[a-z]+$", "", regex=True)
    d["flag"] = d.raw.astype(str).str.strip().str.extract(r"\s([a-z]+)$")[0]
    d["value"] = pd.to_numeric(v.replace(":", None), errors="coerce")
    return d.dropna(subset=["value"])


def main():
    rows = []

    mun = read_tsv("env_wasmun.tsv.gz", ["freq", "wst_oper", "unit", "geo"])
    mun = mun[(mun.unit == "THS_T") & mun.wst_oper.isin(MUN_OPS)]
    for _, r in mun.iterrows():
        rows.append(dict(year=r.year, series="msw_" + r.wst_oper.lower(),
                         region_or_material=r.geo, value=r.value * 1e3, unit="tonnes",
                         source=SRC_MUN,
                         method="observed" if pd.isna(r.flag)
                         else "observed_flag_%s" % r.flag))

    wide = mun.pivot_table(index=["geo", "year"], columns="wst_oper", values="value",
                           aggfunc="first")
    share = 100.0 * wide["TRT"] / wide["GEN"]
    for (geo, year), v in share.dropna().items():
        rows.append(dict(year=int(year), series="treated_share_of_generated",
                         region_or_material=geo, value=float(v),
                         unit="percent_of_generated_MSW", source=SRC_MUN,
                         method="computed"))
    for op in ["RCY", "RCY_M", "RCY_C_D", "RCV_E", "DSP_I_RCV_E", "DSP_L_OTH"]:
        if op not in wide.columns:
            continue
        s = 100.0 * wide[op] / wide["GEN"]
        for (geo, year), v in s.dropna().items():
            rows.append(dict(year=int(year), series="share_%s_of_generated" % op.lower(),
                             region_or_material=geo, value=float(v),
                             unit="percent_of_generated_MSW", source=SRC_MUN,
                             method="computed"))

    exp = read_tsv("env_epea_neep.tsv.gz",
                   ["freq", "env_pa", "sector", "unit", "geo"])
    exp = exp[(exp.env_pa == "CEP0401") & (exp.sector == "S1") &
              (exp.unit == "MIO_EUR")]
    for _, r in exp.iterrows():
        rows.append(dict(year=r.year, series="waste_management_expenditure",
                         region_or_material=r.geo, value=r.value, unit="mio_EUR",
                         source=SRC_EXP,
                         method="observed" if pd.isna(r.flag)
                         else "observed_flag_%s" % r.flag))

    gen = wide["GEN"].rename("gen_ths_t").reset_index()
    e = exp[["geo", "year", "value"]].rename(columns={"value": "mio_eur"})
    j = e.merge(gen, on=["geo", "year"])
    j["eur_per_tonne"] = j.mio_eur * 1e6 / (j.gen_ths_t * 1e3)
    for _, r in j.iterrows():
        rows.append(dict(year=int(r.year), series="waste_expenditure_per_tonne_msw",
                         region_or_material=r.geo, value=float(r.eur_per_tonne),
                         unit="current_EUR_per_tonne_MSW_generated", source=SRC_EXP,
                         method="computed"))

    trt = read_tsv("env_wastrt.tsv.gz",
                   ["freq", "unit", "hazard", "wst_oper", "waste", "geo"])
    trt = trt[(trt.unit == "KG_HAB") & (trt.waste == "TOTAL") & (trt.hazard == "HAZ_NHAZ")]
    for _, r in trt.iterrows():
        rows.append(dict(year=r.year, series="allwaste_%s_kg_per_head" % r.wst_oper.lower(),
                         region_or_material=r.geo, value=r.value, unit="kg_per_head",
                         source=SRC_TRT,
                         method="observed" if pd.isna(r.flag)
                         else "observed_flag_%s" % r.flag))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    out = out.sort_values(["series", "region_or_material", "year"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print("b4_eurostat_waste: %d rows -> %s (%d cost-per-tonne points, %d countries)"
          % (len(out), OUT,
             (out.series == "waste_expenditure_per_tonne_msw").sum(),
             out.region_or_material.nunique()))


if __name__ == "__main__":
    main()
