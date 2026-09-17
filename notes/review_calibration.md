# E1: adversarial review of the calibration and the experiments (2026-09-18)

Task E1 of `notes/plan_calibration_experiments.md`. Everything phases B to D produced was read:
`data/processed/` (the two JSONs, `series.csv`, the `c*` and `d*` files), `data/build/`,
`data/interim/` spot-checked to `data/raw/` and `data/sources/`, `notes/data/`,
`writing/quant/quant_data.tex` and `Tables/`, `model/scripts/run_d1.jl` to `run_d4.jl`,
`model/output/`. Nothing was changed. Numbers not in the reports were produced by three scratch
runs, none committed: a Python pass over `series.csv` (the ledger, the implied $c_N$ path, the
cumulative flows), `pdftotext` on three raw PDFs, and `model/output/e1_review/check.jl` (the
baseline and the $\bar R=23.756$ cell at $T=200$ at the three values of $\mu_N$; output in
`check.txt` beside it, gitignored).

Dispositions: **code** (fix in code), **refit** (refit a parameter), **reword** (reword a claim),
**limitation** (record as a limitation), **none** (no action). Count by primary disposition:
code 6, refit 3, reword 10, limitation 6, none 6; 31 findings. The checklist items of the brief are mapped to findings in
the last section.

## Findings, ranked by consequence for the paper

### R1. The welfare numbers are decided by the discount rate and the damage price, and both sit at the least defensible end of their ranges — **limitation**, with two sensitivities recommended

Every welfare number of E2 and E3 is below $10^{-3}$ percent of consumption (`d2_report.md`,
`d3_report.md`; `Tables/Circularity.tex`, `Tables/Instruments.tex`). Three things make it so,
and all three are the calibration, not the solver or the model.

1. *The discount factor on the planner's path is $\beta e^{(1-\eta)g}=0.954$ per year*
   (`d1_taxonomy.txt`, tvc factor), so a date 200 years out carries weight $8\times10^{-5}$.
   That factor is $\rho=3.74$ percent with $\eta=1.41$ at $g=2.5$ percent, an interest rate of
   7.5 percent (`Data_preferences.tex`). $\rho$ is the intercept of a seven-point regression of
   the PWT internal rate of return on decade growth (`c5_preferences_damages.py`; re-derived,
   $\rho=0.03744$, $\eta=1.4088$). PWT's `irr` is net of depreciation but gross of risk premia
   and taxes, so the note's "gross return on productive capital" is the right caveat; a 7.5
   percent social rate on a 400-year problem is the number that decides every level in the
   tables and the gate-fee date.
2. *The damage price is a marginal DICE loss at 7.5 percent.* $\kappa=6.78\times10^{-6}$ per Gt
   (`Data_damages.tex`) gives a pollution price scale $\kappa Y/(r+\theta)$ of 7.8 dollars per
   tonne of material in 2015, which is 11 dollars per tonne of CO$_2$ at the bridge's 0.706
   tCO$_2$/t. DICE-2023's own social cost of carbon at its own preferences is several times that;
   the gap is the discount rate again, not the damage function.
3. *The utility channel is off*, $\psi=0$ (`notes/data/pollution.md`), for a stated reason (DICE
   has no non-market loss to take it from), so `Vp = 0` at every corner and damages reach welfare
   only through $F_P=-\kappa Y$.

What a defensible alternative would change: the Howard–Sterner $\pi_2=0.01$ and the high TCRE,
both already in `b5_pollution_block.csv`, multiply $\kappa$ by about six and the CE numbers by
about the same; the E2 headline at the best cell would move from 0.04 to roughly 0.2 percent. That
is still "small". DICE-2023's preferences ($\rho=1.5$ percent, $\eta=1.45$) would put the
per-period weight factor near 0.974, raising the weight after 2100 by a factor of about 60, and
the gate fee would turn negative earlier. Strategy (A) of the data plan (materials as pollution)
would price the whole outflow rather than its fossil quarter, but it needs a damage per tonne
and a regeneration rate that no source in the pipeline gives (`pollution.md`, "What strategy (A)
would need"). Recommendation: do not refit; report $\kappa\times6$ and the DICE preference pair
as two sensitivity rows in the results section, and state in prose that the welfare value of
circularity on this calibration is a statement about the discount rate. Also note (R10) that
the welfare comparison is truncated at $T=400$ before the resource side dies, so the level effect
of $\mathcal M_\infty$ the theory names (Appendix B, eq. `app:wh:cbgp:level`) is not in any
welfare number; at these preferences it would be discounted away in any case.

### R2. The model's pollution stock carries overburden that the CO$_2$ bridge never priced — **refit** $\kappa$ or **reword** D4

`period.jl` line 73: `W = R - Omega*phiI*G + delta*MK + Nbase` with `Nbase = OmNS*N + OmDS*D`.
Unused extraction enters the stockpile, is handled at $\mu$ and leaks to $P$ like everything else.
On the solved baseline in 2015 (`check.txt`) the model's waste flow is 96.9 Gt of which `Nbase`
is $0.932\times47.7=44$ Gt, so 45 percent of what reaches $P$ is overburden. $\kappa$ was built
as the loss per GtCO$_2$ times the fossil share of *DPO* (0.261, `c5_preferences_damages.csv`),
and DPO excludes unused extraction. The fossil share of the model's own $\Xi$ is nearer 0.14. The
model therefore prices overburden as if it were a quarter fossil carbon, and $P$ overshoots the
CO$_2$ evidence it was bridged from: 1673 Gt of material in 2015 on the baseline, 1181 GtCO$_2$
at the bridge, against the 865 GtCO$_2$ atmospheric excess stock `series.csv` carries for 2015.
Disposition: either the bridge is the fossil share of the model's $W$ (with `Nbase` in the
denominator, halving $\kappa$), or `Nbase` is booked into $\mathcal W$ but not into $\Xi$ (a model
change, not made here). The first is a refit inside `c5_preferences_damages.py` and should be
stated in `quant_data.tex`, "Damages and decay".

