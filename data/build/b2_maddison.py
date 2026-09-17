"""World GDP and population, 1900-2022, from the Maddison Project Database 2023.

Raw input : data/raw/maddison2023/mpd2023_web.xlsx
Output    : data/interim/b2_maddison.csv   (year, series, value, unit, source, method)

The MPD carries country series on the "Full data" sheet (annual, 169 entities) and its own
regional and world aggregates on the "Regional data" sheet (decadal to 2010, then annual from
2015).  Neither alone gives an annual world series over 1900-2022, so both are used:

  1950-2022  the country sum.  It reproduces the MPD's own world totals to within 0.04 per cent
             at every decadal benchmark and exactly in 1950, 2000, 2010 and 2019-2022, because
             from 1950 the MPD's country coverage is essentially complete.
  1900-1949  the MPD's own world benchmarks (1900, 1920, 1940, 1950) carry the level; the annual
             movement between them comes from a 32-country balanced panel.  A naive country sum
             is unusable here: the annual sample swings between 28 and 145 countries and its
             implied world GDP per capita jumps by up to 30 per cent between adjacent years from
             composition alone.

Double counting.  The MPD reports Former USSR, Czechoslovakia and Former Yugoslavia over the
whole period *and* their successor states from 1950.  The successors are dropped through 1990
and the composites from 1991, which is the MPD's own convention: the resulting population sum
equals the MPD world population exactly in 1950 and from 2000 on.

Run from the repository root.  Idempotent.
"""

import os

import numpy as np
import pandas as pd

RAW = "data/raw/maddison2023/mpd2023_web.xlsx"
OUT = "data/interim/b2_maddison.csv"
SOURCE = "maddison2023"

YEAR_MIN, YEAR_MAX = 1900, 2022
SPLICE = 1950            # first year of the country-sum branch
COMPOSITE_LAST = 1990    # last year in which the composite entities are used

COMPOSITES = ["SUN", "CSK", "YUG"]
SUCCESSORS = [
    "RUS", "UKR", "BLR", "MDA", "EST", "LVA", "LTU", "ARM", "AZE", "GEO",
    "KAZ", "KGZ", "TJK", "TKM", "UZB",          # former USSR
    "CZE", "SVK",                                # former Czechoslovakia
    "HRV", "SRB", "SVN", "BIH", "MKD", "MNE",    # former Yugoslavia
]

U_GDP = "trillion 2011 intl USD"
U_POP = "million persons"
U_PC = "2011 intl USD per person"


def load_countries():
    """Country panel with the composite/successor overlap removed."""
    d = pd.read_excel(RAW, sheet_name="Full data")
    drop_succ = (d["year"] <= COMPOSITE_LAST) & d["countrycode"].isin(SUCCESSORS)
    drop_comp = (d["year"] > COMPOSITE_LAST) & d["countrycode"].isin(COMPOSITES)
    d = d[~(drop_succ | drop_comp)]
    return d[(d["year"] >= YEAR_MIN) & (d["year"] <= YEAR_MAX)].copy()


def load_world_benchmarks():
    """The MPD's own world GDP per capita and population, where the sheet carries them."""
    r = pd.read_excel(RAW, sheet_name="Regional data", header=None)
    # Column 9 is "World GDP pc", column 19 "World Population"; row 2 onward is the year index.
    r = r.iloc[2:, [0, 9, 19]].dropna(subset=[0])
    r.columns = ["year", "gdppc", "pop"]
    r["year"] = r["year"].astype(int)
    r = r.dropna(subset=["gdppc", "pop"])
    return r[(r["year"] >= YEAR_MIN) & (r["year"] <= YEAR_MAX)].set_index("year")


def country_sum(d):
    """Annual world population, covered-country GDP and the population coverage of GDP."""
    d = d.copy()
    both = d["gdppc"].notna() & d["pop"].notna()
    g = pd.DataFrame(index=sorted(d["year"].unique()))
    g["pop_all"] = d.groupby("year")["pop"].sum()
    g["pop_cov"] = d[both].groupby("year")["pop"].sum()
    g["gdp_cov"] = d[both].assign(v=lambda x: x["gdppc"] * x["pop"]).groupby("year")["v"].sum()
    g["n_pop"] = d.groupby("year")["pop"].count()
    g["n_both"] = d[both].groupby("year")["gdppc"].count()
    g["gdppc"] = g["gdp_cov"] / g["pop_cov"]
    g["coverage"] = g["pop_cov"] / g["pop_all"]
    return g


def balanced_panel_gdp(d, lo, hi):
    """Real GDP of the countries observed in every year of [lo, hi], as an interpolator."""
    w = d[(d["year"] >= lo) & (d["year"] <= hi)]
    gp = w.pivot_table(index="year", columns="countrycode", values="gdppc")
    pp = w.pivot_table(index="year", columns="countrycode", values="pop")
    keep = sorted(set(gp.columns[gp.notna().all()]) & set(pp.columns[pp.notna().all()]))
    gdp = (gp[keep] * pp[keep]).sum(axis=1)
    return gdp, keep


