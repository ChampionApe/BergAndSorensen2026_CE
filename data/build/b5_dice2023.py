"""The DICE-2023 damage function, as published.

Source: Barrage, L. and Nordhaus, W., "Policies, projections, and the social cost of
carbon: Results from the DICE-2023 model", PNAS 121(13) e2312030121, 2024, Section 3.3
"Damages". Provenance in data/sources/B5_pollution.md.

DICE-2023 writes output as Q = [1 - Lambda][1 - Omega] A K^gamma L^(1-gamma), with the
damage share of gross output

    Omega(t) = pi1 T_AT(t) + pi2 T_AT(t)^2,

T_AT measured from the 1765 preindustrial baseline. The paper reports the calibration as
two points on that curve rather than as coefficients: damages are 3.1 per cent of output
at 3 degrees and 7.0 per cent at 4.5 degrees. This script parses those two published
points and backs out (pi1, pi2) from them: a pure quadratic (pi1 = 0) fits both to within
a rounding error, so pi2 = 0.031 / 3^2 and the 4.5 degree point is the over-identifying
check, reported as the residual.

Damages in DICE-2023 are a loss of output only; the model has no utility damage channel,
which is what fixes psi = 0 in notes/data/pollution.md.

raw   data/raw/dice2023/barrage_nordhaus_2024_pnas.pdf   (downloaded if absent)
out   data/interim/b5_dice2023.csv                       (year, series, value, unit, source, method)

Run from the repository root:  PYTHONUTF8=1 python data/build/b5_dice2023.py
"""

import re
import sys
import urllib.request
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RAW_FILE = ROOT / "data" / "raw" / "dice2023" / "barrage_nordhaus_2024_pnas.pdf"
RAW_URL = (
    "https://economics.yale.edu/sites/default/files/2024-03/"
    "barrage-nordhaus-2024-policies-projections-and-the-social-cost-of-carbon-"
    "results-from-the-dice-2023-model.pdf"
)
OUT = ROOT / "data" / "interim" / "b5_dice2023.csv"

SOURCE = "Barrage and Nordhaus 2024 PNAS 121(13) e2312030121, Section 3.3"
SOURCE_ALT = "Barrage and Nordhaus 2024 PNAS 121(13) e2312030121, Section 4.6"

# "damages are estimated to be 3.1% of output at 3 degC warming and 7.0% of output at
# 4.5 degC warming" -- hyphenation and soft breaks are removed before matching.
DAMAGE_POINTS = re.compile(
    r"damages are estimated to be ([0-9.]+)% of output at ([0-9.]+) ?.C warming "
    r"and ([0-9.]+)% of output at ([0-9.]+) ?.C warming"
)
# The Howard and Sterner alternative of Section 4.6.
HOWARD_STERNER = re.compile(r"a ([0-9.]+)% damage/output ratio at a ([0-9.]+) ?.C increase")


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
            "pypdf is required to read the published damage points out of "
            + str(pdf_path)
            + "; install it or read Section 3.3 of the paper by hand"
        )
    reader = pypdf.PdfReader(str(pdf_path))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    # The typesetting breaks words across lines with a soft hyphen followed by the
    # line break, so "out<soft hyphen>\nput" has to be rejoined before matching.
    text = re.sub(chr(0x00AD) + r"\s*", "", text)
    text = text.replace(chr(0x2019), "'")
    return re.sub(r"\s+", " ", text)


def main():
    fetch(RAW_FILE, RAW_URL)
    text = pdf_text(RAW_FILE)

    match = DAMAGE_POINTS.search(text)
    if match is None:
        sys.exit("could not locate the two published damage points in " + str(RAW_FILE))
    loss_lo, temp_lo, loss_hi, temp_hi = (float(v) for v in match.groups())
    loss_lo /= 100.0
    loss_hi /= 100.0

    pi2 = loss_lo / temp_lo ** 2
    residual = pi2 * temp_hi ** 2 - loss_hi  # the over-identifying check, in output shares

    rows = [
        ("dice2023_damage_share_at_{:g}C".format(temp_lo), loss_lo, "fraction of gross output", SOURCE, "published"),
        ("dice2023_damage_share_at_{:g}C".format(temp_hi), loss_hi, "fraction of gross output", SOURCE, "published"),
        ("dice2023_pi1", 0.0, "fraction of gross output per degC", SOURCE, "derived"),
        ("dice2023_pi2", pi2, "fraction of gross output per degC^2", SOURCE, "derived"),
        ("dice2023_pi2_check_residual_at_{:g}C".format(temp_hi), residual, "fraction of gross output", SOURCE, "derived"),
    ]

    alt = HOWARD_STERNER.search(text)
    if alt is not None:
        loss_alt, temp_alt = (float(v) for v in alt.groups())
        loss_alt /= 100.0
        rows.append(
            (
                "howard_sterner_damage_share_at_{:g}C".format(temp_alt),
                loss_alt,
                "fraction of gross output",
                SOURCE_ALT,
                "published",
            )
        )
        rows.append(
            (
                "howard_sterner_pi2",
                loss_alt / temp_alt ** 2,
                "fraction of gross output per degC^2",
                SOURCE_ALT,
                "derived",
            )
        )

    out = pd.DataFrame(rows, columns=["series", "value", "unit", "source", "method"])
    out.insert(0, "year", "")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT, index=False, float_format="%.9g")

    print(
        "b5_dice2023: {:.1f}% of output at {:g}C and {:.1f}% at {:g}C give pi1=0, "
        "pi2={:.6f} per degC^2 (check residual {:+.5f} of output) -> {}".format(
            100 * loss_lo, temp_lo, 100 * loss_hi, temp_hi, pi2, residual, OUT.relative_to(ROOT)
        )
    )


if __name__ == "__main__":
    main()