### R3. $\mu$ is the growth rate of the disposal flow in disguise, and it reproduces the whole outflow, not the disposal flow — **reword** the appendix, **limitation**

$\mu=18.62/533.7=0.0349$ (`c4_waste.csv`). The stock is the cumulated flow with no recorded
removal, and for a flow growing at rate $g$ the stock-to-flow ratio of its own cumulation is
about $1/g$; the disposal flow grew at 3.03 percent per year over 1900–2015 (`series.csv`,
`H_disposal`). So $\mu$ is not identified by the stock-to-flow ratio: any cumulated series with
the same growth gives the same number, and the identification would need a measured removal
from the stock, which no source reports (`waste_stock.md` says as much about recovery).

On the solved baseline the handled flow in 2015 is 66.2 Gt (`check.txt`; `c4_handling_level.json`
reports 66), not the 18.6 Gt the appendix says $\mu\mathcal W$ reproduces. The model's stock
(1898 Gt in 2015) is 3.6 times the data's landfill stock because it books every outflow and the
overburden, and $3.6\times18.6=66$. The 66 Gt is not wrong on the model's own definition: $H$ is
everything leaving the stockpile, untreated to the environment and treated to recovery, whose
data counterpart is DPO plus secondary input, 63.8 Gt in 2015 (`series.csv`). The model's 2015
leakage $\Xi=50.3$ Gt is within 13 percent of DPO (57.7). So the flow is right and the appendix
describes the wrong object: `quant_data.tex`, "The stockpile", says $\mu\mathcal W_{2015}$ equals
"the outflow of those three categories to disposal", and it does not.

Two consequences follow. The stock is in the wrong place in time: the data emit CO$_2$ and
dissipative losses in the year of use, the model parks 100 percent of every outflow in the
stockpile for 29 years on average, so $\Xi$ lags DPO early (18.4 against 12.6 Gt in 1950 is the
overburden; the shape differs throughout). And $\mathcal W_0$, "flow-consistent" at 16.4 Gt, is
consistent with the 1900 disposal flow at a $\mu$ that the model does not apply to that flow.
Disposition: reword the appendix and `waste_stock.md` to say what $\mu$ is (a residence time
equal to the inverse growth rate of the cumulated disposal flow), what $H$ reproduces (the whole
outflow), and record the timing mismatch as the limitation it is.

### R4. The recycled-share overshoot is the yield, not the stockpile reading — **reword** `calibration.md` and `quant_data.tex`

D0b attributed the 0.22 model recycled share against 0.096 observed to "the tail rate's and the
stockpile's" problems. On the numbers of `check.txt` it is the yield alone. The model's 2015
handled flow (66.2) matches the data's whole outflow (63.8), and its treated share (0.252) matches
the treated tonnage the observed yield was computed on ($0.62\times24.5=15.2$ Gt on $H=63.8$ is
0.24). What differs is the yield at the treated tonne: the model's recycling-capital margin picks
$x=0.43$ and $a=0.687$ where the calibration point of $\xi$ is $x=0.18$, $a=0.388$
(`Data_waste.tex`). The recovered share of the handled flow is 0.173 against 0.096, a factor 1.8,
and that is the whole overshoot.

