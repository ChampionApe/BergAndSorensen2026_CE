# Terminal limits of the planner's problem (continuous time)

Working note, 2026-08-18. Which configurations the Part 1 planner's problem can converge to as
$t\to\infty$, and the exact condition selecting each. Companion to §`sec:sp:opt:phases` and the open
bullets in §`sec:sp:opt:results`; not authoritative, `writing/docs/` is.

Status flags: **[P]** proved in the docs · **[D]** derived in discussion, not yet written up ·
**[O]** open.

---

## 0. The four objects that decide everything

**Virgin displacement value** (`eq:sp:sum:V`, requires $N>0$):

$$
V \;=\; \Psi - p^W + d^W p^P \;=\; C^N_N\left(1+\zeta\Omega^N\right) + p^S + \Omega^{N,S}p^W + d^W p^P
$$

**Capital margin, interior** (`eq:sp:sum:recycling-virgin-KR`):

$$
V \;=\; \frac{F_K\left(1-\zeta\Omega^Y\right)}{a'(x)}
$$

**Stationary ledger** (`eq:sp:multiplier-identity`):

$$
R \;=\; W \;=\; \frac{N}{1-a\varpi}
$$

**Reserve rent** (`eq:sp:sum:S`), with $C^N(0,S)\equiv 0$ for all $S$ and hence $C^N_S(0,S)=0$:

$$
p^S(t) \;=\; \int_t^\infty \lvert C^N_S\rvert\left(1+\zeta\Omega^N\right)e^{-\int_t^s r\,d\tau}\,ds
$$

The last is the one not currently in the docs: the reserve's dividend vanishes with extraction, so
**$p^S$ is hump-shaped and $p^S\to 0$ whenever $N\to 0$**. The scarcity rent dies of irrelevance, not
of abundance. **[D]**

---

## 1. The candidate limits

| # | Limit | Prevails iff |
|---|---|---|
| L1 | Asymptotic circularity, $N\to 0$ never reached | tail condition (§L1) holds |
| L2 | Extraction corner $N=0$ on an interval | corner inequality holds **and** $\dot M^K<0$ |
| L3 | Material collapse, $R\to 0$ | $\lim_{x\to\infty}a(x)=\bar a<1$, or capital cannot fund $x\to\infty$ |
| L4 | Semi-linear stall, $K^R=0$ forever | $a'(0^+)V\le F_K(1-\zeta\Omega^Y)$ never reversed |
| L5 | Perpetual exploration, $S$ never declines | $C^D_X\to 0$ fast enough |
| L6 | Pollution tipping point | $r+\theta(P)+\theta'(P)P\le 0$ on a terminal interval |

L1–L3 are mutually exclusive and exhaust the post-$t_R$ possibilities. L4 and L5 are pre-$t_R$
escapes; L6 is orthogonal and can accompany any of them.

---

## L1 — Asymptotic circularity *(the intended limit)*

$N\to 0$, $x\to\infty$, $a\to 1$, $\varpi\to 1$, $R$ bounded away from zero, $\Xi\to d^W N\to 0$.

Requires, jointly:

**1. Exploration has ceased** at a finite date,

$$
p^S+p^X \;\le\; C^D_D(0,X)\left(1+\zeta\Omega^D\right)+p^W\Omega^{D,S}
$$

Guaranteed if $C^D_X$ is bounded away from zero, since $p^X$ then accumulates without bound. **[P]**

**2. Recycling is running**: $t_R$ finite, i.e. $a'(0^+)V>F_K(1-\zeta\Omega^Y)$ at some date. **[P]**

**3. The multiplier keeps pace**: $1-a\varpi$ falls at the rate at which $N$ falls, so that
$R=N/(1-a\varpi)$ stays bounded. With $\varpi=1$ this is a condition on $1-a(x)$, and hence on how
fast $K^R$ grows. **[P]** as identity, **[O]** as outcome.

**4. The extraction corner is never reached.** With $p^S\to 0$ and the capital margin substituted,

$$
\frac{F_K\left(1-\zeta\Omega^Y\right)}{a'(x)} \;>\; C^N_N(0,S)\left(1+\zeta\Omega^N\right)+\Omega^{N,S}p^W+d^W p^P \qquad \text{for all } t
$$

Sufficient: $a'(x)\,C^N_N(0,S)\to 0$ along the path, with $F_K(1-\zeta\Omega^Y)$ bounded away from
zero. **[D, O]**

**Reading of (4).** Deep circularity forces $a'\to 0$, so the value $V$ needed to justify the marginal
unit of recycling capital diverges — and $V$ *is* the cost of the virgin tonne displaced. An economy
that has built enough recycling capital to stop extracting has thereby made recovered material so
expensive that extraction is worth restarting. Extraction is self-reviving.

**Two by-products.** $\varpi=1$ is reached in *finite* time under L1: the marginal gain
$\alpha V+p^P(1-d^W)$ diverges against the finite bound $c^{T\prime}(1)(1+\zeta\Omega^W)$, so branch
`eq:sp:sum:varpi-upper` binds. And $p^W<0$ is likely but not required — the exact sign condition,
valid while $N>0$, is

$$
p^W<0 \quad\Longleftrightarrow\quad \alpha\varpi\left[C^N_N\left(1+\zeta\Omega^N\right)+p^S\right] \;>\; c^W\left(1+\zeta\Omega^W\right)+p^P\left[1-\varpi\left(1-d^W\right)-d^W\alpha\varpi\right]
$$

which then makes $\zeta<0$, so the regularity assumption $1+\zeta\Omega^N>0$ of
Prop. `prop:sp:phases` becomes the substantive restriction $\lvert\zeta\rvert\,\Omega^N<1$. **[D]**

**Conditions (3) and (4) pull in opposite directions.** With $\varpi=1$ and $N\sim e^{-gt}$:

| Tail of $a$ | $x$ growth | $K^R$ growth | $a'$ decay | $V$ growth |
|---|---|---|---|---|
| $1-a(x)=e^{-x}$ | $x\sim gt$ | linear in $t$ | $e^{-gt}$ | $e^{gt}$ |
| $1-a(x)=\gamma x^{-\psi}$ | $x\sim e^{gt/\psi}$ | exponential | $e^{-gt(\psi+1)/\psi}$ | $e^{gt(\psi+1)/\psi}$ |

The power tail makes sustaining $R$ *harder* (condition 3) but makes the extraction corner *easier to
avoid* (condition 4), because $V$ diverges faster. Whether L1 or L2/L3 prevails is therefore a race
between the tail of $a(\cdot)$ as $x\to\infty$ and the tail of $C^N(\cdot,S)$ as $S\to 0$. **[O]**

---

## L2 — Extraction corner $N=0$

Admissible only after $t_R$, since $R^R>0$ is what keeps $F_R$ finite. Requires, jointly:

1. $p^S=0$ — automatic, the dividend vanishes with $N$. **[D]**
2. $D=0$ — follows, since $p^S+p^X<0\le$ marginal exploration cost. **[D]**
3. The corner inequality **[P]**:

$$
\Psi \;\le\; C^N_N(0,S)\left(1+\zeta\Omega^N\right)+p^W\left(1+\Omega^{N,S}\right)
$$

4. **Feasibility.** The ledger with $N=D=0$ gives

$$
W\left(1-a\varpi\right) \;=\; -\dot M^K
$$

so a positive material throughput requires the capital stock to be *releasing* embodied material.
Since $M^K\ge 0$, this can finance only a transient episode. **[D]**

So L2 is a temporary corner living off decumulation of embodied material, **not a terminal limit**.
This is what makes the docs' `eq:sp:sum:N-corner` remark true but misleading as written.

Note that condition 3 is *not* made easier by depletion: $C^N_N(0,S)$ rises as $S\to 0$, which pushes
toward the corner, while $p^W<0$ pushes away. The $p^W$ channel alone does not settle it.

---

## L3 — Material collapse $R\to 0$

Prevails if either:

1. $\lim_{x\to\infty}a(x)=\bar a<1$, capping the multiplier at $(1-\bar a\varpi)^{-1}$ and forcing
   $R\to 0$ with $N$. The assumption $\lim_{x\to\infty}a=1$ in `eq:sp:setup:recycling` is carrying the
   entire sustainability result. **[P]**
2. $\bar a=1$ but the required $K^R$ growth (row 2 of the L1 table) cannot be funded — the power-tail
   case, needing productivity growth at rate $g/\psi$ or better. **[O]**

Consumption is then not sustainable and the classical exhaustible-resource conclusion returns.

---

## L4 — Semi-linear stall

$K^R=0$ at every date, i.e. $a'(0^+)V\le F_K(1-\zeta\Omega^Y)$ never reversed.
Prop. `prop:sp:phases` shows the threshold is self-terminating under depletion alone ($C^N_N$ and
$p^S$ rise, $F_K$ falls), so L4 requires reserves effectively inexhaustible — which is L5. Treatment
is still positive throughout ($\varpi>0$, Prop. i) but is chosen for the pollution motive alone,

$$
p^P\left(1-d^W\right) \;=\; c^{T\prime}\left(\varpi\right)\left(1+\zeta\Omega^W\right)
$$

**[P]**

---

## L5 — Perpetual exploration

Excluded in the docs by $p^X\to-\infty$, which rests on $C^D_X$ bounded away from zero. If exploration
cost does not rise with cumulative discovery, $S$ need never decline and the economy stays in L4
indefinitely. Worth stating as an assumption rather than leaving implicit. **[O]**

---

## L6 — Pollution tipping point

If $\theta'<0$ is strong enough that $r+\theta+\theta'P\le 0$ on a terminal interval, the integral for
$p^P$ need not converge. Ruling this out is a restriction on $\theta(\cdot)$, not something the
optimality conditions deliver. Compatible with any of L1–L5. **[P]** as stated, restriction not
imposed.

---

## What to settle next

- Check whether the Part 3 CES aggregator (elasticity $\tfrac12$, $a'(0^+)=a^m_t$ finite) has an
  exponential or power tail — that decides whether L1 condition (4) is a theorem or an assumption in
  the version actually computed.
- Write up $p^S\to 0$ and the hump shape; §`sum:S` currently reads as if the rent rises monotonically.
- Restate $C^N_S<0$ as holding for $N>0$ only. As written it would keep $p^S>0$ at $N=0$.
- Flag that $V$'s "avoided cost of the virgin tonne" reading is conditional on $N>0$; at L2 it becomes
  an inequality and recycling is paid strictly less.
- $S\ge 0$ is not in the domain list of Problem `prob:sp`, and no $\lim_{S\to 0}C^N_N=\infty$
  substitutes for it. One of the two is needed.
