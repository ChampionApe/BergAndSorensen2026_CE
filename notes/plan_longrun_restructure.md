# Plan: restructure the long-run part of the theory note (2026-09-17)

The brief for an unattended run. Each task names its owner model, what it reads, what it writes, and
the check that says it is done. Tasks run in the phase order below; inside a phase they run in
parallel. Every agent reads this file first, then `CLAUDE.md`, `docs_style.md` and
`writing/docs/notation.tex`, and works on the branch `docs-restructure`, one commit per task, message
`Plan <task id>: <what>`. No agent compiles tex, pushes to Overleaf, or touches `writing/paper/`.

## 0. Decisions taken (do not reopen)

- **Parameter space** $\mu\in(0,1]$, $\bar R\ge0$, $\bar a\in(0,1]$. The corner $\mu=1$ is the
  one-period buffer $\mathcal W_{t+1}=W_t$; every result holds there and no separate appendix is
  written for it.
- **Regime (T) only in the classification.** Trending technology as in the current
  Assumption 1(T). Stationary technology survives only as Appendix D, a benchmark outside the
  classification, kept because the quantitative note's terminal closure and verification use its
  closed-form rest point and because it is what makes "only a growing economy can afford a closed
  loop" a statement.
- **Three long-run states**: A collapse, B balanced dematerialization (today's B2), C perpetual
  circular growth. B1 and B3 disappear with regime (S). Essentiality disappears entirely.
- **The four cells** and their states:

  | $\bar R$ | ceiling | state |
  |---|---|---|
  | $0$ | hard | B |
  | $0$ | soft | C if the tail closes the loop, else B |
  | $>0$ | hard | A, collapse despite growth |
  | $>0$ | soft | C if the loop closes and $\mathcal M_\infty>\bar R\,\mathcal T$, else A |

- **Assumptions.** 1 becomes the (T) definition alone. 2 is replaced by its explicit content
  (task 1A). 3 becomes convergence after detrending only. 4 unchanged.
- **Markers.** `theory_planner_setup.tex` and `theory_planner_model.tex` stay `%% ALMOST DONE`
  and are edited only where listed in task 2A. `theory_planner_longrun.tex` and every appendix
  lose the marker and may change freely.
- **Sequencing across documents.** Theory note first, quantitative note after, code last, each
  brought in line with the one before.

## 1. Target structure of `writing/docs/`

| file | content | status |
|---|---|---|
| `theory_planner_setup.tex` | Section 1, Setup | as is, plus the $\mu$ edits of 2A |
| `theory_planner_model.tex` | Section 2, Optimization problem | as is, plus the $\mu$ edit of 2A |
| `theory_planner_longrun.tex` | Section 3, The long run: scope, budget, the three states, taxonomy, sketches | rewritten (1A) |
| `theory_market_*.tex` | Part II | one paragraph rewritten (2B) |
| `Appendix_explainFOCs.tex` | A, comprehensive description | as is, plus the $\mu$ edit of 2A |
| `Appendix_proofs.tex` | B, the three states: necessary conditions and constructions, one section per state | new (1B) |
| `Appendix_sufficiency.tex` | C, sufficiency | trimmed (1C) |
| `Appendix_stationary.tex` | D, the stationary benchmark | new from existing text (1D) |
| `Appendix_workhorse.tex` | E, functional forms and closed-form margins only | trimmed (1B) |
| `Appendix_listofextensions.tex` | F, extensions and open items | updated (2B) |
| `Appendix_exogenousPhiI.tex`, `Appendix_constantPhiI.tex` | stubs | dropped from `main.tex` and deleted (2B); TODO 4 closes |

Labels keep their prefixes: `sec:sp:*`, `eq:sp:*` in the planner part, `sec:app:proofs:*` and
`eq:app:pf:*` in B, `sec:app:stat:*` and `eq:app:st:*` in D. An existing label that moves keeps its
name so that references survive; a label that is deleted must have no remaining `\ref`.

## Phase 1: the mathematics (Fable)

### 1A. Section 3 rewrite — `theory_planner_longrun.tex`
Owner: Fable. Depends on nothing. Runs together with 1B in one agent, since the sketches in 3
and the proofs in B must agree on what is claimed and where.

Contents, in order:
1. *Scope.* Assumption 1 = regime (T) as now written. Assumption 2 replaced by three explicit
   conditions: (i) well-posedness $\ln(1+\rho)>(1-\eta)g$ with $g$ the cell's growth rate, vacuous
   for $\eta\ge1$; (ii) the regularity inequalities under which the balanced price blocks have the
   right signs, $e^{g}<1+r$ (the same inequality as (i) on the balanced path) and, on a B path,
   $(1-\delta)e^{g+\nu}<1+r$ and $(1-\mu)e^{g+\nu}<1+r$; (iii) on collapse paths the ranking
   condition $(1-\delta)^{1-\eta}<1+\rho$ from the shutdown construction. State plainly that
   forward representations of the costates follow from Assumption 3 plus the first-order
   conditions (a bubble grows at $(1+r)/s>e^{g}$ and would break the detrended convergence of a
   price the margins tie to a converging quantity) and are not assumed separately. Assumption 3 as
   now, minus the (S) clause. Assumption 4 as now. Keep the "what has been assumed away" comments
   that survive; drop the essentiality remark. Add one sentence that the model has no endogenous
   growth engine by construction, so "requires growth" is the robust content of Section 3 and
   "requires trending technology" its model-specific form; point to Appendix D for the stationary
   contrast.
2. *The material budget and the accounting facts.* Lemmas stocks, leakage, throughput as now;
   the growth-precondition proposition with items 1 and 2 only, item 3 moved to Appendix D.
3. *The three states, defined.* A: production ceases after a finite total number of operating
   periods, $C\to0$ along the cake-eating aftermath; the definition must allow a finite union of
   operating intervals, not a single one, because Appendix C records that shutdown need not be
   absorbing. B: Definition of the BDP as now. C: the circular growth configuration as now
   described under "Perpetual circular growth (C)", including Little's law, the survival condition
   $\mathcal M_\infty>\bar R\mathcal T$, and the primitive necessary condition $\mu\mathcal B>\bar R$.
4. *Taxonomy.* The four-row table of §0 with the conditions that split the two soft rows; the
   readings "the floor deletes the essentiality column" rewritten as "the floor turns survival
   into a stock condition", "growth is not a free pass", "the bottom-right cell", and "what the
   classification is not" kept.
5. *Sketches.* One paragraph per state pointing to Appendix B: A from the finite-throughput lemma
   (hard) or from the failed survival condition (soft); C from the leakage lemma, Little's law and
   the closure criterion; B from rate matching; selection of C over B by the growth-rate
   comparison.
6. *Configurations to check* and *open items* as now, purged of (S) and essentiality; sufficiency
   item pointing to Appendix C.

Every `\ref` in the file must resolve within `writing/docs/`. The `\quant{}` macro is used for
anything that lives in the quantitative note.

### 1B. Appendix B — `Appendix_proofs.tex`, and the workhorse trim
Owner: the same Fable agent as 1A, after 1A.

One `\section` "The three long-run states" with three subsections, each in two parts: *general
primitives* (what holds under Section 1's assumptions) and *workhorse construction* (what is shown
for the forms of Appendix E). Be explicit about which is which; do not present a Cobb–Douglas
rate table as a general theorem.

- **Collapse (A).** General: the hard-ceiling duration bound (from Lemma throughput); the new
  soft-ceiling argument: if production runs at or above the floor forever then by the growth
  proposition $a\varpi\to1$ and $\mathcal W$ carries the floor, and by Little's law
  $R_\infty=\mathcal M_\infty/\mathcal T$, so $\mathcal M_\infty\le\bar R\mathcal T$ or a failed
  closure criterion contradicts perpetual operation; conclude the total operating time is finite.
  Workhorse: move "The shutdown and its aftermath" here verbatim (Hotelling for the multiplied
  budget, the discrete shutdown, cake-eating, $V^{\mathrm{stop}}$, the condition
  $(1-\delta)^{1-\eta}<1+\rho$). Record that $V^{\mathrm{stop}}$'s legacy stream omits the
  $\delta M^K$ inflow, as TODO 8 does.
- **Balanced dematerialization (B).** General: feasibility of an exponentially decaying material
  block under the budget (summability), the stockpile riding along for $\mu>1-e^{-\nu}$ and the
  drainage case otherwise. Workhorse: move "Balanced dematerialization: rate matching" here
  verbatim, including the exploration-rate remark and the $\mu_N$ table.
- **Perpetual circular growth (C).** General: Little's law and the survival condition (they use
  only stationarity of the two stocks), the growth precondition items 1–2, the tail elasticity and
  the closure criterion stated for a general yield function. Workhorse: move "The circular balanced
  growth path" here verbatim: ansatz, normalized price block, signs, the tail table, the resource
  side, what the planner chooses. Then the comparison with B, "Comparison with the closed loop".