Why the margin over-invests is the aggregation: $a'(x)\,\mathcal G^K=\tilde F_K$ with
$\tilde F_K\approx0.11$ needs $\mathcal G^K\approx130$ dollars per recovered tonne at $x=0.43$
and about 66 at the data's $x=0.18$. The EPA outlay (600 dollars of capital per annual tonne)
with an 11 percent return values a marginal recovered tonne at 66 dollars; the model values it at
the mass aggregate's $\Psi\approx\gamma Y/R$, 130 to 180 dollars per tonne, an average across
fossil at 370, iron ore at 81 and stone at 9 dollars per tonne (`Data_production.tex`), when the
tonnes actually recovered are mostly the cheap ones. Disposition: reword the two attributions; it
is Section "The aggregation cost of one material" of `quant_calibration.tex` showing up in a
number, and worth saying there. Not a reason to move $\xi$.

### R5. The shutdown dates in three tables are the branch's wall, not dates — **code** (the tables), **reword** (state A)

D4 established it (`d4_shutdown.txt`): the objective is monotone in the date on `200:10:400`, 280
is the last date the branch solves, the next 80 periods are worth $3\times10^{-4}$ of the
objective. `Tables/Taxonomy.tex`, `Circularity.tex` and `Surface.tex` all print 280 in the
$T^\dagger$ column; `Surface.tex` alone carries the caveat in its note. What the A cells can
claim: the state, which follows from Lemma "finite cumulative throughput" under a hard ceiling
and needs no computed shutdown; $\mathcal M_\infty$ and the survival ratio at the horizon; the
gate-fee date. What they cannot claim: $T^\dagger$, an era length (the "Era ends" column is empty
in all 18 rows of `Circularity.tex`), or that collapse is exhibited. On this calibration the
duration bound of eq. `sp:lr:duration` is $\bar{\mathcal R}/\bar R$ with $\bar{\mathcal R}$ about
$5\times10^5$ Gt at $\bar a=0.708$, which is 50,000 periods at $\bar R=9.5$ and 21,000 at 23.8:
"collapse despite growth" is a statement about tens of millennia, and over 400 years the A-cell
paths differ from the C-cell paths only in the ceiling. Disposition: drop or relabel the
$T^\dagger$ column in `run_experiments.jl` (`>280`, branch wall) and drop "Era ends"; the E2
consumption-equivalent gains in A cells stand, with the note that both paths are solved without a
shutdown. Withdraw no state.

### R6. The theory's claim that each failure "pushes the wrong way" is wrong for the discovery tax and over-strong for the precondition — **reword** `theory_market_implementation.tex`

(a) `d3_report.md`: switching $\phi^X$ off *raises* $\mathcal M_\infty$ (87,049 against 84,467
Gt) and the survival ratio (85.5 against 83.0), monotonically along the dial path, while welfare
falls. That is the model's accounting, not a code error: $\mathcal M_\infty$ is
$M^K_0+\mathcal W_0+\sum(N+\mathcal N)-\sum(1-a\varpi)H$ (eq. `app:wh:cbgp:retained`), and more
exploration raises the inflow term directly, while the displaced mass $\Omega^{D,S}D$ enters
$\mathcal W$, which is retained. The sentence in "Laissez-faire and the survival margin" conflates
the welfare cost of excessive exploration (real resources burnt) with its effect on the retained
endowment, which is positive at any finite horizon. The claim is wrong as stated, not merely
uncovered by the calibration: it would need the extra matter to leak more than it adds, which the
ledger does not deliver. Reword to: the pollution and attribution failures lower
$\mathcal M_\infty$; the exploration failure raises it while lowering welfare, so laissez-faire is
not the worst corner for survival (it is not: (0,0,0,1) is, at 72.6).

(b) "The precondition: who owns the stockpile" says that without $\tau^W$ "every margin above
unravels at once" and none of the three instruments does anything. In the code only $z$ is inert:
`zeta_star = sigma (tauW - pM)` and `pM`'s dividend is `delta tauW`, so both vanish at
$\phi^W=0$ (`period.jl`, `residuals.jl`), which is why the four $\phi^z$ pairs at $\phi^W=0$
coincide to every digit. The emission tax and the discovery tax keep their bases and move the
allocation at $\phi^W=0$ ((0,1,1,1) against (0,1,0,1): 76,332 against 74,976 Gt). The theory is
right that $z$ needs the disposal market and over-claims for the other two. Reword; present the
16 corners as 12 distinct allocations (or keep 16 and mark the four duplicate pairs), and say
that the identity is the precondition paragraph made exact.

### R7. The calibrated path does not reproduce 1900–2015 and nobody has said so — **limitation**, with a fit table in the write-up

