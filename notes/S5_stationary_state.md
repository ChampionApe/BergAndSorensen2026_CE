# S5 — Stationary extraction–exploration state

Working note, 2026-08-18. Case S5 of
[longrun_sustained_consumption.md](longrun_sustained_consumption.md): the steady state with
permanent virgin inflow and partial circularity forever. First pass: configuration, the selection
map against S1/S2, the full stationary system, its structure, and what needs to be settled.
Equation labels refer to `writing/docs/` (the balanced-path results are now in
`theory_planner_longrun.tex` / `Appendix_longrun.tex`).

Flags: **[docs]** in docs · **[d]** derived here · **[conj]** conjectured · **[open]** open.

---

## 0. Configuration and where S5 sits

All controls and states constant:

$$\bar N=\bar D>0,\quad \bar S>0,\quad \bar a\bar\varpi<1\ \text{strictly},\quad
\bar P>0,\quad \bar C>0,\quad I=0,$$

with cumulative discovery $X_t\to\infty$ (it grows at rate $\bar D$ forever) — so "stationary" is
asymptotic in $X$, and S5 needs the discovery cost to *settle* as $X$ grows (Assumption A2 below).
Circularity is partial forever; pollution is positive forever; the model's answer to "optimal
recycling" is an interior rate, not a limit.

**The selection map.** The S1/S2 analysis delivers two primitives that partition the
sustained-consumption space, and S5 occupies the cell complementary to the balanced path in both:

| | discovery exhaustible ($C^D_D(0,X)\to\infty$ at $\bar X_{\max}<\infty$) | discovery inexhaustible ($C^D\to\bar C^D(D)$ as $X\to\infty$) |
|---|---|---|
| $A_\infty-\delta>\rho$ | **S1/S2** (given tail matching; else exits) | growing hybrid — *not in the current case list; see §5* |
| $A_\infty-\delta<\rho$ | no interior limit → Collection II (collapse) | **S5** |

- $A_\infty-\delta<\rho$ is what makes a *bounded* optimal capital stock exist (the modified
  golden rule below has a finite solution); it is exactly the complement of the balanced path's
  growth condition C1. **[d]**
- Inexhaustible discovery is the complement of C6. Note the S1-vs-S5 selection is therefore *not*
  a matter of parameter regions of one condition but of two independent primitives; the
  off-diagonal cells are real and one of them (growth + inexhaustible discovery) is an unexplored
  configuration. **[d]**

S5 is robust where S1/S2 is fragile: all prices bounded, so the $\Phi^I$ treatment, $v'(0)$, and
tail matching are all innocuous here. **[d]**

## 1. Assumptions S5 needs

- **A1 (bounded optimum):** $A_\infty-\delta<\rho$, i.e. $F_K(K,\bar R,\bar P)$ falls below
  $\rho+\delta$ at finite $K$. Standard neoclassical.
- **A2 (inexhaustible discovery):** $C^D(D,X)\to\bar C^D(D)$ as $X\to\infty$, with
  $C^D_X\to 0$ and $C^D_D\to\bar C^D_D(D)$ finite. (If $C^D_X\to c>0$, the cost *flow* still
  settles but $p^X$ stays a negative constant; if $C^D(D,X)\to\infty$, the exploration cost flow
  eventually exceeds output and S5 dies — this is the L5-type condition, now explicit.)
- **A3 (sink stability):** $\rho+\theta(\bar P)+\theta'(\bar P)\bar P>0$ and $\theta(P)P$
  increasing at $\bar P$ (no local tipping), so $p^P$ is finite and the pollution steady state
  stable.
- **A4 (regularity):** wedges positive at the steady state, $1+\zeta\Omega^j>0$,
  $1-\zeta\Omega^Y>0$.

## 2. The stationary system

With $C$ constant and $\zeta\Omega^C$ constant, `eq:sp:sum:Cgrowth` gives $r=\rho$. The costate
equations then collapse to level conditions **[d]**:

$$p^M=\frac{\delta\,p^W}{\rho+\delta},\qquad
p^W-p^M=\frac{\rho\,p^W}{\rho+\delta},\qquad
\zeta=\sigma\frac{\rho\,p^W}{\rho+\delta},$$

$$p^S=\frac{|C^N_S(\bar N,\bar S)|\,w_N}{\rho},\qquad
p^X=-\frac{C^D_X\,w_D}{\rho}\ \ (\to 0\text{ under A2}),\qquad
p^P=\frac{v'(\bar P)/\bar\lambda-F_Pw_Y}{\rho+\theta(\bar P)+\theta'(\bar P)\bar P},$$