After the move, `Appendix_workhorse.tex` keeps only "Functional forms", "The recycling margins in
closed form" and a shortened "Verification status"; its rest-point subsection goes to 1D. Its
opening paragraph is rewritten to say what it now is.

Check: every label that existed before the move still exists somewhere in `writing/docs/` or has
no remaining `\ref` (grep both); the three subsections each state at least one result for general
primitives; the quantitative note's `\theory{Section}{...}` targets that survive are listed in the
commit message so that 3A can update the rest.

### 1C. Appendix C trim — `Appendix_sufficiency.tex`
Owner: Fable, parallel to 1A/1B. Remove the rest-point branch of the transversality rate count and
every reference to B1, B3, the dichotomy or essentiality; keep the stranding discussion, since
stranding still occurs in (T). Replace "Assumption 2 is the transversality condition" by the
statement in terms of the explicit conditions of 1A(1). The "what is and is not established" list
loses nothing else. Check: no `\ref` to a deleted label; the text nowhere presumes regime (S).

### 1D. Appendix D — `Appendix_stationary.tex`
Owner: Fable, parallel to 1A/1B. Assemble from existing text, no new results: the (S) definition
from Assumption 1; Assumption 2(i) (no accumulation-driven growth) as a local hypothesis; the
no-productive-rest-point proposition; item 3 of the growth proposition, stated as the result of
this appendix, "a closed loop is infeasible in a stationary economy"; the material-autarky lemma;
the essentiality definition and the survival dichotomy; "how the material era ends"; the
workhorse's dematerialized rest point subsection (closed-form block, corners, stranded reserves,
the squeeze remark). Open with two sentences saying this is a benchmark outside the classification
of Section 3 and why it is kept. Labels: existing ones keep their names. Check: the quantitative
note's references "The dematerialized rest point" and "The floorless benchmark: stationary
technology" have a target here or a recorded new name.

