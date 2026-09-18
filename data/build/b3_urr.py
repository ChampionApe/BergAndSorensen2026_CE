"""B3, source 6: ultimately recoverable resources, transcribed with citations.

Fossil fuels.  Rogner, H.-H., and others, 2012, "Energy resources and
potentials", chapter 7 of Global Energy Assessment -- Toward a Sustainable
Future: Cambridge University Press and IIASA, pp. 423-512.  Table 7.1, p. 431,
gives historical production through 2005, 2005 production, reserves, resources
and additional occurrences in EJ for conventional and unconventional oil and
gas, coal and uranium.  Reserves and resources are ranges; resources exclude
reserves and are not cumulative.  Energy is converted to mass with the same IPCC
(2006) net calorific values used in b3_gcb_fossil.py: 1 EJ = 1e9 GJ and the NCV
is in GJ per tonne, so one EJ is 1/NCV gigatonnes of fuel.

Metals and minerals.  The crustal-abundance route (Rankin, A.J., 2011, Minerals,
Metals and Sustainability, CSIRO Publishing) could not be obtained -- a
paywalled book -- and is recorded MANUAL in data/SOURCES.md, block B3.  What
is used instead is the USGS Global Mineral Resource Assessment as the Mineral
Commodity Summaries 2026 reports it commodity by commodity; those figures are in
data/interim/b3_usgs_mcs.csv under identified_resources and
undiscovered_resources, and are combined with reserves in
b3_resource_block.py.  The one range the report states directly, bauxite
resources of 55 to 75 billion tonnes, is recorded here so that its high end is
not lost.

BGR's Energy Study, the second fossil source the plan asks for, could not be
downloaded: every bgr.bund.de and deutsche-rohstoffagentur.de URL answered
HTTP 400 or 404 from this machine.  Recorded MANUAL.

Run from the repository root:  python data/build/b3_urr.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b3_urr.csv")
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

GEA = "rogner2012_gea_ch7:table7.1_p431"
MCS = "usgs_mcs2026"

# Table 7.1, p. 431, in EJ.  None where the table leaves the cell blank.
# (commodity, historical production through 2005, production 2005,
#  reserves low, reserves high, resources low, resources high, occurrences)
GEA_TABLE_7_1 = [
    ("conventional_oil", 6069, 147.9, 4900, 7610, 4170, 6150, None),
    ("unconventional_oil", 513, 20.2, 3750, 5600, 11280, 14800, 40000),
    ("conventional_gas", 3087, 89.8, 5000, 7100, 7200, 8900, None),
    ("unconventional_gas", 113, 9.6, 20100, 67100, 40200, 121900, 1000000),
    ("coal", 6712, 123.8, 17300, 21000, 291000, 435000, None),
    ("conventional_uranium", 1218, 24.7, 2400, 2400, 7400, 7400, None),
    ("unconventional_uranium", 34, None, 7100, 7100, None, None, 2600000),
]
# Net calorific value, GJ per tonne, IPCC (2006) Vol. 2 Ch. 1 Table 1.2 p. 1.18.
# Used only for the three fuels the model's fossil category contains.
NCV = {"oil": 42.3, "gas": 48.0, "coal": 25.8}
FUEL_OF = {
    "conventional_oil": "oil", "unconventional_oil": "oil",
    "conventional_gas": "gas", "unconventional_gas": "gas", "coal": "coal",
}

BAUXITE_RESOURCE_RANGE = (55e9, 75e9)  # tonnes gross weight, MCS 2026 p. 51


def main():
    rows = []
    for (commodity, hist, prod, res_lo, res_hi, rsr_lo, rsr_hi,
         occurrence) in GEA_TABLE_7_1:
        entries = [
            ("historical_production_to_2005", hist),
            ("production_2005", prod),
            ("reserves_low", res_lo),
            ("reserves_high", res_hi),
            ("resources_low", rsr_lo),
            ("resources_high", rsr_hi),
            ("additional_occurrences", occurrence),
        ]
        for series, value in entries:
            if value is None:
                continue
            rows.append(dict(year=2005, series=series, commodity=commodity,
                             value=float(value), unit="EJ", source=GEA,
                             method="transcribed"))
            fuel = FUEL_OF.get(commodity)
            if fuel is not None:
                rows.append(dict(
                    year=2005, series=series + "_mass", commodity=commodity,
                    value=float(value) / NCV[fuel],
                    unit="Gt", source=GEA + "+ipcc2006_v2_ch1_table1.2",
                    method="derived"))
    for label, value in zip(("low", "high"), BAUXITE_RESOURCE_RANGE):
        rows.append(dict(year=2025, series="resources_" + label,
                         commodity="bauxite", value=float(value),
                         unit="t_gross_weight", source=MCS + ":p51",
                         method="transcribed"))
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(["commodity", "series"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print(
        "b3_urr: {} rows from Rogner and others (2012) Table 7.1 (EJ, with mass "
        "derived for coal, oil and gas) and the MCS bauxite resource range; "
        "BGR and Rankin MANUAL -> {}".format(len(out), OUT)
    )


if __name__ == "__main__":
    main()
