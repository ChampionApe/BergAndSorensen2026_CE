# B5 sources: pollution and damages

Provenance for the sources of task B5 of `notes/plan_calibration_experiments.md`. Assembled into the
root `data/SOURCES.md` later; this file is the block's own entry list. Which source was chosen for
which number, and why, is in `notes/data/pollution.md`, not here.

All files accessed **2026-09-17**. Sizes are of the file as downloaded.

**Two download notes.** The four large PDFs are papers and assessment chapters rather than data, are
open access at stable publisher URLs, and are kept out of the history: the paths are in `.gitignore`
and each `data/build/b5_*.py` script downloads its own raw file when it is absent, so a fresh clone
rebuilds the block without a manual step. The one file that is committed is the Global Carbon Budget
flat CSV, which is the block's actual data, is 3.1 MB and is CC BY 4.0.

Reading a published number out of a PDF uses `pypdf`, which is the one dependency beyond pandas that
this block adds. Each script asserts the parsed row against the source's own adding-up condition and
stops rather than guessing if the parse fails.

---

## 1. Global Carbon Budget 2025: the fossil CO2 dataset

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

## 2. Global Carbon Budget 2025: the methods paper

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

## 3. Joos et al. (2013): the CO2 impulse response function

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

## 4. DICE-2023: the damage function

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

## 5. IPCC AR6 WGI: the transient climate response to cumulative emissions

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

## 6. Strategy (A), recorded and not built

Decision D4 makes strategy (A), materials-as-pollution, a variant. Nothing below was downloaded.
What each would be for is in `notes/data/pollution.md`.

| source | what it would give | URL |
|---|---|---|
| IHME, Global Burden of Disease Study 2021, risk-factor attributable burden | deaths and DALYs attributable to ambient and household particulate matter, lead and occupational exposures, 1990-2021, by country | <https://ghdx.healthdata.org/gbd-2021> |
| IHME GBD 2021 air pollution exposure estimates and risk curves 1990-2021 | the exposure-response curves behind the above | <https://ghdx.healthdata.org/record/ihme-data/gbd-2021-air-pollution-exposure-estimates-1990-2021> |
| OECD (2016), *The Economic Consequences of Outdoor Air Pollution* | welfare cost of premature mortality and morbidity as a share of GDP, by region, with projections | <https://www.oecd.org/content/dam/oecd/en/publications/reports/2016/06/the-economic-consequences-of-outdoor-air-pollution_g1g68583/9789264257474-en.pdf> |
| OECD (2014), *The Cost of Air Pollution: Health Impacts of Road Transport* | the value-of-statistical-life method the welfare costs rest on | <https://www.oecd-ilibrary.org/environment/the-cost-of-air-pollution_9789264210448-en> |
| OECD Environment Statistics, "Mortality and welfare cost from exposure to air pollution" | the maintained annual series of the same | <https://www.oecd-ilibrary.org/environment/data/air-quality-and-health/mortality-and-welfare-cost-from-exposure-to-air-pollution_c14fb169-en> |
