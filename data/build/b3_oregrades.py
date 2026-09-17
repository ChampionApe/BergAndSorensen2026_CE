"""B3, source 5: ore grades and energy per tonne, transcribed from the literature.

This block is a literature assembly, not a download.  The three papers report
their grade and energy evidence mostly in figures; only what the papers print as
a number -- in a table, or in the running text -- is recorded here, with the
citation, the table or page, and method = transcribed.  Nothing is read off a
figure.

  Calvo, G., Mudd, G., Valero, Al., and Valero, An., 2016, "Decreasing ore
  grades in global metallic mining: a theoretical issue or a global reality?":
  Resources, v. 5, no. 4, art. 36.  Table 1 (pp. 5-6) gives, per mine, average
  electricity use per tonne of ore and diesel per tonne of rock over a stated
  period.  The text (pp. 9-10) gives average total energy per tonne of metal and
  average ore grades.

  Mudd, G.M., 2010, "The environmental sustainability of mining in Australia:
  key mega-trends and looming constraints": Resources Policy, v. 35, no. 2,
  pp. 98-115.  Table 1 (p. 102) gives cumulative Australian production by
  mineral; Table 2 (p. 106) economic resources, production and years remaining
  at 2008; Table 3 (p. 107) weighted-average energy, water, greenhouse and
  cyanide intensity for gold and uranium.  Figure 8 (p. 107) prints its own
  regression of gold energy intensity on grade, which is a number and is
  recorded; the grade time series of Figures 3 and 7 are not.

  West, J., 2011, "Decreasing metal ore grades: are they really being driven by
  the depletion of high-grade deposits?": Journal of Industrial Ecology, v. 15,
  no. 2, pp. 165-168.  Not obtained (paywalled); recorded MANUAL in
  data/sources/B3_resources.md.  It is a four-page commentary on Mudd and
  carries no tabulated series.

The year column is the midpoint of the reporting period where the source gives a
period, and the publication year for a cross-sectional or whole-sample figure;
the period itself is kept in the unit string so that nothing is lost.

Run from the repository root:  python data/build/b3_oregrades.py
"""

import os

import pandas as pd

OUT = os.path.join("data", "interim", "b3_oregrades.csv")
COLUMNS = ["year", "series", "commodity", "value", "unit", "source", "method"]

CALVO = "calvo2016_resources_5_36"
MUDD = "mudd2010_resources_policy_35_98"

# Calvo and others (2016), Table 1, pp. 5-6.
# (mine, main metals, mine type, kWh/t ore, L diesel/t rock, period start, end)
CALVO_TABLE1 = [
    ("granny_smith", "au", "OC+UG", 199, 2.5, 1989, 2013),
    ("agnew", "au", "OC+UG", 43, 0.6, 1991, 2009),
    ("st_ives", "au", "OC+UG", 31, 1.5, 1991, 2009),
    ("darlot", "au", "UG", 80, None, 1993, 2007),
    ("cadia_valley", "cu_au", "OC", 53, None, 2004, 2009),
    ("ernest_henry", "cu_au", "OC", 49, None, 1998, 2007),
    ("mount_isa_cu", "cu_ag", "UG", 81, 1.1, 2005, 2012),
    ("prominent_hill", "cu_ag", "OC", 64, 0.5, 2009, 2014),
    ("olympic_dam", "cu_u_ag_au", "UG", 107, 2.8, 1991, 2014),
    ("telfer", "cu_au", "OC+UG", 124, None, 2005, 2009),
    ("mcarthur_river", "zn_pb_ag", "OC+UG", 60, None, 2006, 2010),
    ("century", "zn_pb_ag", "OC", 120, None, 2009, 2014),
    ("golden_grove", "zn_cu_ag_au", "UG", 55, None, 2009, 2014),
    ("rosebery", "zn_pb_cu_ag_au", "UG", 62, None, 2009, 2014),
    ("mantos_blancos", "cu", "OC", 15, None, 2002, 2014),
    ("el_soldado", "cu", "OC+UG", 28, 0.4, 2002, 2014),
    ("mantoverde", "cu", "OC", 12, 0.7, 2002, 2014),
    ("el_tesoro", "cu", "OC", 31, 0.3, 2007, 2014),
    ("michilla", "cu", "OC+UG", 34, 0.5, 2007, 2014),
    ("escondida", "cu", "OC", 31, 0.7, 2001, 2014),
    ("radomiro_tomic", "cu", "OC", 13, 1.5, 2011, 2013),
    ("collahuasi", "cu_mo", "OC", 20, 1.4, 2002, 2014),
    ("los_pelambres", "cu_mo", "OC", 27, 0.4, 2007, 2014),
    ("chuquicamata", "cu_mo", "OC", 46, 1.2, 2000, 2013),
    ("los_bronces", "cu_mo", "OC", 20, 0.9, 2002, 2014),
    ("division_andina", "cu_mo_ag", "OC+UG", 25, 1.9, 2001, 2013),
    ("salvador", "cu_mo_ag_au", "OC+UG", 34, 0.8, 2001, 2013),
    ("el_teniente", "cu_mo_ag_au", "UG", 39, None, 2001, 2013),
    ("sepon", "cu_au", "OC", 100, 2.3, 2008, 2014),
    ("el_porvenir", "zn_pb_cu", "UG", 53, None, 2008, 2013),
    ("cerro_lindo", "zn_pb_cu", "UG", 29, None, 2008, 2013),
    ("neves_corvo", "zn_cu_pb_ag", "UG", 71, 0.6, 2007, 2014),
    ("aguablanca", "ni_cu", "OC", 44, 0.5, 2007, 2014),
    ("zinkgruvan", "zn_pb_cu_ag", "UG", 75, 1.0, 2007, 2014),
    ("bingham_canyon", "cu_au", "OC", 112, None, 2003, 2007),
]