## Phase 2: consistency in the theory note (Opus), after phase 1

### 2A. $\mu\in(0,1]$ in the ALMOST DONE files
Minimal edits, five places, nothing else in these files:
- `theory_planner_setup.tex` line 9: rates sentence, $\mu\in(0,1]$ with $\delta,\theta\in(0,1)$.
- Same file, waste-stock footnote (line 51): replace "the theory maintains $\mu<1$ ..." by: the
  corner $\mu=1$ is the one-period buffer; every result holds there; what $\mu<1$ adds is a stock
  distinct from a flow and a residence time $1/\mu$ to calibrate. Delete the persistence clause in
  the main sentence ("and it gives the stockpile the persistence that avoids ..."); the timing
  convention, not $\mu<1$, is what removes the within-period fixed point, and say so.
- `theory_planner_model.tex` line 191: the state bound argument. Replace by: $W\ge0$ gives
  $\mathcal W_{t+1}\ge0$ directly; strict positivity because $W\ge\Omega\omega^YY>0$ while
  production runs and $W=\delta M^K>0$ after it stops.
- `theory_planner_longrun.tex` (already rewritten in 1A; confirm the aftermath paragraph states the
  legacy stream at $\mu=1$ correctly: one period from the stockpile, then $\delta M^K$).
- `Appendix_explainFOCs.tex`: the buffer-corner footnote stays; check nothing else asserts $\mu<1$.
- `notation.tex` rule 7 and the $\mu$ row: $(0,1]$.
Check: `grep -n 'mu<1\|mu < 1\|\\mu<1' writing/docs/*.tex` returns nothing.

### 2B. Abstract, market paragraph, extensions, main.tex
- `abstract.tex`: taxonomy sentence to the three states and four cells; mention Appendix D.
- `theory_market_implementation.tex`, "What the instruments look like along the paths": rewrite
  the collapse/rest-point paragraph for states A and B; the C paragraph stays.
