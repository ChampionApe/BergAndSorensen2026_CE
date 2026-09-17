# B1 sources: core material flows and stocks

Provenance for the sources of task B1 of `notes/plan_calibration_experiments.md`. Assembled into the
root `data/SOURCES.md` later; this file is the block's own entry list. Which source was chosen for
which series, and why, is in `notes/data/material_flows.md`, not here.

All files accessed **2026-09-17**. Sizes are of the file as downloaded.

---

## 1. Krausmann, Lauk, Haas and Wiedenhofer (2018)

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

## 2. Krausmann et al. (2017), PNAS

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

## 3. Haas, Krausmann, Wiedenhofer, Heinz and Pichler (2020)

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

### 3b. Haas, Krausmann, Wiedenhofer and Heinz (2015)

Haas, W., Krausmann, F., Wiedenhofer, D. and Heinz, M. (2015). "How Circular is the Global Economy?
An Assessment of Material Flows, Waste Production, and Recycling in the European Union and the World
in 2005." *Journal of Industrial Ecology* 19(5), 765-777. <https://doi.org/10.1111/jiec.12244>

Licence: CC BY 4.0 (version of record, per Crossref).

**MANUAL: <https://onlinelibrary.wiley.com/doi/full/10.1111/jiec.12244> - article and supporting
information (the 2005 cross-section of end-of-life recycling as a share of material input).**
Wiley returns HTTP 403 to every non-browser request, for the article and for every supplement path
tried. The 2020 update above supersedes it for this block's purpose: it carries the same accounting
annually for 1900-2015 rather than for 2005 alone.

## 4. UN IRP Global Material Flows Database

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

## 5. Krausmann et al. (2009), in the 2011 update

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

## Not obtained

| what | where it would come from | status |
|---|---|---|
| Unused domestic extraction / overburden, global, by category | no source in this block reports it; the IRP technical annex describes it as module 5 but the published database does not carry it | **not obtained**; `Omega^{N,S}` has no observed counterpart from B1 |
| In-use stocks 1900-2010 by material group, Krausmann et al. (2017) | PNAS supporting information | MANUAL, source 2 above |
| End-of-life recycling as a share of input, 2005, Haas et al. (2015) | Wiley supporting information | MANUAL, source 3b above |
| IRP Global Material Flows Database, 1970-2024 vintage | the IRP's own portal | MANUAL, source 4 above |