with $w_j\equiv 1\pm\zeta\Omega^j$, $\bar\lambda=u'(\bar C)/(1+\zeta\Omega^C)$,
$\sigma=\Phi^I\bar G/\bar R$, $\bar G=\delta\bar K$, $\bar M^K=\sigma\bar R/\delta$.

**Capital (modified golden rule):** combining `eq:sp:sum:I` with the stationary `eq:sp:sum:K`:

$$F_K\,w_Y=\left(\rho+\delta\right)q,\qquad q=1-\Phi^I(1-\sigma)\frac{\rho\,p^W}{\rho+\delta}
\quad\Longrightarrow\quad
F_Kw_Y=\rho+\delta-\Phi^I(1-\sigma)\,\rho\,p^W .$$

The golden rule is tilted by the storage value of capital's embodied material: if waste is costly
($p^W>0$), embodying material in capital is a service and the steady state holds *more* capital
than the standard rule; if $p^W<0$ the tilt reverses. **[d]**

**The five materials conditions** (all margins interior; corners in §3):

1. Extraction `eq:sp:sum:N`: $\Psi=C^N_N(\bar N,\bar S)w_N+p^S+p^W(1+\Omega^{N,S})$,
   $\Psi=F_Rw_Y+\zeta$.
2. Exploration `eq:sp:sum:D`: $p^S+p^X=\bar C^D_D(\bar N)w_D+p^W\Omega^{D,S}$.
3. Waste `eq:sp:sum:W`:
   $p^W(1-\alpha\bar\varpi)=c^Ww_W+p^P\left[1-\bar\varpi(1-d^W)-d^W\alpha\bar\varpi\right]-\alpha\bar\varpi\Psi$.
4. Treatment `eq:sp:sum:varpi-interior`: $\alpha V+p^P(1-d^W)=c^{T\prime}(\bar\varpi)w_W$,
   $V=\Psi-p^W+d^Wp^P$.
5. Recycling capital `eq:sp:sum:KR-interior`: $a'(\bar x)V=F_Kw_Y$.

**Quantities:**

$$\bar W\left(1-\bar a\bar\varpi\right)=\bar N\left(1+\Omega^{N,S}+\Omega^{D,S}\right),\qquad
\bar R=\bar N+\bar a\bar\varpi\bar W,\qquad
\theta(\bar P)\bar P=\left[1-\bar\varpi+d^W\bar\varpi(1-\bar a)\right]\bar W,$$

$$\bar\Omega=\frac{\bar R}{\bar{\mathcal D}+\phi^I\bar G},\qquad
F\left(\bar K-\bar K^R,\bar R,\bar P\right)=\bar C+\delta\bar K+C^N(\bar N,\bar S)
+\bar C^D(\bar N)+c^W\bar W .$$

**Count.** 17 unknowns ($\bar C,\bar N,\bar\varpi,\bar x,\bar W,\bar\Omega,\bar K,\bar S,\bar P,
\bar\lambda$ and $p^W,\zeta,p^S,p^X,p^P,p^M,q$) against 17 equations (8 FOCs, 5 stationary
costates, 3 static constraints, 1 pollution stationarity; $\bar D=\bar N$ and $I=0$ built in).
The system closes. **[d]** Existence/uniqueness is §4.

## 3. Reading the system

**The reserve-inventory condition.** Combining the $p^S$ level with the exploration margin
(under A2, $p^X\to0$):

$$\frac{|C^N_S(\bar N,\bar S)|\,w_N}{\rho}\;=\;\bar C^D_D(\bar N)\,w_D+p^W\Omega^{D,S}.$$

Reserves are a *produced inventory*: the stationary stock $\bar S$ is where the flow convenience
yield of a tonne in the ground (the extraction-cost saving $|C^N_S|$) annuitized at $\rho$ equals
its replacement cost (marginal discovery cost, adjusted by the waste charge or credit on
overburden). Hotelling's rent is pinned by replacement cost, not by dynamics — the stock effect
turns the Hotelling rule into an inventory condition. Given $\bar N$, this determines $\bar S$
provided $|C^N_S|$ is monotone in $S$ (needs $C^N_{SS}>0$-type curvature — *not currently
assumed in the docs*; flag). **[d, open]**

