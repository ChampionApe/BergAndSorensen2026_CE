
## 2026-08-19 (second session) — Verification pass and the workhorse family

**Verification of the three flagged claims (all resolved).** The MEG Ξ-decomposition was sound
but its proof presupposed W → ∞, which the definition (R → ∞) does not deliver; the step is now
derived via the ledger and needs δ > 0, added to the proposition's hypotheses. The F_KR ≥ 0
hedge needed two further caveats, now stated: A∞ must be read at the path's limiting pollution
stock (MEG is the only configuration where P̄ > 0 can matter; footnote to Assumption F(ii)
extended), and the growth bound presumes the wedge w_Y → 1 — part of MEG's open price system
(noted in gaps (vii)). The viability assumption was reworded: the regime-(I) clause now names
the joint failure of the N- and D-corners, and the assumption owns that it restricts endogenous
limits, scoping out economies with no material side to study.

**Workhorse family added** (`theory_planner_longrun.tex` §"A workhorse family" +
`Appendix_workhorse.tex`): one nested parametric family — CRRA/power damages, Stone-Geary CES
with material floor R̲ and pollution multiplier, power/exponential recycling tail ψ, two-part
extraction cost (stock-sensitive linear part carrying tail χ + congestion part for MEG),
(E)/(I) discovery switch, saturating decay θ. Dictionary table maps every theory object to a
named parameter; selection map restated in parameters. Placement decision: after the formal
results (which are form-independent), example in main text, verification in appendix; the
appendix doubles as the future quantitative model's spec sheet.

Key findings from the verification:
- **Two maintained assumptions have CES boundaries the text got wrong or missed**: marginal
  indispensability fails below unit elasticity (harmless — bounded branch; clarification
  corrected) and saturation fails above it, patched by the bulk-materials condition
  b_R^{ς/(ς−1)} < c^c (new lemma; also closes Step 3's "free tonnes" loophole for the family).
- **The floor delivers essentiality with A∞ > 0 from a standard form** (the pairing previously
  requiring exotic families), closes the DC exit (R̲ is a fourth selection-map primitive), and
  anchors BCP throughput at W̄ = R̲ — but only softens ONE knife-edge: rate-pinning relaxes to
  the interval g_pS ∈ [g_C/ς, g_C] while χ = (ψ+1)/ψ persists (it never involves F_R). Interval
  selection open — new gap (xi).
- **Exponential production damage (Γ′(0) > 0) kills the BCP**: output damages, like utility
  damages, need vanishing marginal at zero pollution. Family carries β_F > 0.
- Damage dominance needs η > 1, not η ≥ 1 (log utility unbounded) — fixed.
- Flagged conjecture on gap (ii): if g_D = g_N, the discovery matching exponent is
  χ_D = (ψ+1)/ψ = χ.

**Next up (agreed):** MEG rate system under the workhorse tails — candidate feasibility bound
g_W ≤ ψ/(ψ+1)·g_C from the recycling-capital burden (K^R ~ x·W outgrows K otherwise), meaning
even the cornucopian path decouples in relative terms; possible impossibility region feeding
into — then the collapse analysis (extend classification to C → 0 limits; lead case
Cobb–Douglas + regime (E)). Cross-references verified: no dangling labels.

## 2026-08-20 — Collapse subsection and appendix added

**Files**: new `Appendix_collapse.tex` (wired into `main.tex`); §Collapse added to
`theory_planner_longrun.tex` (section retitled "The long run"); edits to
`Appendix_longrun.tex` (no-terminal-corner step patched, gaps (xiii)–(xv) added) and
`Appendix_workhorse.tex` (cumulative depletion clause χ ≥ 1 noted, floor subsection marked
catastrophic). Substance is logged in the root `RESEARCH_LOG.md`; headline: damped vs
catastrophic collapse split by (η−1)|g_C| < ρ, the CD + regime-(E) lead case closed
(self-similar descent, stranded reserves, loop fed by the dying capital stock, pollution
priced away), hard essentiality ⇒ finite-time shutdown, and a χ < 1 finite-time-exhaustion
hole closed by strengthening Assumption regular(ii).

**Existing text changed in substance — coauthor should review**: (1) Assumption regular(ii)
now carries the cumulative-protection clause ∫₀ C^N_N(0,s)ds = ∞ (alternative: leave the
assumption and carry the exhaustion-locked variant as a fifth configuration); (2) the
selection-map footnotes no longer say "collapse" for the growth-(E)-essential cell — they
say no damped regular path (gap (xiv)); (3) the floor's "what it buys" list gained a
counterweight paragraph (catastrophic endgame).

**New claims to double-check on a careful read**: the mass-balance step in
Lemma collapse(iii) (recycling as a strictly losing flow — the Ω̄ fixed-point inequality);
the claim that the corner collapse g = −δ is priceable iff (η−1)δ < ρ; the wedge-choke
bound in `Appendix_collapse.tex` (w̄_Y/q̄ < (ρ+δ)/A∞, only sketched at the level of
bounded prices); and the count of the CD ratio system (S̄ treated as history-tied — is a
further level condition hiding in the second-order asymptotics of the extraction margin?).
Cross-references verified: no dangling labels.
