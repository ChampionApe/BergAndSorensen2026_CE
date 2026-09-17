# Archive: planner theory in continuous time — waste stock and hard floor (2026-08-26)

Snapshot of `writing/docs/` as of 2026-08-26, taken when the documentation was moved to
discrete time. Reserved, together with the earlier archive
`2026-08-20_planner_docs_trend_growth/`, as the basis for a later, more purely theoretical
paper. `README_repo_snapshot.md` and `RESEARCH_LOG_snapshot.md` preserve the repo README
and root research log as they stood at archiving.

## What this version contains

The social planner's problem in continuous time, built on two distinguishing primitives:
an anthropogenic **waste stock** $\mathcal W$ (waste accumulates and is handled at rate
$\mu$; the recycling block runs on the handled flow $H = \mu\mathcal W$, capping circular
throughput by $\bar a\mu\mathcal W$ and pricing the stockpile as the mirror of the virgin
reserve) and a **hard material floor** ($Y = 0$ for $R < \bar R$; no dematerialized mode
of production, so the long-run question is survival).

- **Setup** (`theory_planner_setup.tex`): exogenous technological change in all
  primitives, exhaustible discoveries (ceiling $\bar X_{\max}$), the waste stock, the hard
  floor, both yield-ceiling cases (hard $\bar a < 1$, soft $\bar a = 1$), collection
  charged per treated tonne (dumping free), full process-by-process materials accounting
  with the ledger and the circularity multiplier as a steady-state object.
- **Optimality** (`theory_planner_model.tex` + `Appendix_explainFOCs.tex`): six states,
  five instruments; the waste margin as the identification $p^W = -p^{\mathcal W}$; the
  stockpile costate $\dot p^{\mathcal W} = (r+\mu)p^{\mathcal W} - \mu h$ with effective
  discount $r + \mu(1-\alpha\varpi)$ and the $\mu \to \infty$ limit recovering the static
  waste margin; four bounded controls as Kuhn–Tucker systems; the shutdown against
  $Y = 0$ as a discrete comparison.
- **Long run** (`theory_planner_longrun.tex`): budget $\mathcal B$, stock bound,
  cumulated-leakage lemma, finite throughput and bounded material era under the hard
  ceiling, growth-precondition proposition; the taxonomy over (floor, ceiling, regime)
  with states A (shutdown collapse, incl. collapse despite growth and legacy emissions
  $\Xi = \mu\mathcal W$), B1/B2/B3 ($\bar R = 0$ benchmark), and C (perpetual circular
  growth; survival inequality $\mathcal W \ge \bar R/(\bar a\mu)$).
- **Workhorse** (`Appendix_workhorse.tex`): CES aggregate $Q$, returns exponent $\mu_F$,
  exponential/power yield tails, closed-form recycling margins, dematerialized rest point
  for the choke case, BDP rate-matching table.

## State at archiving and known blemishes

State C's optimality construction (open item v: wedge boundedness along the closing loop,
the exponential-tail degeneracy, the fast/slow tail threshold) and the BDP subexponential
corrections remain open. Two blemishes to fix if this version is revived: the workhorse
references a label `eq:sp:setup:tail-exp` that no longer exists in the setup; and the
long-run section states the rest-point stockpile price as $p^{\mathcal W*} = h^*$, which
is the $\mu \to \infty$ form — the exact rest-point value is
$p^{\mathcal W*} = \mu h^*/(\rho+\mu)$.

The discrete-time successor docs live in `writing/docs/`; the pre-waste-stock,
pre-floor version of the continuous-time theory is in
`writing/_archive/2026-08-20_planner_docs_trend_growth/`.
