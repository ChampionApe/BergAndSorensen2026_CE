# Data sources

Provenance for every file under `data/raw/`: full citation, URL, access date, licence, the files
themselves, and what reads them. This is the one provenance file the repository keeps. It was
assembled 2026-09-18 from the per-block lists the data agents wrote (one file per block, now
deleted); the entries are theirs, moved rather than rewritten.

**The entry format.** One entry per source, numbered inside its block: citation, URL (landing page
and file), licence, a table of the files with sizes and what each is, what was taken where a number
is transcribed rather than read, the download command where the download is not a plain `curl`, and
the `data/build/` script that reads it. A source that could not be obtained carries a bold
**MANUAL** line with the URL and what failed, and appears again under *Not obtained* at the end.

**A raw file is never edited.** Everything under `data/raw/` is the file as downloaded; a format
conversion is committed beside the original with the command that produced it, and every
transformation lives in a `data/build/` script. `data/README.md` has the layout and the rebuild
order, `notes/data/` the decisions, `writing/quant/quant_data.tex` the numbers a reader needs.

Blocks: **B1** material flows and stocks, **B2** macro aggregates, **B3** the resource side,
**B4** waste handling and recycling, **B5** pollution and damages, **C** what the calibration added.

---

## B1. Core material flows and stocks

Task B1 of `notes/plan_calibration_experiments.md`. Which source was chosen for which series, and
why, is in `notes/data/material_flows.md`; the transformations are in `data/build/b1_*.py`.
All files accessed **2026-09-17**. Sizes are of the file as downloaded.

### 1. Krausmann, Lauk, Haas and Wiedenhofer (2018)

Krausmann, F., Lauk, C., Haas, W. and Wiedenhofer, D. (2018). "From resource extraction to outflows
of wastes and emissions: The socioeconomic metabolism of the global economy, 1900-2015."
*Global Environmental Change* 52, 131-140. <https://doi.org/10.1016/j.gloenvcha.2018.07.003>

Licence: CC BY-NC-ND 4.0 (version of record, per Crossref). The companion workbook carries no
licence statement of its own; it is the article's online data and is cited through the article.

Files, in `data/raw/krausmann2018/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `Online_data_Krausmann_et_al_2018.xlsx` | 976313 | version 1.1 (February 2018); global extraction by material group and use type, stocks and net additions to stock, domestic processed output, all annual 1900-2015 | <https://boku.ac.at/fileadmin/data/H03000/H73000/H73700/Data_Download/Data/Online_data_Krausmann_et_al_2018.xlsx> |
| `1-s2.0-S0959378017313031-mmc1.pdf` | 856010 | Supporting Information: methods, estimation procedures, sensitivity analysis | <https://ars.els-cdn.com/content/image/1-s2.0-S0959378017313031-mmc1.pdf> |

The workbook is reached from the authors' data page,
<https://boku.ac.at/en/wiso/isec/data-download> (the URL printed in the article,
`https://www.wiso.boku.ac.at/sec/data-download/`, now redirects there). The supplementary PDF is
encrypted with an owner password and cannot be opened by the Read tool; `pdftotext -layout` reads it.

Read by `data/build/b1_krausmann2018.py`.

### 2. Krausmann et al. (2017), PNAS

Krausmann, F., Wiedenhofer, D., Lauk, C., Haas, W., Tanikawa, H., Fishman, T., Miatto, A., Schandl,
H. and Haberl, H. (2017). "Global socioeconomic material stocks rise 23-fold over the 20th century
and require half of annual resource use." *PNAS* 114(8), 1880-1885.
<https://doi.org/10.1073/pnas.1613773114>

Licence: PNAS user licence (bronze open access; not a Creative Commons licence).

**MANUAL: <https://www.pnas.org/doi/10.1073/pnas.1613773114> - supporting information (in-use
material stocks 1900-2010 by material group, Monte Carlo simulation, stock age distribution).**
PNAS returns HTTP 403 to every non-browser request, including the bronze-OA full text; the PMC copy
(PMC5338421) is not in the open-access subset, so the Europe PMC supplementary-file service refuses
it, and the PMC file endpoint is behind a proof-of-work challenge. Nothing from this source is used.
Its in-use stock series is superseded by source 1, which carries the same MISO model to 2015; see
`notes/data/material_flows.md`.

### 3. Haas, Krausmann, Wiedenhofer, Heinz and Pichler (2020)

Haas, W., Krausmann, F., Wiedenhofer, D., Lauk, C. and Mayer, A. (2020). "Spaceship earth's odyssey
to a circular economy - a century long perspective." *Resources, Conservation and Recycling* 163,
105076. <https://doi.org/10.1016/j.resconrec.2020.105076>

Licence: CC BY-NC-ND 4.0 (version of record, per Crossref).

Files, in `data/raw/haas2020/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `1-s2.0-S0921344920303931-mmc1.zip` | 2058547 (zip 2041939) | Supporting Material Table S1: the data behind the paper's Sankey diagrams, annual 1900-2015, one sheet per material group plus circularity indicators and the uncertainty assessment | <https://ars.els-cdn.com/content/image/1-s2.0-S0921344920303931-mmc1.zip> |
| `1-s2.0-S0921344920303931-mmc2.pdf` | 1369115 | Supporting Material Doc S1: the uncertainty assessment figures | <https://ars.els-cdn.com/content/image/1-s2.0-S0921344920303931-mmc2.pdf> |

The zip holds one workbook, `Supporting Material Table S1 RCR.xlsx`, which
`data/build/b1_haas2020.py` unpacks beside it on first run; the unpacked copy is not committed.

#### 3b. Haas, Krausmann, Wiedenhofer and Heinz (2015)

Haas, W., Krausmann, F., Wiedenhofer, D. and Heinz, M. (2015). "How Circular is the Global Economy?
An Assessment of Material Flows, Waste Production, and Recycling in the European Union and the World
in 2005." *Journal of Industrial Ecology* 19(5), 765-777. <https://doi.org/10.1111/jiec.12244>

Licence: CC BY 4.0 (version of record, per Crossref).

**MANUAL: <https://onlinelibrary.wiley.com/doi/full/10.1111/jiec.12244> - article and supporting
information (the 2005 cross-section of end-of-life recycling as a share of material input).**
Wiley returns HTTP 403 to every non-browser request, for the article and for every supplement path
tried. The 2020 update above supersedes it for this block's purpose: it carries the same accounting
annually for 1900-2015 rather than for 2005 alone.

### 4. UN IRP Global Material Flows Database

UN International Resource Panel, *Global Material Flows Database*, compiled by CSIRO and WU Vienna.
Publisher's page: <https://www.resourcepanel.org/global-material-flows-database>. Technical annex
(version 4, June 2024):
<https://www.resourcepanel.org/sites/default/files/technical_annex_for_global_material_flows_database_-_vers_4_june_2024.pdf>

Licence: CC BY 4.0, as recorded by the mirror below.

Files, in `data/raw/unep_irp/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `global-material-flows-database.csv` | 7484216 | 231 countries and regions including a World row, 11 material categories, 9 flows (DE, DMI, DMC, RMC, imports, exports and the raw-material equivalents), annual 1970-2019 | <https://energydata.info/dataset/8121a8bc-37b6-408a-91b4-b015c299b349/resource/cb390844-66ec-4559-ac1a-e153bb94ee98/download/global-material-flows-database.csv> |

