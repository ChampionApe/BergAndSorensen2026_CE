# Research log

Cleared 2026-08-26. The planner theory in continuous time — waste stock, hard floor,
optimality conditions, and the long-run taxonomy (A, B1/B2/B3, C) — together with the
full session history to that date is archived in
`writing/_archive/2026-08-26_planner_docs_continuous_time/` (see its `DESCRIPTION.md`),
reserved with the earlier `2026-08-20_planner_docs_trend_growth/` archive as the basis
for a later, more purely theoretical paper. New entries below this line.

## 2026-09-17 (evening) - The technical note split in two; data documentation rule

- **`writing/quant/` is now the quantitative note**, its own Overleaf project (`quant` in
  `overleaf.py`), holding `quant_model`, `quant_solution`, `quant_calibration`. The theory note keeps
  everything else, including the workhorse appendix: 71 references out of it and 23 into it from the
  ALMOST DONE planner part made moving it a bad trade. Commit `f7aeb5d`; both projects pushed.
- **Cross-document references name their target** through `\theory{Section}{...}` and
  `\quant{Section}{...}`, defined in each `Packages.tex`; 43 rewritten. The equations the quantitative
  note leans on are named, not yet restated: TODO 10, waiting on the cut of the docs.
- **Where data documentation goes** is now `docs_style.md` §5: reader-facing facts in the quantitative
  note's data appendix (tables `%% GENERATED` by the pipeline), decisions and alternatives in
  `notes/data/` one file per decision area, transformations in the pipeline script, provenance in
  `data/SOURCES.md`. TODO 11.
- Next: RKB's suggestions on the current state of the docs, in a fresh session.

## 2026-09-17 (later) - Both Overleaf projects connected and pushed

- **`docs` and `paper` both pushed**; a dry-run pull each way now reports 23 and 10 files unchanged,
  nothing pending in either direction. The Git URLs are remembered under `writing/exports/`.
- **The docs project was not empty.** `abstract.tex` had been edited on Overleaf after the project was
  created, and that edit existed nowhere here: 4 lines from the local copy against 12-15 from every
  archived one, so it was an edit of the current text, not an older upload. Pulled and committed on its
  own (28031e0) before pushing, so the force-push discarded nothing. This is the case the dry-run step
  exists for, and it appeared on the very first use.
- **The paper project was behind**, byte-identical to the retired repository at 2026-08-06, so the
  force-push only carried the zeta/q work up. It also deleted `sandbox.tex`, `.gitignore` and
  `.github/copilot-instructions.md` from the Overleaf project; none is a paper source and all three
  survive in `BergAndSorensen2026_circular`.
- **Open**: the paper's Overleaf project still has the GitHub integration attached. Until it is
  unlinked, a sync from the retired repository could overwrite the project with 2026-08-06 content.
  `notes/TODO.md` item 2.

## 2026-09-17 — Repository setup brought in line with MEE; paper consolidated here

- **The paper moved into this repository** as `writing/paper/` (was `writing/draft/`), with the
  co-authors' Word drafts as `writing/paper/localfiles/` (gitignored, excluded from Overleaf).
  `BergAndSorensen2026_circular` is retired to history. The two copies had looked hundreds of lines
  apart; almost all of it was CRLF against LF. The real difference was 29 lines, and the local copy was
  ahead: the $\zeta$ normalisation and $q=1+\phi^Kp^M$. Recorded in `notes/overleafSync.md`.
- **Overleaf sync ported from MEE**: `writing/overleaf.py`, `notes/overleafSync.md`, `/overleaf`. Both
  projects registered — paper `6a4378...`, docs `6a74e6...`. Neither has been pushed yet; §1 and §2 of
  the sync note are the two first-push procedures, and §2 must not be run before checking Overleaf's
  history by hand. The reference check found `ddbibresource{references.bib}` against `References.bib`
  in `docs/Packages.tex` — compiles here, fails on Overleaf's Linux. Fixed.
