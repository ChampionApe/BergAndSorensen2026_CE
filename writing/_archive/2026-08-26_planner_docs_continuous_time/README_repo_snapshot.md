# BergAndSorensen2026_CE

Code base for *The Environmental Macroeconomics of the Circular Economy* (2026). See
`CLAUDE.md` for conventions and `RESEARCH_LOG.md` for session-by-session developments.

## Current state of the docs (`writing/docs/`)

Live planner theory (2026-08-21), built on two distinguishing primitives: an
anthropogenic **waste stock** `𝒲` (waste accumulates and is handled at rate `μ`; the
recycling block runs on the handled flow `H = μ𝒲`, capping circular throughput by
`ā·μ·𝒲` and pricing the stockpile as the mirror of the virgin reserve), and a **hard
material floor** (`Y = 0` for `R < R̄`; no dematerialized mode of production, so the
long-run question is survival).

- `theory_planner_setup.tex` — setup with exogenous technological change in all
  primitives, exhaustible discoveries (ceiling `X̄_max`), the waste stock, the hard
  floor, and both yield-ceiling cases: hard `ā < 1` and soft `ā = 1` with the tail of
  `a(·)` classified (exponential = fast; power = slow, conjectured to behave like a hard
  ceiling). Collection is charged per treated tonne (`c^W = c^c·ϖ + c^T(ϖ)`); dumping is
  free, which keeps collapse paths feasible. The circularity multiplier is a steady-state
  object; the throughput cap `R ≤ N + ā·μ·𝒲` holds pointwise under both ceilings.
- `theory_planner_model.tex` — planner problem (six states, five instruments) and
  optimality conditions. The waste margin is the identification `p^W = −p^𝒲`; the
  stockpile costate obeys `ṗ^𝒲 = (r+μ)p^𝒲 − μh` (handling dividend `h`; effective
  discount `r + μ(1−αϖ)`; `μ → ∞` recovers the old static waste margin). Four bounded
  controls as Kuhn–Tucker systems; treatment has a genuine choke at the collection
  charge; the shutdown against `Y = 0` is a discrete comparison, not a first-order margin.
- `theory_planner_longrun.tex` — long-run characterization around the new taxonomy.
  Accounting layer: budget `ℬ` (incl. `𝒲_0`), stock bound `M^K + 𝒲 ≤ ℬ`,
  cumulated-leakage lemma, finite throughput + bounded material era under the hard
  ceiling, and the growth-precondition proposition (perpetual circularity needs the soft
  ceiling, `x → ∞`, and trending technology). With a floor the outcome set is a
  dichotomy: **A** shutdown collapse (incl. collapse despite growth; legacy emissions
  `Ξ = μ𝒲` after the shutdown) vs. **C** perpetual circular growth (survival inequality
  `𝒲 ≥ R̄/(ā·μ)`; growth on constant physical material). **B1/B2/B3** retained as the
  `R̄ = 0` benchmark where essentiality still classifies (labels renumbered 2026-08-25:
  A3 → A, C2 → C). State C's optimality construction is
  the main open item (workhorse item v, incl. the exponential-tail degeneracy and the
  fast/slow threshold).
- `Appendix_explainFOCs.tex` — full derivation/decomposition of the optimality
  conditions, including the stockpile costate (generic costate symbol is `m`; `μ` is the
  handling rate). `Appendix_workhorse.tex` — explicit functional forms (CES aggregate
  `Q`, returns exponent `μ_F`), closed-form margins, rest-point block with
  treatment-without-recycling and no-treatment corners, BDP rate-matching table (stockpile
  row added). `Appendix_exogenousPhiI.tex`, `Appendix_constantPhiI.tex` — stubs for
  alternative embodied-materials assumptions. `Appendix_listofextensions.tex` —
  extensions: residence time in use, `μ` as a control (landfill mining), leaking
  stockpile (`ℓ𝒲` in `Ṗ`), scale-dependent floor, irreversible pollution.

The pre-refocus planner theory as of 2026-08-20 — continuous time, materials accounting,
long-run classification under stationary and trending technology, collapse analysis,
workhorse family — is archived in
`writing/_archive/2026-08-20_planner_docs_trend_growth/` (short description in its
`DESCRIPTION.md`), reserved as the basis for a later, more theoretical paper.
