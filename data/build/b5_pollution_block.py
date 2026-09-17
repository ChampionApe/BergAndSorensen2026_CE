"""The pollution block of the calibration, under decision D4 strategy (B).

Joins the four B5 source files into the series and the scalars the calibration needs:

  * annual fossil CO2 by fuel, global, 1750 to the latest year, in gigatonnes CO2;
  * cumulative CO2 from 1750 and from 1900, by fuel and in total;
  * the atmospheric excess stock implied by applying the Joos et al. (2013) impulse
    response to the emission path, year by year;
  * P0 at 1900 under both readings, cumulative and impulse-response;
  * the fit of the model's one-stock decay theta(P) to the Joos impulse response;
  * the damage ingredients, and the kappa arithmetic proposed for phase C.

inputs   data/interim/b5_gcb.csv, b5_joos2013.csv, b5_dice2023.csv, b5_ipcc_ar6.csv
out      data/interim/b5_pollution_block.csv   (year, series, value, unit, source, method)

Run from the repository root:  PYTHONUTF8=1 python data/build/b5_pollution_block.py

THE DECAY FIT.  The model's pollution stock follows

    P_{t+1} = P_t + Xi_t - theta(P_t) P_t,
    theta(P) = theta_min + (theta_0 - theta_min) exp(-theta_P P),

so with Xi = 0 the retained share of a stock of size P_ref after t years is the path of
P_t / P_ref from P_0 = P_ref. That path is fitted to the Joos et al. multi-model mean
impulse response over 0 to 300 years by least squares on the retained share. One
regenerating stock with a floor is not a carbon cycle, and the fit cannot be good: the
carbon cycle removes fast at first and slowly later, whereas theta' < 0 makes the model
remove slowly while the stock is large and faster as it shrinks. The fitted parameters and
the fit error are recorded as an approximation, and the best constant-theta fit is recorded
beside them as the benchmark that says how much the state dependence buys.

THE KAPPA ARITHMETIC.  The model loses output by the factor exp(-kappa P); DICE-2023 loses
the share Omega = pi2 T^2 of gross output, and the TCRE maps cumulative CO2 to temperature
linearly, T = tcre * P. Equating the two at a reference stock P_ref gives

    kappa_level    = -ln(1 - pi2 (tcre P_ref)^2) / P_ref               (same loss at P_ref)
    kappa_marginal = 2 pi2 tcre^2 P_ref / (1 - pi2 (tcre P_ref)^2)     (same marginal loss)

which differ because the model's loss is exponential in P and DICE's is quadratic; they
agree at one point and nowhere else. Both are written out at two reference stocks, as a
proposal for phase C to choose from, not as a choice made here.
"""

import math
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
INTERIM = ROOT / "data" / "interim"
OUT = INTERIM / "b5_pollution_block.csv"

BASE_YEAR = 1900  # decision D2
RHO = 0.015  # the illustrative rate of model/src/calibration.jl, for the no-tipping check
FIT_HORIZON = 300  # years over which the decay fit is scored

FUEL_SERIES = [
    "co2_fossil_coal",
    "co2_fossil_oil",
    "co2_fossil_gas",
    "co2_cement_process",
    "co2_flaring",
    "co2_other_carbonates",
]
# The fuels proper, without the carbonate process emissions, which the material block
# reaches through cement and lime rather than through fossil energy carriers.
FUELS_ONLY = ["co2_fossil_coal", "co2_fossil_oil", "co2_fossil_gas", "co2_flaring"]


def read(name):
    path = INTERIM / name
    if not path.exists():
        sys.exit("missing " + str(path) + "; run the per-source b5 scripts first")
    return pd.read_csv(path)


def scalar(frame, series):
    row = frame.loc[frame["series"] == series]
    if len(row) != 1:
        sys.exit("expected exactly one row for " + series)
    return float(row["value"].iloc[0])


def irf_factory(joos):
    a0 = scalar(joos, "irf_co2_a0")
    a = [scalar(joos, "irf_co2_a" + str(i)) for i in (1, 2, 3)]
    tau = [scalar(joos, "irf_co2_tau" + str(i)) for i in (1, 2, 3)]

    def irf(t):
        return a0 + sum(ai * math.exp(-t / ti) for ai, ti in zip(a, tau))

    return irf