- **Three style guides now, not two-and-a-copy.** `paper_style.md` was byte-identical to
  `docs_style.md`; it is now the list of differences. `code_style.md` written for what `model/src/`
  actually is — ASCII identifiers, the opposite of MEE's rule and for a stated reason.
- **Notation appendix added** (`writing/docs/notation.tex`) plus `model/SYMBOLS.md`, which is what makes
  the ASCII source affordable. Writing it turned up that $\zeta$ and $q$ mean different things in the
  note and in the paper; both are now stated.
- **Not ported, deliberately**: MEE's three-stage build pipeline, `config.py`, `checkContract.py`,
  numbered cross-cutting findings. Nothing here generates a number into tex yet. The trigger to revisit
  is the first real number doing so — `notes/TODO.md` item 6.

## 2026-08-26 — Docs moved to discrete time; continuous-time version archived

- **Continuous-time docs archived** to
  `writing/_archive/2026-08-26_planner_docs_continuous_time/` and `writing/docs/`
  rebuilt as a discrete-time translation of the same model, keeping both technology
  regimes (S) and (T) and the complete long-run taxonomy. Motivation: the quantitative
  model is discrete, and the plan is to eventually specialise the paper's theory part to
  trending technology.
- **Timing convention adopted** (user-approved design): period $t = 0,1,2,\dots$; all
  stocks beginning-of-period with costates attached to the transition in the period it is
  chosen (capital-style dating). Waste stock:
  `𝒲_{t+1} = (1−μ)𝒲_t + W_t`, `H_t = μ𝒲_t`, `μ ∈ (0,1)` a per-period handling share
  (mean residence time `1/μ` periods, geometric); every waste stream generated during `t`
  enters `𝒲_{t+1}`, so feedstock is predetermined and the material block is recursive
  (no within-period fixed point). `μ = 1` nests the one-period-buffer spec
  (`𝒲_{t+1} = W_t`) but loses the no-multiplier positivity argument and turns the legacy
  emission stream into a single pulse, so `μ ∈ (0,1)` is maintained in the theory.
- **What changed in translation**: control FOCs are form-identical to the continuous
  version (incl. the identification `p^W_t = −p^𝒲_t`, contemporaneous under the chosen
  dating); costate ODEs become recursions `(1+r_{t+1})m_t = dividend_{t+1} +
  survival·m_{t+1}` with forward-sum representations; the stockpile's effective survival
  factor is `1 − μ(1−αϖ)` (analog of the effective discount `r + μ(1−αϖ)`); the
  continuous `μ → ∞` static-margin limit is replaced by the exact rest-point margin,
  which carries a correction term `r/μ` (`p^𝒲* = μh*/(r+μ)`, not `h*` — this also fixes
  a `μ → ∞` sloppiness in the archived continuous version; the workhorse's no-treatment
  corner becomes `p^W* = μ/(ρ+μ)·p^P*`); accounting lemmas telescope with sums;
  material-era duration becomes a period count. Modified golden rule, `p^{P*}`,
  `p^{M*}`, `ζ*` formulas are unchanged with `β = 1/(1+ρ)`. Fixed the dangling workhorse
  reference to `eq:sp:setup:tail-exp`.
- **Collection-charge inconsistency fixed** (found during translation): the archived
  setup and main-text treatment margin still carried `c^W = c^c + c^T(ϖ)` (collection on
  every handled tonne; treatment corner at gain ≤ 0), while the FOC appendix, workhorse,
  README, and the 2026-08-21 log entry all use the intended fix
  `c^W = c^c·ϖ + c^T(ϖ)` (collection per treated tonne, dumping free, choke at `c^c` —
  what keeps collapse paths feasible). The discrete draft is aligned on the
  per-treated-tonne spec throughout: setup cost function, main-text treatment KKT, and
  the `V`-restated system. Both this and the `μ → ∞` sloppiness are recorded as
  blemishes in the archive's `DESCRIPTION.md`.