The calibration reads parameters one at a time; the model's own history is then a test, and it
is not reported. From `check.txt` against `series.csv`, 2015: $Y$ 80.3 against 107.2 trillion, $R$
59.1 against 95.0 Gt, $N$ 47.7 against 88.9, $RR$ 11.5 against 6.1, $\sigma$ 0.32 against 0.52,
$P$ 1181 against 865 GtCO$_2$-equivalent (R2). In 1900, the base year, the planner chooses
$R=5.74$ against the 7.56 the data show and $A_0$ was set with. The 1900 miss is the Cobb–Douglas
test of `Data_production.tex` failing at $t=0$: with $\gamma$ the value share, $F_R=\gamma Y/R$
at the data's 1900 input is 46 dollars per tonne while the calibrated marginal extraction cost
there is about 64 (the price index at 100 against 169 in 2015 with $\varsigma=1$ cannot carry an
intensity that fell 2.4 times), so the planner uses less. The 2015 output miss compounds it: the
composite trend was read off the data's $K$ and $R$ paths, and the model's own $R$ path is lower
throughout. Disposition: a table "model against data, 1900, 1950, 2000, 2015" in
`quant_results.tex`, and one sentence in `quant_data.tex` that the calibration is not a moment
match.

### R8. $c_N(t)$ is pinned at a 2006–2015 mean that is twice the 2015 value — **refit** $c_{N,\infty}$

`c3_extraction.py` sets $c_{N,\infty}$ to the 2006–2015 mean of the implied series. Recomputed:
the implied series is 0.0074 in 2015 and 0.0211 in 2008 (price index 401 against 169), so the
mean, 0.0141, is 1.9 times the 2015 value, and at the fitted level the model's 2015 extraction
cost is 13.1 percent of output against the 6.8 percent cost share it was built to reproduce
(`c2_production_trends.csv`, `extraction_cost_share`). The RMSE of 0.27 log points is reported
but the end-point miss is not. Disposition: form the implied series on a smoothed price index
(a centred ten-year mean of the Jacks aggregate) before pinning the ends, or pin the end at the
2015 value; state the window in `calibration.md`. The range (half of $c_{N,\infty}$) happens to
bracket the answer.

### R9. $\Omega^{N,S}$ puts an EU-15 lignite ratio on world oil and gas — **limitation**, MANUAL

`c1_accounting.py`: fossil 3.44 t/t from EEA (2001) Table 3 (transcription confirmed against the
PDF; the row labels are offset by one line, as `C_calibration.md` says), weighted by the world
fossil share 0.173, is 0.596 of the 0.932 point. EU-15 domestic fossil extraction in 1995 was
coal and lignite; world fossil extraction is two thirds oil and gas by mass (`b3_resource_block`),
whose hidden flows are small. The ratio is an upper reading for the world, and it is the largest
component of the model's waste flow (R2). The world figure is in Schandl et al. (2018), recorded
MANUAL in `C_calibration.md`. Disposition: obtain it; until then the low end of the range (0.76)
is the better point and the appendix should say why.

### R10. The state-C classification rests on the closure criterion, not on a resource side that dies — **reword** the results

Every solved path is far from the C-state ansatz at $T=400$: $N_T=222$ Gt/yr, cumulative $N$ at
0.58 of its bound, $S_T/S_0=0.18$, $D$ large throughout (`d1_taxonomy.txt`, `d2_report.md`).
`classify_longrun` reads C off the closure criterion (`closes = true`, `leak_sum` 0.08) and, with
a floor, the survival ratio at $T$; it does not check $N\to0$, and says so in its docstring. The
path does satisfy the C-state markers that can be checked: $a\varpi=0.998$ at $T$, $\varpi=1$
from 2072, $x=2.28$ rising roughly linearly as the exponential tail predicts ($g/\xi=0.0093$ per
year), cumulated leakage 0.078 of the budget (Lemma "cumulated leakage" holds with room). The
survival ratio is horizon-dependent because $\mathcal M_\infty$ is still accumulating: 10.9 at
$T=200$ and 83.0 at $T=400$ for the same cell (`check.txt`, `d1_taxonomy.txt`). Disposition:
say in the results that the classification is by the criteria, that the resource side is alive at
the horizon, and that the survival ratio is a lower bound at $T$; the D3 caveat already says the
last.

### R11. The Hotelling check tests a claim the theory does not make about the full problem — **code** (drop or redefine), **reword**

Appendix B's rule is for the relaxed problem under a hard ceiling with the period cap dropped, on
the multiplier of the cumulative throughput bound, "while $R_t>\bar R$". The harness compares
$\Psi_{t+1}/\Psi_t$ with $1+r$ on the full problem, where $\Psi=p^S+C^N_N(1+\zeta\Omega^N)+p^W(1+\Omega^{N,S})$
and $p^S$ carries the stock-effect dividend $-C^N_S>0$ and, while discovery is interior, is pinned
by the discovery margin. It must fail whenever $\mu_N>0$ or $D>0$, and it fails by 7 percent in
every cell (`d2_report.md`, item 1). Conditioning on exploration having ceased is necessary but
not sufficient, and no cell reaches it ($D=131$ Gt/yr at 2100). Disposition: drop the column
from `Circularity.tex`; if a check is wanted, report the growth of $p^S$ net of its stock-effect
dividend after the last period with $D>0$, and say in the results that the theory's statement is
about the relaxed envelope.

