# B3, the resource side: sources

Provenance for the resource block of the calibration (plan
`notes/plan_calibration_experiments.md`, task B3). One entry per source: full
citation, URL, access date, licence, files, and where it is used. Reasons and
alternatives are in `notes/data/resources.md`; the transformations are in
`data/build/b3_*.py`. The root `data/SOURCES.md` is assembled later from the
per-block files.

Access dates are all **2026-09-17** unless stated otherwise.

---

## 1. Jacks (2019), real commodity prices 1850-2025

**Citation.** Jacks, D.S., 2019, "From boom to bust: a typology of real
commodity prices in the long run": *Cliometrica*, v. 13, no. 2, pp. 201-220.
Dataset updated by the author to 2025.

**URL.** Landing page <https://davidjacks.org/from-boom-to-bust/>; file
<https://davidjacks.org/wp-content/uploads/2026/01/Real-commodity-prices-1850-2025.xlsx>.
The same dataset is deposited at openICPSR, <https://doi.org/10.3886/E198401V2>.

**Licence.** The author's page states "These data are freely provided to all
comers" and asks that the article be cited. No formal licence is named.

**Files.** `data/raw/jacks2019/Real-commodity-prices-1850-2025.xlsx`, committed
(120 KB). Three sheets: `Commodities` (42 commodities in seven groups, each an
index with 1900 = 100, 1850-2025), `Indices` (three aggregate indices, 1900-2025),
`Sub-indices` (grown / in the ground / in the ground ex-energy).

**Used by.** `data/build/b3_jacks.py` -> `data/interim/b3_jacks.csv`; the metals
and mass-weighted price indices of `b3_resource_block.py`.

```sh
curl -L -o data/raw/jacks2019/Real-commodity-prices-1850-2025.xlsx \
  "https://davidjacks.org/wp-content/uploads/2026/01/Real-commodity-prices-1850-2025.xlsx"
```

---

## 2. USGS Data Series 140, historical statistics for mineral commodities

**Citation.** U.S. Geological Survey, [year], [Mineral commodity] statistics, *in*
Kelly, T.D., and Matos, G.R., comps., Historical statistics for mineral and
material commodities in the United States: U.S. Geological Survey Data Series
140. Each commodity workbook carries its own last-modified date; the file name
carries the last data year (2019 to 2022 across the set).

**URL.** Index
<https://www.usgs.gov/centers/national-minerals-information-center/historical-statistics-mineral-and-material-commodities>;
each commodity at `https://www.usgs.gov/media/files/<commodity>-historical-statistics-data-series-140`,
which redirects to an `.xlsx` on `d9-wret.s3.us-west-2.amazonaws.com`.

**Licence.** US Government work, public domain.

**Files.** `data/raw/usgs_ds140/*.xlsx`, 32 commodities, 1.7 MB, committed:
aluminum, bauxite and alumina, cement, chromium, clays, cobalt, construction sand
and gravel, copper, crushed stone, dimension stone, gold, gypsum, iron ore, iron
and steel, iron and steel scrap, lead, lime, manganese, molybdenum, nickel,
phosphate rock, platinum-group metals, potash, salt, industrial sand and gravel,
silver, soda ash, sulfur, tin, titanium minerals, tungsten, zinc.

**Note.** There is **no bulk download** for Data Series 140; the USGS page offers
one file per commodity and the plain HTTP request is refused without a browser
user agent. The loop below is what was run.