- `Appendix_listofextensions.tex`: add "stationary technology" as a set-aside variant pointing to
  Appendix D; remove the two $\Phi^I$ variants and the stub files; `main.tex` inputs updated to
  the §1 order.
- `theory_planner.tex`: marker comment updated to name only the two files still marked.
- `docs_style.md` §1: marked files list updated.
Check: `main.tex` inputs exist; no `\ref` in `writing/docs/` without a `\label`; no `\label`
defined twice. Report both greps' output in the commit message.

### 2C. Notation table
`notation.tex` "Defined in" column repointed where a definition moved; add $\mathcal T$,
$\mathcal M_\infty$, $\mathcal B$, $\epsilon_a$, $\Theta_{\mathcal W}$ if absent. No symbol renamed.

## Phase 3: the quantitative note (after phase 2)

### 3A. Cross-references — Opus
Every `\theory{Section}{...}` and `\theory{Appendix}{...}` in `writing/quant/*.tex` names a section
that exists in the restructured theory note. List: `grep -o '\\theory{[^}]*}{[^}]*}' writing/quant/*.tex | sort -u`
against `grep -h '\\section\|\\subsection' writing/docs/*.tex`. Rename targets; where the target
moved to Appendix D, say so in the sentence (it is a benchmark, not the classification).

### 3B. Substance — Fable
- `quant_model.tex` scope: state the parameter space of §0 and regime (T) as the maintained case,
  with (S) available through $\Gamma=1$ for the benchmark checks only.
- `quant_solution.tex` terminal conditions: the "nests both long-run regimes" paragraph now points
  to Appendix D for $\Gamma=1$.
- `quant_solution.tex` verification item 3: rest-point check described as a benchmark test.
- `quant_calibration.tex`: experiments and the $\bar R$ paragraph use the three-state language;
  E2 no longer says "rest-point cells".
- TODO 10 (restate the equations the note leans on) stays open unless trivially closed in passing.
Check: no mention of B1, B3, dichotomy or essentiality remains in `writing/quant/`.

## Phase 4: the code (after phase 3)

### 4A. $\mu=1$ admissible — Opus
`src/parameters.jl` `check_params`: `mu_h` in `(0, 1]`. Add a `@testset` in `test/runtests.jl`
that at `mu_h = 1.0` the ledger holds, the planner and market residuals agree at the planner
corner, and a short horizon solves. If the solver assumes `1 - mu_h > 0` anywhere (division,
log), fix it. `model/SYMBOLS.md` unchanged. Suite green; report the count.

### 4B. The explicit assumptions — Opus
`src/sufficiency.jl` or `check_params`: warn when any of the conditions of 1A(1) fails at the
calibration: $\ln(1+\rho)>(1-\eta)g$, $(1-\delta)e^{g+\nu}<1+r$, $(1-\mu)e^{g+\nu}<1+r$,
$(1-\delta)^{1-\eta}<1+\rho$. The tvc check already carries the first; do not duplicate it,
extend it. Test each warning fires on a constructed parameter set. Suite green.

### 4C. A long-run classifier — Fable, optional
`src/longrun.jl`: `classify_longrun(mo, x)` returning `:A`, `:B` or `:C` for a solved path by the
taxonomy of §0: floor and ceiling from the parameters, closure from the existing criterion,
survival from Little's law against the path's retained endowment. Diagnostic only; documented in
`model/README.md` under "What is verified"; one test on the baseline. Skip if it would take more
than the other code tasks combined.

### 4D. Docs that must stay current — Opus
`model/README.md` file map and "What is verified"; `model/SYMBOLS.md` only if a symbol was added;
`notes/TODO.md`: close item 4, add nothing that this plan already carries.

## Phase 5: close (Opus)
Append one entry each to `RESEARCH_LOG.md` (the restructure, the decisions, where to look) and
`model/RESEARCH_LOG.md` (4A–4D), at most ten lines each. Leave the branch unmerged and Overleaf
untouched: the morning review merges and pushes.

## What is not in this plan
The paper (`writing/paper/`). Extending the C and B constructions beyond Cobb–Douglas (the note's
open item). Fixing TODO 7, 8 or 9. Any restyling of Sections 1–2.
