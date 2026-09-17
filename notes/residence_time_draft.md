# Residence time for materials: what it does to the balance principle and the ledger

*Draft for evaluation -- not committed to writing/docs/. Date: 2026-08-21.*

## 1. The problem this is meant to solve

The model gives material a residence time in exactly one place: the capital stock, via $M^K$
with release rate $\delta$. Every other use of the final good -- the embodied content of
consumption, of extraction and exploration effort, of treatment -- generates its waste in the
same instant it absorbs the good. The recycling loop inherits that: waste is generated,
collected, treated and returned to $R$ with no time elapsing.

The consequence is the circularity multiplier. $\left(1-a\varpi\right)^{-1}$ counts passes
through production, and those passes cost no time, so the *level* of material throughput is not
tied to the quantity of matter in the economy at all. Under the hard ceiling this never bites,
because the multiplier is bounded by $\left(1-\bar a\right)^{-1}$. Under the soft ceiling
$\bar a=1$ it bites hard: at $a\varpi=1$ the collected ledger reads $0=N-\dot M^K+\mathcal N$
and says nothing whatever about $W$, so a closed loop supports **any** throughput, including an
unboundedly growing one, from an arbitrarily small stock of matter. That is not a knife-edge
curiosity; it is the configuration the soft ceiling is supposed to describe.

A second, independent motivation: a paper about the circular economy currently has no stock of
secondary material. There is a virgin reserve $S$ with a rent $p^S$, and nothing on the other
side. Landfills, stockpiles and discarded durables -- the anthropogenic reserve -- are the
obvious missing object, and they are the same object that fixes the throughput problem.

## 2. The general form: give every use a stock

Index the uses of the final good by $j\in\left\{Y,N,D,C,W,I\right\}$, let $Q^j$ be the
final-good quantity each absorbs, and replace the pair "embodiment intensity $\Phi^j$ / waste
intensity $\Omega^j$" by a single intensity plus a release rate:

$$\dot M^j = \Phi^j Q^j - \delta^j M^j, \qquad \text{waste outflow from } j = \delta^j M^j .$$

The present model is the limiting case $\delta^j\to\infty$ for every $j\neq I$ -- the stock
collapses to zero, the outflow converges to $\Phi^jQ^j$, and that product is what is currently
written $\Omega^jQ^j$. So $\Omega^j$ and $\Phi^j$ are not two different objects: $\Omega^j$ is
what $\Phi^j$ is called when residence time is zero. Capital is the one use already treated
correctly, with $\delta^I=\delta$.

### 2.1 The ledger is unchanged in form

Keep the production split into scrap and embodied content, $R=\Omega^YY+\Phi^YY$, with the
embodied part distributed across uses, $\Phi^YY=\sum_j\Phi^jQ^j$. Total waste generation is

$$W \;=\; \underbrace{\Omega^Y Y}_{\text{production scrap}} \;+\; \underbrace{\sum_j \delta^j M^j}_{\text{end of life}} \;+\; \underbrace{\mathcal N}_{\text{displaced from nature}} .$$

Write $M\equiv\sum_j M^j$ for total material embodied in goods in use. Summing the laws of
motion gives $\sum_j\delta^jM^j=\Phi^YY-\dot M$, hence

$$\boxed{\;W \;=\; R-\dot M+\mathcal N\;}$$

which is **exactly** the ledger (eq:sp:setup:ledger) with $M^K$ replaced by $M$. Nothing in the
statement changes; the interpretation broadens from "material embodied in the capital stock" to
"material embodied in all goods in use". This is the reassuring half of the answer: the
materials-balance layer of Section 1 is robust to the generalisation, and $p^W$, $\zeta$ and the
whole optimality structure survive in form.

### 2.2 But it does not, on its own, cap throughput

Set $N=\mathcal N=0$ and look for a stationary closed loop, $\dot M=0$. The ledger gives $W=R$,
and $R=a\varpi W$ then forces $a\varpi=1$ -- the same conclusion as before, with the same
silence about the level of $W$. The reason is that residence time was added to *goods in use*
but not to the *loop itself*: production scrap $\Omega^YY$ can travel
$R\to\text{scrap}\to\text{treated}\to R$ instantaneously, so an arbitrarily small stock still
supports arbitrarily large throughput.

**Residence in use is the wrong place to put the delay.** The delay has to be in the recovery
pipeline.

## 3. The design that works: a waste stock

Let $\mathcal W$ be the stock of waste held in the economy -- in place, in landfill, in
stockpile, in discarded durables. Waste generation $W$ (defined exactly as now) flows into it;
material is drawn out for handling at rate $\mu>0$:

$$\dot{\mathcal W} \;=\; W-\mu\mathcal W .$$

Everything downstream is levied on the **handled** flow $H\equiv\mu\mathcal W$ rather than on
generation:

$$T=\varpi H,\qquad R^R=a\left(x\right)T,\qquad x=\frac{K^R}{\varpi\mu\mathcal W},\qquad
\Xi=\left[1-\varpi+d^W\varpi\left(1-a\right)\right]\mu\mathcal W,$$

and the handling cost becomes $C^W=\left[c^c+c^T\left(\varpi\right)\right]\mu\mathcal W$, which
is arguably the more correct reading anyway: collection and treatment are paid on what you
process, not on what you generate.

### 3.1 It nests the current model exactly

As $\mu\to\infty$, $\mathcal W\to W/\mu\to0$ and $H=\mu\mathcal W\to W$: every expression
collapses to the present one. The same holds in any stationary state, where
$\dot{\mathcal W}=0$ gives $\mu\mathcal W=W$ directly. **So the current formulation is the
instantaneous-handling limit, and the circularity multiplier survives as the steady-state value
of a dynamic system rather than as a definition.** That is the honest way to describe what is
lost: $\left(1-a\varpi\right)^{-1}$ stops being an algebraic identity and becomes a property of
a path. It is still the right object at a rest point.