# Calvo and others (2016), running text, pp. 9-10.
CALVO_TEXT = [
    (2016, "average_total_energy_per_tonne_metal", "copper", 28.2, "GJ_per_t",
     "p9, sample average over the mines of Table 1"),
    (2016, "average_total_energy_per_tonne_metal", "zinc", 11.03, "GJ_per_t",
     "p9"),
    (2016, "average_total_energy_per_tonne_metal", "gold", 145888.0, "GJ_per_t",
     "p9"),
    (2016, "average_ore_grade", "gold", 5.26, "g_per_t", "p10, mines analysed"),
    (2016, "average_ore_grade", "zinc", 9.6, "percent", "p10, mines analysed"),
    (2016, "average_ore_grade", "lead", 3.4, "percent", "p10, mines analysed"),
    (2016, "average_ore_grade", "copper", 1.48, "percent",
     "p10, 25 copper mines analysed, about 32 percent of 2009 world production"),
    (1990, "average_ore_grade", "copper", 1.67, "percent",
     "p10, quoting Cox and Singer for about 1990"),
    (2013, "ore_grade_change_2003_2013", "copper", -25.0, "percent",
     "p10, combined weighted average decline across the mines analysed, "
     "2003 to 2013"),
    (2013, "ore_grade_change_2003_2013", "copper_el_soldado", -72.9, "percent",
     "p10, El Soldado oxide ore 1.7 percent in 2003 to 0.46 percent in 2012"),
]