Open next: market (decentralized) version of the discrete-time model, including the
instrument set that decentralizes the first-best planner outcome; then the quantitative
parts. State C's optimality construction (workhorse item v) remains the main open
theory item.

## 2026-08-26 (overnight) — State C constructed, market part written, quantitative model built

Worked through the five-item plan: finish the open theory, decentralize, set up the
quantitative model, plan the data, implement in Julia.

**1. State C constructed (the main open item, now closed).** New
`Appendix_workhorse.tex` §"The circular balanced growth path", promoted into
`theory_planner_longrun.tex`.
- **Little's law for matter.** `R_∞ = ℳ_∞/𝒯`, `𝒯 = 1/μ + σ_∞/δ`, where `ℳ_∞` is the retained
  endowment (budget less what was never extracted and what leaked). Survival is
  `ℳ_∞ > R̄·𝒯`; necessary in primitives alone: `μℬ > R̄`. Counter-intuitive corollary: for a
  given endowment a *more durable* economy sustains a *smaller* throughput, because more of
  its matter is standing still.
- **Closed-form normalized price block.** As `αϖ → 1` the stockpile's effective survival
  factor → 1, so `p^𝒲 = Θ_𝒲·Ψ` with `Θ_𝒲 = μe^g/(1+r−e^g)` — a perpetuity, not a
  run-off asset; `Θ_𝒲 → μ/ρ` as `g → 0`, *not* the rest-point `μ/(ρ+μ)`. Wedges `ζΩ^j` are
  bounded constants (the boundedness the construction needed). `Ψ̂ = γ/[1+Υ(1−γΩ̂ω^Y)]`.
  Sign result: **`ζ < 0`** — embodied material carries a negative shadow price on a closed
  loop, because storing matter keeps it out of the recovery loop.
- **The "exact degeneracy" was an artefact.** `a'` and `|p^W|` do not cancel: `Ψ` is driven
  by calendar time, not by `x`, so the capital margin pins `x_t` uniquely (linearly in `t`
  for the exponential tail).
- **The fast/slow tail conjecture is false and is retired.** Leakage per period = recycling
  capital share / tail elasticity `ε_a = xa'/(ā−a)`. Exponential *and* power tails close the
  loop, at every exponent — growth outbids any polynomial resistance. Only vanishing-`ε_a`
  tails (logarithmic, `ι ≤ 1`) fail. Taxonomy restated with plain hard/soft ceilings.

**2. BDP rate matching solved; selection settled.** The system was never over-determined —
`g` and `ν` must be solved *jointly*, and then `ν = (g_A+γg_B)/[(μ_N−1)(1−β_K)+γ]`,
`g = (μ_N−1)ν`. `μ_N` selects the regime; `μ_N = 1` is the sustained-*level* case, not a
knife-edge failure. Since B2 and C share a numerator,
`g_B2 = [(μ_N−1)(1−β_K)/((μ_N−1)(1−β_K)+γ)]·g_C < g_C` always: **the closed loop always grows
strictly faster**, so the planner closes it whenever the tail allows, floor or no floor. Also
fixed the exploration row of the rate table, which wrongly imposed `ν_X = ν` and manufactured
a knife-edge `μ_D = μ_N`.

**3. Shutdown block.** Hotelling's rule applies to the recycling-multiplied budget
(`Ψ_{t+1}/Ψ_t = 1+r`) — circularity lowers the level of the price path, not its slope. After
a shutdown the economy is a cake-eating problem in its depreciating capital, closed form
`C_t = [(1−δ)−γ_C]K_t`, `γ_C = [(1−δ)/(1+ρ)]^{1/η}`, so `V^stop` is computable and the
shutdown date is a scalar comparison.