def decay_path(theta0, theta_min, thetaP, p_ref, horizon):
    """Retained share of a stock of size p_ref after 0, 1, ... horizon years, Xi = 0."""
    share = [1.0]
    p = p_ref
    for _ in range(horizon):
        theta = theta_min + (theta0 - theta_min) * math.exp(-thetaP * p)
        p = max(p * (1.0 - theta), 0.0)
        share.append(p / p_ref)
    return share


def nelder_mead(f, x0, step=0.5, tol=1e-10, max_iter=20000):
    """Minimise f over a small vector. Kept here so the block needs only pandas."""
    n = len(x0)
    simplex = [list(x0)]
    for i in range(n):
        point = list(x0)
        point[i] += step
        simplex.append(point)
    values = [f(p) for p in simplex]
    for _ in range(max_iter):
        order = sorted(range(n + 1), key=lambda i: values[i])
        simplex = [simplex[i] for i in order]
        values = [values[i] for i in order]
        if abs(values[-1] - values[0]) < tol * (abs(values[0]) + tol):
            break
        centroid = [sum(p[i] for p in simplex[:-1]) / n for i in range(n)]
        worst = simplex[-1]
        reflected = [centroid[i] + (centroid[i] - worst[i]) for i in range(n)]
        f_reflected = f(reflected)
        if f_reflected < values[0]:
            expanded = [centroid[i] + 2.0 * (centroid[i] - worst[i]) for i in range(n)]
            f_expanded = f(expanded)
            if f_expanded < f_reflected:
                simplex[-1], values[-1] = expanded, f_expanded
            else:
                simplex[-1], values[-1] = reflected, f_reflected
        elif f_reflected < values[-2]:
            simplex[-1], values[-1] = reflected, f_reflected
        else:
            contracted = [centroid[i] + 0.5 * (worst[i] - centroid[i]) for i in range(n)]
            f_contracted = f(contracted)
            if f_contracted < values[-1]:
                simplex[-1], values[-1] = contracted, f_contracted
            else:
                best = simplex[0]
                simplex = [best] + [
                    [best[i] + 0.5 * (p[i] - best[i]) for i in range(n)]
                    for p in simplex[1:]
                ]
                values = [f(p) for p in simplex]
    order = sorted(range(n + 1), key=lambda i: values[i])
    return simplex[order[0]], values[order[0]]


def fit_theta(target, p_ref, horizon):
    """Fit (theta_0, theta_min, theta_P) to the target retained-share path."""

    def unpack(x):
        theta_min = math.exp(x[0])
        gap = math.exp(x[1])
        thetaP = math.exp(x[2])
        return theta_min + gap, theta_min, thetaP

    def sse(x):
        theta0, theta_min, thetaP = unpack(x)
        if not (0.0 < theta_min < theta0 < 0.999):
            return 1e6
        path = decay_path(theta0, theta_min, thetaP, p_ref, horizon)
        return sum((m - g) ** 2 for m, g in zip(path, target))

    best = None
    for start in (
        (math.log(0.002), math.log(0.02), math.log(1.0 / p_ref)),
        (math.log(0.0005), math.log(0.05), math.log(5.0 / p_ref)),
        (math.log(0.01), math.log(0.005), math.log(0.2 / p_ref)),
        (math.log(0.003), math.log(0.3), math.log(20.0 / p_ref)),
    ):
        x, value = nelder_mead(sse, start)
        if best is None or value < best[1]:
            best = (x, value)
    theta0, theta_min, thetaP = unpack(best[0])
    path = decay_path(theta0, theta_min, thetaP, p_ref, horizon)
    errors = [m - g for m, g in zip(path, target)]
    rmse = math.sqrt(sum(e * e for e in errors) / len(errors))
    return theta0, theta_min, thetaP, rmse, max(abs(e) for e in errors), path


def fit_constant_theta(target, horizon):
    """The best single constant decay rate over the same horizon, as a benchmark."""

    def sse(x):
        theta = math.exp(x[0])
        if not (0.0 < theta < 0.999):
            return 1e6
        path = [(1.0 - theta) ** t for t in range(horizon + 1)]
        return sum((m - g) ** 2 for m, g in zip(path, target))

    x, _ = nelder_mead(sse, (math.log(0.004),), step=0.3)
    theta = math.exp(x[0])
    path = [(1.0 - theta) ** t for t in range(horizon + 1)]
    errors = [m - g for m, g in zip(path, target)]
    rmse = math.sqrt(sum(e * e for e in errors) / len(errors))
    return theta, rmse, max(abs(e) for e in errors)


