"""The multi-model mean CO2 impulse response function of Joos et al. (2013).

Source: Joos, F. et al., "Carbon dioxide and climate impulse response functions for the
computation of greenhouse gas metrics: a multi-model analysis", Atmos. Chem. Phys. 13,
2793-2825, 2013, Table 5, row IRF_CO2. Provenance in data/SOURCES.md, block B5.

The fitted form is Joos et al. equation (11),

    IRF(t) = a0 + sum_i a_i exp(-t / tau_i),   0 < t < 1000 yr,

with sum_i a_i = 1 including a0, fitted to the multi-model mean response to a pulse of
100 GtC added to a 389 ppm background under present-day climate.

raw   data/raw/joos2013/acp-13-2793-2013.pdf    (downloaded if absent)
out   data/interim/b5_joos2013.csv              (year, series, value, unit, source, method)

The coefficients are parsed out of the published table rather than typed in, so that the
number in the interim file traces to the page it was read from. Text extraction uses pypdf;
the parsed row is asserted against the paper's own adding-up condition sum a_i = 1.

In the output the `year` column carries the horizon in years since the pulse for the
retained-fraction path, and is empty for the coefficient rows.

Run from the repository root:  PYTHONUTF8=1 python data/build/b5_joos2013.py
"""

import math
import re
import sys
import urllib.request
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RAW_FILE = ROOT / "data" / "raw" / "joos2013" / "acp-13-2793-2013.pdf"
RAW_URL = "https://acp.copernicus.org/articles/13/2793/2013/acp-13-2793-2013.pdf"
OUT = ROOT / "data" / "interim" / "b5_joos2013.csv"

SOURCE = "Joos et al. 2013 ACP 13:2793-2825, Table 5, row IRF_CO2"
HORIZON = 300  # years of the retained-fraction path written out

# "IRFCO2 0.6 0.2173 0.2240 0.2824 0.2763 394.4 36.54 4.304"
# columns: rel. error (per cent), a0, a1, a2, a3, tau1, tau2, tau3
TABLE_ROW = re.compile(
    r"IRF\s*CO\s*2\s+" + r"\s+".join([r"([0-9]+\.[0-9]+)"] * 8)
)


def fetch(path, url):
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        data = response.read()
    path.write_bytes(data)


def parse_table5(pdf_path):
    try:
        import pypdf
    except ImportError:
        sys.exit(
            "pypdf is required to read the published table out of "
            + str(pdf_path)
            + "; install it or read Table 5 of the paper by hand"
        )
    reader = pypdf.PdfReader(str(pdf_path))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    text = re.sub(r"\s+", " ", text)
    match = TABLE_ROW.search(text)
    if match is None:
        sys.exit("could not locate the IRF_CO2 row of Table 5 in " + str(pdf_path))
    values = [float(v) for v in match.groups()]
    rel_error, a0, a1, a2, a3, tau1, tau2, tau3 = values
    total = a0 + a1 + a2 + a3
    if abs(total - 1.0) > 1e-3:
        sys.exit(
            "parsed coefficients do not satisfy the paper's adding-up condition "
            "sum a_i = 1 (got {:.6f})".format(total)
        )
    return {
        "rel_error_pct": rel_error,
        "a0": a0,
        "a1": a1,
        "a2": a2,
        "a3": a3,
        "tau1": tau1,
        "tau2": tau2,
        "tau3": tau3,
    }


def irf(t, p):
    """Retained airborne fraction t years after the pulse, Joos et al. equation (11)."""
    return (
        p["a0"]
        + p["a1"] * math.exp(-t / p["tau1"])
        + p["a2"] * math.exp(-t / p["tau2"])
        + p["a3"] * math.exp(-t / p["tau3"])
    )


def main():
    fetch(RAW_FILE, RAW_URL)
    p = parse_table5(RAW_FILE)

    rows = []
    units = {
        "rel_error_pct": "per cent",
        "a0": "fraction",
        "a1": "fraction",
        "a2": "fraction",
        "a3": "fraction",
        "tau1": "years",
        "tau2": "years",
        "tau3": "years",
    }
    for name, value in p.items():
        rows.append(
            {
                "year": "",
                "series": "irf_co2_" + name,
                "value": value,
                "unit": units[name],
                "source": SOURCE,
                "method": "published",
            }
        )
    for t in range(0, HORIZON + 1):
        rows.append(
            {
                "year": t,
                "series": "irf_co2_retained_fraction_at_horizon",
                "value": irf(t, p),
                "unit": "fraction of pulse",
                "source": SOURCE,
                "method": "evaluated",
            }
        )

    out = pd.DataFrame(rows)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT, index=False, float_format="%.9g")

    print(
        "b5_joos2013: a0={a0} a1={a1} a2={a2} a3={a3} tau=({tau1},{tau2},{tau3}) yr, "
        "paper's own fit error {rel_error_pct}%; retained fraction "
        .format(**p)
        + "{:.4f} at 100 yr and {:.4f} at {} yr -> {}".format(
            irf(100, p), irf(HORIZON, p), HORIZON, OUT.relative_to(ROOT)
        )
    )


if __name__ == "__main__":
    main()
