# Candidate long-run states: the broad list

*Working note, 2026-08-21. Purpose: enumerate widely first, narrow later. Section 4 of the docs
is written for the old primitives and is not to be trusted against this list until rewritten.*

## 1. The classifying dimensions

| | Dimension | Values |
|---|---|---|
| D1 | Minimum material requirement | $\bar R=0$ / $\bar R>0$ |
| D2 | Yield ceiling | hard $\bar a<1$ / soft $\bar a=1$ with fast tail / soft with slow tail ($\psi\le1$) |
| D3 | Technology regime | (S) asymptotically stationary / (T) trending, $g>0$ |
| D4 | Level essentiality of $R^e$ | $\mathcal F\left(K,0,P\right)=0$ / $>0$ |
| D5 | Marginal essentiality | $\mathcal F_{R^e}\to\infty$ as $R^e\to0$ / finite choke |

That is 3 x 2 x 2 x 2 x 2 = 48 raw cells. Most collapse, and the point of this note is to say
which and why.

Assumption maintained throughout: $c^{T\prime}\left(1\right)<\infty$, so $\varpi=1$ is always
reachable and circularity is capped by the recycling technology alone.

## 2. The accounting facts that do the eliminating

**F1 (always).** Cumulative leakage is bounded by the budget:
$$\int_0^\infty\left[1-a\varpi\right]W\,dt \;\le\; \mathcal B .$$
This holds in both ceiling cases -- it is the ledger integrated, using $M^K\ge0$ and the
cumulative bounds on $N$ and $D$. It is the general form that should replace Lemma 4.3.

**F2 (iff $\bar a<1$).** Finite cumulative throughput, $\int W\,dt\le\mathcal B/\left(1-\bar
a\right)$ and $\int R\,dt\le\bar{\mathcal R}$. Follows from F1 because the leakage rate is then
bounded below by $1-\bar a>0$.

**F3 (needs $\bar R>0$ and F2).** The material era has bounded duration,
$$\left|\left\{t:R(t)>\bar R\right\}\right|\;\le\;\bar{\mathcal R}/\bar R .$$

**F4 (needs $\bar a=1$).** Holding $R\ge\bar R$ forever requires
$\int\left[1-a\varpi\right]dt<\infty$, hence $x\to\infty$, hence $K^R\to\infty$, hence
maintenance $\delta K^R\to\infty$ -- which requires **unbounded net output**. Under regime (S)
net output is bounded (Assumption 4.2), so this is infeasible. *Growth is a precondition for
perpetual circularity.*

## 3. The state space, as a 3 x 3

Classify a terminal configuration by what the material block and the goods block do.

Material block:
- **M0 dead** -- $R=0$ from some finite date, or $R<\bar R$ so that $R^e=0$.
- **M1 vanishing** -- $R\to0$ but strictly positive forever.
- **M2 perpetual loop** -- $N=0$, $R$ bounded away from zero forever, sustained by recycling.
- **M3 perpetual extraction** -- $N$ bounded away from zero forever.

Goods block: **G0** collapse $C\to0$; **G1** rest point $C^*>0$; **G2** growth at $g>0$.

| | G0 collapse | G1 rest point | G2 growth |
|---|---|---|---|
| **M0 dead** | A3 | A1 | A2 |
| **M1 vanishing** | B3 | B1 | B2 |
| **M2 perpetual loop** | C3 | C1 | C2 |
| **M3 perpetual extraction** | -- eliminated by F1/F2 in every cell -- |

### The nine cells

- **A1 Dematerialized rest point.** Material sector shut down in finite time; modified golden
  rule on $\mathcal F^\infty\left(K,0,0\right)$. Reached when $\bar R>0$ and materials are
  level-inessential. This is Prop 4.5(i) but arrived at by discrete shutdown rather than
  asymptotically.
- **A2 Dematerialized growth.** Same shutdown, then growth at $g=g_A/\left(1-\beta_K\right)$
  on the material-free technology. Regime (T), $\bar R>0$, level-inessential. **New** -- the
  current draft has no such row, because with $\bar R=0$ regime (T) always keeps materials
  alive.
- **A3 Shutdown collapse.** $\bar R>0$ and level-essential: the floor cannot be met after the
  budget runs out, output from materials ceases at $T^\dagger$, and the economy lives off
  capital decumulation with $C\to0$. Occurs in **both** regimes -- trending technology does not
  rescue it, because $B(t)$ multiplies $R-\bar R$ and cannot economise on the floor.
- **B1 Asymptotic squeeze to a rest point.** $\bar R=0$, level-inessential, marginally
  essential. Current draft row 2: circularity climbs to $\bar a$, $S\to0$, $C\to C^*$.
- **B2 Balanced dematerialization path.** $\bar R=0$, regime (T). Current Section 4.4.
- **B3 Exhaustible-resource collapse.** $\bar R=0$, level-essential, regime (S). Current row 3.
- **C1 Perpetual circular stationary economy.** *Eliminated by F4* -- unbounded recycling
  capital cannot be maintained against bounded output.
- **C2 Perpetual circular growth economy.** The only surviving M2 cell. Requires $\bar a=1$,
  fast tail, regime (T) with $g>0$. Throughput held at or above the floor forever; $a\varpi\to1$
  with $x\to\infty$; $\Omega\to0$; leakage financed out of $M^K$. **This is the state in which
  the circular economy is the answer rather than a palliative**, and it is the only one in which
  a positive $\bar R$ is survivable indefinitely.
