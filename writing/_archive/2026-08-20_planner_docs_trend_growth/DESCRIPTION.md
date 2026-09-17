# Archive: planner theory with technology trends (2026-08-20)

Snapshot of `writing/docs/` as of 2026-08-20, kept as the basis for a later, more
theoretical paper. `README_repo_snapshot.md` and `RESEARCH_LOG_snapshot.md` preserve the
repo README and root research log as they stood at archiving; `RESEARCH_LOG.md` is the
docs-folder log that lived inside `writing/docs/` itself.

## What this version contains

The social planner's problem in continuous time, complete through the long-run analysis:

- **Setup and optimality conditions** with full materials accounting (the ledger, the
  intensity condition, the embodied-material stock), shadow prices for waste ($p^W$) and
  embodied material ($\zeta$), and exogenous technology trends: Hicks-neutral TFP
  $A=e^{g_A t}$ and material-augmenting progress $B=e^{g_B t}$ entering as
  $Y = A\,F(K^Y, BR, P)$, with a marginal-product convention that leaves every optimality
  condition form-invariant.
- **The long run, at two levels of rigour.** At stationary technology ($g_A=g_B=0$): the
  four-way classification theorem (SS, BCP, MEG, DC), the selection map over three
  primitives, full characterisations of the SS and BCP, the workhorse closure of MEG, and
  the collapse analysis (damped vs catastrophic, the Cobb–Douglas lead case), with complete
  derivations in the appendices. Under trend growth (rate-and-count rigour): the growth
  structure lemma (explosive / endogenous / trend-paced / stationary branches, the
  effective threshold, the pace $g_C=\gamma_A g_A+g_B+g_R$), the affluence lemma (no
  polluted long run on any growing path), the trending classification (the SS cell empties
  into MEG; the (E) column's exits become rate races), and the trending workhorse rate
  systems.
- **Headline theoretical results of the trending rebuild:** the stationary state — and
  with it any polluted long run — does not survive technological progress; the structural
  knife-edges ($\chi=(\psi+1)/\psi$ matching, congestion threshold $\mu>(\psi+1)/\psi$)
  are trend-invariant while the damage-rate conditions tighten with growth; the circular
  economy (BCP) opens to neoclassical kernels under trends; DC opens to kernel-essential
  technologies via the Stiglitz escape, with only the tonnage floor trend-proof.
- **Nineteen enumerated gaps** in `Appendix_longrun.tex`, of which (xvi)–(xix) delimit
  exactly what the trending results do and do not establish.

## State at archiving

Transition dynamics not started; `writing/draft/` (the paper) not updated to this content;
the quantitative model not started in code. The workhorse family doubles as the intended
specification of the quantitative model.