This is a World Bank *energydata.info* mirror of the database (dataset
`world-unep-irp-global-material-flows-database`, CKAN metadata last modified 2022-03-30), not the
publisher's copy. It is the vintage ending in 2019.

**MANUAL: <https://www.resourcepanel.org/global-material-flows-database> - the current vintage,
1970-2024.** The publisher serves it only through the Shiny application at
<https://visualisations.materialflows.net/mf-shiny/>, which has no scriptable bulk endpoint, and
`materialflows.net` carries no download page. Unused domestic extraction is described in module 5 of
the technical annex but is not among the flows the published database reports.

Read by `data/build/b1_unep_irp.py`.

### 5. Krausmann et al. (2009), in the 2011 update

Krausmann, F., Gingrich, S., Eisenmenger, N., Erb, K.-H., Haberl, H. and Fischer-Kowalski, M. (2009).
"Growth in global materials use, GDP and population during the 20th century." *Ecological Economics*
68(10), 2696-2705. <https://doi.org/10.1016/j.ecolecon.2009.05.007>

Licence: no statement on the workbook; the authors' online data, cited through the article.

Files, in `data/raw/krausmann2009/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `Online_data_global_flows_update_2011.xls` | 440832 | version 1.2 (August 2011): global extraction by four material groups, per capita and per unit of GDP, annual 1900-2009, plus energy flows | <https://boku.ac.at/fileadmin/data/H03000/H73000/H73700/Data_Download/Data/Online_data_global_flows_update_2011.xls> |
| `Online_data_global_flows_update_2011_converted.xlsx` | 211203 | format conversion of the line above, committed so that the pipeline runs without Excel | derived |

The original is a BIFF8 workbook and `xlrd` is not among the packages this project may use, so it was
converted once with Excel and the conversion committed beside it. The original is untouched. The
conversion, run from `data/raw/krausmann2009/`:

```python
import os, win32com.client
app = win32com.client.Dispatch("Excel.Application")
app.Visible = False; app.DisplayAlerts = False
wb = app.Workbooks.Open(os.path.abspath("Online_data_global_flows_update_2011.xls"), ReadOnly=True)
wb.SaveAs(os.path.abspath("Online_data_global_flows_update_2011_converted.xlsx"), FileFormat=51)
wb.Close(False); app.Quit()
```

Read by `data/build/b1_krausmann2009.py`.

---

## B2. Macro aggregates and the use split

Task B2. Choices and reasons in `notes/data/macro.md`; transformations in `data/build/b2_*.py`.
All files accessed **2026-09-17**. Sizes are of the file as downloaded.

**One download note that applies to sources 1 and 2.** Both are served from DataverseNL, which sits
behind the Anubis bot filter. The filter's policy denies a bare `curl/*` user agent outright (HTTP
200 with a 2236-byte "Access Denied" page, which a script will happily save as an `.xlsx`) and
serves every other non-browser client normally. The downloads below were made with Python's
`urllib.request` at its default user agent, which the filter allows. `curl -O` will silently
produce a broken file; check that the result is a zip archive, not HTML, before trusting it.

### 1. Maddison Project Database 2023

Bolt, J. and van Zanden, J. L. (2024). "Maddison style estimates of the evolution of the world
economy: A new 2023 update." *Journal of Economic Surveys* 39(2), 631-671.
<https://doi.org/10.1111/joes.12618>

Dataset: Maddison Project Database, version 2023. Groningen Growth and Development Centre,
University of Groningen. DOI <https://doi.org/10.34894/INZBF2>. Release page:
<https://www.rug.nl/ggdc/historicaldevelopment/maddison/releases/maddison-project-database-2023>

Licence: CC BY 4.0 (stated on the release page and on the DataverseNL record). The MPD's own
citation policy additionally requires the original country papers to be cited if the data are shown
in graphical form or if fewer than twelve countries are used; neither applies to a world aggregate.

Files, in `data/raw/maddison2023/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `mpd2023_web.xlsx` | 4903804 | the database: `Full data` (169 entities, annual GDP per capita in 2011 international dollars and population in thousands), `Regional data` (the MPD's own regional and world aggregates), `Sources`, `Notes` | <https://dataverse.nl/api/access/datafile/421302> |
| `maddison2023_web.dta` | 10892389 | the same data in Stata format; downloaded, not used, not committed | <https://dataverse.nl/api/access/datafile/421303> |

Read by `data/build/b2_maddison.py`.

### 2. Penn World Table 10.01

Feenstra, R. C., Inklaar, R. and Timmer, M. P. (2015). "The Next Generation of the Penn World
Table." *American Economic Review* 105(10), 3150-3182. <https://doi.org/10.1257/aer.20130954>

Dataset: Penn World Table version 10.01. Groningen Growth and Development Centre, University of
Groningen. DOI <https://doi.org/10.34894/QT5BCC>. Release page:
<https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt1001>

Licence: CC BY 4.0 (stated on the release page).

Files, in `data/raw/pwt1001/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `pwt1001.xlsx` | 6551843 | the main table: 183 countries, 1950-2019, 52 variables; sheets `Info`, `Legend`, `Data` | <https://dataverse.nl/api/access/datafile/354095> |
| `pwt1001.dta` | 3452645 | the same data in Stata format; downloaded, not used, not committed | <https://dataverse.nl/api/access/datafile/354098> |

Variables used: `cgdpo`, `cn`, `csh_c`, `csh_i`, `csh_g`, `csh_x`, `csh_m`, `csh_r`, `delta`, `pop`.
Read by `data/build/b2_pwt.py`.

The GGDC web server also carries older releases as plain files (`pwt100.xlsx`, `pwt91.xlsx` under
`https://www.rug.nl/ggdc/docs/`, `mpd2020.xlsx` under
`https://www.rug.nl/ggdc/historicaldevelopment/maddison/data/`), which are reachable without the
DataverseNL detour. Neither 10.01 nor MPD 2023 is among them.

### 3. Piketty and Zucman (2014), "Capital is Back"

Piketty, T. and Zucman, G. (2014). "Capital is Back: Wealth-Income Ratios in Rich Countries
1700-2010." *Quarterly Journal of Economics* 129(3), 1255-1310.
<https://doi.org/10.1093/qje/qju018>

Data page: <http://piketty.pse.ens.fr/en/capitalisback> (mirrored at
<https://gabriel-zucman.eu/capitalisback/>).

Licence: none stated. The workbooks are posted by the authors on their institutional pages as the
supporting data of the published article. Treated as readable but not redistributable: the
directory is in `.gitignore` and the files are re-obtained with the URLs below.

Files, in `data/raw/piketty_zucman2014/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `USA.xlsx` | 3179989 | United States, 1770-2010, 58 tables; `TableUS6a` is the annual structure of national wealth as a ratio to national income, 1870-2012 | <http://piketty.pse.ens.fr/files/capitalisback/USA.xlsx> |
| `AppendixTables.xls` | 6556672 | the paper's appendix tables | <http://piketty.pse.ens.fr/files/capitalisback/AppendixTables.xls> |
| `Figures.xls` | 701952 | the data behind the paper's figures | <http://piketty.pse.ens.fr/files/capitalisback/Figures.xls> |
| `UK.xls`, `France.xls`, `Germany.xls`, `Japan.xls`, `Canada.xls`, `Australia.xls`, `Italy.xls`, `Spain.xls` | 236544-4262912 | the other eight country workbooks | `http://piketty.pse.ens.fr/files/capitalisback/<Country>.xls` |

**MANUAL: the eight legacy `.xls` workbooks (every country except the United States, plus
`AppendixTables.xls` and `Figures.xls`).** They download cleanly but cannot be opened here: pandas
needs `xlrd` for the pre-2007 BIFF format and `xlrd` is not installed, and the task's environment is
pandas, openpyxl and pyarrow only. Only the United States enters the cross-check. Installing `xlrd`,
or converting the workbooks once to `.xlsx`, would extend it to the other seven countries; nothing
else about the block would change.

Read by `data/build/b2_piketty_zucman.py` (the `USA.xlsx` sheet `TableUS6a` only).

Re-download, from the repository root:

```
python -c "import urllib.request,os; os.makedirs('data/raw/piketty_zucman2014',exist_ok=True); [open('data/raw/piketty_zucman2014/'+f,'wb').write(urllib.request.urlopen('http://piketty.pse.ens.fr/files/capitalisback/'+f).read()) for f in ['USA.xlsx','AppendixTables.xls','Figures.xls','UK.xls','France.xls','Germany.xls','Japan.xls','Canada.xls','Australia.xls','Italy.xls','Spain.xls']]"
```

---

## B3. The resource side

Task B3. Reasons and alternatives in `notes/data/resources.md`; transformations in
`data/build/b3_*.py`. Access dates are all **2026-09-17** unless stated otherwise.

### 1. Jacks (2019), real commodity prices 1850-2025

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

### 2. USGS Data Series 140, historical statistics for mineral commodities

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

### 3. USGS Mineral Commodity Summaries 2026

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

### 4. Global Carbon Budget 2025 (fossil CO2 by fuel)

**Citation.** Friedlingstein, P., and others, 2026, "Global Carbon Budget 2025":
*Earth System Science Data*, v. 18, pp. 3211-..., <https://doi.org/10.5194/essd-18-3211-2026>;
dataset version 2025v15.

**Licence.** CC BY 4.0, stated in the dataset's own metadata file.

**Files.** `data/raw/gcb/GCB2025v15_MtCO2_flat.csv` and its metadata JSON.
**Downloaded by block B5, read here, not re-downloaded** (the task's instruction:
`data/raw/gcb/` already existed). block B5 owns the
entry; this file records only that B3 reads the `Global` rows of the flat CSV for
coal, oil and gas CO2, 1750-2024.

**Used by.** `data/build/b3_gcb_fossil.py` -> `data/interim/b3_gcb_fossil.csv`.

---

### 4b. IPCC (2006) carbon contents, for CO2 -> fossil mass

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

### 5. Ore grades and energy per tonne

#### 5a. Calvo and others (2016)

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

#### 5b. Mudd (2010)

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

#### 5c. West (2011) -- MANUAL

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

### 6. Ultimately recoverable resources

#### 6a. Rogner and others (2012), Global Energy Assessment chapter 7

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

#### 6b. BGR Energy Study -- MANUAL

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

#### 6c. Rankin (2011) -- MANUAL

**Citation.** Rankin, W.J., 2011, *Minerals, Metals and Sustainability -- Meeting
Future Material Needs*: CSIRO Publishing, Melbourne, 440 p.

**MANUAL: <https://www.publish.csiro.au/book/6265/>.** A paywalled monograph; no
open copy located. It is the source the data plan names for crustal-abundance
estimates of metal URR, and nothing in this block replaces it. What stands in its
place is 6d.

#### 6d. USGS Global Mineral Resource Assessment, as reported in MCS 2026

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

### 7. Exploration

#### 7a. Schodde / MinEx Consulting

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

#### 7b. S&P Global, World Exploration Trends -- MANUAL

**Citation.** S&P Global Market Intelligence, *World Exploration Trends*, annual,
and the *Corporate Exploration Strategies* series from which it is drawn.

**MANUAL: <https://www.spglobal.com/market-intelligence/en/solutions/products/world-exploration-trends>.**
Commercial; the public summary carries a headline budget total and no series, and
was not obtained. MinEx's expenditure series (7a) is built partly from the same
S&P data and is the public substitute used here.

---

### What each script reads and writes

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

---

## B4. Waste handling and recycling

Task B4. Which source was chosen for which parameter, and why, is in
`notes/data/waste_recycling.md`; transformations in `data/build/b4_*.py`.
All files accessed **2026-09-17**. Sizes are of the file as downloaded.

Two `curl` conventions recur below and are not repeated in each cell.
`UA` is a browser user-agent string; `wedocs.unep.org` and several publisher hosts return HTTP 403
without one, and the UNEP bitstream endpoint additionally needs `-H "Referer: https://wedocs.unep.org/"`.

```
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
```

### 1. Kaza, Yao, Bhada-Tata and Van Woerden (2018), *What a Waste 2.0*

Kaza, S., Yao, L., Bhada-Tata, P. and Van Woerden, F. (2018). *What a Waste 2.0: A Global Snapshot
of Solid Waste Management to 2050*. Urban Development Series. Washington, DC: World Bank.
<https://doi.org/10.1596/978-1-4648-1329-0>. Report page:
<https://openknowledge.worldbank.org/handle/10986/30317>. Dataset page:
<https://datacatalog.worldbank.org/search/dataset/0039597/what-a-waste-global-database>.

Licence: CC BY 3.0 IGO, stated on the report's copyright page (p. iv) and carried by the dataset.

Files, in `data/raw/whatawaste2/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `country_level_data.csv` | 35581 | 217 countries: MSW generation, composition, collection coverage, treatment shares, special wastes | <https://datacatalogfiles.worldbank.org/ddh-published/0039597/DR0049199/country_level_data.csv> |
| `city_level_data_0_0.csv` | 96818 | 367 cities: the same plus cost-recovery and waste-management-cost fields | <https://datacatalogfiles.worldbank.org/ddh-published/0039597/DR0049200/city_level_data_0_0.csv> |
| `country_level_codebook.csv` | 1388380 | per country and measurement: units, year, source citation | <https://datacatalogfiles.worldbank.org/ddh-published/0039597/DR0049201/country_level_codebook.csv> |
| `city_level_codebook_0.csv` | 224836 | the same for cities; covers only population and total MSW | <https://datacatalogfiles.worldbank.org/ddh-published/0039597/DR0049202/city_level_codebook_0.csv> |
| `What-a-Waste-2-0_full_report.pdf` | 11231334 | the full report; source of table 5.2 (p. 104), table 5.3 (p. 105) and the global shares on pp. 5 and 34 | <https://documents1.worldbank.org/curated/en/697271544470229584/pdf/What-a-Waste-2-0-A-Global-Snapshot-of-Solid-Waste-Management-to-2050.pdf> |

The report PDF is `.gitignore`d as literature; the four CSVs are committed. The PDF is encrypted
with an owner password, so the `Read` tool refuses it; `pdftotext -table` reads it, and `-table`
rather than `-layout` is what resolves table 5.2's columns.

The city-level cost fields (`waste_management_cost_*`, `waste_disposal_cost_recovery_*`) carry no
unit and no currency in the open dataset - the city codebook covers only population and MSW
generation - and mix per-tonne figures with annual totals in local currency. **Nothing is taken from
them.** The unit costs come from the report's tables instead.

Read by `data/build/b4_whatawaste2.py`.

### 2. UNEP (2024), *Global Waste Management Outlook 2024*

United Nations Environment Programme (2024). *Global Waste Management Outlook 2024: Beyond an Age of
Waste - Turning Rubbish into a Resource*. Nairobi: UNEP. ISBN 978-92-807-4129-2.
<https://wedocs.unep.org/items/36e16872-2f02-4447-a3c1-c939bf50ea92>.

Licence: "This publication may be reproduced in whole or in part and in any form for educational or
non-profit services without special permission from the copyright holder, provided acknowledgement
of the source is made" (copyright page). Not a Creative Commons licence.

Files, in `data/raw/unep_gwmo2024/` (`.gitignore`d; re-download command below):

| file | bytes | what it is |
|---|---|---|
| `global_waste_management_outlook_2024.pdf` | 6953351 | the full report; source of the 2020 uncontrolled share (p. 21), the cost totals (p. 41), table 2B.1.1 and table 2C.1 (annex 2) |

```
curl -L -A "$UA" -H "Referer: https://wedocs.unep.org/" \
  -o data/raw/unep_gwmo2024/global_waste_management_outlook_2024.pdf \
  "https://wedocs.unep.org/bitstreams/daa56f4d-2479-4e10-88c6-4d65da463299/download"
```

The landing page `https://wedocs.unep.org/items/36e16872-...` is a DSpace 7 single-page app and
returns only the shell; the bitstream UUID above is taken from it.

Read by `data/build/b4_unep_gwmo2024.py`.

### 3. UNEP IRP (2011), *Recycling Rates of Metals: A Status Report*

Graedel, T.E., Allwood, J., Birat, J.-P., Reck, B.K., Sibley, S.F., Sonnemann, G., Buchert, M. and
Hagelueken, C. (2011). *Recycling Rates of Metals - A Status Report*. A Report of the Working Group
on the Global Flows of Metals to the International Resource Panel. Nairobi: UNEP.
ISBN 978-92-807-3161-3. <https://www.resourcepanel.org/reports/recycling-rates-metals>.

Licence: "This publication may be reproduced in whole or in part and in any form for educational or
non-profit purposes without special permission from the copyright holder, provided acknowledgement
of the source is made" (p. 2).

Files, in `data/raw/unep_irp2011/` (`.gitignore`d; re-download command below):

| file | bytes | what it is |
|---|---|---|
| `metals_status_report_full_report_english.pdf` | 2452896 | the full report; source of appendix tables C1 (p. 30), D1 (p. 31), E2 (p. 33) and F1 (pp. 36-37) and of the bin counts on p. 17 |

```
curl -L -A "$UA" -o data/raw/unep_irp2011/metals_status_report_full_report_english.pdf \
  "https://www.resourcepanel.org/sites/default/files/documents/document/media/metals_status_report_full_report_english.pdf"
```

Figure 4, the periodic table of EOL-RR bins, is the report's headline display and is **not** used:
it is a figure. The appendix tables carry the same evidence as numbers.

Read by `data/build/b4_unep_irp2011.py`.

### 4. Graedel et al. (2011), *Journal of Industrial Ecology* - MANUAL

Graedel, T.E., Allwood, J., Birat, J.-P., Buchert, M., Hagelueken, C., Reck, B.K., Sibley, S.F. and
Sonnemann, G. (2011). "What Do We Know About Metal Recycling Rates?" *Journal of Industrial Ecology*
15(3), 355-366. <https://doi.org/10.1111/j.1530-9290.2011.00342.x>.

**MANUAL: <https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1530-9290.2011.00342.x>.** Paywalled at
Wiley. The USGS staff-publications copy at
`https://digitalcommons.unl.edu/cgi/viewcontent.cgi?article=1605&context=usgsstaffpub` returns
HTTP 403 to every request tried, with and without a browser user-agent and referer.

Nothing is lost but the citation: this is the journal version of source 3, by the same working group
with the same estimates, and source 3 is downloaded.

### 5. OECD Environment Statistics, municipal waste

OECD (2026). *Municipal waste: generation and treatment*. OECD Data Explorer, dataflow
`OECD.ENV.EPI:DSD_MUNW@DF_MUNW(1.0)`.
<https://data-explorer.oecd.org/vis?df[ds]=dsDisseminateFinalDMZ&df[id]=DSD_MUNW%40DF_MUNW>.

Licence: OECD Terms and Conditions (<https://www.oecd.org/termsandconditions/>), which permit
reproduction and dissemination of OECD data with attribution.

Files, in `data/raw/oecd_waste/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `oecd_municipal_waste.csv` | 8625683 | the whole dataflow, labelled CSV: 68 reference areas, 1975-2024, 17 measures, tonnes / kg per head / per cent of treated waste / index | <https://sdmx.oecd.org/public/rest/data/OECD.ENV.EPI,DSD_MUNW@DF_MUNW,1.0/all?format=csvfilewithlabels> |

Read by `data/build/b4_oecd_waste.py`.

### 6. Eurostat waste statistics and environmental protection expenditure

Eurostat (2026). Datasets `env_wasmun` (municipal waste by waste management operations),
`env_wastrt` (treatment of waste by waste category, hazardousness and waste management operations)
and `env_epea_neep` (national expenditure on environmental protection by institutional sector and
environmental purpose). <https://ec.europa.eu/eurostat/web/waste/database>.

Licence: free reuse with attribution, under the Commission's reuse policy
(Decision 2011/833/EU), <https://ec.europa.eu/eurostat/about-us/policies/copyright>.

Files, in `data/raw/eurostat_waste/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `env_wasmun.tsv.gz` | 34194 | municipal waste by operation, 38 areas, 1995-2024, thousand tonnes and kg per head | <https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/env_wasmun/?format=TSV&compressed=true> |
| `env_wastrt.tsv.gz` | 905504 | all waste by operation, category and hazardousness, biennial 2004-2022 | <https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/env_wastrt/?format=TSV&compressed=true> |
| `env_epea_neep.tsv.gz` | 38819 | national environmental protection expenditure by purpose, 2012-2025, million euro | <https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/env_epea_neep/?format=TSV&compressed=true> |

The environmental purpose used is **CEP0401, "Waste management"**, under CEP04 "Waste, materials
recovery and savings". This is worth stating because the obvious guess is wrong: CEP0301 is
*wastewater* management. The code labels come from
<https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/ENV_PA?format=TSV>.

Eurostat publishes no unit cost of waste management services by country. The expenditure account is
the nearest public substitute and its numerator covers all waste, not municipal waste alone; see
`notes/data/waste_recycling.md`.

Read by `data/build/b4_eurostat_waste.py`.

### 7. Circle Economy (2025), *The Circularity Gap Report 2025*

Circle Economy (2025). *The Circularity Gap Report 2025*. Version 1.0 (May 2025). Amsterdam: Circle
Economy. <https://circularity-gap.world/2025>.

Licence: CC BY-SA 4.0, stated on the acknowledgements page (p. 71).

Files, in `data/raw/circularity_gap/` (`.gitignore`d; re-download command below):

| file | bytes | what it is |
|---|---|---|
| `CGR_Global_2025_Report.pdf` | 9802345 | the full report; source of table one and table two (pp. 23-24) and the figure-three text (p. 24) |

```
curl -L -A "$UA" -o data/raw/circularity_gap/CGR_Global_2025_Report.pdf \
  "https://circulareconomy.europa.eu/platform/sites/default/files/2025-09/CGR%202025%20complete%20document.pdf"
```

The publisher's own download button resolves through
`https://pdf.circularity-gap.world/?report=CGR_Global_2025_Report_0c90048033`, a viewer rather than a
file; the European Circular Economy Stakeholder Platform copy above is the same document as a PDF.

Read by `data/build/b4_circularity_gap.py`.

### 8. The recovery-cost gradient literature

Seven items, none of them data in the sense of the blocks above: each contributes one or a few
quantitative relations between recovery and its cost or energy, typed into
`data/build/b4_xi_literature.py` with the page. The directory `data/raw/xi_literature/` is
`.gitignore`d in full, because the licences differ and three of the seven are all-rights-reserved.
Re-download commands follow the table.

| file | bytes | citation | licence |
|---|---|---|---|
| `cullen2017_circular_economy_accepted.docx` | 149825 | Cullen, J.M. (2017). "Circular Economy: Theoretical Benchmark or Perpetual Motion Machine?" *Journal of Industrial Ecology* 21(3), 483-486. <https://doi.org/10.1111/jiec.12599>. Accepted manuscript, Cambridge Apollo. | all rights reserved (RIOXX, stated on the Apollo record) |
| `reck_graedel_2012_challenges_in_metal_recycling.pdf` | 377041 | Reck, B.K. and Graedel, T.E. (2012). "Challenges in Metal Recycling." *Science* 337(6095), 690-695. <https://doi.org/10.1126/science.1217501>. | copyright AAAS; the copy used is a third-party posting |
| `nber_w32981_economics_of_recycling_heterogeneity.pdf` | 456558 | Fullerton, D. and Kinnaman, T.C. (2024). "The Economics of Recycling Heterogeneity." NBER working paper 32981. <https://www.nber.org/papers/w32981>. | (c) the authors, all rights reserved |
| `natcomm2024_imported_plastic_waste_recycling_economics.pdf` | 938325 | Li, K., Ward, H., Lin, H.X. and Tukker, A. (2024). "Economic viability requires higher recycling rates for imported plastic waste than expected." *Nature Communications* 15, 7527. <https://doi.org/10.1038/s41467-024-51923-4>. | CC BY 4.0 |
| `epa2024_financial_assessment_us_recycling_system.pdf` | 10408313 | US EPA (2024). *An Assessment of the U.S. Recycling System: Financial Estimates to Improve Recycling Infrastructure*. EPA. | US Government work, public domain |
| `ip_etal_mrf_network_flow_model.pdf` | 1105749 | Ip, K., Testa, M., Raymond, A., Graves, S.C. and Gutowski, T. (2018). "Performance evaluation of material separation in a material recovery facility using a network flow model." *Resources, Conservation and Recycling* 131, 192-205. <https://doi.org/10.1016/j.resconrec.2017.11.021>. | Elsevier; the copy used is the authors' MIT posting |
| `vancamp2024_pitfalls_plastics_mechanical_recycling_cost.pdf` | 6559339 | Van Camp, N., Lase, I.S., De Meester, S., Hoozee, S. and Ragaert, K. (2024). "Exposing the pitfalls of plastics mechanical recycling through cost calculation." *Waste Management* 189, 300-313. <https://doi.org/10.1016/j.wasman.2024.08.030>. | Elsevier; the copy used is a project posting |

```
mkdir -p data/raw/xi_literature && cd data/raw/xi_literature
curl -L -A "$UA" -o cullen2017_circular_economy_accepted.docx \
  "https://www.repository.cam.ac.uk/bitstreams/37832832-7821-4eed-b36e-51e6643dc1af/download"
curl -L -A "$UA" -o reck_graedel_2012_challenges_in_metal_recycling.pdf \
  "https://mmta.co.uk/wp-content/uploads/2015/01/Science-Challenges-in-Metal-Recycling-Graedel-and-Reck-2012.pdf"
curl -L -A "$UA" -o nber_w32981_economics_of_recycling_heterogeneity.pdf \
  "https://www.nber.org/system/files/working_papers/w32981/w32981.pdf"
curl -L -A "$UA" -o natcomm2024_imported_plastic_waste_recycling_economics.pdf \
  "https://www.nature.com/articles/s41467-024-51923-4.pdf"
curl -L -A "$UA" -o epa2024_financial_assessment_us_recycling_system.pdf \
  "https://www.epa.gov/system/files/documents/2024-12/financial_assessment_of_us_recycling_system_infrastructure.pdf"
curl -L -A "$UA" -o ip_etal_mrf_network_flow_model.pdf \
  "https://web.mit.edu/ebm/www/Publications/Ip%20et%20al_MRF.pdf"
curl -L -A "$UA" -o vancamp2024_pitfalls_plastics_mechanical_recycling_cost.pdf \
  "https://circularplasticsnl.org/wp-content/uploads/2024/09/1-s2.0-S0956053X24004513-main.pdf"
```

The Cullen file arrives as a `.docx` whatever extension is asked for; it is the accepted manuscript
and carries table 1, which is the item wanted.

#### MANUAL, in this group

**MANUAL: <https://doi.org/10.1016/j.jeem.2014.01.004>** - Kinnaman, T.C., Shinkuma, T. and
Yamamoto, M. (2014). "The socially optimal recycling rate: Evidence from Japan." *Journal of
Environmental Economics and Management* 68(1), 54-70. Paywalled at Elsevier. This is the closest
published object to the treatment-cost gradient the model needs: it estimates the average **social
cost of municipal waste management as a function of the recycling rate**, which is `c^W(varpi)`
itself. Obtaining it is the highest-value single download left in this block.

#### Searched for and not found

No public study was found that gives cost or energy per tonne recovered as an explicit function of
the recovery rate achieved, for any single stream - aluminium, steel, copper, e-waste or plastics
sorting. Ip et al. (2018) model exactly that object for a materials-recovery facility but report it
only in figures 5 and 6. What the search did turn up is in
`data/interim/b4_xi_literature.csv` under `method = not_found` and is discussed in
`notes/data/waste_recycling.md`.

---

## B5. Pollution and damages

Task B5. Which source was chosen for which number, and why, is in `notes/data/pollution.md`;
transformations in `data/build/b5_*.py`.
All files accessed **2026-09-17**. Sizes are of the file as downloaded.

**Two download notes.** The four large PDFs are papers and assessment chapters rather than data, are
open access at stable publisher URLs, and are kept out of the history: the paths are in `.gitignore`
and each `data/build/b5_*.py` script downloads its own raw file when it is absent, so a fresh clone
rebuilds the block without a manual step. The one file that is committed is the Global Carbon Budget
flat CSV, which is the block's actual data, is 3.1 MB and is CC BY 4.0.

Reading a published number out of a PDF uses `pypdf`, which is the one dependency beyond pandas that
this block adds. Each script asserts the parsed row against the source's own adding-up condition and
stops rather than guessing if the parse fails.

### 1. Global Carbon Budget 2025: the fossil CO2 dataset

Andrew, R. M. and Peters, G. P. (2025). "The Global Carbon Project's fossil CO2 emissions dataset"
(2025v15) [Data set]. Zenodo. <https://doi.org/10.5281/zenodo.17417124>. Published 22 October 2025.

Licence: CC BY 4.0.

Files, in `data/raw/gcb/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `GCB2025v15_MtCO2_flat.csv` | 3147221 | fossil CO2 emissions by country and by fuel, 1750-2024, in MtCO2: Total, Coal, Oil, Gas, Cement, Flaring, Other; the row block `Country == "Global"` is what B5 uses | <https://zenodo.org/records/17417124/files/GCB2025v15_MtCO2_flat.csv?download=1> |
| `GCB2025v15_MtCO2_flat_metadata.json` | 3784 | field definitions, units and licence for the above | <https://zenodo.org/records/17417124/files/GCB2025v15_MtCO2_flat_metadata.json?download=1> |
| `GCP_fossilCO2_2025v15.pdf` | 893846 | the dataset's own documentation | <https://zenodo.org/records/17417124/files/GCP%20fossilCO2%202025v15.pdf?download=1> |

The `citation` field inside the metadata JSON still points at Friedlingstein et al. 2020; the release
is the 2025 one and is cited as source 2 below.

Read by `data/build/b5_gcb.py`.

### 2. Global Carbon Budget 2025: the methods paper

Friedlingstein, P., O'Sullivan, M., Jones, M. W., Andrew, R. M., Bakker, D. C. E., Hauck, J.,
Landschuetzer, P., Le Quere, C., Li, H., Luijkx, I. T., Peters, G. P., Peters, W., Pongratz, J.,
Schwingshackl, C., Sitch, S. et al. (2026). "Global Carbon Budget 2025." *Earth System Science Data*
18, 3211-3288. <https://doi.org/10.5194/essd-18-3211-2026>. Data DOI <https://doi.org/10.18160/GCP-2025>.

Licence: CC BY 4.0.

Files, in `data/raw/gcb/` (gitignored):

| file | bytes | what it is | URL |
|---|---|---|---|
| `essd-18-3211-2026.pdf` | 13426392 | the methods paper; B5 takes Table 8, "Cumulative CO2 for different time periods in gigatonnes of carbon", column 1750-2024 | <https://essd.copernicus.org/articles/18/3211/2026/essd-18-3211-2026.pdf> |

Download command:

```
curl -sSL -o data/raw/gcb/essd-18-3211-2026.pdf \
  https://essd.copernicus.org/articles/18/3211/2026/essd-18-3211-2026.pdf
```

Read by `data/build/b5_gcb.py`, which parses the Table 8 row block anchored on the column header
`1750-2024 1850-2014 1850-2024 1960-2024 1850-2025` so that it cannot match Table 7, which carries
the same row labels for decadal mean flows.

**MANUAL: the Global Carbon Budget supplemental workbook.** The annual land-use change and
partitioning series live in `Global_Carbon_Budget_2025v1.0.xlsx` at
<https://www.icos-cp.eu/GCP/2025> (object `qSjPBsV1drZnYdH-yCJMmkGn`), behind a licence-acceptance
step that returns an HTML page to a script rather than the workbook. B5 does not need the annual
land-use series, only the cumulative totals, which the paper prints; a block that needs the annual
series has to accept the licence in a browser. Metadata:
<https://meta.icos-cp.eu/objects/qSjPBsV1drZnYdH-yCJMmkGn>.

### 3. Joos et al. (2013): the CO2 impulse response function

Joos, F., Roth, R., Fuglestvedt, J. S., Peters, G. P., Enting, I. G., von Bloh, W., Brovkin, V.,
Burke, E. J., Eby, M., Edwards, N. R., Friedrich, T., Froelicher, T. L., Halloran, P. R., Holden,
P. B., Jones, C., Kleinen, T., Mackenzie, F. T., Matsumoto, K., Meinshausen, M., Plattner, G.-K.,
Reisinger, A., Segschneider, J., Shaffer, G., Steinacher, M., Strassmann, K., Tanaka, K., Timmermann,
A. and Weaver, A. J. (2013). "Carbon dioxide and climate impulse response functions for the
computation of greenhouse gas metrics: a multi-model analysis." *Atmospheric Chemistry and Physics*
13, 2793-2825. <https://doi.org/10.5194/acp-13-2793-2013>

Licence: CC BY 3.0.

Files, in `data/raw/joos2013/` (gitignored):

| file | bytes | what it is | URL |
|---|---|---|---|
| `acp-13-2793-2013.pdf` | 5538185 | the paper; B5 takes Table 5, row `IRF_CO2`, and equation (11) | <https://acp.copernicus.org/articles/13/2793/2013/acp-13-2793-2013.pdf> |

Download command:

```
curl -sSL -o data/raw/joos2013/acp-13-2793-2013.pdf \
  https://acp.copernicus.org/articles/13/2793/2013/acp-13-2793-2013.pdf
```

Table 5 row `IRF_CO2` reads, verbatim: `IRFCO2 0.6 0.2173 0.2240 0.2824 0.2763 394.4 36.54 4.304`,
the columns being the mean relative error of the fit in per cent, then `a0, a1, a2, a3` and
`tau1, tau2, tau3` in years. The fit is to the multi-model mean response to a pulse of 100 GtC added
to a 389 ppm background under present-day climate, and the paper states it holds only for
0 < t < 1000 yr. The PDF carries an owner password and the Read tool refuses it; `pypdf` opens it.

Read by `data/build/b5_joos2013.py`.

### 4. DICE-2023: the damage function

Barrage, L. and Nordhaus, W. (2024). "Policies, projections, and the social cost of carbon: Results
from the DICE-2023 model." *Proceedings of the National Academy of Sciences* 121(13), e2312030121.
<https://doi.org/10.1073/pnas.2312030121>

Licence: CC BY 4.0 (the article states it).

Files, in `data/raw/dice2023/`:

| file | bytes | what it is | URL |
|---|---|---|---|
| `barrage_nordhaus_2024_pnas.pdf` | 727994 | the paper; B5 takes Section 3.3 "Damages" and Section 4.6 | <https://economics.yale.edu/sites/default/files/2024-03/barrage-nordhaus-2024-policies-projections-and-the-social-cost-of-carbon-results-from-the-dice-2023-model.pdf> |

The same file is at <https://www.pnas.org/doi/pdf/10.1073/pnas.2312030121>; the Yale copy is used
because it serves a script without a browser user agent.

The paper's equations are typeset as images and do not survive text extraction, but their symbolic
form does: output is `Q = [1 - Lambda][1 - Omega] A K^gamma L^(1-gamma)` and the damage share is
`Omega = pi1 T_AT + pi2 T_AT^2`, with `T_AT` measured from the 1765 preindustrial baseline. The
coefficients themselves are not printed; the calibration is given as two points on the curve, "in
total, damages are estimated to be 3.1% of output at 3 degC warming and 7.0% of output at 4.5 degC
warming", and `b5_dice2023.py` backs `(pi1, pi2)` out of those two points.

**MANUAL: the DICE-2023 GAMS code and SI Appendix.** The published coefficient would settle the
rounding directly. The SI Appendix is at
<https://www.pnas.org/doi/suppl/10.1073/pnas.2312030121/suppl_file/pnas.2312030121.sapp.pdf> and the
model code is distributed from Nordhaus' Yale page, <https://williamnordhaus.com/dicerice-models>.
Neither was downloaded; the two published points over-identify the quadratic and the check residual
is reported, so the block does not depend on them.

### 5. IPCC AR6 WGI: the transient climate response to cumulative emissions

Canadell, J. G., Monteiro, P. M. S., Costa, M. H., Cotrim da Cunha, L., Cox, P. M., Eliseev, A. V.,
Henson, S., Ishii, M., Jaccard, S., Koven, C., Lohila, A., Patra, P. K., Piao, S., Rogelj, J.,
Syampungani, S., Zaehle, S. and Zickfeld, K. (2021). "Global Carbon and other Biogeochemical Cycles
and Feedbacks." In *Climate Change 2021: The Physical Science Basis. Contribution of Working Group I
to the Sixth Assessment Report of the Intergovernmental Panel on Climate Change*, Cambridge
University Press, 673-816. <https://doi.org/10.1017/9781009157896.007>

Licence: the chapter PDF is distributed by the IPCC for non-commercial use with attribution; it is
cited, not redistributed here.

Files, in `data/raw/ipcc_ar6_wg1/` (gitignored):

| file | bytes | what it is | URL |
|---|---|---|---|
| `IPCC_AR6_WGI_Chapter05.pdf` | 24623157 | the chapter; B5 takes Section 5.5.1.4 "Combined Assessment of TCRE" | <https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WGI_Chapter05.pdf> |

Download command:

```
curl -sSL -A "Mozilla/5.0" -o data/raw/ipcc_ar6_wg1/IPCC_AR6_WGI_Chapter05.pdf \
  https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WGI_Chapter05.pdf
```

Read by `data/build/b5_ipcc_ar6.py`, which parses the two sentences of Section 5.5.1.4 that carry
the assessed range and the best estimate and checks that they agree on the bounds.

### 6. Strategy (A), recorded and not built

Decision D4 makes strategy (A), materials-as-pollution, a variant. Nothing below was downloaded.
What each would be for is in `notes/data/pollution.md`.

| source | what it would give | URL |
|---|---|---|
| IHME, Global Burden of Disease Study 2021, risk-factor attributable burden | deaths and DALYs attributable to ambient and household particulate matter, lead and occupational exposures, 1990-2021, by country | <https://ghdx.healthdata.org/gbd-2021> |
| IHME GBD 2021 air pollution exposure estimates and risk curves 1990-2021 | the exposure-response curves behind the above | <https://ghdx.healthdata.org/record/ihme-data/gbd-2021-air-pollution-exposure-estimates-1990-2021> |
| OECD (2016), *The Economic Consequences of Outdoor Air Pollution* | welfare cost of premature mortality and morbidity as a share of GDP, by region, with projections | <https://www.oecd.org/content/dam/oecd/en/publications/reports/2016/06/the-economic-consequences-of-outdoor-air-pollution_g1g68583/9789264257474-en.pdf> |
| OECD (2014), *The Cost of Air Pollution: Health Impacts of Road Transport* | the value-of-statistical-life method the welfare costs rest on | <https://www.oecd-ilibrary.org/environment/the-cost-of-air-pollution_9789264210448-en> |
| OECD Environment Statistics, "Mortality and welfare cost from exposure to air pollution" | the maintained annual series of the same | <https://www.oecd-ilibrary.org/environment/data/air-quality-and-health/mortality-and-welfare-cost-from-exposure-to-air-pollution_c14fb169-en> |

---

## C. What the calibration added to the blocks

Phase C, beyond blocks B1 to B5. What each is used for is in `writing/quant/quant_data.tex`; why it
was chosen is in `notes/data/calibration.md`. Phase C also reads two Penn World Table variables the
B2 pipeline did not extract, the internal rate of return `irr` and the labour share `labsh`, from the
workbook `data/raw/pwt1001/pwt1001.xlsx` recorded under B2; nothing new was downloaded for them.
All files accessed **2026-09-17**.

### 1. EEA (2001), Total material requirement of the European Union

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

### 2. World Bank Commodity Price Data (the Pink Sheet), annual

World Bank (2026). *Commodity Price Data (The Pink Sheet)*, annual prices 1960 to present,
nominal and real. Updated 6 January 2026.
<https://thedocs.worldbank.org/en/doc/18675f1d1639c7a34d463f59263ba0a2-0050012025/related/CMO-Historical-Data-Annual.xlsx>.
Accessed 2026-09-17. Licence: Creative Commons Attribution 4.0 (World Bank open data terms).

Raw: `data/raw/worldbank_cmo/CMO-Historical-Data-Annual.xlsx`. Used: sheet "Annual Prices
(Nominal)", columns "Crude oil, average" ($/bbl), "Coal, Australian" ($/mt), "Natural gas, US",
"Natural gas, Europe", "Liquefied natural gas, Japan" ($/mmbtu), years 2011 and 2015, in
`data/build/c2_production_trends.py`. Oil is converted at 7.33 barrels per tonne, the factor
stated in footnote 5 of Rogner et al. (2012) (block B3, source 6a); gas at
1.05506 GJ per mmbtu (a unit definition) and the IPCC (2006) net calorific value of 48 GJ/t already
in `data/build/b3_gcb_fossil.py`.

### 3. World Development Indicators, world aggregate

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

---

## Not obtained

Every MANUAL item of the blocks above, collected. None is used anywhere; each says what it holds and
why it failed. The plan's rule is that a value that cannot be downloaded is recorded here and the
task continues without it, never estimated in its place.

| what it holds | block | why it failed | what stands in its place |
|---|---|---|---|
| Krausmann et al. (2017), PNAS supporting information: in-use material stocks 1900-2010 by material group, the Monte Carlo simulation, the stock age distribution | B1 | PNAS answers HTTP 403 to every non-browser request, the PMC copy (PMC5338421) is not in the open-access subset, and the PMC file endpoint is behind a proof-of-work challenge | Krausmann et al. (2018), which carries the same MISO model to 2015 |
| Haas et al. (2015), article and supporting information: the 2005 cross-section of end-of-life recycling as a share of material input | B1 | Wiley answers HTTP 403 to every non-browser request, for the article and every supplement path tried | Haas et al. (2020), the same accounting annually for 1900-2015 |
| UN IRP Global Material Flows Database, the current 1970-2024 vintage | B1 | served only through the publisher's Shiny application, which has no scriptable bulk endpoint | the World Bank `energydata.info` mirror of the vintage ending in 2019 |
| Unused domestic extraction (overburden), global, by category | B1 | no source in the block reports it; the IRP technical annex describes it as module 5 but the published database does not carry it | the EEA (2001) EU-15 ratios of block C, which is what makes $\Omega^{N,S}$ the weak point (review R9) |
| Piketty and Zucman (2014): the eight non-US country workbooks, `AppendixTables.xls` and `Figures.xls` | B2 | they download cleanly but are pre-2007 BIFF workbooks, and `xlrd` is not among the packages this project may use | the United States workbook alone enters the capital cross-check |
| USGS *Mineral Commodity Summaries 2026* bulk data release (<https://doi.org/10.5066/P1WKQ63T>) | B3 | ScienceBase answers HTTP 403 behind a Cloudflare interstitial from this machine, to `curl` with a full browser header set and to the agent's fetch tool | the published report, transcribed with page numbers in `b3_usgs_mcs.py` |
| West (2011), "Decreasing metal ore grades" | B3 | paywalled at Wiley; no open version located | nothing is missing but its argument, which `notes/data/resources.md` records; it tabulates no series |
| BGR *Energy Study 2024*: fossil reserves and resources | B3 | every `bgr.bund.de` and mirror URL answered HTTP 400 or 404 from this machine | Rogner et al. (2012) Table 7.1 alone, which is the older of the two and should be cross-checked when the file is in hand |
| Rankin (2011), *Minerals, Metals and Sustainability*: crustal-abundance estimates of metal URR | B3 | a paywalled monograph; no open copy located | the USGS Global Mineral Resource Assessment figures as reported in MCS 2026 |
| S&P Global, *World Exploration Trends*: annual exploration budgets | B3 | commercial; the public summary carries a headline total and no series | Schodde's MinEx presentations, built partly from the same S&P data |
| Graedel et al. (2011), *Journal of Industrial Ecology*, "What Do We Know About Metal Recycling Rates?" | B4 | paywalled at Wiley; the USGS staff-publications copy answers HTTP 403 | the UNEP IRP (2011) report, the same working group and the same estimates, which is downloaded |
| Kinnaman, Shinkuma and Yamamoto (2014), "The socially optimal recycling rate": the average social cost of municipal waste management as a function of the recycling rate, which is $c^W(\varpi)$ itself | B4 | paywalled at Elsevier | nothing; $\xi$ rests on the engineering cost evidence of the same entry. **The highest-value single download left in the pipeline** |
| A public study giving cost or energy per tonne recovered as an explicit function of the recovery rate, for any single stream | B4 | searched for and not found; Ip et al. (2018) model exactly that object but report it only in figures | the scattered relations of `b4_xi_literature.py`, which is why `notes/data/waste_recycling.md` calls $\xi$ the thin spot |
| Global Carbon Budget supplemental workbook: annual land-use change and partitioning series | B5 | the ICOS licence-acceptance step returns an HTML page to a script rather than the workbook | not needed: B5 uses the cumulative totals, which the methods paper prints |
| DICE-2023 GAMS code and SI Appendix: the published damage coefficients | B5 | not downloaded | the two published points on the damage curve, which over-identify the quadratic; the check residual is reported |
| Strategy (A) sources: IHME GBD 2021 burden and exposure, the three OECD air-pollution costings | B5 | not downloaded, by decision D4, which makes materials-as-pollution a variant | strategy (B), the CO2 bridge; what (A) would need is in `notes/data/pollution.md` |
| Schandl et al. (2018), "Global Material Flows and Resource Productivity": a global unused-extraction ratio | C | Wiley refuses automated download (HTTP 403 on the pdfdirect link) and Unpaywall lists no open copy | the EEA (2001) EU-15 ratios at the world composition, marked weak (review R9) |
| BP or Energy Institute energy conversion factors | C | both sites refuse automated download (HTTP 403) | the barrel-to-tonne factor of Rogner et al. (2012), footnote 5; no loss |
| Oil and gas exploration spend | C | not sought: the sources are commercial | the exploration cost check compares the model's $C^D$ with metals exploration only |
| A cost-of-production series for fossil fuels or ores before 1960 | C | none public | the extraction cost level is a 2011-2015 number and the century's path is the price index |