**4. Market part written** (`theory_market_{setup,equilibrium,implementation}.tex`, new
Part II). Verified line by line against the planner conditions; the correspondence is exact.
- Equilibrium prices: `p^R = Ψ − p^W` (a tonne is charged once at entry, once at exit, and
  the two sum to `Ψ`), `z = ζ − p^W`, `τ^W = −p^𝒲`, `r^K = F_K(1−ζΩ^Y)`, `q = 1 + Φ^I(z+p^M)`.
- **The gate fee is a price, not a tax.** `τ^W = −p^𝒲` is the market-clearing condition of the
  disposal market and needs no instrument — only that `𝒲` be *owned*. Property rights over
  waste stocks are the precondition for the other three instruments, not one of them.
- **Recycling needs no subsidy.** No recycling instrument appears anywhere.
- Three externalities: pollution; common-pool exploration; and a **material-attribution
  failure** with no counterpart in a model without materials accounting — the gate fee charges
  whoever disposes, while the decision that brings matter in is taken elsewhere, so
  uncorrected the economy over-charges *every* embodied tonne uniformly by `(1−σ)p^W + σp^M`.
  `z = ζ − p^W` is the uniform rebate; at `φ^I = 0` it exactly refunds the gate fee.
- **Policy result:** in the bottom-right cell the destination is not a primitive, because
  `ℳ_∞` is endogenous. A laissez-faire economy can fail to survive where the planner grows
  forever.

**5. Quantitative part written** (`quant_{model,solution,calibration}.tex`, new Part III) as
the literal spec for the code. `Ω` and `W` are solved from the two identities rather than
adjoined, giving 18 residuals per period. Single system with four policy dials, planner at
`(1,1,1,1)`.

**6. Data plan** (`notes/data_plan_global_1850.md`). Source-by-source, with an identification
map and a sequencing plan. Two things flagged hard: (a) the identification structure is
favourable in an unusual way — the *accounting* parameters are the best identified, the
*resource-side* ones the weakest, which is the right way round for this paper; (b) **the
interpretation of `𝒲` must be decided early** — narrow (pipeline, `μ ≈ 1`, degenerate) vs
broad (landfill-as-reserve, `μ` a few percent). Recommend broad, and record the genuine
specification tension: the geometric draw spreads handling evenly over the stock, while
observed recovery is strongly age-dependent.

**7. Julia implementation** (`model/`, stdlib only, 621 tests passing).
- Planner and market are **one residual system**; two independent transcriptions are carried
  and agree to ~1e-16 at the planner corner, which tests the decentralization proposition as
  an algebraic identity rather than as a property of a solution.
- Stacked Newton, block-tridiagonal Jacobian by structured finite differences (one Jacobian
  costs `3×18` residual evaluations at any horizon); complementarity via a smoothed min-map
  with a homotopy finishing at zero. 200 periods (3612 unknowns) in ~2.5 s.
- Analytic long-run blocks (`restpoint_B1`, `cbgp`, `closure_check`) solved independently and
  used as checks. The solved path converges to them: Little's law predicts `R_∞ = 2.74`
  against a path value of `2.82` still converging at `T = 200`. The closure criterion
  reproduces `x_t` growth of exactly `g/(1+ψ)` on power tails.
- Baseline behaviour matches the theory: the gate fee **turns negative at t ≈ 36** (waste
  becomes a resource), `a → 0.997` under a soft ceiling but plateaus at `ā` under a hard one,
  and the effective survival factor rises from `1−μ = 0.98` to `0.9996`.
- Policy: planner corner maximises welfare; laissez-faire retains **22% less material**
  (`ℳ_∞` 147 → 114) and leaks 5.6× more — the survival-margin channel, quantified.

**Two errors the code found in the theory drafts, both now fixed in the docs.**
- The power-tail yield function `a = ā u/(1+u)`, `u = (ξx)^ψ`, is **not globally concave**: it
  behaves like `ā(ξx)^ψ` near the origin, so for `ψ > 1` it is convex there, `a'` is
  non-monotone, and `α = a − a'x < 0`. The appendix said "satisfies the same properties for
  `ψ ≥ 1`"; the correct restriction is `ψ ≤ 1`. `ψ > 1` remains fine as a *tail* description
  (which is all the closure criterion uses) but the corner test is no longer decided by `a'(0)`.
