# Research log

Session logs, newest last: what was settled and why, not algebra. Derivations belong in
`writing/docs/`. Appended at the end of a working session, not during it.

---

## 2026-08-18 — Planner

**Clean draft.** Part 1 now contains social planner description, but long run and transition dynamics 
need to be refined before proceeding to other parts. 

## 2026-08-19 — Long-run section restructured around a classification theorem

**The long-run section (`theory_planner_longrun.tex` + `Appendix_longrun.tex`) was rewritten.**
The organising idea is now a four-way classification of sustained-consumption limits by the fate
of material input: SS (R settles, N > 0), BCP (R settles, N → 0), MEG (R → ∞, new), and DC
(R → 0, promoted from a remark to a co-equal path). A classification theorem proves these are
the only limits within a "regular class" (extended-sense convergence; cycles excluded by scope,
not proof), and the old ruled-out list became the theorem's proof. Key decisions settled:

- **Exponential growth is derived, not assumed**: subexponential sustained growth requires
  r → ρ, i.e. exactly the knife-edge A∞ − δ = ρ, so excluding the knife-edge *is* the
  exponentiality assumption. Now an explicit remark.
- **Selection map has three primitives**: growth threshold, discovery regime (E)/(I), and
  essentiality — the last interrogated only in the (E) column, since the backstop never forces
  the economy to live without materials.
- **MEG has real content**: bounded pollution with growing throughput forces deep circularity in
  absolute terms and storage absorption — the capital stock is the landfill ("the mine moves
  into the building stock"). FOC-consistency of MEG remains open (gaps list).
- **Common growth notation** g_Z (signed; g_Z = 0 can mean subexponential divergence), with a
  rates-by-configuration table closing the section.
- New scoping assumptions: regularity, damage dominance (fixes a utility-race hole in the old
  sink proof), reserve depletion (absorbs old Remark S6), viability, and saturation
  (F_R → 0 as R → ∞) added to Assumption F.
- Also: clarifying sentence added to the discovery-regime assumption (costs rise in both
  regimes; they differ in whether the rise saturates at a backstop or diverges at a finite
  endowment).

New claims to double-check on a careful read: the MEG proposition's Ξ-decomposition argument,
the F_KR ≥ 0 hedge on MEG's growth bound, and the viability assumption's wording. Appendix gaps
list expanded to ten items. Cross-references verified: no dangling labels.

## 2026-08-19 — MEG rate system closed under the workhorse

**MEG is now characterised under the workhorse family** (new `Appendix_workhorse.tex`
subsection + Proposition `prop:sp:wh:meg` in the main text), resolving the substance of gap
(vii). Key results and decisions:

- **One common material rate**: storage absorption plus the ledger force
  g_N = g_D = g_R = g_W = g_{M^K} = g_m, and the same F_R-vs-ζ cancellation that pins the BCP
  delivers g_m = g_C/(1+μς) — absolute expansion with relative decoupling, virgin share of R
  converging to a constant in (0,1), every net tonne stored in the capital stock.
- **Waste is the asset on both growth paths**: −p^W and −ζ diverge (rate μg_m) on MEG too;
  extraction is disciplined by *congestion against the waste credit*, the exact analogue of
  the BCP's depletion-against-credit matching. Scarcity becomes inventory: p^S → κ̄ (rent
  pinned by replacement cost, as in the SS), reserves grow as S ~ N^{1/(1+χ)}.
- **A threshold, not a knife-edge**: sink stability requires μ > (ψ+1)/ψ — the BCP's matching
  number turned from an equality into an open region — plus tame-damage conditions at the MEG
  rates (β_F = 0 kills MEG for the same reason it kills the BCP; a slow sink θ_0 can kill it
  independently). Below the threshold the growth-(I) cell admits **no regular exponential
  sustained-consumption limit at all** — new gap (xii); the cell's fate there is open.
- **Hedges resolved**: on workhorse-MEG P → 0, all wedges vanish, growth is exactly g_C at the
  undamaged return b_K^{ς/(ς−1)}; the F_KR and w_Y hedges of Prop `prop:sp:lr:meg`(iii) are
  discharged.
