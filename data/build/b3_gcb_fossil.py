"""B3, source 4: fossil extraction mass from the Global Carbon Budget.

Input, downloaded by block B5 and read here rather than downloaded again:
data/raw/gcb/GCB2025v15_MtCO2_flat.csv, fossil CO2 by country, year and fuel,
1750-2024, in Mt CO2.  The "Global" rows are the world totals.

The model needs mass of fossil fuel extracted, not CO2.  The conversion is
    t fuel = t CO2 / (NCV [GJ/t] * carbon content [kg C/GJ] * (44/12) / 1000)
with NCV from Table 1.2 (p. 1.18) and carbon content from Table 1.3 (p. 1.21) of
IPCC (2006), 2006 IPCC Guidelines for National Greenhouse Gas Inventories,
Volume 2 (Energy), Chapter 1, transcribed below.  The IPCC default carbon
oxidation factor is 1 (Table 1.4, p. 1.23), which is what makes the arithmetic a
pure stoichiometric identity.

Two caveats, recorded here and in notes/data/resources.md rather than adjusted
for:
  * The GCB's CO2 is emitted carbon.  Carbon that leaves the wellhead but is
    stored in products (bitumen, lubricants, petrochemical feedstock) or is not
    oxidised never appears in it, so mass derived this way UNDERSTATES extraction,
    most of all for oil.
  * A single grade stands for each fuel.  Global coal is a mix whose average
    calorific value has drifted; the low and high variants below bracket it with
    lignite and anthracite.  Oil is priced at crude, gas at natural gas.

Run from the repository root:  python data/build/b3_gcb_fossil.py
"""

import os

import pandas as pd

RAW = os.path.join("data", "raw", "gcb", "GCB2025v15_MtCO2_flat.csv")
OUT = os.path.join("data", "interim", "b3_gcb_fossil.csv")
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

GCB = "gcb2025v15"
IPCC = "ipcc2006_v2_ch1"

# fuel -> (IPCC fuel used for the central factor, NCV TJ/Gg = GJ/t, carbon kg/GJ)
# The low and high variants are alternative IPCC grades, not confidence bounds.
FACTORS = {
    "Coal": {
        "central": ("Other Bituminous Coal", 25.8, 25.8),
        "low": ("Anthracite", 26.7, 26.8),
        "high": ("Lignite", 11.9, 27.6),
    },
    "Oil": {
        "central": ("Crude Oil", 42.3, 20.0),
        "low": ("Residual Fuel Oil", 40.4, 21.1),
        "high": ("Natural Gas Liquids", 44.2, 17.5),
    },
    "Gas": {
        "central": ("Natural Gas", 48.0, 15.3),
        "low": ("Natural Gas", 48.0, 15.9),   # upper carbon content, Table 1.3
        "high": ("Natural Gas", 48.0, 14.8),  # lower carbon content, Table 1.3
    },
}
CO2_PER_C = 44.0 / 12.0


def co2_per_tonne(ncv_gj_per_t, carbon_kg_per_gj):
    """Tonnes of CO2 released by full oxidation of one tonne of fuel."""
    return ncv_gj_per_t * carbon_kg_per_gj * CO2_PER_C / 1000.0


def main():
    raw = pd.read_csv(RAW)
    world = raw[raw["Country"] == "Global"].copy()
    rows = []
    for fuel, variants in FACTORS.items():
        series_co2 = pd.to_numeric(world[fuel], errors="coerce")
        for year, mt_co2 in zip(world["Year"], series_co2):
            if pd.isna(mt_co2):
                continue
            rows.append(
                dict(year=int(year), series="fossil_co2", commodity=fuel.lower(),
                     value=float(mt_co2), unit="Mt_CO2", source=GCB,
                     method="observed")
            )
            for variant, (grade, ncv, carbon) in variants.items():
                factor = co2_per_tonne(ncv, carbon)
                rows.append(
                    dict(year=int(year),
                         series="fossil_mass_" + variant,
                         commodity=fuel.lower(),
                         value=float(mt_co2) / factor / 1000.0,
                         unit="Gt",
                         source="{}+{}".format(GCB, IPCC),
                         method="derived")
                )
    # The conversion factors themselves, so the interim file is self-contained.
    for fuel, variants in FACTORS.items():
        for variant, (grade, ncv, carbon) in variants.items():
            rows.append(
                dict(year=2006, series="co2_per_tonne_fuel_" + variant,
                     commodity=fuel.lower(),
                     value=co2_per_tonne(ncv, carbon),
                     unit="t_CO2_per_t_fuel ({})".format(grade),
                     source=IPCC, method="transcribed")
            )
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["series", "commodity", "year"]
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    mass = out[out["series"] == "fossil_mass_central"]
    print(
        "b3_gcb_fossil: {} rows, global fossil CO2 and derived mass by fuel "
        "{}-{}; central factors t CO2/t fuel: {} -> {}".format(
            len(out),
            int(mass["year"].min()),
            int(mass["year"].max()),
            ", ".join(
                "{} {:.3f}".format(f, co2_per_tonne(*FACTORS[f]["central"][1:]))
                for f in FACTORS
            ),
            OUT,
        )
    )


if __name__ == "__main__":
    main()