- The post-shutdown cake-eating problem needs **`(1−δ)^{1−η} < 1+ρ`** — the two conditions
  (positive consumption rate, finite value) are the same restriction. At `δ = 0.05` it needs
  `ρ > 2.6%` for `η = 1.5`. Below it, a collapsing economy has *no* interior consumption plan
  and collapse paths cannot be ranked — the concrete form of the utility-degeneracy caveat.

**Open / not done.**
- **Sufficiency, everywhere.** Every long-run state is necessary-conditions-plus-ansatz; the
  problem is non-convex. This is now the largest gap in the theory.
- **The shutdown branch of the solver is fragile.** It needs a homotopy in `R̄` from zero
  (the floor makes the residual discontinuous and Newton cannot backtrack across it); with
  that it works, but ~1/4 of candidate dates stall short of tolerance. Not covered by the
  test suite; results from it are provisional. `p^M = 0` is imposed at the handover.
- A parameter-space observation worth following up: with plausible numbers the material era
  is either **centuries** long (budget-limited) or **a decade** (throughput-cap-limited, when
  `𝒲` cannot build fast enough), with little in between. Worth checking whether that survives
  calibration, because it changes what the collapse cells mean in practice.
- Transition into state C — how much of the budget an optimal path retains — is the central
  quantitative question and is untouched.
- The two `Φ^I` appendices are still stubs; no data has been downloaded.

## 2026-08-27 — Sufficiency

New `writing/docs/Appendix_sufficiency.tex`, plus `model/src/sufficiency.jl` and
`scripts/run_sufficiency.jl`. The aim was the largest open gap: every long-run state was
necessary-conditions-plus-ansatz.

**The main structural result: a change of variables localises the non-convexity to one
constraint.** Two of the planner's controls are *ratios* multiplying a stock, and ratios times
stocks are bilinear. Replacing each by the tonnage it represents:
- **Treated tonnage `T = ϖμ𝒲` instead of the treated share.** Then the recycling technology
  `𝓡(T,K^R) = T·a(K^R/T)` is the **perspective** of the yield function, hence concave iff `a`
  is; the handling cost `C^W = c^c T + H·c^T(T/H)` is the perspective of `c^T`, hence jointly
  convex in `(T,𝒲)`; and `Ξ` is affine. *The specification that charges collection per treated
  tonne and treatment at a rising rate in the share is exactly the one whose cost function is
  convex in tonnages.* Nice accident.
- **Stored tonnage `m = Φ^I G` instead of the intensity.** The ledger and the `M^K` transition
  become affine, and everything non-convex in the accounting collapses into the intensity
  condition `m(𝒟+φ^I G) = R φ^I G` — bilinear on both sides, and irreducibly so.
- Plus free disposal on two margins (goods, and recovered material `R^R ≤ 𝓡`). The second
  matters specifically: `R^R` enters the ledger with multiplier `−p^W`, whose sign is an
  outcome, so making it a control is what stops the sign of `p^W` mattering.

Result: **exactly one constraint per period is non-convex.** The material floor, which looks
like the worst offender, is not one at all once the operating set is fixed — `{R ≥ R̄}` is a
half-space. It only makes the problem a *family* of convex programmes.

**Transversality is nearly free, and the reason is physical.** Mass conservation bounds
`S, X, P, M^K, 𝒲` on *every* feasible path (Lemma stocks + the discovery ceiling + the
regeneration floor), so five of six boundary terms vanish whatever the sign of their price —
which matters, since `p^𝒲`, `p^M`, `p^X` have no fixed sign. The only genuine condition is on
capital, and on every candidate path it is `[β e^{(1−η)g}]^t → 0` ⟺ `ln(1+ρ) > (1−η)g`.
**Assumption "bounded accumulation and finite values" *is* the transversality condition**, not
an extra restriction.

