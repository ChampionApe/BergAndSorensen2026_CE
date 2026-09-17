"""Global fossil CO2 emissions by fuel, global total, 1750 to the latest year.

Source: the Global Carbon Project's fossil CO2 emissions dataset, release 2025v15,
the dataset behind the Global Carbon Budget 2025 (Friedlingstein et al., 2026).
Provenance in data/sources/B5_pollution.md.

raw   data/raw/gcb/GCB2025v15_MtCO2_flat.csv      (downloaded if absent)
      data/raw/gcb/essd-18-3211-2026.pdf          (downloaded if absent, 13 MB)
out   data/interim/b5_gcb.csv                     (year, series, value, unit, source, method)

Transformation of the flat file: keep the row block Country == "Global", drop the
per-capita column, convert millions of tonnes CO2 to gigatonnes CO2 (divide by 1000),
melt to long format. Nothing else: the raw file is the published series.

The methods paper contributes four scalars that the flat file does not carry and that the
mapping to a damage function needs: the cumulative fossil, land-use and total
anthropogenic CO2 of Table 8 for 1750-2024, and the cumulative atmospheric growth over
the same period that gives the airborne fraction. They are parsed out of the paper; if the
paper cannot be read the annual series are still written and the scalars are reported as
missing rather than filled in.

Run from the repository root:  PYTHONUTF8=1 python data/build/b5_gcb.py
"""

import re
import sys
import urllib.request
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw" / "gcb"
OUT = ROOT / "data" / "interim" / "b5_gcb.csv"

RAW_FILE = RAW / "GCB2025v15_MtCO2_flat.csv"
RAW_URL = "https://zenodo.org/records/17417124/files/GCB2025v15_MtCO2_flat.csv?download=1"

PAPER_FILE = RAW / "essd-18-3211-2026.pdf"
PAPER_URL = "https://essd.copernicus.org/articles/18/3211/2026/essd-18-3211-2026.pdf"

SOURCE = "GCP fossil CO2 dataset 2025v15 (Andrew and Peters 2025); GCB 2025"
PAPER = "Friedlingstein et al. 2026 ESSD 18:3211-3288 (Global Carbon Budget 2025)"

# One gigatonne of carbon is 44/12 gigatonnes of CO2 (molar masses 44.009 and 12.011,
# the conversion the Global Carbon Budget itself uses).
GTC_TO_GTCO2 = 44.0 / 12.0

# Table 8 of the methods paper, "Cumulative CO2 for different time periods in gigatonnes
# of carbon", first column 1750-2024. The regex is anchored on the column header so that
# it cannot match Table 7, which carries the same row labels for decadal mean flows.
NUM = r"([0-9]+) ?. ?([0-9]+)"
TABLE8 = re.compile(
    r"1750.2024 1850.2014 1850.2024 1960.2024 1850.2025 Emissions "
    r"Fossil CO\s*2 emissions \(EFOS\) " + NUM + r" .*?"
    r"Land-use change emissions \(ELUC\) " + NUM + r" .*?"
    r"Total emissions " + NUM + r" .*?"
    r"Growth rate in atmos CO\s*2 \(GATM\) " + NUM + r" "
)

# Column in the raw file -> series name in the interim file.
COLUMNS = {
    "Total": "co2_fossil_total",
    "Coal": "co2_fossil_coal",
    "Oil": "co2_fossil_oil",
    "Gas": "co2_fossil_gas",
    "Cement": "co2_cement_process",
    "Flaring": "co2_flaring",
    "Other": "co2_other_carbonates",
}


def fetch(path, url):
    """Download the raw file once. Raw files are never edited afterwards."""
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        data = response.read()
    path.write_bytes(data)


def paper_scalars():
    """The Table 8 cumulative totals and the cumulative airborne fraction, or None."""
    try:
        fetch(PAPER_FILE, PAPER_URL)
        import pypdf
    except Exception:
        return None
    reader = pypdf.PdfReader(str(PAPER_FILE))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    text = re.sub(r"\s+", " ", text)
    t8 = TABLE8.search(text)
    if t8 is None:
        return None
    efos, efos_sd, eluc, eluc_sd, total, total_sd, gatm, gatm_sd = (
        float(v) for v in t8.groups()
    )
    if abs(efos + eluc - total) > 10.0:
        sys.exit("Table 8 parse is inconsistent: EFOS + ELUC does not match the total")
    return {
        "cum_fossil_co2_1750_2024": (efos * GTC_TO_GTCO2, "GtCO2"),
        "cum_fossil_co2_1750_2024_sd": (efos_sd * GTC_TO_GTCO2, "GtCO2"),
        "cum_landuse_co2_1750_2024": (eluc * GTC_TO_GTCO2, "GtCO2"),
        "cum_landuse_co2_1750_2024_sd": (eluc_sd * GTC_TO_GTCO2, "GtCO2"),
        "cum_total_anthropogenic_co2_1750_2024": (total * GTC_TO_GTCO2, "GtCO2"),
        "cum_total_anthropogenic_co2_1750_2024_sd": (total_sd * GTC_TO_GTCO2, "GtCO2"),
        "cum_atmospheric_growth_1750_2024": (gatm * GTC_TO_GTCO2, "GtCO2"),
        "cum_atmospheric_growth_1750_2024_sd": (gatm_sd * GTC_TO_GTCO2, "GtCO2"),
        "fossil_share_of_cumulative_co2_1750_2024": (efos / total, "fraction"),
        "cumulative_airborne_fraction_1750_2024": (gatm / total, "fraction"),
    }


def main():
    fetch(RAW_FILE, RAW_URL)
    raw = pd.read_csv(RAW_FILE)
    world = raw.loc[raw["Country"] == "Global", ["Year"] + list(COLUMNS)].copy()
    if world.empty:
        sys.exit("no rows with Country == 'Global' in " + str(RAW_FILE))

    world = world.rename(columns=COLUMNS).rename(columns={"Year": "year"})
    long = world.melt(id_vars="year", var_name="series", value_name="value")
    long = long.dropna(subset=["value"])
    long["value"] = long["value"] / 1000.0  # MtCO2 -> GtCO2
    long["unit"] = "GtCO2"
    long["source"] = SOURCE
    long["method"] = "observed"
    long = long.sort_values(["series", "year"]).reset_index(drop=True)

    scalars = paper_scalars()
    if scalars is None:
        note = "; the methods paper could not be read, its cumulative totals are missing"
    else:
        note = ""
        long = pd.concat(
            [
                long,
                pd.DataFrame(
                    [
                        {
                            "year": "",
                            "series": name,
                            "value": value,
                            "unit": unit,
                            "source": PAPER + ", Table 8",
                            "method": "published",
                        }
                        for name, (value, unit) in scalars.items()
                    ]
                ),
            ],
            ignore_index=True,
        )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    long.to_csv(OUT, index=False, float_format="%.9g")

    total = long.loc[long["series"] == "co2_fossil_total"]
    print(
        "b5_gcb: {} rows, {} series, {}-{}, total fossil CO2 {:.3f} GtCO2 in {}{} -> {}".format(
            len(long),
            long["series"].nunique(),
            int(total["year"].min()),
            int(total["year"].max()),
            total["value"].iloc[-1],
            int(total["year"].iloc[-1]),
            note,
            OUT.relative_to(ROOT),
        )
    )


if __name__ == "__main__":
    main()