- **Scoping decision**: Ω^{D,S} = 0 on MEG. With bounded discovery costs and a diverging waste
  asset, any exploration overburden makes exploration a direct mass-harvesting technology —
  the overburden artefact (existing remark) becomes binding; only resolving the setup's
  stock-flow caveat would discipline it. Also noted: φ^I = 0 and constant/exogenous Φ^I both
  kill MEG (mirror of the BCP's dematerialising-capital condition, sign reversed).
- **Honest weak points, flagged in the text**: existence is by rate-and-count of level
  conditions (five conditions, five constants), not a fixed point; the F_R–ζ cancellation
  assumes sub-leading terms behave (same caveat as the BCP).

Gaps list now twelve items ((vii) rewritten, (xii) added). Selection map, dictionary, rates
table and the two warnings updated; cross-references checked (all new labels defined once,
all refs resolve). Next per plan: collapse analysis (C → 0 limits), then transition dynamics.

## 2026-08-20 — Collapse analysis: the classification completed for C → 0

**The long-run section now covers collapse** (`theory_planner_longrun.tex` §Collapse, new
`Appendix_collapse.tex`; section retitled "The long run"). Key decisions and results:

- **One condition governs everything on a collapse path**: (η−1)|g_C| < ρ is simultaneously
  finite lifetime utility, convergence of every forward price integral, and transversality.
  Collapse splits into *damped* and *catastrophic*; essentiality splits into *soft*
  (output positive at every R > 0; workhorse ς ≤ 1) and *hard* (the floor).
- **Hard essentiality makes every collapse catastrophic**: the loop cannot hold R ≥ R̲ on
  dying inflows, production halts at a finite date, U₀ = −∞. So damped collapse requires
  soft essentiality, and the growth-(E)-essential cell with failed matching has **no damped
  regular path at all** — the (E)-column twin of gap (xii). The selection-map footnotes
  (which flatly said "collapse" there) were corrected; the floor subsection now records this
  cost alongside its four benefits.
- **Lead case closed (Cobb–Douglas + regime (E))**: self-similar descent at one common rate
  g ∈ [−δ, 0) — the depreciation floor comes from I + δK ≥ 0 — with an SS-like price system
  on the way down; r → ρ + ηg < ρ. Slower death with a richer stranded reserve or cheaper
  recycling; corner variant at g = −δ exists iff (η−1)δ < ρ. At δ = 0 it recovers the
  classic declining-consumption optimum g_C = −ρ/η.
- **Stranding is the signature of collapse**: S̄ > 0 pinned by the terminal extraction
  margin, rent dying at g, exploration stopping at a finite date with X̄ < X̄_max —
  "reserves are never stranded" is a sustained-consumption theorem, not a general one.
- **The building stock becomes the mine**: the loop is fed by the release −ṀK > 0 from the
  depreciating capital stock (MEG's storage absorption, sign reversed), with a closed-loop
  sub-variant running on the release alone. A mass-balance step shows recycling is a return
  flow, not a source: no material side can grow on the loop without virgin inflow.
- **Collapse never interrogates the damage tails**: P → 0 and p^P → 0 (marginal utility of
  dying consumption explodes, so pollution is priced away in goods units) — no β_v, β_F
  conditions, unlike both growth paths.
- **A hole found and fixed in the sustained-consumption results**: for χ < 1, finite-time
  exhaustion has finite cumulative cost and locks the extraction corner behind the depletion
  barrier, evading the no-terminal-corner revival argument. Assumption regular(ii) gained a
  cumulative-protection clause (∫₀ C^N_N(0,s)ds = ∞; workhorse χ ≥ 1, automatic on the
  matched BCP); the failure mode — an "exhaustion-locked" circular variant — is gap (xv).

Gaps list now fifteen items ((xiii) collapse variants/selection/transition; (xiv)
catastrophic regions, overtaking criteria, the wedge-choked caveat for φ^I > 0; (xv) the
exhaustion-locked variant). Also fixed a dangling ref (def:sp:lr:dc → def:sp:dc) and a
typo in the floor subsection. Cross-references verified: no dangling labels. Next per plan:
transition dynamics.