- **C3 Perpetual loop with collapsing consumption.** *Eliminated* -- collapsing output cannot
  fund $K^R\to\infty$ either.

## 4. Mapping parameter cells to states

With the slow-tail case ($\psi\le1$) behaving exactly like a hard ceiling -- leakage not
integrable, so F2 and F3 go through -- D2 collapses to two effective values. That leaves 16
live cells:

| $\bar R$ | ceiling | regime | level ess. | state | how the material era ends |
|---|---|---|---|---|---|
| $0$ | hard/slow | (S) | inessential | B1 | exhaustion (marg. ess.) or choke (marg. iness.) |
| $0$ | hard/slow | (S) | essential | B3 | exhaustion, collapse |
| $0$ | hard/slow | (T) | either | B2 | perpetual squeeze, never ends |
| $0$ | soft fast | (S) | inessential | B1 | as above; C1 blocked by F4 |
| $0$ | soft fast | (S) | essential | B3 | as above |
| $0$ | soft fast | (T) | either | **C2** or B2 | planner compares; loop can close |
| $>0$ | hard/slow | (S) | inessential | **A1** | discrete shutdown at $R^\dagger$, finite time |
| $>0$ | hard/slow | (S) | essential | **A3** | discrete shutdown, then collapse |
| $>0$ | hard/slow | (T) | inessential | **A2** | discrete shutdown, growth continues |
| $>0$ | hard/slow | (T) | essential | **A3** | shutdown, collapse *despite growth* |
| $>0$ | soft fast | (S) | inessential | A1 | C2 blocked by F4 |
| $>0$ | soft fast | (S) | essential | A3 | C2 blocked by F4 |
| $>0$ | soft fast | (T) | inessential | **C2** or A2 | planner compares |
| $>0$ | soft fast | (T) | essential | **C2** or A3 | C2 is the only survival route |

Three readings worth keeping.

1. **D5 (marginal essentiality) only matters when $\bar R=0$.** With a floor, the shutdown at
   $R^\dagger>\bar R$ happens before the marginal value can diverge, so the exhaustion/choke
   distinction that organises the current Section 4 disappears. That is a large simplification
   and should be stated as one.
2. **Regime (T) stops being a free pass.** With $\bar R>0$, growth does not overturn
   essentiality; it only changes what happens after the shutdown (A2 vs A3).
3. **The bottom-right cell is the paper's sharpest claim.** $\bar R>0$, materials essential,
   trending technology, soft ceiling with a fast tail: the circular economy is not an efficiency
   improvement but the entire survival condition, and it is affordable only because the economy
   grows.

## 5. States that are not states: things to check, not to classify

- **Chattering / pulsed material operation.** The non-convexity at $R=\bar R$ means the flat
  stretch of the concave hull is attained by time-averaging between an idle material sector and
  one running at $R^\dagger$. This is a property of the approach, not of the terminal state, but
  it changes what "declining material use" means empirically.
- **Skiba points from the pollution non-convexity.** $\theta'<0$ can strand the economy at an
  inferior rest point. Orthogonal to everything above; already flagged in the draft.
- **Tipping.** $r+\theta+\theta'P\le0$ makes $p^P$ diverge. Excluded by assumption, kept on the
  list because the assumption is not innocuous.
- **Utility degeneracy.** In A3 and B3, if $u\left(0\right)=-\infty$ (CRRA, $\eta\ge1$) then
  every feasible path has $U_0=-\infty$ and the problem cannot rank them. This is a real hazard
  for the quantitative model, not a curiosity. Fixes: require level-inessentiality whenever
  $\bar R>0$; bound $u$; or use an overtaking criterion.
- **C2 is currently ill-posed.** Without residence time, a closed loop supports any throughput
  from any stock of matter (see residence_time_draft.md). So C2 cannot be stated as a result
  until either the waste stock is added or the state is explicitly conditioned as heuristic.

## 6. Proposed narrowing

Keep as headline states: **A1** (dematerialized survival after a finite material era), **A3**
(shutdown collapse), **C2** (perpetual circularity). These are the three qualitatively distinct
answers to "what happens to an economy with a material floor", and each maps to a clean policy
reading.

Keep as limiting cases for comparison, not as headline results: **B1, B2, B3** -- these are the
$\bar R=0$ states the current Section 4 already contains, and they should be retained as the
$\bar R\to0$ limit rather than deleted, since they show what the floor is doing.

Drop: **C1, C3** (eliminated by F4), **M3** (eliminated by the cumulative bound), and the
marginal-essentiality subdivision whenever $\bar R>0$.

## 7. Unverified

Everything in Sections 3-4 above about C2 rests on a heuristic rate-matching pass, not a
completed derivation. Specifically: that the wedges $\zeta\Omega^j$ stay bounded along a
closing loop, that the recycling-capital condition is satisfiable with a finite marginal
product of capital, and the claim that sustainable throughput scales with $g$ times the
retained material stock. The exponential yield form has a degeneracy here -- $a'$ and
$\left|p^W\right|$ scale as $e^{-\xi x}$ and $e^{+\xi x}$ exactly, so their product is
independent of $x$ -- which needs to be understood before any of it goes into the paper. The
eliminations (F1-F4, M3, C1, C3) are feasibility arguments and are solid.
