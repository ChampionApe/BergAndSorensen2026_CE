"""Shared helpers for the phase C calibration scripts, data/build/c*.py.

Every C script reads the interim blocks of phase B, computes its block of
parameters, and writes them into data/processed/calibration.json (the schema of
notes/plan_calibration_experiments.md, task A3: keys are the Julia identifiers of
model/SYMBOLS.md).  Beside the JSON each script writes one long-format CSV,
data/processed/c<N>_<block>.csv, with the intermediate numbers a reader needs;
data/build/appendix_tables.py turns those into the generated tables of
writing/quant/quant_data.tex.

Units (decision D5): goods in trillions of 2011 international dollars, material in
gigatonnes, pollution in gigatonnes of material, one period one year.  A price in
US dollars per tonne is 0.001 trillion dollars per gigatonne.

Run from the repository root with PYTHONUTF8=1.  Idempotent: a script rewrites its
own entries and leaves the others.
"""

import json
import math
import os
from collections import OrderedDict
from datetime import date

import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INTERIM = os.path.join(ROOT, "data", "interim")
PROCESSED = os.path.join(ROOT, "data", "processed")
RAW = os.path.join(ROOT, "data", "raw")
CALIBRATION = os.path.join(PROCESSED, "calibration.json")

USD_PER_T_TO_TN_PER_GT = 0.001   # 1 US$/t = 0.001 trillion $/Gt
BASE_YEAR = 1900
LAST_YEAR = 2015                 # the last year every B1 series covers
WINDOW = (2000, 2015)            # the calibration window for compositions

CATEGORIES = ["biomass", "fossil", "metals", "non_metallic_minerals"]
EXHAUSTIBLE = ["fossil", "metals"]

META = OrderedDict([
    ("base_year", BASE_YEAR),
    ("units", OrderedDict([
        ("goods", "trillions of 2011 international dollars"),
        ("material", "gigatonnes"),
        ("pollution", "gigatonnes of material (decision D4)"),
        ("period", "1 year"),
        ("prices", "trillion dollars per gigatonne (= 1000 US$/t)"),
    ])),
    ("built_by", "data/build/c1_accounting.py ... c6_states.py"),
    ("date", None),
])


# ---------------------------------------------------------------------------
# interim blocks
# ---------------------------------------------------------------------------

def load_block(name):
    return pd.read_csv(os.path.join(INTERIM, name + ".csv"))


def b1_series(block, series, category="total", source=None):
    """One B1 series as a year-indexed Series."""
    d = block[(block["series"] == series) & (block["category"] == category)]
    if source is not None:
        d = d[d["source"] == source]
    if d.empty:
        raise KeyError(f"B1 has no {series}/{category}/{source}")
    if d["source"].nunique() > 1:
        raise KeyError(f"B1 {series}/{category} has several sources; name one")
    return d.set_index("year")["value"].sort_index()


def b2_series(block, series):
    d = block[block["series"] == series]
    return d.set_index("year")["value"].sort_index()


def macro_series():
    """Y, C, G, K of block B2 with the pre-1950 use split at the perpetual-inventory
    investment share (ruling 5 of phase C): before 1950 G = s_pim * Y and C = Y - G,
    so the reconstructed capital stock and the reconstructed gross formation rest on
    the same share.  Rows carry the method the ruling implies."""
    m = load_block("b2_macro_block")
    Y = b2_series(m, "Y")
    C = b2_series(m, "C").copy()
    G = b2_series(m, "G").copy()
    K = b2_series(m, "K")
    s_pim = b2_series(m, "investment_share_pim")
    pre = s_pim.index
    G.loc[pre] = s_pim * Y.loc[pre]
    C.loc[pre] = Y.loc[pre] - G.loc[pre]
    method = pd.Series("aggregated", index=Y.index)
    method.loc[pre] = "reconstructed"
    return pd.DataFrame({"Y": Y, "C": C, "G": G, "K": K, "method": method})


def pwt_world():
    """World averages of PWT 10.01 rates that block B2 did not extract: the internal
    rate of return `irr` and the depreciation rate `delta`, weighted by the capital
    stock at current PPPs `cn`, and the labour share `labsh`, weighted by output-side
    GDP at current PPPs `cgdpo`.  Countries missing a rate in a year are left out of
    that year's weight.  Year-indexed frame with the country counts."""
    import numpy as np
    d = pd.read_excel(os.path.join(RAW, "pwt1001", "pwt1001.xlsx"), sheet_name="Data")
    out = {}
    for var, wvar in (("irr", "cn"), ("delta", "cn"), ("labsh", "cgdpo")):
        x = d.dropna(subset=[var, wvar])
        g = x.groupby("year")
        out[var] = g.apply(lambda f: np.average(f[var], weights=f[wvar]), include_groups=False)
        out["n_" + var] = g.size()
    return pd.DataFrame(out)


def b1_by_category(block, series, source="haas2020"):
    """Year x category frame of one B1 series."""
    d = block[(block["series"] == series) & (block["source"] == source)
              & (block["category"].isin(CATEGORIES))]
    return d.pivot_table(index="year", columns="category", values="value")


# ---------------------------------------------------------------------------
# the calibration file
# ---------------------------------------------------------------------------

def load_calibration():
    if os.path.exists(CALIBRATION):
        with open(CALIBRATION, encoding="utf-8") as f:
            return json.load(f, object_pairs_hook=OrderedDict)
    return OrderedDict([("meta", META), ("params", OrderedDict()),
                        ("states", OrderedDict()), ("cases", OrderedDict())])


def save_calibration(cal):
    cal["meta"]["date"] = date.today().isoformat()
    os.makedirs(PROCESSED, exist_ok=True)
    with open(CALIBRATION, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cal, f, indent=2)
        f.write("\n")


def entry(value, source, low=None, high=None):
    """One params entry.  Missing low/high means a point (calibration.jl)."""
    e = OrderedDict([("value", _num(value))])
    if low is not None:
        e["low"] = _num(low)
    if high is not None:
        e["high"] = _num(high)
    e["source"] = source
    return e


def _num(x):
    if isinstance(x, str):
        return x
    return float(x)


def set_params(cal, block):
    """Write a dict of name -> entry into params, keeping file order stable."""
    for k, v in block.items():
        cal["params"][k] = v


# ---------------------------------------------------------------------------
# the per-block record for the appendix tables
# ---------------------------------------------------------------------------

class Record:
    """Long-format rows (name, value, unit, note) written to processed/c<N>_<block>.csv."""

    def __init__(self, name):
        self.name = name
        self.rows = []

    def add(self, name, value, unit, note=""):
        self.rows.append(OrderedDict(name=name, value=value, unit=unit, note=note))
        return value

    def write(self):
        os.makedirs(PROCESSED, exist_ok=True)
        path = os.path.join(PROCESSED, self.name + ".csv")
        pd.DataFrame(self.rows).to_csv(path, index=False, lineterminator="\n")
        return path


def log_growth(series, y0, y1):
    """Average log growth rate per year between two dates of a year-indexed series."""
    return math.log(series.loc[y1] / series.loc[y0]) / (y1 - y0)