### 3.2 It delivers the cap

Recovered material is bounded by the stock,

$$R^R=a\varpi\mu\mathcal W\;\le\;\bar a\,\mu\,\mathcal W ,$$

and total material ever inside the economy is bounded by the budget $\mathcal B$ of
(eq:sp:lr:budget), so $\mathcal W\le\mathcal B$ and

$$R \;\le\; N+\bar a\,\mu\,\mathcal B .$$

**Circular throughput is bounded by the material budget times the handling rate, and the bound
holds at $\bar a=1$.** The pathology of Section 1 is gone: a closed loop can no longer
manufacture throughput out of nothing, and the soft ceiling becomes analysable rather than
degenerate.

With the minimum material requirement $\bar R>0$, the survival question then reduces to a single
interpretable inequality -- the economy can hold the floor forever only if it can hold

$$\mathcal W \;\ge\; \frac{\bar R}{\bar a\,\mu}$$

forever, i.e. only if the retained anthropogenic stock, turning over at rate $\mu$, covers the
floor. This is the physically meaningful version of "can the circular economy sustain itself",
and it is not available in the current model at any parameter values.

### 3.3 What it adds to the state vector

One state, $\mathcal W$, and one costate. The natural guesses, to be derived properly:

- The costate $\lambda p^{\mathcal W}$ on $\dot{\mathcal W}$ prices a tonne of stockpiled
  material. On squeeze paths it should be **positive** -- the stockpile is an asset -- which is
  the same economics the current model expresses through $p^W<0$, but now attached to a stock
  that actually exists.
- The static multiplier $p^W$ on the ledger survives unchanged, linked to $p^{\mathcal W}$
  through the $W$ first-order condition: generating a tonne of waste puts a tonne into the
  stockpile, so roughly $p^W=-p^{\mathcal W}$ up to the collection margin.
- $\dot p^{\mathcal W}=rp^{\mathcal W}-\mu\left[\text{value of handling a tonne}\right]$, an
  ordinary asset-pricing equation. The forward representation makes the anthropogenic reserve
  the exact mirror of the virgin reserve: $S$ pays a dividend by making future extraction
  cheaper, $\mathcal W$ pays one by making future recovery possible.

That symmetry is the substantive gain, and it is arguably worth the state variable independently
of the throughput problem.

### 3.4 Optional: make the handling rate a control

Nothing forces $\mu$ to be a parameter. A collection-intensity margin -- faster recovery of the
stockpile at a rising marginal cost -- would give the model an explicit landfill-mining
decision, which is the kind of thing the quantitative part could speak to. It also makes
$\mathcal W$ genuinely a reserve depleted at a chosen rate rather than a passive buffer.
Recommendation: keep $\mu$ constant in the theory, allow it to be a control in the quantitative
model.

## 4. The more radical variant, for comparison

The design above keeps the $\Omega^j$ apparatus intact. The alternative is to remove
instantaneous release everywhere -- set $\Omega^Y=0$ and route *all* material through use
stocks, so that $W=\delta^MM+\mathcal N$ with a single aggregated stock and release rate. The
ledger then becomes a genuine law of motion, $\dot M=R+\mathcal N-\delta^MM$, waste generation
is proportional to the material stock, and the throughput cap follows without a separate waste
stock.

It is cleaner, and it collapses the two intensity families into one. But it costs two things the
current draft explicitly wants: the $\Omega,\omega^j$ layer that Section 1.4 justifies as the
bridge to published material-flow accounts, and the distinction between fast and slow reservoirs
unless several stocks are carried anyway. On balance I would not do it -- the waste-stock design
buys the same cap for less.

## 5. What this would cost in the documents

- **Setup (Sections 1.2-1.4).** New primitive $\mu$ and state $\mathcal W$; recycling arguments
  change from $\varpi W$ to $\varpi\mu\mathcal W$; handling cost levied on $\mu\mathcal W$. The
  balance principle and the ledger identity are **unchanged in form** (Section 2.1 above). The
  circularity-multiplier paragraph needs rewriting as a steady-state statement (Section 3.1).
- **Optimality (Section 2).** One more state, one more costate, one more law of motion. The
  eight FOCs keep their structure; the waste margin (eq:sp:sum:W) and the recycling block need
  re-deriving with $H=\mu\mathcal W$ in place of $W$. The elimination behind $V$ should survive.
- **Long run (Section 4).** Substantially strengthened rather than damaged: the
  finite-throughput lemma gains a companion stock bound that holds under the soft ceiling, and
  the long-run states involving perpetual circularity become well posed instead of degenerate.
- **Workhorse.** $x=K^R/\left(\varpi\mu\mathcal W\right)$ throughout; the closed-form margins
  are otherwise unaffected.

## 6. Decision points

1. Waste stock, or full residence time on every use? -- recommendation: the waste stock.
2. Is $\mu$ constant or a control? -- recommendation: constant in theory, control in the
   quantitative model.
3. Does the untreated stockpile pollute while it sits, or only when handled? The draft assumes
   the latter, which is convenient but makes landfills environmentally free. A leakage term
   $\ell\mathcal W$ into $\dot P$ is the obvious fix, and would give the stockpile a genuine
   cost as well as a value.
4. Now, or deferred to the extensions list with the soft-ceiling analysis conditioned on it?
   The throughput pathology only matters for the $\bar a=1$ rows of the taxonomy, so deferring
   is defensible -- but then those rows cannot be stated as results.
