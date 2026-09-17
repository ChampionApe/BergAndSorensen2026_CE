"""B4: OECD municipal waste generation and treatment -> data/interim/b4_oecd_waste.csv.

Downloaded whole from the OECD SDMX endpoint (DSD_MUNW@DF_MUNW).  This script keeps the
tonnage series the model needs and reshapes them long: total generated, amounts
designated for treatment, and the five treatment routes.  From those it forms, per
country and year, the treated share used against unit cost in b4_waste_block.py:

    treated share = (recycling + composting + incineration + other recovery
                     + landfill + other disposal) / total generated,

that is, the share of generated municipal waste entering any recorded treatment or
controlled-disposal operation.  Rows the source marks with an observation status of
estimated or provisional keep that status in `method`.

Run from the repository root:  python data/build/b4_oecd_waste.py
"""

import os

import pandas as pd

RAW = os.path.join("data", "raw", "oecd_waste", "oecd_municipal_waste.csv")
OUT = os.path.join("data", "interim", "b4_oecd_waste.csv")
SOURCE = ("OECD Environment Statistics, Municipal waste: generation and treatment "
          "(OECD.ENV.EPI, DSD_MUNW@DF_MUNW)")

KEEP = ["MUNICIPAL", "TREATMENT", "RECYCLING", "COMPOST", "INCINERATION",
        "INCINERATION_WITH", "INCINERATION_WITHOUT", "OTH_RECOV", "LANDFILL",
        "OTH_DISP", "RECOVERY", "DISPOSAL"]
# The routes that together make up "treated", chosen so that no tonne is double counted:
# INCINERATION is a memo total of the two incineration rows and RECOVERY / DISPOSAL are
# themselves subtotals, so none of the three enters the sum.
TREATED = ["RECYCLING", "COMPOST", "INCINERATION", "OTH_RECOV", "LANDFILL", "OTH_DISP"]


def main():
    d = pd.read_csv(RAW, low_memory=False)
    d = d[(d.UNIT_MEASURE == "T") & d.MEASURE.isin(KEEP)]
    d = d[["REF_AREA", "Reference area", "MEASURE", "TIME_PERIOD", "OBS_VALUE",
           "OBS_STATUS", "UNIT_MULT"]].dropna(subset=["OBS_VALUE"])
    d["tonnes"] = d.OBS_VALUE * (10.0 ** d.UNIT_MULT.fillna(0))

    rows = []
    for _, r in d.iterrows():
        rows.append(dict(year=int(r.TIME_PERIOD), series="msw_" + r.MEASURE.lower(),
                         region_or_material=r.REF_AREA, value=r.tonnes, unit="tonnes",
                         source=SOURCE,
                         method="observed" if pd.isna(r.OBS_STATUS)
                         else "observed_status_%s" % r.OBS_STATUS))

    wide = d.pivot_table(index=["REF_AREA", "TIME_PERIOD"], columns="MEASURE",
                         values="tonnes", aggfunc="first")
    have = [c for c in TREATED if c in wide.columns]
    treated = wide[have].sum(axis=1, min_count=1)
    share = 100.0 * treated / wide["MUNICIPAL"]
    share = share[share.notna() & (wide[have].notna().sum(axis=1) >= 3)]
    for (area, year), v in share.items():
        rows.append(dict(year=int(year), series="treated_share_of_generated",
                         region_or_material=area, value=float(v),
                         unit="percent_of_generated_MSW", source=SOURCE,
                         method="computed"))

    out = pd.DataFrame(rows, columns=["year", "series", "region_or_material", "value",
                                      "unit", "source", "method"])
    out = out.sort_values(["series", "region_or_material", "year"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print("b4_oecd_waste: %d rows -> %s (%d countries, %d-%d, %d treated-share points)"
          % (len(out), OUT, out.region_or_material.nunique(), out.year.min(),
             out.year.max(), (out.series == "treated_share_of_generated").sum()))


if __name__ == "__main__":
    main()
