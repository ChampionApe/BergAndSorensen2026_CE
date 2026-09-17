# Research log

Cleared 2026-08-20. The planner theory in continuous time — setup, optimality conditions,
and the long-run classification under stationary and trending technology — together with
the full session history to that date is archived in
`writing/_archive/2026-08-20_planner_docs_trend_growth/` (see its `DESCRIPTION.md`), kept
as the basis for a later, more theoretical paper. New entries below this line.

## 2026-08-20 — Restart from new section 1; optimality realigned; long-run draft + workhorse appendix

Working from the rewritten setup (exogenous technological change in `F`, `a`, `C^N`, `C^D`,
`c^c`, `c^T`; exhaustible discoveries `C^D_D(0,X,t) → ∞` as `X → X̄_max`; earlier sections
dropped):

- **Section 2 (optimality) and FOC appendix realigned** with the new section 1. Fixed a stale
  `Y = A·F(...)` footnote, added time arguments, and stated the two structural consequences:
  the problem is non-autonomous but `t` adds no first-order condition, and the discovery
  ceiling never needs to be imposed as a constraint — it enforces itself through the
  exploration margin. New results recorded: cumulative extraction bound
  `∫N ≤ S_0 + X̄_max − X_0` (eq:sp:sum:cumulative-N); the exploration corner `D = 0` is
  eventually unavoidable and must be carried as a genuine phase; once exploration ceases
  permanently, `p^X = 0` (the liability expires because `C^D_X(0,·) = 0`). Fixed a dangling
  reference to a proposition from the removed long-run sections; Inada conditions used by
  section 2 but no longer stated in section 1 are now marked "maintained" (cleaner fix:
  add them to section 1's assumption lists).
- **Yield ceiling added to section 1** (user-approved): `lim_{x→∞} a(x,t) = ā < 1`
  (irreducible process loss). Motivation: without it, squeeze scenarios push `aϖ → 1` and
  the circularity multiplier outruns the material value, making `p^W`, `ζ` explode and
  breaking the balanced-trend asymptotics. With it, the multiplier is bounded by
  `1/(1−ā)` and everything downstream is regular.
- **New long-run section drafted** (`theory_planner_longrun.tex`): maintained scoping
  assumptions (two tech regimes — asymptotically stationary (S) and trending (T) with
  `F = A(t)·F̃(K, B(t)R, P)`, constant `g_A, g_B`, recycling tech asymptotically
  stationary; bounded accumulation; convergence/no cycles; regeneration floor
  `θ ≥ θ_min > 0`). Key results: unconditional finite-cumulative-throughput lemma
  (`∫W ≤ B/(1−ā)` — physical throughput, waste and pollution are transitional in every
  scenario); material-autarky lemma (all rest points are dematerialized and clean);
  survival dichotomy (level-inessential ⇒ modified-golden-rule rest point with closed-form
  limit prices, resource rents die; essential ⇒ collapse); marginal essentiality decides
  how the material era ends (choke/stranded reserves vs. asymptotic
  exhaustion/circularity → ā — "maximal circularity is the shadow of maximal scarcity");
  balanced dematerialization paths under regime (T) with growth
  `g = [g_A + γ(g_B − ν)]/(1 − β_K)`, negative waste prices (waste as asset), wedges
  bounded thanks to the ceiling. Taxonomy table + open items close the section.
- **New workhorse appendix** (`Appendix_workhorse.tex`, added to `main.tex`): explicit
  forms — CRRA/power preferences, CES-in-`(K, BR)` production with decreasing returns `μ`
  where substitution `ς` alone spans collapse (`ς ≤ 1`), squeeze (`1 < ς < ∞`), choke
  (`ς = ∞`); yield `a = ā(1 − e^{−ξx})` giving closed-form optimal yield
  `a* = ā − F̃_K/(ξ·G^K)`; power-plus-linear extraction/discovery costs. Closed-form
  dematerialized rest point for the choke case incl. stranded reserves `S_∞` and a
  "treatment without recycling" corner; BDP rate-matching table with
  `ν = g/(μ_N − 1)` where clean.
- **Open questions for next session** (flagged in draft + chat): (i) choke ending requires
  finite `F_R` at `R = 0` (backstop-like `ς = ∞`) — which ending to foreground?
  (ii) negative `p^W` on squeeze paths (waste subsidises even exploration via overburden) —
  keep as feature? (iii) knife-edge: pure material-augmenting case (`g_A = 0`) needs
  `μ_N = 1` or subexponential corrections in the rate matching; (iv) treatment upper corner
  `ϖ = 1` reachable (finite `c^T'(1)`) — keep? Pending work: BDP rate-matching completion,
  squeeze-case decay rates, numerical solve of rest-point block `(p^W*, x*, ϖ*)`.

## 2026-08-20 (later session) — Corners promoted to first-class; yield-ceiling foundations

Discussion session on three model comments, two of which led to edits:

- **Collapsing extraction and exploration into one activity — considered and rejected.**
  Reasons to keep two stocks: (i) the wedge between the reserve rent `p^S` and the
  discovery margin is the economics of the resource side (Pindyck-style anchoring of the
  rent by marginal discovery cost, breaking pure Hotelling dynamics); (ii) the
  stranding-vs-exhaustion distinction in the long-run taxonomy (`S_∞ > 0` stranded by
  choice) is unstatable with one stock; (iii) the decentralized version needs an asset
  market for proven reserves. Noted: the one-stock model is the special case
  `C^D_DD = 0` (just-in-time discovery), usable later as a streamlined presentation.
- **Why corners in finite time rather than `N, D → 0` asymptotically** (user query):
  asymptotic-never-zero is the signature of Inada-protected margins; here recycling breaks
  the Inada shield on virgin extraction (`R = N + R^R` keeps `Ψ` finite), the ledger puts
  per-tonne waste-charge floors (`p^W(1+Ω^{N,S})`, `p^W Ω^{D,S}`) under both activities,
  and exhaustible discoveries make the first-tonne cost diverge. Asymptotic `N → 0`
  survives only as the essential-at-the-margin branch of the taxonomy.
- **Restructured `theory_planner_model.tex` accordingly** (user-approved): extraction and
  exploration moved from equality statements with corners "recorded at the end of the
  section" into full Kuhn–Tucker systems (`eq:sp:sum:Nsys`, `eq:sp:sum:Dsys`) alongside
  the recycling block — "The four bounded controls". New "Phase structure" remark before
  the costates carries the asymmetric status of the two corners and the cumulative bound
  `eq:sp:sum:cumulative-N`; the restated recycling conditions now warn that the
  `V`-elimination fails in the `N = 0` phase; system count updated (four branch-by-branch
  conditions); old closing "Corners outside the recycling block" deleted. All labels
  preserved; appendices needed no changes. Note: `eq:sp:sum:N`/`eq:sp:sum:D` now render
  as subequation letters.
- **Yield ceiling `ā < 1` vs. entropy** (user query on whether entropy-law arguments
  justify the ceiling): resolved that thermodynamics prices re-concentration (finite Gibbs
  mixing work; open system) but does not forbid it — Georgescu-Roegen's "fourth law" is
  generally rejected (Bianciardi et al. 1993; Ayres 1999). The entropic content lives in
  the *curvature* of `a(·)`; `ā < 1` is a strictly stronger assumption about matter, read
  as a reduced form for quality degradation and economically-unreachable dissipative
  losses under the one-material abstraction. Added (user-approved): footnote in
  `theory_planner_setup.tex` making this precise; first entry in
  `Appendix_listofextensions.tex` — the soft-ceiling variant `lim a = 1`, under which
  finite cumulative throughput turns from an accounting result into a cost-side question
  and a new terminal regime (asymptotically perfect recycling) becomes a candidate; five
  new bib entries (Georgescu-Roegen 1977; Bianciardi–Tiezzi–Ulgiati 1993; Ayres 1999;
  Reck–Graedel 2012; Cullen 2017 — page numbers written from memory, verify before
  submission).

## 2026-08-21 — Waste stock adopted; hard floor; sections 1–2 + FOC appendix re-derived; section 4 rewritten around the new taxonomy

Working from `notes/residence_time_draft.md` and `notes/longrun_states_broad.md` (both user-approved for adoption):

- **Waste stock `𝒲` adopted** (section 1, then propagated everywhere): waste generation
  `W` accumulates in an anthropogenic stock, handled at constant rate `μ`; treatment,
  recycling, disposal/emissions and handling costs all levied on the handled flow
  `H = μ𝒲` instead of on `W`. Nests the old model exactly as `μ → ∞` and at any
  stationary point. The circularity multiplier `1/(1−aϖ)` becomes a steady-state object;
  new pointwise cap `R ≤ N + ā·μ·𝒲 ≤ N + ā·μ·ℬ` holds under both ceilings and makes the
  soft-ceiling closed loop well posed (kills the "any throughput from no matter"
  pathology). `μ` constant in theory; control version (landfill mining) deferred to the
  quantitative model; stockpile environmentally inert while sitting (leakage `ℓ𝒲` into
  `Ṗ` kept as an extension).
- **Hard reading of the floor** (user decision): `Y = 0` for `R < R̄` (technology not
  defined below the floor), replacing `R^e = max{R−R̄, 0}`. Consequences: materials are
  level-essential by construction whenever `R̄ > 0` (no dematerialized mode exists);
  marginal essentiality pre-empted by the discrete shutdown; the shutdown chord runs from
  the origin, so `eq:sp:sum:Rdagger` simplifies to `𝓕/𝓕_{R^e} − R^e = R̄`.
- **Section 2 + FOC appendix re-derived** for the six-state system `{K,S,X,P,M^K,𝒲}`:
  the waste FOC collapses to the identification `p^W = −p^𝒲` (the note's conjecture,
  exact, no collection-margin correction); new costate equation
  `ṗ^𝒲 = (r+μ)p^𝒲 − μh` with handling dividend
  `h = αϖ(Ψ−p^W) − c^W(1+ζΩ^W) − p^P[…]`; effective discount on the stockpile is
  `r + μ(1−αϖ)` (runs off only through true leakage); `μ→∞` / rest-point limit recovers
  the old static waste margin verbatim (`eq:sp:sum:W-limit`). All other FOCs unchanged in
  form with `H` as the recycling base. Generic costate symbol renamed `μ` → `m` in the
  appendix (collision with handling rate).
- **Feasibility defect found and fixed** (Claude-initiated, flagged for review):
  mandatory collection `c^c·H` made every hard-ceiling-with-floor path infeasible (finite
  material era forced, but `𝒲 > 0` forever leaves an unpayable bill at `Y = 0`). Fix:
  `c^W(ϖ,t) ≡ c^c(t)·ϖ + c^T(ϖ,t)` — collection charged per treated tonne, dumping free.
  Treatment margin gains a genuine choke at `c^c`; collapse paths gain legacy emissions
  `Ξ = μ𝒲` (landfills outlive the economy); workhorse gains a closed-form no-treatment
  corner (`p^{W*} = p^{P*}`).
- **Section 4 rewritten** around the note's taxonomy, adjusted for the hard floor, which
  deletes the dematerialized-survival cells A1/A2: with a floor the outcome set is a
  dichotomy — A3 shutdown collapse (including "collapse despite growth" under a hard
  ceiling in regime (T), since `B(t)` cannot economise on the floor) vs. C2 perpetual
  circular growth (soft ceiling + fast tail + trending technology; survival inequality
  `𝒲 ≥ R̄/(ā·μ)`; growth `g = (g_A+γg_B)/(1−β_K)` on constant physical material). B1/B2/B3
  retained as the `R̄ = 0` benchmark. New accounting layer: budget `ℬ` includes `𝒲_0`;
  stock bound `M^K + 𝒲 ≤ ℬ`; cumulated-leakage lemma; growth-precondition proposition
  (F4). Scope gains a collapse-ranking remark (CRRA `η ≥ 1` gives `U_0 = −∞` in collapse
  cells; assume `u` bounded below or use overtaking).
- **Tail claim demoted** (Claude-initiated, flagged for review): the `ψ ≤ 1`
  slow-tail-equals-hard-ceiling assertion is *not* a feasibility fact — under growth,
  `∫x^{−ψ}dt` converges for any `ψ > 0` — so it must come from the value side; carried as
  a working classification (fast = exponential, slow = power) with the threshold as
  workhorse open item (v), alongside the exponential-tail degeneracy
  (`a'·|p^W|` independent of `x`).
- **Workhorse**: notation collisions resolved (CES aggregate → `Q`, returns exponent →
  `μ_F`); production spec two-branch with `Z = B·R^e`; essentiality table now classifies
  only under `R̄ = 0`; `ϖ*` inversion and rest-point block updated for `c^c`; BDP table
  gains stockpile row (`𝒲 = W/(μ−ν)`, needs `μ > ν`) and the balanced-growth stockpile
  price `p^𝒲 = μh/(r+μ−g−ν)`. **Abstract** rewritten (two distinguishing primitives,
  survival framing; no longer claims the market/quantitative parts exist). Extensions
  appendix: residence-time entry replaced by the remaining refinements (residence time in
  use, `μ` as control, leaking stockpile). All cross-references verified (no missing
  labels, no duplicates).
- **Discrete-time note** (user query): a one-period recycling lag (waste at `t` returns
  at `t+1`) is exactly the `μΔt = 1` case of the waste stock — it delivers the cap, but
  the handling rate hides in the period length, it has no accumulation/persistence, and
  its continuous-time limit recovers the pathology.

Open next: C2 optimality construction + tail threshold (workhorse item v), BDP
subexponential corrections, market implementation, quantitative parts.
