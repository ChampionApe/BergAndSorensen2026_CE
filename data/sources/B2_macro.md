# B2 sources: macro aggregates and the use split

Provenance for the sources of task B2 of `notes/plan_calibration_experiments.md`. Assembled into the
root `data/SOURCES.md` later; this file is the block's own entry list. Which source was chosen for
which series, and why, is in `notes/data/macro.md`, not here.

All files accessed **2026-09-17**. Sizes are of the file as downloaded.

**One download note that applies to sources 1 and 2.** Both are served from DataverseNL, which sits
behind the Anubis bot filter. The filter's policy denies a bare `curl/*` user agent outright (HTTP
200 with a 2236-byte "Access Denied" page, which a script will happily save as an `.xlsx`) and
serves every other non-browser client normally. The downloads below were made with Python's
`urllib.request` at its default user agent, which the filter allows. `curl -O` will silently
produce a broken file; check that the result is a zip archive, not HTML, before trusting it.

---

## 1. Maddison Project Database 2023

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

## 2. Penn World Table 10.01

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

## 3. Piketty and Zucman (2014), "Capital is Back"

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

## What the block could not obtain

- The eight non-US Piketty-Zucman workbooks, for the reason above (MANUAL entry under source 3).
- Nothing else. No world investment share before 1950 was sought from a source, because none was
  found that is global rather than a handful of rich countries; what the pipeline does instead is
  in `notes/data/macro.md` and is flagged `reconstructed` at the row level.