# Mudd (2010), Table 1, p. 102: cumulative Australian production to 2008.
MUDD_TABLE1 = [
    ("bauxite", 1480.0, "Mt", 1927), ("black_coal_raw", 8947.0, "Mt", 1829),
    ("brown_coal_raw", 2193.0, "Mt", 1889), ("copper", 20473.0, "kt", 1842),
    ("gold", 11777.0, "t", 1851), ("iron_ore", 5298.0, "Mt", 1889),
    ("lead", 37945.0, "kt", 1850), ("manganese_ore", 81599.0, "kt", 1946),
    ("nickel", 4467.7, "kt", 1967), ("silver", 78435.0, "t", 1870),
    ("tin", 814.7, "kt", 1870), ("uranium", 184714.0, "t_u3o8", 1906),
    ("zinc", 48465.0, "kt", 1883), ("ilmenite", 47050.0, "kt_concentrate", 1934),
    ("rutile", 12531.0, "kt_concentrate", 1934),
    ("zircon", 19901.0, "kt_concentrate", 1934),
]
# Mudd (2010), Table 2, p. 106: economic resources and 2008 production.
MUDD_TABLE2 = [
    ("bauxite", 64.63, "Mt", 6200.0, "Mt"), ("black_coal", 430.5, "Mt", 39200.0, "Mt"),
    ("brown_coal", 66.03, "Mt", 37200.0, "Mt"), ("copper", 886.0, "kt", 77.8, "Mt"),
    ("gold", 214.0, "t", 6255.0, "t"), ("iron_ore", 341.7, "Mt", 24000.0, "Mt"),
    ("manganese_ore", 4.84, "Mt", 181.0, "Mt"), ("lead", 645.0, "kt", 28.8, "Mt"),
    ("nickel", 200.0, "kt", 26.4, "Mt"), ("silver", 1926.0, "t", 63.4, "kt"),
    ("uranium", 9989.0, "t_u3o8", 1371.0, "kt_u3o8"),
    ("zinc", 1519.0, "kt", 57.6, "Mt"),
]
# Mudd (2010), Table 3, p. 107, and the Figure 8 regression on the same page.
MUDD_INTENSITY = [
    (2010, "energy_intensity", "gold", 149.0, "GJ_per_kg_Au",
     "Table 3, weighted average, standard deviation 105"),
    (2010, "energy_intensity", "uranium", 273.0, "GJ_per_t_U3O8",
     "Table 3, weighted average excluding Olympic Dam, standard deviation 124"),
    (2010, "water_intensity", "gold", 634.9, "kL_per_kg_Au",
     "Table 3, standard deviation 1208"),
    (2010, "water_intensity", "uranium", 1753.0, "kL_per_t_U3O8",
     "Table 3, standard deviation 2798"),
    (2010, "greenhouse_intensity", "gold", 13.9, "t_CO2e_per_kg_Au",
     "Table 3, standard deviation 12.9"),
    (2010, "greenhouse_intensity", "uranium", 26.4, "t_CO2e_per_t_U3O8",
     "Table 3, standard deviation 17.6"),
    (2010, "cyanide_intensity", "gold", 198.0, "kg_CN_per_kg_Au",
     "Table 3, standard deviation 204"),
    (2010, "energy_grade_elasticity", "gold", -0.2848, "dimensionless",
     "Figure 8, p107, fitted power regression of unit energy consumption "
     "(GJ/kg Au) on ore grade (g/t Au): y = 167487 x^-0.2848, R2 = 0.1962"),
    (2010, "energy_grade_regression_constant", "gold", 167487.0,
     "GJ_per_kg_Au_at_1_g_per_t", "Figure 8, p107"),
    (2008, "average_ore_grade", "copper_australia", 0.95, "percent",
     "p112, Australia's average 2008 copper ore grade"),
]


def main():
    rows = []
    for mine, metals, mine_type, kwh, diesel, y0, y1 in CALVO_TABLE1:
        year = (y0 + y1) // 2
        period = "{}-{}".format(y0, y1)
        if kwh is not None:
            rows.append(dict(
                year=year, series="electricity_per_tonne_ore",
                commodity="{}[{}][{}]".format(mine, metals, mine_type),
                value=float(kwh), unit="kWh_per_t_ore (period {})".format(period),
                source=CALVO + ":table1", method="transcribed"))
        if diesel is not None:
            rows.append(dict(
                year=year, series="diesel_per_tonne_rock",
                commodity="{}[{}][{}]".format(mine, metals, mine_type),
                value=float(diesel), unit="L_per_t_rock (period {})".format(period),
                source=CALVO + ":table1", method="transcribed"))
    for year, series, commodity, value, unit, where in CALVO_TEXT:
        rows.append(dict(year=year, series=series, commodity=commodity,
                         value=float(value), unit="{} [{}]".format(unit, where),
                         source=CALVO, method="transcribed"))
    for commodity, value, unit, start in MUDD_TABLE1:
        rows.append(dict(
            year=2008, series="cumulative_production_australia",
            commodity=commodity, value=float(value),
            unit="{} (since {})".format(unit, start),
            source=MUDD + ":table1", method="transcribed"))
    for commodity, prod, prod_unit, res, res_unit in MUDD_TABLE2:
        rows.append(dict(
            year=2008, series="production_australia", commodity=commodity,
            value=float(prod), unit=prod_unit, source=MUDD + ":table2",
            method="transcribed"))
        rows.append(dict(
            year=2008, series="economic_resources_australia", commodity=commodity,
            value=float(res), unit=res_unit, source=MUDD + ":table2",
            method="transcribed"))
    for year, series, commodity, value, unit, where in MUDD_INTENSITY:
        rows.append(dict(year=year, series=series, commodity=commodity,
                         value=float(value), unit="{} [{}]".format(unit, where),
                         source=MUDD, method="transcribed"))
    out = pd.DataFrame(rows, columns=COLUMNS).sort_values(
        ["source", "series", "commodity"]
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.to_csv(OUT, index=False)
    print(
        "b3_oregrades: {} rows, {} series, from Calvo and others (2016) Table 1 "
        "and text and Mudd (2010) Tables 1-3 and Figure 8; West (2011) MANUAL "
        "-> {}".format(len(out), out["series"].nunique(), OUT)
    )


if __name__ == "__main__":
    main()
