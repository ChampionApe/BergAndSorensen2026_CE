"""The B2 macro block: world Y, POP, C, G, K and the use split, 1900-2020, in D5 units.

Inputs  : data/interim/b2_maddison.csv, b2_pwt.csv, b2_piketty_zucman.csv
Output  : data/interim/b2_macro_block.csv   (year, series, value, unit, source, method)

Units are those of decision D5 of notes/plan_calibration_experiments.md: goods in trillions of
2011 international dollars, population in millions, one period one year.

The construction in one line each.

  Y, POP   Maddison, unchanged (`b2_maddison.py` has the aggregation).
  shares   1950-2019 PWT's world use split renormalised on consumption plus gross capital
           formation; 1900-1949 held at the 1950 split; 2020 held at 2019.  Reconstructed
           wherever held.
  C, G     the shares times Y.  C is household plus government consumption: the model has one
           consumption good and no separate public sector, and putting government consumption in
           G would count it as capital formation, which it is not.
  K        1950-2019 PWT's world capital-output ratio `cn/cgdpo` times Maddison Y -- the ratio is
           comparable across countries and free of the 2017-versus-2011 base, the level is
           Maddison's.  1900-1949 a perpetual inventory backwards from that 1950 value; 2020 the
           same recursion one year forward.

The perpetual inventory, and the one thing it forced.
  K_{t+1} = (1 - delta) K_t + s Y_t, with delta the PWT world depreciation rate in 1950 and K in
  1900 at its steady-state value s Y_1900 / (g + delta), g the trend growth of Y over 1900-1913.
  The recursion is linear and homogeneous in s given that initialisation, so requiring it to
  reproduce the 1950 anchor pins s exactly -- there is no search.  It does *not* pin s at the
  1950 investment share: holding the 1950 share of 0.21 back to 1900 accumulates about a fifth
  more capital than the 1950 stock holds.  The anchored share is lower, and that is the expected
  direction, since it has to absorb both genuinely lower pre-war investment rates and the capital
  destroyed in two world wars, which the recursion has no other way to represent.  The gap is
  carried in the output as `investment_share_pim` beside `investment_share` rather than
  reconciled, because the two answer different questions and phase C should see both.

Cross-check.  The reconstructed world capital-output ratio is printed against the US national
wealth-to-national-income ratio of Piketty and Zucman (2014).  The two are not the same object
(see `b2_piketty_zucman.py`); the check is on order of magnitude and on the shape of the path.

Run from the repository root.  Idempotent.
"""

import os

import numpy as np
import pandas as pd

MADDISON = "data/interim/b2_maddison.csv"
PWT = "data/interim/b2_pwt.csv"
PZ = "data/interim/b2_piketty_zucman.csv"
OUT = "data/interim/b2_macro_block.csv"

YEAR_MIN, YEAR_MAX = 1900, 2020
PWT_FIRST, PWT_LAST = 1950, 2019
TREND_END = 1913          # end of the pre-WWI window used for the steady-state initialisation

U_GDP = "trillion 2011 intl USD"
U_POP = "million persons"

SRC = "maddison2023+pwt1001"


def wide(path):
    return pd.read_csv(path).pivot_table(index="year", columns="series", values="value")


def main():
    M, P = wide(MADDISON), wide(PWT)
    years = pd.Index(range(YEAR_MIN, YEAR_MAX + 1), name="year")

    Y = M["gdp_world"].reindex(years)
    POP = M["pop_world"].reindex(years)

    # --- the use split ------------------------------------------------------------------------
    s_i = P["investment_share"].reindex(years)
    s_c = P["consumption_share"].reindex(years)
    delta = P["depreciation_rate"].reindex(years)
    held = pd.Series("aggregated", index=years)
    held[years < PWT_FIRST] = "reconstructed"
    held[years > PWT_LAST] = "reconstructed"
    s_i = s_i.ffill().bfill()
    s_c = s_c.ffill().bfill()
    delta = delta.ffill().bfill()

    G = s_i * Y
    C = s_c * Y

    # --- the capital stock -------------------------------------------------------------------
    ky = P["capital_output_ratio"].reindex(years)
    K = ky * Y

    d50 = float(P.loc[PWT_FIRST, "depreciation_rate"])
    anchor = float(K.loc[PWT_FIRST])
    g = float((Y.loc[TREND_END] / Y.loc[YEAR_MIN]) ** (1.0 / (TREND_END - YEAR_MIN)) - 1.0)

    def pim_to_1950(s):
        """K in 1950 from the recursion started at its steady-state value, given s."""
        k = s * float(Y.loc[YEAR_MIN]) / (g + d50)
        for t in range(YEAR_MIN, PWT_FIRST):
            k = (1 - d50) * k + s * float(Y.loc[t])
        return k

    s_pim = 1.0 * anchor / pim_to_1950(1.0)          # the recursion is homogeneous of degree 1 in s
    k = s_pim * float(Y.loc[YEAR_MIN]) / (g + d50)
    for t in range(YEAR_MIN, PWT_FIRST):
        K.loc[t] = k
        k = (1 - d50) * k + s_pim * float(Y.loc[t])

    # 2020: the same recursion one year forward, on the 2019 depreciation rate and share.
    d19 = float(P.loc[PWT_LAST, "depreciation_rate"])
    for t in range(PWT_LAST + 1, YEAR_MAX + 1):
        K.loc[t] = (1 - d19) * float(K.loc[t - 1]) + float(G.loc[t - 1])

    k_method = pd.Series("aggregated", index=years)
    k_method[years < PWT_FIRST] = "reconstructed"
    k_method[years > PWT_LAST] = "reconstructed"

    # --- coverage diagnostic and the Piketty-Zucman cross-check --------------------------------
    pwt_cover = P["pop_world_pwt"].reindex(years) / POP

    rows = []

    def add(series, values, unit, methods):
        for y, v in values.items():
            if pd.notna(v):
                m = methods if isinstance(methods, str) else methods[y]
                rows.append((int(y), series, float(v), unit, SRC, m))

    add("Y", Y, U_GDP, "aggregated")
    add("POP", POP, U_POP, "aggregated")
    add("C", C, U_GDP, held)
    add("G", G, U_GDP, held)
    add("K", K, U_GDP, k_method)
    add("investment_share", s_i, "share", held)
    add("consumption_share", s_c, "share", held)
    add("K_over_Y", K / Y, "ratio", k_method)
    add("depreciation_rate", delta, "per year", held)
    add("investment_share_pim", pd.Series(s_pim, index=years[years < PWT_FIRST]),
        "share", "reconstructed")
    add("pwt_population_coverage", pwt_cover.dropna(), "share", "aggregated")

    out = pd.DataFrame(rows, columns=["year", "series", "value", "unit", "source", "method"])
    out = out.sort_values(["series", "year"]).reset_index(drop=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False, lineterminator="\n")

    pz = wide(PZ)["national_wealth_over_national_income_usa"]
    chk = ", ".join(f"{y}: {K.loc[y] / Y.loc[y]:.2f} vs {pz.loc[y]:.2f}"
                    for y in (1900, 1920, 1940, 1950) if y in pz.index)
    print(f"b2_macro_block: {len(out)} rows, {out['series'].nunique()} series, "
          f"{YEAR_MIN}-{YEAR_MAX}; PIM g={g:.4f} delta={d50:.4f} s={s_pim:.4f} "
          f"(1950 investment share {float(P.loc[PWT_FIRST, 'investment_share']):.4f}); "
          f"K/Y world vs US wealth/income [{chk}] -> {OUT}")


if __name__ == "__main__":
    main()