def benchmark_interpolate(index, benchmarks):
    """Log-linear interpolation of a benchmark series onto every year of `index`."""
    s = pd.Series(np.nan, index=index, dtype=float)
    for y, v in benchmarks.items():
        if y in s.index:
            s.loc[y] = v
    return np.exp(np.log(s).interpolate(method="index"))


def benchmark_with_indicator(index, benchmarks, indicator):
    """Benchmark levels, annual movement from `indicator`, discrepancy spread log-linearly."""
    ind = indicator.reindex(index)
    ratio = pd.Series(np.nan, index=index, dtype=float)
    for y, v in benchmarks.items():
        if y in ratio.index and not np.isnan(ind.get(y, np.nan)):
            ratio.loc[y] = v / ind.loc[y]
    ratio = np.exp(np.log(ratio).interpolate(method="index").ffill().bfill())
    return ind * ratio


def main():
    d = load_countries()
    bm = load_world_benchmarks()
    g = country_sum(d)

    years = list(range(YEAR_MIN, YEAR_MAX + 1))

    # --- 1950-2022: the country sum, scaled to the full population where GDP is missing -------
    late = [y for y in years if y >= SPLICE]
    pop_late = g.loc[late, "pop_all"]
    gdppc_late = g.loc[late, "gdppc"]
    gdp_late = gdppc_late * pop_late

    # --- 1900-1949: MPD world benchmarks, annual movement from the balanced panel -------------
    early = [y for y in years if y < SPLICE]
    idx_all = pd.Index(years)
    bm_early = {y: bm.loc[y, "pop"] for y in bm.index if y <= SPLICE}
    pop_early = benchmark_interpolate(idx_all, bm_early).loc[early]

    ind, panel = balanced_panel_gdp(d, YEAR_MIN, SPLICE)
    bm_gdp = {y: bm.loc[y, "gdppc"] * bm.loc[y, "pop"] for y in bm.index if y <= SPLICE}
    gdp_early = benchmark_with_indicator(idx_all, bm_gdp, ind).loc[early]
    gdppc_early = gdp_early / pop_early

    pop = pd.concat([pop_early, pop_late])
    gdp = pd.concat([gdp_early, gdp_late])
    gdppc = pd.concat([gdppc_early, gdppc_late])
    method = pd.Series(["interpolated"] * len(early) + ["aggregated"] * len(late), index=years)

    rows = []

    def add(series, values, unit, methods):
        """`methods` is either one label for the whole series or a Series indexed by year."""
        for y, v in values.items():
            if pd.notna(v):
                m = methods if isinstance(methods, str) else methods[y]
                rows.append((int(y), series, float(v), unit, SOURCE, m))

    add("gdp_world", gdp / 1e9, U_GDP, method)          # thousand persons * USD -> trillion USD
    add("pop_world", pop / 1e3, U_POP, method)          # thousands -> millions
    add("gdppc_world", gdppc, U_PC, method)

    # The MPD's own world aggregates, kept beside the constructed annual series.
    add("gdp_world_mpd_benchmark", (bm["gdppc"] * bm["pop"]) / 1e9, U_GDP, "observed")
    add("pop_world_mpd_benchmark", bm["pop"] / 1e3, U_POP, "observed")
    add("gdppc_world_mpd_benchmark", bm["gdppc"], U_PC, "observed")

    # Diagnostics: how much of the world the country sum actually covers.
    add("gdp_world_country_sum", g["gdp_cov"] / 1e9, U_GDP, "aggregated")
    add("pop_world_country_sum", g["pop_all"] / 1e3, U_POP, "aggregated")
    add("gdppc_coverage_pop_share", g["coverage"], "share", "aggregated")
    add("n_countries_pop", g["n_pop"], "count", "aggregated")
    add("n_countries_gdppc_and_pop", g["n_both"], "count", "aggregated")

    out = pd.DataFrame(rows, columns=["year", "series", "value", "unit", "source", "method"])
    out = out.sort_values(["series", "year"]).reset_index(drop=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False, lineterminator="\n")

    check = max(abs(gdp_late.get(y, np.nan) / (bm.loc[y, "gdppc"] * bm.loc[y, "pop"]) - 1)
                for y in bm.index if y >= SPLICE)
    print(f"b2_maddison: {len(out)} rows, {out['series'].nunique()} series, "
          f"{YEAR_MIN}-{YEAR_MAX}; pre-{SPLICE} interpolator = {len(panel)} balanced countries; "
          f"post-{SPLICE} max gap to MPD world GDP = {check:.2%} -> {OUT}")


if __name__ == "__main__":
    main()
