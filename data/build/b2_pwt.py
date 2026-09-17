"""World capital stock, use split and depreciation, 1950-2019, from Penn World Table 10.01.

Raw input : data/raw/pwt1001/pwt1001.xlsx
Output    : data/interim/b2_pwt.csv   (year, series, value, unit, source, method)

Price concept.  PWT carries two capital stocks: `rnna`, at constant 2017 *national* prices, and
`cn`, at current PPPs.  Only `cn` is comparable across countries, so only `cn` can be summed to a
world total; `rnna` is a within-country time series in units that differ by country.  `cn` is
paired with `cgdpo`, output-side real GDP at current PPPs, which is its own denominator in PWT's
construction, so `cn/cgdpo` is the capital-output ratio PWT is built to support.  The use shares
`csh_*` are shares of `cgdpo` at the same current PPPs.

Everything PWT contributes downstream is a *ratio* -- the capital-output ratio, the use shares and
the depreciation rate.  That is deliberate: PWT 10.01 is denominated in 2017 US dollars and D5 of
the calibration plan asks for 2011 international dollars, and the levels are carried by Maddison
(`b2_maddison.py`).  Rebasing PWT levels from 2017 to 2011 would add a deflator with no bearing on
any ratio, so it is not done.  The 2017-dollar levels are written out as well, clearly labelled,
for anyone who wants them.

Coverage.  PWT starts at 183 countries but only 55 have data in 1950, rising to 180 by 2000.  The
world aggregates here are sums over the countries observed in each year; `b2_macro_block.py`
reports what share of Maddison world GDP that sample is.

Run from the repository root.  Idempotent.
"""

import os

import pandas as pd

RAW = "data/raw/pwt1001/pwt1001.xlsx"
OUT = "data/interim/b2_pwt.csv"
SOURCE = "pwt1001"

U_USD = "trillion 2017 USD at current PPPs"
U_POP = "million persons"


def main():
    d = pd.read_excel(RAW, sheet_name="Data")

    # The use split needs cgdpo and all five shares; the capital ratio needs cgdpo and cn.
    shares = ["csh_c", "csh_i", "csh_g", "csh_x", "csh_m", "csh_r"]
    use = d.dropna(subset=["cgdpo"] + shares).copy()
    for s in shares:
        use[s + "_lvl"] = use[s] * use["cgdpo"]
    u = use.groupby("year").agg(
        cgdpo=("cgdpo", "sum"),
        C=("csh_c_lvl", "sum"),
        G=("csh_i_lvl", "sum"),
        Gov=("csh_g_lvl", "sum"),
        X=("csh_x_lvl", "sum"),
        M=("csh_m_lvl", "sum"),
        Res=("csh_r_lvl", "sum"),
        n_use=("cgdpo", "size"),
    )

    cap = d.dropna(subset=["cgdpo", "cn"])
    k = cap.groupby("year").agg(cn=("cn", "sum"), cgdpo_k=("cgdpo", "sum"), n_cap=("cn", "size"))

    dep = d.dropna(subset=["cn", "delta"]).copy()
    dep["w"] = dep["cn"] * dep["delta"]
    dl = dep.groupby("year").agg(w=("w", "sum"), cn=("cn", "sum"))
    delta = dl["w"] / dl["cn"]

    pop = d.dropna(subset=["pop"]).groupby("year")["pop"].sum()

    # The world is closed, so exports, imports and the statistical discrepancy have no
    # counterpart in the model.  They are kept as a series so their size stays visible, and the
    # consumption/investment split is renormalised on C + Gov + I alone.
    absorption = u["C"] + u["Gov"] + u["G"]
    share_i = u["G"] / absorption
    share_c = (u["C"] + u["Gov"]) / absorption

    rows = []

    def add(series, values, unit, method="aggregated"):
        for y, v in values.items():
            if pd.notna(v):
                rows.append((int(y), series, float(v), unit, SOURCE, method))

    add("gdp_world_pwt", u["cgdpo"] / 1e6, U_USD)
    add("capital_world_pwt", k["cn"] / 1e6, U_USD)
    add("capital_output_ratio", k["cn"] / k["cgdpo_k"], "ratio")
    add("investment_share", share_i, "share")
    add("consumption_share", share_c, "share")
    add("share_household_consumption", u["C"] / u["cgdpo"], "share of cgdpo")
    add("share_government_consumption", u["Gov"] / u["cgdpo"], "share of cgdpo")
    add("share_gross_capital_formation", u["G"] / u["cgdpo"], "share of cgdpo")
    add("share_net_exports_and_residual", (u["X"] + u["M"] + u["Res"]) / u["cgdpo"], "share of cgdpo")
    add("depreciation_rate", delta, "per year")
    add("pop_world_pwt", pop, U_POP)
    add("n_countries_use_split", u["n_use"], "count")
    add("n_countries_capital", k["n_cap"], "count")

    out = pd.DataFrame(rows, columns=["year", "series", "value", "unit", "source", "method"])
    out = out.sort_values(["series", "year"]).reset_index(drop=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False, lineterminator="\n")

    y0, y1 = int(out["year"].min()), int(out["year"].max())
    print(f"b2_pwt: {len(out)} rows, {out['series'].nunique()} series, {y0}-{y1}; "
          f"countries {int(u['n_use'].iloc[0])}->{int(u['n_use'].iloc[-1])}; "
          f"K/Y {k['cn'].iloc[0] / k['cgdpo_k'].iloc[0]:.2f}->{k['cn'].iloc[-1] / k['cgdpo_k'].iloc[-1]:.2f} -> {OUT}")


if __name__ == "__main__":
    main()