**Theorem.** Given the operating set and the intensity path, and under (C1)–(C4), the
necessary conditions plus that assumption are sufficient, with uniqueness in `C`. The
decentralisation result inherits this directly — it is a corollary, needing no convexity of
its own.

**Two failures that are informative rather than technical.**
- `C^N` is jointly convex in `(N,S)` only if `χ_N ≥ μ_N` **and** `κ_N = 0`. But `κ_N > 0` is
  precisely what gives extraction a finite choke and hence makes *stranding* possible. *The
  parameter that creates stranded reserves is the parameter that destroys convexity of the
  resource block* — so if Skiba points live anywhere, it is there.
- Multiplicative damages `e^{−κP}` are convex in `P` and break joint concavity. Standard in
  climate–economy models. Two limits on its bite: it vanishes at `κ=0` (damages via `v(P)`
  alone), and it vanishes *asymptotically in every cell of the taxonomy* since `P→0`. The
  non-convexity is transitional, so any multiplicity it generates concerns the transition, not
  the long-run classification.

**Shutdown need not be absorbing — a genuinely new observation.** After a shutdown the economy
still holds capital, and `I < 0` is permitted, so capital can be scrapped to fund extraction;
scrapped and depreciating capital releases embodied material into `𝒲`, so *the stockpile grows
while the economy is idle*. An idle economy may therefore be able to restart, and the optimal
operating set could be a union of intervals rather than one. Under a hard ceiling it must
still terminate (finite cumulative throughput). Proposition gives a checkable sufficient
condition for permanence, `ā μ(M^K+𝒲) + N^max < R̄`, using only mass conservation. **This is a
caveat on last session's single-date shutdown search**, which is searching over too small a
family where the condition fails.

**Code.** `convexity_report` (which of (C1)–(C5) hold), `tvc_report` (the six boundary terms),
`deviation_profile` (value profile along one direction — the diagnostic that distinguishes a
local optimum from a Skiba point), `perturbation_test` (random feasible deviations),
`absorbing_shutdown`. Both deviation tests **refuse to run on a non-converged path**; that
guard is load-bearing, and I added it after watching the tests cheerfully "find improvements"
on a path with `|F| = 0.17`.

Also added **horizon continuation** (`extend_horizon`, `solve_long`), which was needed before
the horizon-sensitivity check could be run at all. Two things were wrong in the first attempt
and both are recorded in the docs: growth factors must be measured *away* from the terminal
date (the last periods are distorted by the terminal closure, investment most of all, and
extrapolating them explodes), and the tail states must come from forward simulation rather
than extrapolation, with investment pinned to balanced growth and consumption residual.

**Findings on the illustrative calibration.** Four conditions fail (damages, extraction,
exploration, intensity). Transversality holds. Nothing beat the candidate: the random search
over 400 draws and the profiles in extraction, investment and recycling capital are all
single-peaked at zero. Horizon sensitivity: `Y` and `C` over `t = 0..100` move by ~1e-3 when
`T` goes 150 → 300. 742 tests pass.

**A limitation worth naming.** There is a horizon wall and it belongs to the model, not the
solver: on an exhaustion path `(S_ref/S)^{μ_N}` diverges as the reserve empties and the Newton
system inherits the conditioning. Cold solves stall near `T = 220`; continuation reaches
`T ≈ 300–325`. Fine here because the window of interest has already settled, but a
faster-depleting calibration would hit it sooner.

**Still open.** (i) Deviations that change the intensity path — the one bilinear constraint;
inactive only at `φ^I = 0`, and its footprint is the bounded wedges `ζΩ^j`. (ii) Optimality
across operating sets where a restart is not excluded. (iii) Sufficiency where the extraction
choke is finite. (iv) Uniqueness of the long-run state: nothing excludes several candidates
converging to different cells from the same initial condition.