def main():
    gcb = read("b5_gcb.csv")
    joos = read("b5_joos2013.csv")
    dice = read("b5_dice2023.csv")
    ar6 = read("b5_ipcc_ar6.csv")

    annual = gcb.loc[gcb["year"] != ""].copy()
    annual = annual.dropna(subset=["year"])
    annual["year"] = annual["year"].astype(int)
    wide = annual.pivot_table(index="year", columns="series", values="value")
    wide = wide.reindex(range(int(wide.index.min()), int(wide.index.max()) + 1)).fillna(0.0)
    gcb_source = str(gcb.loc[gcb["series"] == "co2_fossil_total", "source"].iloc[0])
    joos_source = str(joos["source"].iloc[0])

    rows = []

    def add(year, series, value, unit, source, method):
        rows.append(
            {
                "year": year,
                "series": series,
                "value": value,
                "unit": unit,
                "source": source,
                "method": method,
            }
        )

    # 1. The annual series by fuel, carried through unchanged.
    for name in ["co2_fossil_total"] + FUEL_SERIES:
        for year, value in wide[name].items():
            add(year, name, value, "GtCO2", gcb_source, "observed")
    fuels_only = wide[FUELS_ONLY].sum(axis=1)
    for year, value in fuels_only.items():
        add(year, "co2_fossil_fuels_only", value, "GtCO2", gcb_source, "derived")

    # 2. Cumulative CO2 from 1750 and from 1900.
    cumulative = {}
    for name, column in (
        ("co2_fossil_total", wide["co2_fossil_total"]),
        ("co2_fossil_fuels_only", fuels_only),
    ):
        from_1750 = column.cumsum()
        cumulative[name] = from_1750
        for year, value in from_1750.items():
            add(year, "cum_" + name + "_from_1750", value, "GtCO2", gcb_source, "derived")
        post = column.loc[column.index >= BASE_YEAR].cumsum()
        for year, value in post.items():
            add(year, "cum_" + name + "_from_1900", value, "GtCO2", gcb_source, "derived")

    # 3. The atmospheric excess stock implied by the Joos impulse response, year by year.
    #    A_t = sum_{s < t} E_s IRF(t - s): the stock at the beginning of year t left by all
    #    emissions up to the end of year t-1. The impulse response is the one fitted to a
    #    100 GtC pulse on a present-day background, applied here to the whole path, which
    #    is an approximation the note records.
    irf = irf_factory(joos)
    years = list(wide.index)
    emissions = list(wide["co2_fossil_total"].values)
    memory = [irf(h) for h in range(len(years) + 1)]
    excess = []
    for i, year in enumerate(years):
        excess.append(sum(emissions[j] * memory[i - j] for j in range(i)))
        add(year, "atm_excess_co2_fossil_irf", excess[-1], "GtCO2", joos_source, "derived")

    # 4. P0 at 1900 under both readings. Stocks dated t are measured at the beginning of
    #    period t, so P_1900 is what emissions through 1899 leave behind.
    index_1900 = years.index(BASE_YEAR)
    p0_cumulative = float(cumulative["co2_fossil_total"].loc[BASE_YEAR - 1])
    p0_fuels = float(cumulative["co2_fossil_fuels_only"].loc[BASE_YEAR - 1])
    p0_irf = excess[index_1900]
    add("", "P0_1900_cumulative_since_1750", p0_cumulative, "GtCO2", gcb_source, "derived")
    add("", "P0_1900_cumulative_fuels_only", p0_fuels, "GtCO2", gcb_source, "derived")
    add("", "P0_1900_irf_excess_stock", p0_irf, "GtCO2", joos_source, "derived")

    # 5. The decay fit, scored on the retained share of a stock the size of the cumulative
    #    fossil CO2 emitted to date, which is the stock the model is calibrated around.
    p_ref = float(cumulative["co2_fossil_total"].iloc[-1])
    add("", "P_ref_cumulative_fossil_co2_to_latest", p_ref, "GtCO2", gcb_source, "derived")
    target = [irf(t) for t in range(FIT_HORIZON + 1)]
    theta0, theta_min, thetaP, rmse, max_error, path = fit_theta(target, p_ref, FIT_HORIZON)
    fit_source = joos_source + "; fitted by data/build/b5_pollution_block.py"
    add("", "theta0", theta0, "per year", fit_source, "fitted")
    add("", "theta_min", theta_min, "per year", fit_source, "fitted")
    add("", "thetaP", thetaP, "per GtCO2", fit_source, "fitted")
    add("", "theta_fit_rmse", rmse, "retained share", fit_source, "fitted")
    add("", "theta_fit_max_abs_error", max_error, "retained share", fit_source, "fitted")
    add("", "theta_fit_horizon", FIT_HORIZON, "years", fit_source, "fitted")
    add("", "theta_fit_retained_share_at_100yr", path[100], "retained share", fit_source, "fitted")
    add("", "theta_fit_retained_share_at_300yr", path[300], "retained share", fit_source, "fitted")
    add("", "irf_retained_share_at_100yr", target[100], "retained share", joos_source, "evaluated")
    add("", "irf_retained_share_at_300yr", target[300], "retained share", joos_source, "evaluated")

    theta_const, rmse_const, max_const = fit_constant_theta(target, FIT_HORIZON)
    add("", "theta_constant_benchmark", theta_const, "per year", fit_source, "fitted")
    add("", "theta_constant_rmse", rmse_const, "retained share", fit_source, "fitted")
    add("", "theta_constant_max_abs_error", max_const, "retained share", fit_source, "fitted")

    # What the state dependence buys over a constant decay rate. It is zero to the
    # optimiser's tolerance, because theta' < 0 has the wrong sign for a carbon cycle: the
    # exponential term can only raise the decay rate as the stock shrinks, so the fit sets
    # thetaP high enough that exp(-thetaP P) is numerically zero over the whole path and
    # theta_0 is then not identified by this experiment at all.
    add("", "theta_fit_rmse_gain_over_constant", rmse_const - rmse, "retained share", fit_source, "derived")
    add("", "theta0_identified_by_this_fit", 0.0, "indicator", fit_source, "derived")

    # The sufficient no-tipping condition of the workhorse appendix, at the illustrative rho.
    margin = RHO + theta_min - (theta0 - theta_min) / math.e
    add("", "notipping_margin_at_rho_0.015", margin, "per year", fit_source, "derived")
    add("", "notipping_holds_at_rho_0.015", 1.0 if margin >= 0.0 else 0.0, "indicator", fit_source, "derived")
    # Since theta_0 is unidentified, the condition is a restriction on the reported value
    # rather than a test the data can fail: any theta_0 up to this ceiling fits equally well.
    theta0_max = theta_min + math.e * (RHO + theta_min)
    add("", "theta0_max_under_notipping_at_rho_0.015", theta0_max, "per year", fit_source, "derived")

    # A driven check of the same decay rate: run the model's own transition on the observed
    # emission path from the first year of the data and compare the stock it leaves in the
    # last year with the impulse-response stock and with the published atmospheric growth.
    def driven_stock(theta, upto=None):
        p = 0.0
        stocks = []
        for value in emissions[: upto if upto is not None else len(emissions)]:
            stocks.append(p)
            p = p + value - theta * p
        return p, stocks

    p_driven, _ = driven_stock(theta_min)
    target_stock = excess[-1] + emissions[-1] * irf(0.0)
    add("", "P_latest_model_with_fitted_theta", p_driven, "GtCO2", fit_source, "derived")
    add("", "P_latest_irf_excess_stock", target_stock, "GtCO2", joos_source, "derived")

    # The same decay rate identified the other way round: the constant theta for which the
    # observed emission path, run through the model's own transition, leaves the stock the
    # impulse response says it leaves. This is what the historical record identifies, and it
    # is the number phase C should weigh against the pulse fit above.
    lo, hi = 0.0, 0.5
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if driven_stock(mid)[0] > target_stock:
            lo = mid
        else:
            hi = mid
    theta_driven = 0.5 * (lo + hi)
    p_final, stocks = driven_stock(theta_driven)
    add("", "theta_constant_driven_to_irf_stock", theta_driven, "per year", fit_source, "fitted_driven")
    add("", "P_latest_model_driven_theta", p_final, "GtCO2", fit_source, "derived")
    add("", "P0_1900_model_driven_theta", stocks[index_1900], "GtCO2", fit_source, "derived")

    # 6. The damage ingredients and the kappa arithmetic.
    pi2 = scalar(dice, "dice2023_pi2")
    dice_source = str(dice.loc[dice["series"] == "dice2023_pi2", "source"].iloc[0])
    ar6_source = str(ar6.loc[ar6["series"] == "tcre_best", "source"].iloc[0])
    tcre = {
        "best": scalar(ar6, "tcre_best"),
        "low": scalar(ar6, "tcre_low"),
        "high": scalar(ar6, "tcre_high"),
    }
    add("", "damage_pi2", pi2, "fraction of gross output per degC^2", dice_source, "derived")
    for name, value in tcre.items():
        add("", "damage_tcre_" + name, value, "degC per GtCO2", ar6_source, "published")

    # The TCRE maps cumulative *total* anthropogenic CO2 to temperature, while P under
    # strategy (B) is cumulative *fossil* CO2. The gap is the fossil share of cumulative
    # emissions, carried through from the Global Carbon Budget, and the temperature the
    # TCRE assigns to the fossil stock alone, which is well below observed warming.
    fossil_share = gcb.loc[
        gcb["series"] == "fossil_share_of_cumulative_co2_1750_2024", "value"
    ]
    if len(fossil_share) == 1:
        add(
            "",
            "fossil_share_of_cumulative_co2",
            float(fossil_share.iloc[0]),
            "fraction",
            str(gcb.loc[gcb["series"] == "fossil_share_of_cumulative_co2_1750_2024", "source"].iloc[0]),
            "published",
        )
    add(
        "",
        "implied_temperature_at_latest_fossil_cumulative_tcre_best",
        tcre["best"] * p_ref,
        "degC",
        ar6_source,
        "derived",
    )

    reference_stocks = {
        "at_latest_cumulative_fossil_co2": p_ref,
        "at_3degC_under_best_tcre": 3.0 / tcre["best"],
    }
    proposal = dice_source + " with " + ar6_source + "; arithmetic in this script"
    for label, stock in reference_stocks.items():
        add("", "kappa_reference_stock_" + label, stock, "GtCO2", proposal, "proposal_phaseC")
        for tag, rate in tcre.items():
            loss = pi2 * (rate * stock) ** 2
            if loss >= 1.0:
                continue
            add(
                "",
                "kappa_level_" + label + "_tcre_" + tag,
                -math.log(1.0 - loss) / stock,
                "per GtCO2",
                proposal,
                "proposal_phaseC",
            )
            add(
                "",
                "kappa_marginal_" + label + "_tcre_" + tag,
                2.0 * pi2 * rate ** 2 * stock / (1.0 - loss),
                "per GtCO2",
                proposal,
                "proposal_phaseC",
            )
            add(
                "",
                "damage_output_loss_" + label + "_tcre_" + tag,
                loss,
                "fraction of gross output",
                proposal,
                "derived",
            )

    # DICE-2023 has no utility damage channel: all damages are a loss of gross output.
    add("", "psi_v", 0.0, "utility per GtCO2^(1+varphi)", dice_source, "set_by_source")
    add("", "varphi", float("nan"), "exponent", dice_source, "undefined_when_psi_zero")

    out = pd.DataFrame(rows)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT, index=False, float_format="%.9g")

    print(
        "b5_pollution_block: {} rows, fossil CO2 {}-{}; P0(1900) = {:.2f} GtCO2 cumulative "
        "and {:.2f} GtCO2 as an impulse-response stock; theta fit "
        "(theta0 {:.4g}, theta_min {:.4g}, thetaP {:.4g} per GtCO2) rmse {:.4f}, max error "
        "{:.4f}, no-tipping margin {:+.4f} at rho = {} -> {}".format(
            len(out),
            years[0],
            years[-1],
            p0_cumulative,
            p0_irf,
            theta0,
            theta_min,
            thetaP,
            rmse,
            max_error,
            margin,
            RHO,
            OUT.relative_to(ROOT),
        )
    )


if __name__ == "__main__":
    main()