**The sign of $p^W$ is a genuine question in S5.** Unlike the balanced path (where
$p^W\to-\infty$ necessarily), the stationary waste price can be positive (waste is a social cost:
treatment + pollution dominate) or negative (waste is an asset: recycling surplus dominates).
From the waste FOC, $p^W<0$ iff $\alpha\bar\varpi\Psi>c^Ww_W+p^P[\cdot]$ at the steady state.
Both regimes are admissible; the sign flips the golden-rule tilt and the overburden term in the
inventory condition. Worth mapping in the quantitative model. **[d]**

**S5a vs S5b (recycling active or not).** The recycling-capital margin selects:
$\bar x>0$ iff $a'(0)V>F_Kw_Y$ at the candidate steady state. If $a(\cdot)$ has an Inada slope at
zero ($a'(0)=\infty$), S5b is impossible and recycling is always active — the Part 3 functional
form choice decides this. In S5b ($\bar K^R=0$): $\alpha=a(0)-a'(0)\cdot 0=0$, so the treatment
margin collapses to the pure pollution motive $p^P(1-d^W)=c^{T\prime}(\bar\varpi)w_W$, and
$\bar R=\bar N$, $\bar W=\bar N(1+\Omega^{N,S}+\Omega^{D,S})$. **[d]**

**Treatment interior.** $\bar\varpi\in(0,1)$ requires $0<\alpha V+p^P(1-d^W)<c^{T\prime}(1)w_W$;
the lower bound holds whenever $p^P>0$ (always) and $\alpha V\ge 0$, so an S5 steady state never
sits at $\bar\varpi=0$ — Prop-style statement worth recording: *some treatment always*, for the
pollution motive alone. Upper corner $\bar\varpi=1$ possible if $c^{T\prime}(1)$ finite and the
gain large; then the ledger still has $\bar a<1$ keeping $\bar a\bar\varpi<1$. **[d]**

## 4. Existence and uniqueness — the plan

Heuristic block-recursion for existence **[open]**, to be made rigorous or verified numerically:

1. Guess $(\bar N,\bar P,p^W)$.
2. Inventory condition → $\bar S$; extraction FOC → $\Psi$; $\Psi=F_Rw_Y+\zeta$ and the
   golden rule → $(\bar K^Y,\bar R)$-consistency; recycling block (4)–(5) → $(\bar\varpi,\bar x)$;
   ledger + $R$-definition → $(\bar W,\bar N)$-consistency; pollution stationarity → $\bar P$;
   waste FOC → $p^W$. Iterate.
3. Goods constraint reads off $\bar C$; need $\bar C>0$ — the substantive existence condition
   beyond A1–A4: the stationary economy must afford its extraction, exploration and treatment
   bills. Sufficient conditions **[open]**.

Uniqueness is not expected in general (the $p^W$-sign discussion suggests possibly two
self-consistent regimes); check numerically first. **[open]**

## 5. The unexplored cell: growth + inexhaustible discovery

Flagged, not analyzed. With $A_\infty-\delta>\rho$ *and* cheap perpetual discovery, the economy
grows and there is no force killing extraction: candidate configuration has growing $Y,K$ and
material throughput either stationary or *growing*. A materially-stationary version seems
inconsistent: growth makes $F_R$ (hence $\Psi$) grow, pushing the recycling and extraction margins
— plausibly toward growing $R$ and $W$ financed by perpetual extraction with $S$ regulated by the
inventory condition. This is a distinct long-run configuration ("materially expanding growth
path") that the collection note should list; it may be the empirically relevant one for a
calibration with realistic growth. **[conj]** Add to the collection note after a first pass.

## 6. To settle next

1. Curvature assumption $C^N_{SS}$ (monotone convenience yield) — needed by the inventory
   condition; propose adding to `eq:sp:setup:extraction-cost`.
2. Existence: implement the §4 iteration symbolically/numerically on benchmark functional forms;
   determine when $\bar C>0$.
3. Uniqueness / multiplicity, esp. across the $p^W$ sign regimes.
4. Comparative statics: $(\bar N,\bar x,\bar\varpi,\bar a\bar\varpi,\bar P)$ in $\rho$, $d^W$,
   treatment cost level, discovery cost level, damage scale. These are the paper's
   policy-relevant objects (the "optimal recycling rate" in the long run).
5. The growth+discovery cell (§5): decide whether it enters the paper or is excluded by
   assumption.
6. Local dynamics around the steady state (saddle-path) — needed for Part 3 transition anyway.
