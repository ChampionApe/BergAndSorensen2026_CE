# B4 sources: waste handling and recycling

Provenance for the sources of task B4 of `notes/plan_calibration_experiments.md`. Assembled into the
root `data/SOURCES.md` later; this file is the block's own entry list. Which source was chosen for
which parameter, and why, is in `notes/data/waste_recycling.md`, not here.

All files accessed **2026-09-17**. Sizes are of the file as downloaded.

Two `curl` conventions recur below and are not repeated in each cell.
`UA` is a browser user-agent string; `wedocs.unep.org` and several publisher hosts return HTTP 403
without one, and the UNEP bitstream endpoint additionally needs `-H "Referer: https://wedocs.unep.org/"`.

```
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
```

---

## 1. Kaza, Yao, Bhada-Tata and Van Woerden (2018), *What a Waste 2.0*

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

## 2. UNEP (2024), *Global Waste Management Outlook 2024*

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

## 3. UNEP IRP (2011), *Recycling Rates of Metals: A Status Report*

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

## 4. Graedel et al. (2011), *Journal of Industrial Ecology* - MANUAL

Graedel, T.E., Allwood, J., Birat, J.-P., Buchert, M., Hagelueken, C., Reck, B.K., Sibley, S.F. and
Sonnemann, G. (2011). "What Do We Know About Metal Recycling Rates?" *Journal of Industrial Ecology*
15(3), 355-366. <https://doi.org/10.1111/j.1530-9290.2011.00342.x>.

**MANUAL: <https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1530-9290.2011.00342.x>.** Paywalled at
Wiley. The USGS staff-publications copy at
`https://digitalcommons.unl.edu/cgi/viewcontent.cgi?article=1605&context=usgsstaffpub` returns
HTTP 403 to every request tried, with and without a browser user-agent and referer.

Nothing is lost but the citation: this is the journal version of source 3, by the same working group
with the same estimates, and source 3 is downloaded.

## 5. OECD Environment Statistics, municipal waste

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

## 6. Eurostat waste statistics and environmental protection expenditure

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

## 7. Circle Economy (2025), *The Circularity Gap Report 2025*

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

## 8. The recovery-cost gradient literature

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

### MANUAL, in this group

**MANUAL: <https://doi.org/10.1016/j.jeem.2014.01.004>** - Kinnaman, T.C., Shinkuma, T. and
Yamamoto, M. (2014). "The socially optimal recycling rate: Evidence from Japan." *Journal of
Environmental Economics and Management* 68(1), 54-70. Paywalled at Elsevier. This is the closest
published object to the treatment-cost gradient the model needs: it estimates the average **social
cost of municipal waste management as a function of the recycling rate**, which is `c^W(varpi)`
itself. Obtaining it is the highest-value single download left in this block.

### Searched for and not found

No public study was found that gives cost or energy per tonne recovered as an explicit function of
the recovery rate achieved, for any single stream - aluminium, steel, copper, e-waste or plastics
sorting. Ip et al. (2018) model exactly that object for a materials-recovery facility but report it
only in figures 5 and 6. What the search did turn up is in
`data/interim/b4_xi_literature.csv` under `method = not_found` and is discussed in
`notes/data/waste_recycling.md`.
