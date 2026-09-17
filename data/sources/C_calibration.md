# Phase C sources: what the calibration added to the blocks

Provenance for the files phase C downloaded beyond blocks B1 to B5, in the form of
`notes/data_plan_global_1850.md` section 8: full citation, URL, access date, licence. What each is
used for is in `writing/quant/quant_data.tex`; why it was chosen is in `notes/data/calibration.md`.
Phase C also reads two Penn World Table variables the B2 pipeline did not extract, the internal
rate of return `irr` and the labour share `labsh`, from the workbook `data/raw/pwt1001/pwt1001.xlsx`
recorded in `data/sources/B2_macro.md`; nothing new was downloaded for them.

## 1. EEA (2001), Total material requirement of the European Union

Bringezu, S. and Schuetz, H. (2001). *Total material requirement of the European Union*. Technical
report No 55. Copenhagen: European Environment Agency. Page:
<https://www.eea.europa.eu/en/analysis/publications/technical_report_no_55>. File:
<https://www.eea.europa.eu/en/analysis/publications/technical_report_no_55/technical_report_no_55/@@download/file>.
Accessed 2026-09-17. Licence: EEA standard re-use policy (re-use permitted with acknowledgement).

Raw: `data/raw/eea_tmr2001/eea_technical_report_55_tmr_eu.pdf`. Used: Table 3, p. 22, ratios of
hidden flows to commodities for EU-15 in 1995, domestic column (fossil fuels 3.44, metals 0.94,
minerals 0.22, agricultural biomass 0.62, total 0.92) and the metals total column (11.33), typed
into `data/build/c1_accounting.py`. The row labels in the PDF text extraction are offset by one
line from their values; the transcription was checked against the prose on the same page (mineral
hidden flows 18.3 percent of total extraction; imported metals seventeen times the domestic ratio).

**What it stands in for.** Schandl, H., Fischer-Kowalski, M., West, J., Giljum, S., Dittrich, M.,
Eisenmenger, N., Geschke, A., Lieber, M., Wieland, H., Schaffartzik, A., Krausmann, F., Gierlinger,
S., Hosking, K., Lenzen, M., Tanikawa, H., Miatto, A. and Fishman, T. (2018). "Global Material
Flows and Resource Productivity: Forty Years of Evidence." *Journal of Industrial Ecology* 22(4),
827-838. <https://doi.org/10.1111/jiec.12626>. **MANUAL**: Wiley refuses automated download (HTTP
403 on the pdfdirect link) and Unpaywall lists no open copy. A global unused-extraction ratio from
this or from the Wuppertal Institute's global TMR work would replace the EU-based figure.

## 2. World Bank Commodity Price Data (the Pink Sheet), annual

World Bank (2026). *Commodity Price Data (The Pink Sheet)*, annual prices 1960 to present,
nominal and real. Updated 6 January 2026.
<https://thedocs.worldbank.org/en/doc/18675f1d1639c7a34d463f59263ba0a2-0050012025/related/CMO-Historical-Data-Annual.xlsx>.
Accessed 2026-09-17. Licence: Creative Commons Attribution 4.0 (World Bank open data terms).

Raw: `data/raw/worldbank_cmo/CMO-Historical-Data-Annual.xlsx`. Used: sheet "Annual Prices
(Nominal)", columns "Crude oil, average" ($/bbl), "Coal, Australian" ($/mt), "Natural gas, US",
"Natural gas, Europe", "Liquefied natural gas, Japan" ($/mmbtu), years 2011 and 2015, in
`data/build/c2_production_trends.py`. Oil is converted at 7.33 barrels per tonne, the factor
stated in footnote 5 of Rogner et al. (2012) (`data/sources/B3_resources.md`, source 6a); gas at
1.05506 GJ per mmbtu (a unit definition) and the IPCC (2006) net calorific value of 48 GJ/t already
in `data/build/b3_gcb_fossil.py`.

## 3. World Development Indicators, world aggregate

World Bank (2026). *World Development Indicators*, through the API
<https://api.worldbank.org/v2/country/WLD/indicator/<code>?format=json&per_page=100>.
Accessed 2026-09-17. Licence: Creative Commons Attribution 4.0.

Raw: `data/raw/wdi/WLD_<code>.json`, one file per indicator:

| code | indicator | used for |
|---|---|---|
| `NY.GDP.TOTL.RT.ZS` | total natural resources rents, % of GDP | the extraction cost share (value less rents); the rent per tonne for `c_D` |
| `NY.GDP.MINR.RT.ZS`, `NY.GDP.COAL.RT.ZS`, `NY.GDP.PETR.RT.ZS`, `NY.GDP.NGAS.RT.ZS`, `NY.GDP.FRST.RT.ZS` | the rent components | downloaded for the record; not used separately |
| `NV.AGR.TOTL.ZS` | agriculture, forestry and fishing value added, % of GDP | the biomass component of the material value share |
| `NY.GDP.MKTP.CD` | GDP, current US$ | the denominator of the value share |
| `NY.GDP.DEFL.ZS` | GDP deflator | empty for the world aggregate; not used |

Years 2011 and 2015 in `data/build/c2_production_trends.py` and `c3_extraction.py`.

## What phase C could not obtain

| what | why | effect |
|---|---|---|
| Schandl et al. (2018), global unused extraction | paywalled (above) | `Omega^{N,S}` rests on EU-15 ratios at the world composition; marked weak |
| BP or Energy Institute conversion factors | both sites refuse automated download (HTTP 403) | the barrel-to-tonne factor is taken from Rogner et al. (2012) instead; no loss |
| oil and gas exploration spend | not sought; commercial sources | the exploration cost check compares the model's `C^D` with metals exploration only |
| a cost-of-production series for fossil fuels or ores before 1960 | none public | the extraction cost level is a 2011-2015 number; the century's path is the price index |