### R12. The metals bound is infeasible at $\mu_N=0$; the smallest repair is the physical channel — **refit**

D1 and my check agree: at $\mu_N=0$ the reserve goes negative ($S_T/S_0=-0.16$ at $T=200$ with a
floor, `check.txt`; $-578$ at $T=400$, `d1_taxonomy.txt`) and there is no exploration at all
($D=0$, since $p^S=0$). The metals price channel gives $-1.53$ and the floor at zero is arbitrary.
The smallest change with a source is the physical channel already in `Data_extraction.tex`:
Mudd's energy–grade elasticity of 0.285, which the appendix says is "of the order of the metals
reading". Set the metals $\mu_N$ there, keep zero as the range's infeasible bottom, and test
$\min S>0$ before reporting; a terminal complementarity on $S$ is a model change and second
choice. Until then `Tables/metals/Taxonomy.tex` must not be input (R24).

### R13. The floor grid is bounded by 1900, which the theory's extension list anticipates — **reword** the results

D4's edge at 34.6 Gt is 6.4 times the model's 1900 input (`d4_report.md`); the floor binds in the
base year and is slack at every later date on every solved path. `Rbar_grid` is fractions of 2015
input (`c6_states.csv`), imposed from 1900. `Appendix_listofextensions.tex`, "A scale-dependent
material requirement", names the constant floor as the strong form and $\bar R=\bar rK$ as the
alternative. The results should state that E5 is a grid of counterfactual 1900 economies, that
the survival margin lies 50 times beyond the solvable edge, and that the version of the question
that could be answered needs either the scale-dependent floor or a floor switched on at a later
date (a smaller change: $\bar R_t=0$ before some $t_0$). Do not present the edge as a property of
the long run.

### R14. The gate-fee sign date is the least robust headline, and $\rho$ is not in its range — **limitation**

D2 already shows 1979 to 2093 across $\xi$. The check adds $\mu_N$: 138 at the point and at the
high end at $\bar R=0$, 178 at $\mu_N=0$ (infeasible economy). What has not been varied is
$\rho$, which prices the stockpile's option value directly (R1). Disposition: quote the date with
the $\xi$ range and add the DICE-preference row of R1 to E4.

### R15. The emission tax off makes the gate fee negative from 1900, and the table prints it as a date — **code**

`Tables/GateFee.tex` prints `-0.0` and a sign change at 0 for (1,0,0,0); `d2_report.md` item 6.
`first_date(<(0), tauW)` returns 0 on a value of $-1.9\times10^{-9}$. Print a dash and a note
("negative throughout, numerically zero at $t=0$") when $|\tau^W_0|$ is below a tolerance relative
to $|\tau^W_T|$; the same rule for the `Instruments.tex` column.

### R16. `Instruments.tex` is in units of $10^{-5}$ percent — **code**

The unit is stated in the note and is not wrong, but a reader compares it with the E2 column in
percent. Print percent with enough digits, or dollars of consumption per year, in both tables.

### R17. The A and B cells' survival ratio is printed as if it decided something — **reword**

Under a hard ceiling the ratio "is reported but does not decide the state" (table notes). In
`Surface.tex` it is the only number in 16 of 24 cells. Say in the results what it is there: the
retained endowment over the floor's turnover, on a path whose loop cannot close.

### R18. $P_0$ and the `P` series are converted at different compositions — **code**

`c5`: $P_0=27.54/0.349=79.0$ Gt at the 1900 composition. `c0_series.py`: `P = atm / conv` at the
2000–2015 composition, so `series.csv` has $P_{1900}=39.0$ Gt against the JSON's 79.0. And
$\kappa P_0$ prices 79 Gt at 0.706 tCO$_2$/t, 55.8 GtCO$_2$ for a 27.5 GtCO$_2$ stock. Convert
$P_0$ at the same composition as $\kappa$ (the loss at $P_0$ halves to $2.6\times10^{-4}$) or say
that $P$ is in tonnes at a composition and that the two differ.

### R19. $\phi^I$ constant against a stored share that tripled — **limitation**

`Data_accounting.tex`: $\sigma$ 0.164 in 1900, 0.519 in 2015; $\phi^I=4.61$ on the cumulative.
On the solved baseline $\sigma$ is 0.259 in 1900 and 0.322 in 2015 (`check.txt`): the model
stores too much early and too little late, so $M^K$ is wrong in both directions and the 1900
waste flow is 10 percent low. The consequence for the results is in $\mathcal T$ through
$\sigma_\infty$ (0.53) and in $\mathcal M_\infty$'s split, not in the state. Record; a
time-varying $\phi^I$ is the model change `theory_planner_setup.tex` line 284 sets aside.