**Used by.** `data/build/b3_usgs_ds140.py` -> `data/interim/b3_usgs_ds140.csv`:
world production (the block's only long global mass series), US production, and
unit value in current and constant 1998 dollars.

```sh
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
for c in aluminum bauxite-and-alumina chromium cobalt copper gold iron-ore iron-and-steel \
         iron-and-steel-scrap lead manganese molybdenum nickel platinum-group-metals silver tin \
         titanium-minerals tungsten zinc cement construction-sand-and-gravel crushed-stone gypsum \
         lime phosphate-rock potash salt soda-ash sulfur clays industrial-sand-and-gravel \
         dimension-stone; do
  url=$(curl -sL -A "$UA" "https://www.usgs.gov/media/files/${c}-historical-statistics-data-series-140" \
        | grep -oE 'https?://[^"'"'"' ]*\.xlsx' | sort -u | head -1)
  curl -sL -A "$UA" -o "data/raw/usgs_ds140/$(basename "$url")" "$url"
done
```

---

## 3. USGS Mineral Commodity Summaries 2026

**Citation.** U.S. Geological Survey, 2026, *Mineral Commodity Summaries 2026*:
U.S. Geological Survey, 226 p., <https://doi.org/10.3133/mcs2026>. The
accompanying data release is National Minerals Information Center, 2026, *Mineral
Commodity Summaries 2026*: U.S. Geological Survey data release,
<https://doi.org/10.5066/P1WKQ63T>, published 6 February 2026.

**URL.** Report PDF <https://pubs.usgs.gov/periodicals/mcs2026/mcs2026.pdf>.
Data release on ScienceBase
<https://www.sciencebase.gov/catalog/item/696a75d5d4be0228872d3bf8>.

**Licence.** Public domain (`http://www.usa.gov/publicdomain/label/1.0/`).

**MANUAL: the bulk CSV data release could not be downloaded.**
`https://www.sciencebase.gov/catalog/item/696a75d5d4be0228872d3bf8?format=json`
and every ScienceBase file endpoint answer **HTTP 403** behind a Cloudflare
interstitial from this machine, through both `curl` (with a browser user agent
and full header set) and the agent's fetch tool. The data.gov and
data.usgs.gov catalogue entries carry only the DOI, not file URLs. The morning
review should download the release from
<https://doi.org/10.5066/P1WKQ63T> in a browser into `data/raw/usgs_mcs/`.

**What was used instead.** The published report, which carries the same numbers.
`data/build/b3_usgs_mcs.py` transcribes the "World total (rounded)" line of each
commodity's world production and reserves table, and the commodity's "World
Resources" statement, with the printed page number in the `source` column, for 35
commodities. Reserve figures reported as ">" are recorded as the bound with the
">" in the note column of `data/interim/b3_usgs_mcs_notes.csv`.

**Files.** `data/raw/usgs_mcs/mcs2026.pdf` (17 MB). **Not committed** --
`.gitignore` carries `data/raw/usgs_mcs/`; a 17 MB report behind a stable USGS
URL is not worth its weight in the history for a 25-row transcription, and the
transcription itself is in the build script with page numbers.

```sh
curl -L -o data/raw/usgs_mcs/mcs2026.pdf https://pubs.usgs.gov/periodicals/mcs2026/mcs2026.pdf
```

---

## 4. Global Carbon Budget 2025 (fossil CO2 by fuel)

**Citation.** Friedlingstein, P., and others, 2026, "Global Carbon Budget 2025":
*Earth System Science Data*, v. 18, pp. 3211-..., <https://doi.org/10.5194/essd-18-3211-2026>;
dataset version 2025v15.

**Licence.** CC BY 4.0, stated in the dataset's own metadata file.

**Files.** `data/raw/gcb/GCB2025v15_MtCO2_flat.csv` and its metadata JSON.
**Downloaded by block B5, read here, not re-downloaded** (the task's instruction:
`data/raw/gcb/` already existed). B5's `data/sources/B5_pollution.md` owns the
entry; this file records only that B3 reads the `Global` rows of the flat CSV for
coal, oil and gas CO2, 1750-2024.

**Used by.** `data/build/b3_gcb_fossil.py` -> `data/interim/b3_gcb_fossil.csv`.

---

## 4b. IPCC (2006) carbon contents, for CO2 -> fossil mass

**Citation.** Intergovernmental Panel on Climate Change, 2006, *2006 IPCC
Guidelines for National Greenhouse Gas Inventories*, Volume 2 (Energy), Chapter 1
(Introduction), prepared by the National Greenhouse Gas Inventories Programme:
IGES, Japan. Table 1.2 (default net calorific values), p. 1.18; Table 1.3
(default carbon content), p. 1.21; Table 1.4 (default CO2 emission factors, with
the default carbon oxidation factor of 1), p. 1.23.

**URL.** <https://www.ipcc-nggip.iges.or.jp/public/2006gl/pdf/2_Volume2/V2_1_Ch1_Introduction.pdf>

**Licence.** IPCC/IGES publication; reproduction permitted with acknowledgement.
Not committed (`.gitignore` carries `data/raw/ipcc2006/`).

**Files.** `data/raw/ipcc2006/V2_1_Ch1_Introduction.pdf` (856 KB).

**Used by.** `data/build/b3_gcb_fossil.py` and `data/build/b3_urr.py`. The three
central factors, transcribed and then combined in the script, are: coal (other
bituminous) NCV 25.8 GJ/t and 25.8 kg C/GJ, oil (crude) 42.3 and 20.0, natural
gas 48.0 and 15.3, giving 2.441, 3.102 and 2.693 t CO2 per t of fuel.

```sh
curl -L -o data/raw/ipcc2006/V2_1_Ch1_Introduction.pdf \
  https://www.ipcc-nggip.iges.or.jp/public/2006gl/pdf/2_Volume2/V2_1_Ch1_Introduction.pdf
```

---

## 5. Ore grades and energy per tonne

### 5a. Calvo and others (2016)

**Citation.** Calvo, G., Mudd, G., Valero, Al., and Valero, An., 2016,
"Decreasing ore grades in global metallic mining: a theoretical issue or a global
reality?": *Resources*, v. 5, no. 4, art. 36,
<https://doi.org/10.3390/resources5040036>.

**URL.** MDPI's own PDF endpoint <https://www.mdpi.com/2079-9276/5/4/36/pdf> is
behind Cloudflare and returned an HTML challenge; the open-access PDF was taken
from Semantic Scholar,
<https://pdfs.semanticscholar.org/0fb2/3ed97e4675abcf94f6b3debc8a49acc60e50.pdf>.

**Licence.** CC BY 4.0 (MDPI open access). Not committed, for consistency with
the other papers in `data/raw/oregrades/`.

**Files.** `data/raw/oregrades/calvo2016_resources_5_36.pdf` (3.7 MB).

**What was taken.** Table 1, pp. 5-6: 35 mines with average electricity use per
tonne of ore, diesel per tonne of rock, and the reporting period. Text, pp. 9-10:
average total energy per tonne of metal for copper, zinc and gold; average ore
grades for gold, zinc, lead and copper; the 25 percent fall in the weighted
average copper grade from 2003 to 2013. The grade **time series** are in
Figures 4 and 5 only and were not taken: no number is read off a figure.

### 5b. Mudd (2010)

**Citation.** Mudd, G.M., 2010, "The environmental sustainability of mining in
Australia: key mega-trends and looming constraints": *Resources Policy*, v. 35,
no. 2, pp. 98-115, <https://doi.org/10.1016/j.resourpol.2009.12.001>.

**URL.** Publisher version is paywalled (Elsevier). A PDF was obtained from
<https://www.geokniga.org/bookfiles/geokniga-theenvironmentalsustainabilityofmininginaustraliakeymega.pdf>.

**Licence.** Elsevier, all rights reserved. **Not ours to redistribute**;
`.gitignore` carries `data/raw/oregrades/`.

**Files.** `data/raw/oregrades/mudd2010_resources_policy.pdf` (1.3 MB).

**What was taken.** Table 1, p. 102 (cumulative Australian production by mineral
to 2008, with the first year of the series); Table 2, p. 106 (economic resources,
2008 production, years remaining); Table 3, p. 107 (weighted-average energy,
water, greenhouse and cyanide intensity for gold and uranium); the fitted
regression printed in Figure 8, p. 107, of unit energy consumption on gold ore
grade; and the 2008 Australian average copper grade quoted on p. 112. The grade
time series of Figures 3 and 7 were not taken.

### 5c. West (2011) -- MANUAL

**Citation.** West, J., 2011, "Decreasing metal ore grades: are they really being
driven by the depletion of high-grade deposits?": *Journal of Industrial
Ecology*, v. 15, no. 2, pp. 165-168,
<https://doi.org/10.1111/j.1530-9290.2011.00334.x>.

**MANUAL: <https://onlinelibrary.wiley.com/doi/10.1111/j.1530-9290.2011.00334.x>.**
Paywalled (Wiley); no open version located. It is a four-page commentary on Mudd
and carries no tabulated series, so nothing is missing from
`data/interim/b3_oregrades.csv` except its argument, which
`notes/data/resources.md` records.

---

## 6. Ultimately recoverable resources

### 6a. Rogner and others (2012), Global Energy Assessment chapter 7

**Citation.** Rogner, H.-H., Aguilera, R.F., Archer, C., Bertani, R.,
Bhattacharya, S.C., Dusseault, M.B., Gagnon, L., Haberl, H., Hoogwijk, M.,
Johnson, A., Rogner, M.L., Wagner, H., and Yakushev, V., 2012, "Energy resources
and potentials", chapter 7 *of* *Global Energy Assessment -- Toward a Sustainable
Future*: Cambridge University Press, Cambridge, and the International Institute
for Applied Systems Analysis, Laxenburg, pp. 423-512.

**URL.** <https://pure.iiasa.ac.at/id/eprint/10061/1/GEA%20Chapter%207%20Energy%20Resources%20and%20Potentials.pdf>

**Licence.** Cambridge University Press / IIASA; the chapter is posted openly in
the IIASA repository. Not committed (`.gitignore` carries `data/raw/urr/`).

**Files.** `data/raw/urr/GEA_Chapter7_Energy_Resources_and_Potentials.pdf` (10 MB).

**What was taken.** Table 7.1, p. 431, "Fossil and uranium reserves, resources,
and occurrences": historical production through 2005, 2005 production, reserves
(a range), resources (a range) and additional occurrences, in EJ, for
conventional and unconventional oil and gas, coal and uranium.

```sh
curl -L -o "data/raw/urr/GEA_Chapter7_Energy_Resources_and_Potentials.pdf" \
  "https://pure.iiasa.ac.at/id/eprint/10061/1/GEA%20Chapter%207%20Energy%20Resources%20and%20Potentials.pdf"
```

### 6b. BGR Energy Study -- MANUAL

**Citation.** Bundesanstalt fuer Geowissenschaften und Rohstoffe, 2025, *BGR
Energy Study 2024 -- Data and Developments Concerning German and Global Energy
Supplies*: Hannover (latest edition; the 2023 edition covers end-2022).

**MANUAL: <https://www.bgr.bund.de/EN/Themen/Rohstoffe/Produkte/Energiestudien_en/energiestudie_node_en.html>.**
Every `bgr.bund.de`, `deutsche-rohstoffagentur.de`, `pebs-eu.de` and `whymap.org`
URL for the study answered **HTTP 400** (landing pages) or **404** (the PDF paths
returned by search) from this machine, with both `curl` and the agent's fetch
tool. Fossil reserves and resources therefore rest on Rogner and others (2012)
alone, which is the older of the two and should be cross-checked against BGR when
the file is in hand.

### 6c. Rankin (2011) -- MANUAL

**Citation.** Rankin, W.J., 2011, *Minerals, Metals and Sustainability -- Meeting
Future Material Needs*: CSIRO Publishing, Melbourne, 440 p.

**MANUAL: <https://www.publish.csiro.au/book/6265/>.** A paywalled monograph; no
open copy located. It is the source the data plan names for crustal-abundance
estimates of metal URR, and nothing in this block replaces it. What stands in its
place is 6d.

### 6d. USGS Global Mineral Resource Assessment, as reported in MCS 2026

**Citation.** The commodity "World Resources" paragraphs of *Mineral Commodity
Summaries 2026* (source 3), with the underlying assessment cited there. For
copper: Hammarstrom, J.M., Zientek, M.L., Parks, H.L., Dicken, C.L., and the
U.S. Geological Survey Global Copper Mineral Resource Assessment Team, 2019,
"Assessment of undiscovered copper resources of the world, 2015" (ver. 1.2,
December 2021): U.S. Geological Survey Scientific Investigations Report
2018-5160, 619 p., <https://doi.org/10.3133/sir20185160>.

**What was taken.** Identified and, for copper only, undiscovered resources by
commodity, transcribed in `data/build/b3_usgs_mcs.py` with page numbers.

---

## 7. Exploration

### 7a. Schodde / MinEx Consulting

**Citation.** Schodde, R., 2023, "Exploration: Australia vs the World":
presentation to the International Mining and Resource Conference (IMARC), Sydney,
31 October 2023, MinEx Consulting, 31 slides. Also held: Schodde, R., 2017,
"Challenges of exploring under deep cover": AMIRA Exploration Managers
Conference, March 2017.

**URL.** <https://minexconsulting.com/wp-content/uploads/2023/11/IMARC-Presentation-31-Oct-2023.pdf>
and <https://minexconsulting.com/wp-content/uploads/2019/04/AMIRA-EMC-Presentation-exploring-under-cover-FINAL-March-2017.pdf>.

**Licence.** MinEx Consulting copyright; the presentations are posted for public
download ("Copies of this and other similar presentations can be downloaded from
my website"). Not committed (`.gitignore` carries `data/raw/minex/`).

**Files.** `data/raw/minex/schodde_imarc_2023.pdf` (3.8 MB),
`data/raw/minex/schodde_amira_2017_deep_cover.pdf` (4.9 MB).

**What was taken.** The numbers printed as labels on the charts of the 2023
presentation, with slide numbers: world exploration expenditure at eight labelled
years (slide 4); average discovery cost, 1975-2005 and 2011-2020 (slide 13);
discoveries in the last decade (slide 14); spend, discoveries, cost per discovery
and "bang-per-buck" by region for 2002-2011 and 2012-2021 (slide 22); and the
decade totals of slides 29 and 30. The **annual** series are drawn but not
printed and were not taken.

```sh
curl -L -o data/raw/minex/schodde_imarc_2023.pdf \
  https://minexconsulting.com/wp-content/uploads/2023/11/IMARC-Presentation-31-Oct-2023.pdf
curl -L -o data/raw/minex/schodde_amira_2017_deep_cover.pdf \
  https://minexconsulting.com/wp-content/uploads/2019/04/AMIRA-EMC-Presentation-exploring-under-cover-FINAL-March-2017.pdf
```

### 7b. S&P Global, World Exploration Trends -- MANUAL

**Citation.** S&P Global Market Intelligence, *World Exploration Trends*, annual,
and the *Corporate Exploration Strategies* series from which it is drawn.

**MANUAL: <https://www.spglobal.com/market-intelligence/en/solutions/products/world-exploration-trends>.**
Commercial; the public summary carries a headline budget total and no series, and
was not obtained. MinEx's expenditure series (7a) is built partly from the same
S&P data and is the public substitute used here.

---

## What each script reads and writes

| script | reads | writes |
|---|---|---|
| `b3_jacks.py` | `raw/jacks2019/` | `interim/b3_jacks.csv` |
| `b3_usgs_ds140.py` | `raw/usgs_ds140/` | `interim/b3_usgs_ds140.csv` |
| `b3_usgs_mcs.py` | transcribed from `raw/usgs_mcs/mcs2026.pdf` | `interim/b3_usgs_mcs.csv`, `interim/b3_usgs_mcs_notes.csv` |
| `b3_gcb_fossil.py` | `raw/gcb/GCB2025v15_MtCO2_flat.csv`, IPCC factors | `interim/b3_gcb_fossil.csv` |
| `b3_oregrades.py` | transcribed from `raw/oregrades/` | `interim/b3_oregrades.csv` |
| `b3_urr.py` | transcribed from `raw/urr/` and MCS | `interim/b3_urr.csv` |
| `b3_exploration.py` | transcribed from `raw/minex/` | `interim/b3_exploration.csv` |
| `b3_resource_block.py` | all of the above | `interim/b3_resource_block.csv` |
