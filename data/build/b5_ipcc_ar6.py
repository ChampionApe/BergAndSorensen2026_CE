"""The transient climate response to cumulative CO2 emissions (TCRE), as assessed by IPCC AR6.

Source: Canadell, J.G. et al., "Global Carbon and other Biogeochemical Cycles and
Feedbacks", Chapter 5 of Climate Change 2021: The Physical Science Basis (IPCC AR6 WGI),
Section 5.5.1.4 "Combined Assessment of TCRE". Provenance in data/sources/B5_pollution.md.

The assessed sentence is parsed out of the chapter rather than typed in:

    "... results in a 5-95% range of 1.0-2.3 degC per 1000 PgC (0.27 degC-0.63 degC per
    1000 GtCO2). Based on expert judgement ... a consolidated assessment that TCRE would
    fall likely in the range of 1.0-2.3 degC per 1000 PgC, with a best estimate of
    1.65 degC per 1000 PgC (0.45 degC per 1000 GtCO2)."

The chapter reports the same assessment in two units; the per-GtCO2 figures are the ones
the model needs, since P is a stock of gigatonnes CO2 under decision D5.

raw   data/raw/ipcc_ar6_wg1/IPCC_AR6_WGI_Chapter05.pdf   (downloaded if absent, 25 MB)
out   data/interim/b5_ipcc_ar6.csv                       (year, series, value, unit, source, method)

Run from the repository root:  PYTHONUTF8=1 python data/build/b5_ipcc_ar6.py
"""

import re
import sys
import urllib.request
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RAW_FILE = ROOT / "data" / "raw" / "ipcc_ar6_wg1" / "IPCC_AR6_WGI_Chapter05.pdf"
RAW_URL = "https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WGI_Chapter05.pdf"
OUT = ROOT / "data" / "interim" / "b5_ipcc_ar6.csv"

SOURCE = "IPCC AR6 WGI Chapter 5, Section 5.5.1.4"

DEG = r"[°℃]?C"
DASH = r"[-‐–—]"

FIVE_NINETYFIVE = re.compile(
    r"5" + DASH + r"95% range of ([0-9.]+)" + DASH + r"([0-9.]+)" + DEG
    + r" per 1000 PgC \(([0-9.]+)" + DEG + r"" + DASH + r"([0-9.]+)" + DEG
    + r" per 1000 GtCO ?2\)"
)
LIKELY_AND_BEST = re.compile(
    r"likely in the range of ([0-9.]+)" + DASH + r"([0-9.]+)" + DEG
    + r" per 1000 PgC, with a best estimate of ([0-9.]+)" + DEG
    + r" per 1000 PgC \(([0-9.]+)" + DEG + r" per 1000 GtCO ?2\)"
)


def fetch(path, url):
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request) as response:
        data = response.read()
    path.write_bytes(data)


def pdf_text(pdf_path):
    try:
        import pypdf
    except ImportError:
        sys.exit(
            "pypdf is required to read the assessed TCRE out of "
            + str(pdf_path)
            + "; install it or read Section 5.5.1.4 of the chapter by hand"
        )
    reader = pypdf.PdfReader(str(pdf_path))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    return re.sub(r"\s+", " ", text)


def main():
    fetch(RAW_FILE, RAW_URL)
    text = pdf_text(RAW_FILE)

    m1 = FIVE_NINETYFIVE.search(text)
    m2 = LIKELY_AND_BEST.search(text)
    if m1 is None or m2 is None:
        sys.exit("could not locate the assessed TCRE sentence in " + str(RAW_FILE))

    pgc_lo_5, pgc_hi_95, co2_lo_5, co2_hi_95 = (float(v) for v in m1.groups())
    pgc_lo, pgc_hi, pgc_best, co2_best = (float(v) for v in m2.groups())
    if (pgc_lo, pgc_hi) != (pgc_lo_5, pgc_hi_95):
        sys.exit("the two parsed TCRE ranges disagree; check the chapter text")

    per_gtco2 = 1.0 / 1000.0
    rows = [
        ("tcre_best", co2_best * per_gtco2, "degC per GtCO2", "likely-range best estimate"),
        ("tcre_low", co2_lo_5 * per_gtco2, "degC per GtCO2", "likely range lower bound"),
        ("tcre_high", co2_hi_95 * per_gtco2, "degC per GtCO2", "likely range upper bound"),
        ("tcre_best_per_1000PgC", pgc_best, "degC per 1000 PgC", "as reported"),
        ("tcre_low_per_1000PgC", pgc_lo, "degC per 1000 PgC", "as reported"),
        ("tcre_high_per_1000PgC", pgc_hi, "degC per 1000 PgC", "as reported"),
    ]

    out = pd.DataFrame(
        [
            {
                "year": "",
                "series": name,
                "value": value,
                "unit": unit,
                "source": SOURCE + " (" + note + ")",
                "method": "published",
            }
            for name, value, unit, note in rows
        ]
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT, index=False, float_format="%.9g")

    print(
        "b5_ipcc_ar6: TCRE {:g} degC per 1000 PgC best estimate, likely range {:g}-{:g}; "
        "in the model's units {:g} degC per GtCO2, range {:g}-{:g} -> {}".format(
            pgc_best,
            pgc_lo,
            pgc_hi,
            co2_best * per_gtco2,
            co2_lo_5 * per_gtco2,
            co2_hi_95 * per_gtco2,
            OUT.relative_to(ROOT),
        )
    )


if __name__ == "__main__":
    main()