### R20. $\mu_D$ counts deposits and its stock is the wrong one — **limitation**

$\mu_D=6.9$ is the elasticity of the cost per *discovery* to the room below a contained-metal
resource of 8.3 Gt (`c3_extraction.csv`); it is applied to $\bar X_{\max}-X$ on a
fossil-dominated aggregate of 89,195 Gt. It hardly matters at the point, because $\bar X_{\max}$
is 6.6 times $X_0$ and $(X_{\mathrm{ref}}/(\bar X_{\max}-X))^{\mu_D}$ stays near one for
centuries: discovery is cheap (28 dollars per tonne at replacement) and runs at 27 Gt/yr in 2015
and 130 in 2100 on the baseline. The sensitivity that would matter is $\bar X_{\max}$ at its low
end (17,217 Gt, 1.27 times $X_0$), which no phase-D run touched. Record; recommend one E1 row at
`Xmax = low`.

### R21. The no-recycling counterfactual is defensible and should be named for what it keeps — **none**, one sentence

$\bar a=0.01$ leaves treatment, and its residue leakage, in the counterfactual economy, so E2
measures recovery and not the waste sector. The three counterfactual welfares agree to
$2\times10^{-8}$ across $\xi$ (`d2_report.md`), which is the check that the tail no longer matters
at the corner. Say what it keeps; do not change it.

### R22. `quant_data.tex` misstates the choke — **reword**

"$\kappa_N$ is a tenth of 1900 extraction, so that the choke price is a tenth of the 1900
marginal cost." With $mc(N)=\kappa_N+N^{\chi_N}$ at $N_{1900}=7.28$ and $\chi_N=0.48$ the choke
is $0.728/(0.728+2.60)=0.22$ of the 1900 marginal cost. A tenth of extraction is the judgement;
say that and drop the marginal-cost gloss.

### R23. The (unused) metals table duplicates a label — **code** (delete)

`Tables/metals/Taxonomy.tex` carries `\label{tab:q:res:taxonomy}`, the baseline table's label,
and rows D1 says are not feasible. `main.tex` does not input it today; delete it, or regenerate
under a different label with a banner, when R12 is done.

### R24. Two commits are misattributed — **reword** (one log line)

`010c112` "Cal A5" carries B5's 19 files; `9d02e25` "Cal B5" is empty and says why. One line in
`RESEARCH_LOG.md` (E3).

### R25. The handling-level target and the model's treated share are on flows of different size — **reword**

`c4_handling_level.jl` targets $RR/(RR+\text{disposal})=0.241$ on the non-biomass flow (24.5 Gt);
the model's $\varpi$ is a share of $H=66$ Gt. They agree (0.252 achieved) because
$0.62\times24.5/63.8=0.238$ happens to equal $5.9/24.5$; the appendix should say the target is a
share of a flow a third the size of the model's, and that on the model's own flow the observed
treated share is the same number by coincidence.

### R26. The ledger on `series.csv` closes within the sources' error — **none**

$N+RR$ against $W+\Delta M^K$ with Krausmann's in-use stock: mean $-0.7$ percent of input, range
$-3.8$ to $+1.6$ percent over 1900–2015; $W=DPO+RR$ to 0.2 percent; $R=N+RR$ to
$4\times10^{-5}$. The cross-source closure with NAS rather than $\Delta M^K$ is $-0.06$ to
$+0.01$ percent (`material_flows.md`); the wider band here is the NAS-against-stock-model
definitional gap, not an error. Report the first pair in the appendix.

### R27. $\Omega$ on the model's definition is consistent with the published intensity — **none**, one sentence

`series.csv`: $R/Y=0.887$ kg per 2011 international dollar in 2015; Krausmann et al. (2018)'s own
GDP series (`b1_krausmann2018.csv`, 62.96 trillion 1990 dollars) gives 1.51 kg per 1990 dollar,
and the two GDP levels differ by the same factor 1.70. $\Omega$ on the model's definition (0.298)
is a third of it because the activity aggregate is $Y+C+4.6G$. The appendix reports the rates;
add the level reconciliation.

### R28. The over-identification test is honest and its split is genuinely free — **none**

$g_Y/(-g_\Omega)=3.5$ against 1 (C) or $(\mu_N-1)/\mu_N=0.46$ (B): history is on no balanced
path (`Data_production.tex`). Under $\varsigma=1$ only $AB^\gamma$ enters, with or without a
floor, since $B$ multiplies $R-\bar R$ under the same exponent, so $g_B=0$ costs nothing. The
1950–2015 composite (0.0233) as the range's top is a third higher and would raise $g$ to 3.4
percent; it is in the file and untested in D.

