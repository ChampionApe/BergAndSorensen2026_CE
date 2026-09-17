<!-- Archived 2026-09-17. This is README.md as it stood before being cut down to a repository map.
     It is kept because its digest of the settled theory results was written carefully and is a useful
     orientation, but it is NOT an owner: writing/docs/ owns every claim below, and where the two
     disagree the document is right. Do not restate any of this into a live file -- link here. -->

# BergAndSorensen2026_CE

Code base for *The Environmental Macroeconomics of the Circular Economy* (2026). See
`CLAUDE.md` for conventions and `RESEARCH_LOG.md` for session-by-session developments.

## Current state of the docs (`writing/docs/`)

Three parts, all in **discrete time**, plus appendices. The two primitives that distinguish
the model from a standard environmental Ramsey problem are an anthropogenic **waste stock**
`𝒲` (transition `𝒲_{t+1} = (1−μ)𝒲_t + W_t`, handled flow `H_t = μ𝒲_t`) and a **hard
material floor** (`Y = 0` for `R < R̄`). Timing: stocks are beginning-of-period, costates
attach to the transition in the period it is chosen.

### Part I — the planner (`theory_planner*.tex`)

- `theory_planner_setup.tex` — primitives, exogenous technological change, exhaustible
  discoveries (ceiling `X̄_max`), both yield-ceiling cases (hard `ā < 1`, soft `ā = 1`),
  collection charged per treated tonne, full materials accounting, the ledger and the
  throughput cap `R_t ≤ N_t + ā·μ·𝒲_t`.
- `theory_planner_model.tex` — planner problem (six states, five instruments) and optimality
  conditions, including the identification `p^W_t = −p^𝒲_t`.
- `theory_planner_longrun.tex` — the taxonomy over (floor, ceiling, regime): **A** shutdown
  collapse, **B1/B2/B3** the `R̄ = 0` benchmark, **C** perpetual circular growth.

### Part II — the market economy (`theory_market*.tex`)

The decentralization. Its three results: the waste **gate fee is a market price**, not a
tax, whenever the stockpile is privately owned (`τ^W = −p^𝒲` is a market-clearing
condition); **recycling needs no subsidy** — it is paid the cost of the virgin tonne it
displaces; and three externalities remain — pollution, common-pool exploration, and a
**material-attribution failure** specific to the materials accounting, under which a
competitive economy charges downstream users of the final good for matter they did not draw
into circulation. Instruments: `τ^P = p^P`, `τ^X = −p^X`, `z = ζ − p^W`, plus property
rights over `𝒲`. The sharpest implication is that in the bottom-right cell of the taxonomy
policy failure can be the difference between perpetual growth and a scheduled shutdown,
because the survival margin `ℳ_∞ > R̄·𝒯` is endogenous.

### Part III — the quantitative model (`quant*.tex`)

The computable system, the solution method, and the calibration strategy — written as the
spec that `model/` implements literally.

### Appendices

`Appendix_explainFOCs.tex` (full derivation and decomposition of the optimality conditions);
`Appendix_workhorse.tex` (explicit functional forms, closed-form margins, the circular
balanced growth path, the solved BDP rate matching, the shutdown block);
`Appendix_sufficiency.tex` (when the necessary conditions are sufficient);
`Appendix_exogenousPhiI.tex`, `Appendix_constantPhiI.tex` (stubs);
`Appendix_listofextensions.tex`.

## Key theory results now settled

- **Little's law for matter.** `R_∞ = ℳ_∞ / 𝒯` with `𝒯 = 1/μ + σ_∞/δ`: the circulating flow
  is the retained stock over the mean time a tonne spends immobile. Survival needs
  `ℳ_∞ > R̄·𝒯`; a necessary condition in primitives alone is `μ·ℬ > R̄`. For a given
  endowment, a *more* durable economy supports a *smaller* sustainable throughput.
- **The state-C price block in closed form**, with `p^W = −Θ_𝒲·Ψ` and `Θ_𝒲 = μe^g/(1+r−e^g)`:
  on a closed loop the stockpile is a perpetuity, and `ζ < 0` — at the margin, durability
  competes with the recovery loop for matter.
- **A closure criterion, and the retirement of the fast/slow tail conjecture.** Leakage per
  period equals the recycling capital share deflated by the tail elasticity. Exponential and
  power tails both close the loop, at any exponent; only tails with vanishing elasticity
  (logarithmic) fail. The ceiling column of the taxonomy is about `ā`, not about the speed at
  which `ā` is approached.
- **The BDP rate matching, solved.** `g` and `ν` are jointly determined; `μ_N` selects the
  regime (growth / sustained level / decline). Balanced dematerialization always grows
  strictly slower than the closed loop, which settles the "planner compares" cell.
- **The shutdown and its aftermath.** Hotelling's rule applies to the recycling-multiplied
  budget; after a shutdown the economy is a cake-eating problem in its depreciating capital,
  with a closed-form value.
- **Sufficiency, and where the non-convexity actually lives.** In the tonnage variables —
  treated tonnage instead of the treated share, stored tonnage instead of the intensity —
  the recycling and waste-handling blocks become *perspective functions* and are convex, and
  **exactly one constraint per period is non-convex**: the intensity condition. Mass
  conservation bounds five of the six states on every feasible path, so five of the six
  transversality conditions vanish for free and the only genuine one is on capital — where it
  coincides with the boundedness assumption already maintained. Given the operating set and
  the intensity path, the necessary conditions are sufficient under four checkable conditions.
  Two of those conditions are informative in failure: a finite extraction choke (`κ_N > 0`) is
  simultaneously what makes stranded reserves possible and what breaks convexity of the
  resource block, and the material floor is not a non-convexity at all once the operating set
  is fixed — it only makes the problem a *family* of convex programmes.

## Quantitative model (`model/`)

Julia, standard library only. Planner and market are one residual system with the planner
nested as a corner of a four-dimensional policy space; both transcriptions are carried and
checked against each other. 742 tests pass; a 200-period path solves in ~2.5 s.
`scripts/run_sufficiency.jl` runs the verification protocol of the sufficiency appendix —
which conditions fail, whether transversality holds, and whether any feasible deviation beats
the computed path. See `model/README.md` for the method and the known limitations.

## Data

`notes/data_plan_global_1850.md` — what the calibration needs, where each series comes from,
what has to be constructed, and in what order. Two decisions to take before any downloading:
which materials, and whether the base year is 1850 (with a backcast) or 1900 (observed).

## Archives (`writing/_archive/`)

- `2026-08-26_planner_docs_continuous_time/` — the continuous-time planner theory as it stood
  before the discrete-time translation; see its `DESCRIPTION.md`.
- `2026-08-20_planner_docs_trend_growth/` — the pre-refocus continuous-time theory.

Both are reserved as the basis for a later, more purely theoretical paper.