### R29. Signs on the solved baseline match Appendix B and the market part — **none**

`gatefee_paths.csv`: $\tau^W=-p^{\mathcal W}$ is $+1.5\times10^{-4}$ in 1900 (the stockpile a
liability, $z=-1.3\times10^{-4}<0$ a rebate: the state-A reading of "What the instruments look
like along the paths"), crosses zero at $t=139$, and is $-5.10$ at $T$ with $\zeta=-1.53<0$ and
$z=+3.57>0$: $p^W<0$, $\zeta<0$, $\tau^W<0$, $z>0$, exactly eq. `mkt:cbgp-instruments`. $\zeta$
turns negative at $t=149$, ten periods after the gate fee (`check.txt`). The early positive phase
is the pollution liability, as D2 reads it: with $\phi^P=0$ the fee is negative from 1900.

### R30. The $\mu_N$ perturbation does not move the headline — **none**

`check.txt`, $\bar R=23.756$, $T=200$: state C at all three values; survival 10.86 at the point
and at 2.272, 15.32 at 0 (infeasible, R12); gate fee negative from 118, 116 and 178. Between the
point and the high end nothing moves; the low end is not an economy. With D2's $\xi$ span, the E3
headline ("no corner crosses") survives both ranges.

### R31. `quant_model.tex` still starts the baseline at 1850 — **reword** (E2, already planned)

Line 14. Decision D2 puts it at 1900; E2 owns the sentence.

## The checklist, item by item

| item | findings | verdict |
|---|---|---|
| 1 traceability | table below; R8, R22 | 20 parameters trace to the interim file and the script; the transformation differs from the appendix's words for $c_{N,\infty}$ (R8, end-point miss) and $\kappa_N$ (R22); three raw PDFs confirm the EEA ratios, the Kaza ladder rows and DICE's two damage points |
| 2 units | R2, R18 | conversions are right (US\$/t to tn\$/Gt at 0.001; TCRE 1.65 degC per 1000 PgC is 0.00045 per GtCO$_2$; $\kappa$ re-derived to $9.60\times10^{-6}$ per GtCO$_2$; PWT ratios on Maddison levels); the CO$_2$-to-material bridge is applied to a flow that contains overburden (R2) and $P_0$ at a different composition (R18) |
| 3 ledger, handled flow, overshoot | R3, R4, R26 | ledger closes; $\mu$ reproduces the whole outflow and is the flow's growth rate; the overshoot is the yield |
| 4 $\Omega$, $(g_A,g_B)$ | R27, R28 | consistent; honest |
| 5 D1 against state C | R10 | markers hold at $T$; resource side alive; leak sum consistent with the lemma |
| 6 signs | R29 | match |
| 7a discovery tax | R6(a) | the theory's claim is wrong as stated |
| 7b $\phi^z$ inert | R6(b) | confirmed; 12 allocations; the theory over-claims for the other two |
| 7c welfare | R1 | the calibration; two sensitivities |
| 8 E2 headline, counterfactual | R1, R10, R21 | the calibration; counterfactual defensible |
| 9 Hotelling | R11 | conditional on more than exploration ceasing; drop the column |
| 10 shutdown | R5 | withdraw $T^\dagger$ and "Era ends"; states stand |
| 11 floor edge | R13 | a property of the constant floor; the extension list anticipates it |
| 12 metals bound | R12 | physical channel as the point |
| 13 $\mu_N$ robustness | R30 | does not move |
| 14 the four flagged values | R1, R8, R9, R19, R20 | one refit ($c_{N,\infty}$), the rest recorded |
| 15 presentation | R15, R16, R23, R24 | four code or log fixes |
| 16 else | R2, R7, R17, R25, R31 | the overburden in $P$ and the unreported history fit are the two that matter |

## Traceability: the parameters traced

Each was re-derived from the interim value the script names and compared with `calibration.json`;
all agree to the digits printed. Sources are those the scripts and `data/sources/` cite.

| parameter | value | traced through | terminal source |
|---|---|---|---|
| $\phi^I$ | 4.611 | `c1`: $0.3992/0.6008\times6.9385$ | Haas 2020 NAS, Maddison/PWT |
| $\Omega^{N,S}$ | 0.932 | `c1`: EEA ratios at the 2000–15 $N$ shares | EEA 2001 Table 3 p. 22 (PDF checked) |
| $\Omega^{D,S}$ | 0.0093 | judgement, one hundredth | none, declared |
| $\mu_F$, $\beta$, $\gamma$ | 0.413, 0.756, 0.101 | `c2`: $1-$ labour share; value share 0.114 and 0.088 | PWT `labsh`; Pink Sheet, DS140, WDI |
| $\delta$ | 0.0375 | `c2`: PWT `delta` cn-weighted mean | PWT 10.01 |
| $g_A$ | 0.01736 | `c2`: $0.02974-0.3123\times0.03253-0.1011\times0.02201$ | Maddison, B2 $K$, Haas $R$ |
| $A_0$ | 1.365 | `c2`: $Y_0/(K_0^{\beta}R_0^{1-\beta})^{\mu_F}$ | as above |
| $S_0$, $X_0$, $\bar X_{\max}$ | 13,429; 13,503; 89,195 | `c3`: exhaustible figures over 0.2364 | Rogner 2012 Table 7.1; USGS MCS; GCB |
| $\mu_N$ | 1.844 | `c3`: $-\ln1.686/\ln(10117/13429)$ | Jacks 2019 aggregate |
| $\chi_N$, $\kappa_N$ | 0.482, 0.728 | `c3`: $0.1011/0.0682-1$; $0.1\times7.281$ | C2 shares; judgement |
| $c_{N,0}$, $c_{N,\infty}$, $g_{c_N}$ | 0.0193, 0.0141, 0.0317 | `c3`: implied series, two window means, grid fit | Jacks, WDI rents (R8) |
| $\mu_D$, $c_{D,0}$ | 6.91, $3.19\times10^{-4}$ | `c3`: $\ln(218/65)/\ln(7.12/5.98)$; rent per tonne over $(\kappa_D+N_{2015})$ | MinEx slide 13; USGS; WDI |
| $\mu$, $\mathcal W_0$ | 0.0349, 16.39 | `c4`: $18.62/533.7$; $0.572/\mu$ | Haas 2020 (R3) |
| $c^c$, $c_T$ | 0.0435, 0.0869 | `c4`: ladder midpoints 35 and 70 US\$/t times 1.242 | Kaza 2018 Table 5.2 (PDF checked); the level fitted by `c4_handling_level.jl` |
| $\bar a_H$ | 0.708 | `b4`: mass-weighted EOL-RR over 13 metals | UNEP IRP 2011 appendix; USGS 2024 production (not re-derived) |
| $\xi$ | 2.722 | `c4`: $1.665/(1-0.388)$ | EPA 2024; Haas; UNEP 2024 share |
| $\rho$, $\eta$ | 0.0374, 1.409 | `c5`: regression re-run on the seven decade pairs | PWT `irr`, Maddison |
| $\kappa$ | $6.78\times10^{-6}$ | `c5`: $9.60\times10^{-6}\times0.261\times2.708$; the $9.60$ re-derived from $\pi_2=0.003444$, TCRE 0.00045, $P_{\mathrm{ref}}=6667$ | Barrage–Nordhaus 2024 (3.1 percent at 3 degC and 7.0 at 4.5, PDF checked); AR6 ch. 5 |
| $\theta$ | 0.01816 | `b5` driven fit; not re-run | Joos 2013, GCB |
| $P_0$ | 78.96 | `c5`: $27.54/(0.1418\times2.460)$ | Joos IRF on GCB (R18) |
| $K_0$, $M^K_0$ | 10.63, 35.61 | `b2` PIM; `b1` | Maddison/PWT; Krausmann 2018 |

Declared judgements with no source, as the plan allows when said so: $\kappa_N$, $\kappa_D$,
$\Omega^{D,S}$, $\chi_D=1$, $\chi_T$ and $d^W$ (ranges), $g_B=0$, $\theta_0=\theta_{\min}$, the
$\xi$ range, the $\bar R$ grid. None is hidden.

## What E2 should change in the tables and prose, collected

- Drop $T^\dagger$ and "Era ends" from `Taxonomy`, `Circularity`, `Surface` or relabel (R5).
- Drop the Hotelling column (R11). Print the gate-fee sign change as a dash where the fee is
  negative throughout (R15). Put `Instruments` in percent (R16). Twelve distinct corners (R6b).
- Delete `Tables/metals/Taxonomy.tex` (R23). Two sensitivity rows: $\kappa\times6$ and
  DICE preferences (R1, R14); one E1 row at low $\bar X_{\max}$ (R20).
- A model-against-data table (R7). Reword the stockpile and yield paragraphs of `quant_data.tex`
  (R3, R4, R25), the choke sentence (R22), $P_0$'s composition (R18).
- Theory note: the "pushes the wrong way" sentence and the precondition paragraph (R6). These are
  the only edits this review asks of `writing/docs/`.
- `notes/TODO.md`: R2 ($\kappa$ or the $\Xi$ booking), R8, R9 (MANUAL), R12, R19, R20.
