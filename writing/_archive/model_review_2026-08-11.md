# Complete re-derivation and review of the three models

Working document, 11 August 2026. Re-derives every optimality condition in
`writing/docs/Part1_theory_central.tex`, `Part1_theory_decentral.tex` and `Part1_quant.tex`
from the Hamiltonian, under the agreed reading that the materials balance is an
**accounting ledger** (which determines $\Omega$) rather than a constraint on the allocation.

Section 8 is the discrepancy table against the current drafts. Section 9 lists what I could
not verify.

Notation follows the drafts. Time arguments suppressed; a dot is $d/dt$.

---

## 1. The materials ledger

### 1.1 What is a parameter and what is not

The process-level accounting of `subsec:ac:accounting` is unchanged. Write the
final-good-denominated waste base as

$$\mathcal D \;\equiv\; \omega^Y Y+\omega^{N,Y}C^N+\omega^{D,Y}C^D+\omega^W C^W+\omega^C C ,
\qquad C^W=\left[c^c+c^T(\varpi)\right]W .$$

Summing the process balances and using $\phi^K\delta K^Y+\phi^K\delta K^R=\delta\Phi$:

$$W \;=\; \Omega\,\mathcal D+\Omega\left[\omega^{N,S}N+\omega^{D,S}D\right]+\delta\Phi
\tag{WG}$$

$$\phi^Y Y \;=\; \Omega\left[\omega^{N,Y}C^N+\omega^{D,Y}C^D+\omega^W C^W+\omega^C C\right]+\phi^I(I+\delta K)
\tag{CONS}$$

$$R\;=\;N+R^R\;=\;\Omega\,\mathcal D+\phi^I(I+\delta K)
\tag{MB}$$

**Both** $\Omega$ and $\phi^Y$ are endogenous. (MB) determines $\Omega$; (CONS) then determines
$\phi^Y$, which appears nowhere else and is discarded. Neither restricts the allocation. The
relative intensities $\omega^i$ are the technological primitives, and their *ratios* carry all the
economic content — $\phi^Y$ is the composition-weighted average material intensity of the $Y$
bundle, which moves as the bundle's composition moves.

This is the only change of substance relative to the drafts, and everything below follows from it.

### 1.2 The ledger

Substituting (MB) into (WG), with $\omega^{N,S}=\omega^{D,S}=0$:

$$\boxed{\;W \;=\; N+R^R-\phi^I(I+\delta K)+\delta\Phi \;=\; R-\dot\Phi\;}
\tag{L}$$

**Waste generated = material entering production minus net accumulation of material embodied in
capital.** This is a better statement than the draft's
$W=N+R^R-\phi^I I+\delta K[\phi^K-\phi^I]$ — algebraically identical, but it makes clear that
$\phi^K$ is not needed to state the ledger at all, only to report it.

Since $R^R=a\varpi W$, (L) solves explicitly:

$$\boxed{\;W=\frac{N-\dot\Phi}{1-a\varpi},\qquad R=\frac{N-a\varpi\dot\Phi}{1-a\varpi}\;}
\tag{L$'$}$$

$1/(1-a\varpi)$ is the **circularity multiplier**: the number of times a tonne of virgin material
passes through production before leaving the economy. Well defined since $a\le a^m<1$. In a
stationary capital stock ($\dot\Phi=0$), $N=W(1-a\varpi)$: virgin extraction equals waste not
recycled. This is worth putting in the paper — it is the cleanest one-line statement of what the
circular economy *is* in this model.

### 1.3 When does $\Omega$ matter for the allocation?

Only through the nature-attributable terms. With $\omega^{N,S},\omega^{D,S}>0$, (WG) becomes

$$W = N+R^R-\phi^I(I+\delta K)+\delta\Phi+\Omega\left[\omega^{N,S}N+\omega^{D,S}D\right],$$

and $\Omega$ from (MB) does not cancel, so $(W,\Omega)$ must be solved jointly *and* $\Omega$ enters
the first-order conditions. That is the correct statement of what the split costs — it is not only
a loss of closed form (as `rem:aq:scope` currently says) but a loss of the property that the
relative-intensity calibration is allocation-irrelevant.

The economics is exact: mass conservation pins waste down only when every gram of waste passed
through $R$ on its way in. Overburden is a mass source outside the accounted flow, so it needs its
own intensity, and that intensity has real allocative bite.

---

## 2. The planner's problem

### 2.1 Statement

Controls $\{C,I,K^R,\varpi,N,D,W\}$; states $\{K,\Phi,S,X,P\}$. $\Omega$ appears nowhere.

Current-value Hamiltonian, with $x\equiv K^R/(\varpi W)$, $a\equiv a(x)$, $R^R\equiv a\varpi W$:

$$\begin{aligned}
\mathcal H =\;& u(C)-v(P)+\lambda^K I+\lambda^\Phi\!\left[\phi^I(I+\delta K)-\delta\Phi\right]
+\lambda^S(D-N)+\lambda^X D+\lambda^P\!\left[\Xi-\theta(P)P\right]\\[2pt]
&+\zeta\Big[F\!\left(K-K^R,\,N+R^R,\,P\right)-\delta K-C-C^N(N,S)-C^D(D,X)-\left(c^c+c^T(\varpi)\right)W-I\Big]\\[2pt]
&+\eta\Big[N+R^R-\phi^I(I+\delta K)+\delta\Phi-W\Big]
\end{aligned}$$

**Normalizations.** All prices in units of the final good, all *positive* by construction for the
bad stocks:

$$p^S\equiv\frac{\lambda^S}{\zeta},\quad
p^X\equiv-\frac{\lambda^X}{\zeta},\quad
p^P\equiv-\frac{\lambda^P}{\zeta},\quad
p^\Phi\equiv-\frac{\lambda^\Phi}{\zeta},\quad
p^W\equiv-\frac{\eta}{\zeta}.$$

Note $p^\Phi$ now follows the same convention as $p^P$ and $p^X$ — this alone fixes the sign
confusion in the draft. **There is no $p^M$ and no $MSC^W$.**

### 2.2 Derivatives used

With $z\equiv\varpi W$ and $R^R=a(K^R/z)z$, and $\varepsilon\equiv a'x/a\in(0,1)$:

$$\frac{\partial R^R}{\partial K^R}=a',\qquad
\frac{\partial R^R}{\partial\varpi}=a(1-\varepsilon)W,\qquad
\frac{\partial R^R}{\partial W}=a(1-\varepsilon)\varpi .$$

The pollution flow simplifies, because $a\varpi W=R^R$:

$$\Xi\equiv\left[1-\varpi+d^W\varpi(1-a)\right]W
= W\left(1-\varpi+d^W\varpi\right)-d^W R^R ,$$

$$\frac{\partial\Xi}{\partial K^R}=-d^Wa',\quad
\frac{\partial\Xi}{\partial\varpi}=-W(1-d^W)-d^Wa(1-\varepsilon)W,\quad
\frac{\partial\Xi}{\partial W}=(1-\varpi+d^W\varpi)-d^Wa(1-\varepsilon)\varpi .$$

Writing $\Xi$ this way is worth adopting in the paper; it removes every $\partial a/\partial\cdot$
term from the derivation.

### 2.3 First-order conditions

**Consumption.** $\partial\mathcal H/\partial C=u'(C)-\zeta=0$:

$$\boxed{u'(C)=\zeta}
\tag{P1}$$

No wedge. Consumption generates no marginal waste — the mass was counted when it entered as $R$.

**Investment.** $\partial\mathcal H/\partial I=\lambda^K+\lambda^\Phi\phi^I-\zeta-\eta\phi^I=0$, so
$\zeta=\lambda^K+\phi^I(\lambda^\Phi-\eta)$. Dividing by $\zeta$:

$$\boxed{q\equiv\frac{\lambda^K}{\zeta}=1-\phi^I\left(p^W-p^\Phi\right)\;<\;1}
\tag{P2}$$

The social cost of a unit of capital is *below* one unit of the final good: capital is a temporary
materials sink. $p^W$ is the waste avoided now; $p^\Phi$ is the discounted liability of releasing it
later. Section 3.3 shows $p^W-p^\Phi>0$ always.

**Extraction.** $\partial\mathcal H/\partial N=-\lambda^S+\zeta\left[F_R-C^N_N\right]+\eta=0$:

$$\boxed{F_R-C^N_N-p^W=p^S}
\tag{P3}$$

**Exploration.** $\partial\mathcal H/\partial D=-\zeta C^D_D+\lambda^S+\lambda^X=0$:

$$\boxed{C^D_D+p^X=p^S}
\tag{P4}$$

**Recycling capital.**
$\partial\mathcal H/\partial K^R=-\lambda^P d^Wa'+\zeta\left[F_Ra'-F_K\right]+\eta a'=0$:

$$\boxed{a'(x)\,B=F_K,\qquad B\equiv F_R-p^W+d^Wp^P}
\tag{P5}$$

with complementary slackness $K^R=0$ if $a'(0)B\le F_K$.

**Waste treatment.** Dividing $\partial\mathcal H/\partial\varpi=0$ by $\zeta W$:

$$\boxed{a(1-\varepsilon)\,B+p^P\left(1-d^W\right)=\frac{dc^T}{d\varpi}}
\tag{P6}$$

**Waste (determines the multiplier).** Dividing $\partial\mathcal H/\partial W=0$ by $\zeta$:

$$\varpi\,a(1-\varepsilon)\,B+p^W=c^c+c^T(\varpi)+p^P\left(1-\varpi+d^W\varpi\right)
\tag{P7}$$

$W$ is not a genuine margin — the ledger pins it. (P7) is what determines $p^W$, which keeps the
system square.

### 2.4 Co-state conditions

**Capital.** $\partial\mathcal H/\partial K=\lambda^\Phi\phi^I\delta+\zeta(F_K-\delta)-\eta\phi^I\delta
=\zeta\left[F_K-\delta+\delta\phi^I(p^W-p^\Phi)\right]=\zeta\left[F_K-\delta q\right]$ by (P2). Hence

$$\rho\lambda^K-\dot\lambda^K=\zeta\left[F_K-\delta q\right]=\lambda^K r,
\qquad\boxed{r\equiv\frac{F_K}{q}-\delta}
\tag{P8}$$

**Depreciation is valued at $q$, not at 1**, because replacing worn capital draws fresh material
through the ledger's $\phi^I\delta K$ term. Consequently $\dot\lambda^K/\lambda^K=\rho-r$.

**The goods rate of interest.** From $\lambda^K=\zeta q$,

$$\frac{\dot\zeta}{\zeta}=\rho-r-\frac{\dot q}{q}\;\equiv\;\rho-\iota,
\qquad\boxed{\iota\equiv\frac{F_K}{q}-\delta+\frac{\dot q}{q}}
\tag{P9}$$

$\iota$ is the rate at which the planner trades *goods* across time: the return on capital plus the
capital gain on the materials it embodies. **Every $\zeta$-normalized shadow price discounts at
$\iota$, not at $r$.** The drafts discount at $r$ throughout, which is the single most pervasive
error in them.

**Reserves.** $\partial\mathcal H/\partial S=-\zeta C^N_S$, so with $\lambda^S=\zeta p^S$:

$$\dot p^S=\iota\,p^S+C^N_S
\quad\Longleftrightarrow\quad
p^S(t)=\int_t^\infty\left(-C^N_S(z)\right)e^{-\int_t^z\iota(u)du}\,dz>0
\tag{P10}$$

**Discoveries.** $\partial\mathcal H/\partial X=-\zeta C^D_X$:

$$\dot p^X=\iota\,p^X-C^D_X
\quad\Longleftrightarrow\quad
p^X(t)=\int_t^\infty C^D_X(z)\,e^{-\int_t^z\iota(u)du}\,dz>0
\tag{P11}$$

**Pollution.** $\partial\mathcal H/\partial P=-v'(P)+\zeta F_P+\zeta p^P\hat\theta$:

$$\dot p^P=\left(\iota+\hat\theta\right)p^P-MSC^P,\qquad
MSC^P\equiv\frac{v'(P)}{\zeta}-F_P,\qquad
\hat\theta\equiv\frac{d[\theta(P)P]}{dP}=\theta\left(1-\varepsilon^P\right)
\tag{P12}$$

$$p^P(t)=\int_t^\infty MSC^P(z)\,e^{-\int_t^z\left[\iota(u)+\hat\theta(u)\right]du}\,dz>0$$

**Embodied material.** $\Phi$ enters only through $+\delta\Phi$ in the ledger and its own decay:
$\partial\mathcal H/\partial\Phi=-\lambda^\Phi\delta+\eta\delta=\zeta\delta(p^\Phi-p^W)$. With
$\lambda^\Phi=-\zeta p^\Phi$:

$$\dot p^\Phi=\left(\iota+\delta\right)p^\Phi-\delta p^W
\quad\Longleftrightarrow\quad
\boxed{p^\Phi(t)=\int_t^\infty\delta\,p^W(z)\,e^{-\int_t^z\left[\iota(u)+\delta(u)\right]du}dz\;\ge 0}
\tag{P13}$$

Structurally identical to (P12) with $\delta$ for $\hat\theta$ and $\delta p^W$ for $MSC^P$ — the
pattern-match `rem:ac:Phi-derivation` guessed at is confirmed, but with the opposite sign
convention and with $\iota$ rather than $r$.

**Transversality.** All five are needed:

$$\lim_{t\to\infty}\lambda^K K=\lim_{t\to\infty}\lambda^\Phi\Phi=\lim_{t\to\infty}\lambda^S S
=\lim_{t\to\infty}\lambda^X X=\lim_{t\to\infty}\lambda^P P=0 .
\tag{P14}$$

**Keynes–Ramsey.** Differentiating (P1) and using (P9):

$$\boxed{\frac{\dot C}{C}=\frac{1}{\sigma}\left[\iota-\rho\right],\qquad\sigma\equiv-\frac{u''C}{u'}}
\tag{P15}$$

Textbook form. The draft's $\phi\,g^{MSC}$ term came entirely from $\tau^C$ and disappears.

---

## 3. Cross-checks

These are the checks that convinced me the system is right. They are also the numerical
consistency tests worth coding.

### 3.1 $p^W$ cancels on the recycling margin

Substituting (P3) into $B$:

$$\boxed{B=F_R-p^W+d^Wp^P=p^S+C^N_N+d^Wp^P}
\tag{X1}$$

So (P5) and (P6) become

$$a'(x)\left[p^S+C^N_N+d^Wp^P\right]=F_K,
\qquad
a(1-\varepsilon)\left[p^S+C^N_N+d^Wp^P\right]+p^P(1-d^W)=\frac{dc^T}{d\varpi}.$$

**The marginal social value of recycled material is exactly the extraction cost it saves, plus the
reserve rent it saves, plus the pollution it avoids.** Nothing else. This is a strong check: the
ledger multiplier $p^W$ must drop out here, because recycled material displaces virgin extraction
one-for-one and neither changes total waste at the margin. It does.

This also gives a much more transparent transition condition than the draft's: the economy enters
the circular stage when

$$a'(0)\left[p^S+C^N_N+d^Wp^P\right]>F_K .$$

### 3.2 The circularity multiplier is in (P7), and cancels correctly

Rearranging (P7), $p^W\left[1-\varpi a(1-\varepsilon)\right]=c^c+c^T+p^P(1-\varpi+d^W\varpi)
-\varpi a(1-\varepsilon)\left[F_R+d^Wp^P\right]$, i.e. $p^W$ carries the multiplier
$\left[1-\varpi a(1-\varepsilon)\right]^{-1}$ — the marginal counterpart of $(1-a\varpi)^{-1}$ in
(L$'$), reduced by the dilution effect $(1-\varepsilon)$ of spreading fixed $K^R$ over more waste.
Eliminating $F_R$ with (X1) makes it cancel:

$$\boxed{p^W=c^c+c^T(\varpi)+p^P\left(1-\varpi+d^W\varpi\right)
-\varpi\,a(1-\varepsilon)\left[p^S+C^N_N+d^Wp^P\right]}
\tag{X2}$$

Explicit, no simultaneity. In the linear stage ($a=0$, $\varpi=0$): $p^W=c^c+p^P$.

**The sign of $p^W$ is an outcome, not an assumption.** (X2) can go negative once
$\varpi a(1-\varepsilon)\left[p^S+C^N_N+d^Wp^P\right]$ exceeds collection, treatment and pollution
cost — plausible late in the transition when $p^S$ is large. Then waste is a resource, and by (P3)
extraction carries a *negative* Pigouvian tax: extracting a tonne stocks the recycling loop, and no
private agent internalizes that. The draft asserts $p^W>0$ in `eq:ac:normalizations`; it should
not. Flagging this as something to watch in the simulations rather than a defect.

### 3.3 $p^\Phi<p^W$ always, so $q<1$ always

From (P13), $p^\Phi$ is a $(\iota+\delta)$-discounted stream of $\delta p^W$. If $p^W$ were
constant, $p^\Phi=\delta p^W/(\iota+\delta)<p^W$, hence

$$q=1-\phi^I p^W\frac{\iota}{\iota+\delta}<1 .$$

Capital defers waste, and deferral is worth $\iota/(\iota+\delta)$ per tonne. This holds for any
positive $p^W$ path by the same comparison. So $q<1$ and $\tau^K<0$ unambiguously **whenever
$p^W>0$** — and flips with $p^W$, consistently.

### 3.4 Ledger consistency in steady state

Set $\dot\Phi=0$ in (L$'$): $N=W(1-a\varpi)$. As $a\varpi\to1$, $N\to0$: full circularity with zero
virgin extraction. The model has the right limit.

---

## 4. The decentralized economy

Tastes and technologies unchanged. Three decision units, one price $P^W$.

### 4.1 Instruments

The needed set collapses from nine to **four**, plus $s^W$ which is not free (it is pinned by the
tender's zero-profit condition):

| Instrument | Base | Note |
|---|---|---|
| $\tau^N$ | $N$ | per-tonne extraction tax |
| $s^R$ | $aW^R$ | recycling subsidy (may be negative) |
| $\tau^W$ | $(1-\varpi)W$ | untreated-deposit tax |
| $\tau^K$ | $I+\delta K$ | **gross** capital formation — see §4.4 |
| $s^W$ | $W$ | residual, from zero profit |

Dropped as unnecessary: $\tau^Y$, $\tau^C$, $\tau^D$, $\tau^{W^R}$.

### 4.2 Waste industry

Unchanged from the draft:

$$\Pi^W=\left[P^W\varpi+s^W-c^c-c^T(\varpi)-\tau^W(1-\varpi)\right]W,
\qquad \frac{dc^T}{d\varpi}=P^W+\tau^W,
\tag{M1}$$
$$s^W=c^c+c^T(\varpi)+\tau^W(1-\varpi)-P^W\varpi .
\tag{M2}$$

### 4.3 Household, mine, final goods firm

$$\Pi^H=F\!\left(K-K^R,\,N+a\!\left(\tfrac{K^R}{W^R}\right)W^R,\,P\right)-C^N(N,S)-C^D(D,X)
+s^Ra\!\left(\tfrac{K^R}{W^R}\right)W^R-\tau^NN-P^WW^R$$

$$Q\left(\dot K+\delta K\right)=\Pi^H+T-C,\qquad Q\equiv1+\tau^K .
\tag{M3}$$

Firm's conditions ($\partial/\partial K^R$, $\partial/\partial W^R$):

$$a'\left[F_R+s^R\right]=F_K,
\qquad
a(1-\varepsilon)\left[F_R+s^R\right]=P^W .
\tag{M4, M5}$$

Household, with $\mu^K$ the co-state on $K$ and $\zeta^m\equiv\mu^K/Q$ the marginal utility of a unit
of the final good:

$$u'(C)=\zeta^m,\qquad
F_R-C^N_N-\tau^N=P^S,\qquad
C^D_D+P^X=P^S .
\tag{M6--M8}$$

$$\frac{\dot\mu^K}{\mu^K}=\rho-r^m,\qquad r^m\equiv\frac{F_K}{Q}-\delta,
\qquad
\frac{\dot\zeta^m}{\zeta^m}=\rho-\iota^m,\qquad \iota^m\equiv r^m+\frac{\dot Q}{Q}.
\tag{M9}$$

$$\dot P^S=\iota^m P^S+C^N_S,\qquad \dot P^X=\iota^m P^X-C^D_X .
\tag{M10}$$

Structurally identical to (P8)–(P11) with $Q$ for $q$. The household treats $P$ parametrically, so
there is no private analogue of (P12), and no private analogue of $p^W$ or $p^\Phi$.

### 4.4 Why $\tau^K$ must sit on gross formation

The ledger charges *gross* investment $\phi^I(I+\delta K)$, and $\dot\Phi$ does too. Levying
$\tau^K$ on net $I$ only (as `tab:ad:instruments` and `Part1_theory_decentral.tex:82` do) leaves
replacement investment mispriced, which is exactly the $\delta(q-1)$ discrepancy that shows up
between the draft's $r=F_K\Lambda-\delta$ and the correct (P8). With $\tau^K$ on $I+\delta K$,
capital is priced at $Q$ uniformly, user cost is $(r^m+\delta)Q$, and (M9) matches (P8) term for
term.

**Government budget check.** With
$T=\tau^NN+\tau^K(I+\delta K)+\tau^W(1-\varpi)W-s^WW-s^RaW^R$, substituting $T$ and $\Pi^H$ into
(M3), applying (M2) and $W^R=\varpi W$, every instrument cancels and (M3) collapses to

$$\dot K=Y-C-\delta K-C^N-C^D-\left[c^c+c^T(\varpi)\right]W ,$$

the economy's resource constraint. Verified explicitly, including the $\tau^K$ terms.

### 4.5 Equilibrium

Given initial stocks and policy paths, a competitive equilibrium is
$\{C,K^R,N,D,W,W^R,\varpi\}$, $\Omega\ge0$, $P^W\ge0$, $s^W$, and $\{P^S,P^X,\mu^K\}$ such that
(M1)–(M2) hold; (M4)–(M10) hold; $W^R=\varpi W$ with $P^W\ge0$ and (M5) holding with equality when
$P^WW^R>0$; **$W$ is given by the ledger (L$'$) and $\Omega$ by (MB)**; and the stocks evolve as
stated.

The closure of $\Omega$ is now *the same* in the planner and market problems, which is as it should
be — it is physics, not an institution.

**Counting.** Nine equations in the nine unknowns
$\{C,K^R,N,D,W,W^R,\varpi,P^W,s^W\}$, with $\Omega$ read off (MB) afterwards, $P^S,P^X,\mu^K$ from
their forward relations, and $\mu^K(0)$ pinned by transversality. $\Phi$ is predetermined and enters
only (L). $\Omega$ is no longer needed to make the system square — the ledger does that — so it is
a pure reporting object unless $\omega^{N,S}$ or $\omega^{D,S}$ is nonzero (§1.3).

---

## 5. Implementing the first best

**Proposition.** Set

$$\boxed{\;\tau^N=p^W,\qquad
s^R=d^Wp^P-p^W,\qquad
\tau^W=p^P\left(1-d^W\right),\qquad
\tau^K=-\phi^I\left(p^W-p^\Phi\right)\;}$$

with $\tau^Y=\tau^C=\tau^D=\tau^{W^R}=0$ and $s^W$ from (M2). Then the competitive equilibrium
coincides with the first best.

**Argument**, term by term:

1. *Extraction.* (M7) vs (P3): $\tau^N=p^W$ immediately, given $P^S=p^S$ from step 4.
2. *Exploration.* (M8) vs (P4): $\tau^D=0$.
3. *Recycling capital.* (M4) vs (P5): need $F_R+s^R=B=F_R-p^W+d^Wp^P$, i.e. $s^R=d^Wp^P-p^W$. Note
   this requires $\tau^Y=0$, since $\tau^Y$ would scale both sides of (M4) unequally against (P5)
   and (M7) simultaneously.
4. *Treatment and waste input.* (M5) gives $P^W=a(1-\varepsilon)\left[F_R+s^R\right]
   =a(1-\varepsilon)B$. Substituting into (M1), $c^{T\prime}=a(1-\varepsilon)B+\tau^W$, which is
   (P6) iff $\tau^W=p^P(1-d^W)$. Reading: **the deposit tax is exactly the extra pollution caused
   by depositing a tonne untreated rather than treated.** Note also $P^W=a(1-\varepsilon)B>0$ by
   (X1), so the price of treated waste is automatically positive in the circular stage — the draft's
   $P^W=a(1-\varepsilon)X-\tau^{W^R}$ had no such guarantee.
5. *Saving.* With $\tau^Y=0$ and $Q=q$: $r^m=r$, $\iota^m=\iota$, $\mu^K\equiv\lambda^K$ given
   matched transversality and initial stocks, hence $\zeta^m=\zeta$ and $P^S=p^S$, $P^X=p^X$ from
   (M10) vs (P10)–(P11). Then (M6) is (P1) with $\tau^C=0$.
6. *Budget consistency.* Verified in §4.4.

**Instrument non-uniqueness.** Only $\tau^W-\tau^{W^R}=p^P(1-d^W)$ is pinned, not the two
separately. Setting $\tau^{W^R}=0$ is the normalization that makes $\tau^W$ readable as a pure
pollution tax; the draft's $\tau^{W^R}=s^R$ is an equally valid but less interpretable choice. Worth
stating as a normalization rather than a result.

**Reading of the instrument set.** The whole menu is now interpretable in one sentence each:

- $\tau^N=p^W$ and $s^R=d^Wp^P-p^W$ are the *same* instrument — a tax $p^W$ on every tonne of
  material entering production, $R=N+R^R$, with recycling credited $d^Wp^P$ for the pollution it
  avoids.
- $\tau^W=p^P(1-d^W)$ is the pollution tax on the deposit margin.
- $\tau^K=-\phi^I(p^W-p^\Phi)<0$ is a **subsidy to capital formation**, equal to the value of
  deferring waste by embodying it in a stock that decays at $\delta$ rather than releasing it now.
  This is the opposite sign to the draft's $\tau^K=\phi^I(p^M+p^\Phi)$ and is, I think, the most
  interesting single result to come out of the correction.
- $s^W$ is not Pigouvian at all; it is the transfer that makes the tender break even.

A Pigouvian pollution tax alone is still not sufficient — but the reason is now sharper than the
draft's: it is not that materials are scarce, it is that *capital is a materials sink whose social
value no market prices*.

---

## 6. Discrete-time quantitative system

### 6.1 States and ledger

$$K_{t+1}=(1-\delta)K_t+G_t,\quad G_t\equiv I_t+\delta K_t=Y_t-C_t-C^N_t-C^D_t-\left[c^c_t+c^T_t\right]W_t,$$
$$\Phi_{t+1}=(1-\delta)\Phi_t+\phi^I_tG_t,\qquad S_{t+1}=S_t+D_t-N_t,\qquad X_{t+1}=X_t+D_t,$$
$$P_{t+1}=\left[1-\theta(P_t)\right]P_t+W_t\left(1-\varpi_t+d^W\varpi_t\right)-d^WR^R_t .$$

$$\boxed{\;W_t=\frac{N_t-\left(\Phi_{t+1}-\Phi_t\right)}{1-a_t\varpi_t}\;}
\tag{Q1}$$

### 6.2 The goods rate of interest

A unit of goods at $t$ buys $1/q_t$ units of capital, which yields $F_{K,t+1}$ and leaves
$(1-\delta)$ units worth $q_{t+1}$:

$$\boxed{1+\iota_{t+1}=\frac{F_{K,t+1}+(1-\delta)q_{t+1}}{q_t}}
\qquad\text{(market: }F_K\to\Lambda^m_{t+1}F_{K,t+1},\ q\to Q\text{)}
\tag{Q2}$$

This replaces `eq:aq:r`. The draft's numerator $1-\delta+\Lambda^mF_K+\tau^K_{t+1}$ differs from
$\Lambda^mF_K+(1-\delta)Q_{t+1}$ by $\delta\tau^K_{t+1}$ — the same "depreciation valued at 1"
error as in continuous time.

$$\boxed{C_t^{-\sigma}=\beta\left(1+\iota_{t+1}\right)C_{t+1}^{-\sigma}}
\tag{Q3}$$

### 6.3 Shadow prices (backward recursions)

Timing: $p^P_t$ and $p^\Phi_t$ are present values at $t$ of a unit of $P_{t+1}$ and $\Phi_{t+1}$
respectively.

$$p^S_t=\frac{p^S_{t+1}-C^N_{S,t+1}}{1+\iota_{t+1}},\qquad
p^X_t=\frac{p^X_{t+1}+C^D_{X,t+1}}{1+\iota_{t+1}},
\tag{Q4}$$
$$p^P_t=\frac{MSC^P_{t+1}+\left(1-\hat\theta_{t+1}\right)p^P_{t+1}}{1+\iota_{t+1}},\qquad
MSC^P_t=\frac{\psi_tP_t^{\phi}}{\zeta_t}+\gamma\frac{Y_t}{P_t},\quad \zeta_t=C_t^{-\sigma},
\tag{Q5}$$
$$\boxed{p^\Phi_t=\frac{\delta\,p^W_{t+1}+(1-\delta)p^\Phi_{t+1}}{1+\iota_{t+1}}\ \ge 0},
\qquad
q_t=1-\phi^I_t\left(p^W_t-p^\Phi_t\right).
\tag{Q6}$$

Note $\zeta_t=C_t^{-\sigma}$ with no $\left[1+\Omega\omega^C MSC^W\right]$ divisor, and
$\Lambda_t\equiv1$ throughout.

### 6.4 Static block

$$\xi_t\equiv p^S_t+C^N_{N,t}+p^W_t
\quad\text{(market: }P^S_t+C^N_{N,t}+\tau^N_t\text{)},$$
$$R_t-\bar R=\left[\frac{(1-\alpha)A_t\left(K^Y_t\right)^{\alpha}}{\xi_t}\right]^{1/\alpha},
\qquad Y_t=A_t\left(K^Y_t\right)^{\alpha}\left(R_t-\bar R\right)^{1-\alpha},
\qquad N_t=R_t-a_tW^R_t .
\tag{Q7}$$

$$X_t=\left[\frac{\left(1+\varepsilon^X\right)\left(p^S_t-p^X_t\right)}{c^D_t}\right]^{1/\left(1+\varepsilon^X\right)}
\quad\text{if } p^S_t>p^X_t,\qquad D_{t-1}=X_t-X_{t-1}.
\tag{Q8}$$

**Recycling block, closed form.** With $B_t=p^S_t+C^N_{N,t}+d^Wp^P_t$ from (X1), and
$\nu_t\equiv c^{T\prime}_t(\varpi_t)-p^P_t(1-d^W)$ the planner's shadow price of a unit of *treated*
waste (market: $\nu_t=P^W_t$), conditions (P5)–(P6) give ratio $x_t^2$ exactly as in the draft:

$$\boxed{x_t=\sqrt{\frac{\nu_t}{F_{K,t}}},\qquad \sqrt{F_{K,t}}+\sqrt{\nu_t}=\sqrt{a^m_tB_t}}
\tag{Q9}$$

The closed form survives the correction intact. Treatment share, from
$c^{T\prime}_t=\nu_t+p^P_t(1-d^W)$ (market: $P^W_t+\tau^W_t$):

$$\varpi_t=\min\left\{1,\ \left[\frac{\left(\nu_t+p^P_t(1-d^W)\right)\left(1+g^T\right)^t}{\bar c^T}\right]^{1/\varepsilon^T}\right\}.
\tag{Q10}$$

And $p^W_t$ from (X2):

$$p^W_t=c^c_t+c^T_t(\varpi_t)+p^P_t\left(1-\varpi_t+d^W\varpi_t\right)-\varpi_t a_t(1-\varepsilon_t)B_t .
\tag{Q11}$$

### 6.5 Residual unknowns

Planner: $\{C_t,\ x_t,\ W_t,\ \varpi_t,\ p^W_t,\ p^S_t,\ p^X_t,\ p^P_t,\ p^\Phi_t\}$, of which
$C_t,p^S_t,p^X_t,p^P_t,p^\Phi_t$ are forward-looking. Market under exogenous policy:
$\{C_t,\ x_t,\ W_t,\ \varpi_t,\ P^W_t,\ P^S_t,\ P^X_t\}$ — $p^P$ and $p^\Phi$ are not needed, as
`rem:ad:pP` correctly says. $\Omega_t$ and $\phi^K_t$ are computed afterwards for reporting.

### 6.6 Regimes

$$\text{(i) linear: } a^m_t\left[p^S_t+C^N_{N,t}+d^Wp^P_t\right]\le F_{K,t}
\ \Rightarrow\ K^R_t=W^R_t=0,\ P^W_t=0 .$$

Under laissez-faire, $\tau^W=0$ and $P^W=0$ give $\varpi_t=0$: a well-defined date of first
treatment and date of first recycling, as before. Regime (ii) requires $\tau^W_t>0$. The transition
condition no longer involves $p^W$, $\Omega$, or any $\omega^i$ — it is a clean comparison of the
marginal product of recycling capital against the marginal product of production capital.

### 6.7 Welfare

The Euler (Q3) implies the goods discount factor $\Delta_t=\prod_{i=1}^t(1+\iota_i)^{-1}$ with
$\iota$ from (Q2). Iterating,

$$w_t=\frac{C_t}{C_0}=\left[\beta^t\prod_{i=1}^t\left(1+\iota_i\right)\right]^{1/\sigma}
\quad(\tau^C\equiv0).
\tag{Q12}$$

So the draft's substitution rule was structurally right — replace $\prod(1+r_i)^{-1}$ throughout —
but with the wrong $\iota$: it used $(1+r_i+\tau^K_i)/(1+\tau^K_{i-1})$ instead of
$\left[\Lambda^m_iF_{K,i}+(1-\delta)Q_i\right]/Q_{i-1}$.

I also re-derived the lifetime budget constraint, which the draft flags as unverified
(`Part1_quant.tex:497`). Discounting (M3) and telescoping the capital terms using (Q2):

$$\sum_{t\ge0}\Delta_t C_t=H_0+A_0,\qquad
H_0\equiv\sum_{t\ge0}\Delta_t\left[\Pi^H_t+T_t-\Lambda^m_tF_{K,t}K_t\right],\qquad
A_0\equiv\left[\Lambda^m_0F_{K,0}+(1-\delta)Q_0\right]K_0 .
\tag{Q13}$$

$A_0$ is the value at $t=0$ of the predetermined capital stock: current marginal product plus resale
value. **This resolves the $\tau^K_{-1}$ boundary problem the draft flags** — no lagged instrument
appears. $H_0$'s flow term is unchanged (the draft's $Y_t-(r_t+\delta)K_t-\cdots$ is correct, since
$r_t+\delta=\Lambda^m_tF_{K,t}$); only the discount factor and the initial-wealth term change.

---

## 7. What survives unchanged

Worth recording, since most of the drafts is fine:

- All functional forms in `subsec:aq:functional-forms`, and every derivative in
  `eq:aq:F-derivatives`–`eq:aq:theta-hat`. I checked each by differentiation.
- The recycling algebra `eq:aq:recycling-algebra` ($\varepsilon_t=1/(1+x_t)$, $a'_t=a^m_t/(1+x_t)^2$,
  $a_t(1-\varepsilon_t)=a^m_tx_t^2/(1+x_t)^2$, $a'_t(0)=a^m_t$) — all correct, and the closed-form
  collapse (Q9) survives.
- The closed forms for $R_t-\bar R$ and $X_t$, and the inversion of $c^T$ for $\varpi_t$.
- The waste industry's problem, its FOC, and the zero-profit condition.
- The three-regime structure and its ordering argument.
- `rem:ad:argument` (two arguments of $a(\cdot)$), `rem:ad:pP` (which prices the market model needs),
  `rem:aq:linear-costs` (bang-bang exploration), `rem:aq:scaling` (conditioning) — all still stand.
- `rem:ac:depreciation` still stands and is arguably strengthened: depreciated capital enters $W$ on
  the same footing as any other waste, now visibly through $\dot\Phi$.

---

## 8. Discrepancy table

| # | Location | Issue | Correction |
|---|---|---|---|
| 1 | `eq:ac:consistency`, `subsec:ac:balances` | Called a restriction on primitives holding along any feasible path; it is not, unless $\phi^Y$ is endogenous | Both $\Omega$ and $\phi^Y$ endogenous; (MB) defines $\Omega$, (CONS) defines $\phi^Y$ |
| 2 | `prob:ac:planner` | Planner faces two materials constraints with multipliers $p^W,p^M$ | One ledger constraint, one multiplier $p^W$. $p^M\equiv0$ |
| 3 | `eq:ac:Lambda` and everywhere | $\Lambda=1-\Omega\omega^Y MSC^W$ | $\Lambda\equiv1$. Delete $\Lambda$, $MSC^W$, $\chi$ |
| 4 | `eq:ac:foc-saving` | $u'(C)/(1+\Omega\omega^C MSC^W)=\zeta$ | $u'(C)=\zeta$ (P1) |
| 5 | `eq:ac:zeta`, `eq:ac:foc-investment` | $q=1+\phi^I(p^M+p^\Phi)$; sign of $\lambda^\Phi$ term wrong even on its own terms | $q=1-\phi^I(p^W-p^\Phi)<1$ (P2) |
| 6 | `eq:ac:foc-extraction` | $+p^M$ and the $C^N_N$ markup | $F_R-C^N_N-p^W=p^S$ (P3) |
| 7 | `eq:ac:foc-exploration` | $C^D_D$ markup | $C^D_D+p^X=p^S$ (P4) |
| 8 | `eq:ac:foc-recycling`, `eq:ac:foc-treatment`, `eq:ac:foc-waste-use` | $\Lambda$, $p^M$, $\Omega\omega^W$ markups | (P5)–(P7); $B$ reduces to $p^S+C^N_N+d^Wp^P$ by (X1) |
| 9 | `eq:ac:r`, `eq:ac:lambdaK` | $r=F_K\Lambda-\delta$; $K$-costate omits the $\delta K$ terms in the ledger and in $\dot\Phi$ | $r=F_K/q-\delta$; depreciation valued at $q$ (P8) |
| 10 | `eq:ac:pS`, `eq:ac:pX`, `eq:ac:pP`, `eq:ac:pPhi` | All discount at $r$ | All discount at $\iota=r+\dot q/q$ (P9)–(P13) |
| 11 | `eq:ac:pPhi` | $p^\Phi\le0$, inconsistent with the prose in `Part1_theory_decentral.tex:252` | Redefine $p^\Phi\equiv-\lambda^\Phi/\zeta\ge0$, matching $p^P$ and $p^X$ |
| 12 | `eq:ac:normalizations` | $p^W>0$ asserted | Sign is an outcome; see (X2) and §3.2 |
| 13 | `eq:ac:keynes-ramsey` | $\phi\,g^{MSC}$ term | $\dot C/C=(\iota-\rho)/\sigma$ (P15) |
| 14 | `subsec:ac:system` | Transversality stated on $K$ only | Five conditions (P14) |
| 15 | `tab:ad:instruments`, `Part1_theory_decentral.tex:82` | $\tau^K$ on net $I$; replacement exempt | $\tau^K$ on gross $I+\delta K$ (§4.4) |
| 16 | `tab:ad:instruments` | Nine instruments | Four: $\tau^N$, $s^R$, $\tau^W$, $\tau^K$ (+ residual $s^W$) |
| 17 | `prop:ad:implementation` | $\tau^K=\phi^I(p^M+p^\Phi)>0$ | $\tau^K=-\phi^I(p^W-p^\Phi)<0$ — a **subsidy** |
| 18 | `eq:ad:implement-waste` | $\tau^W$ with $\chi$ markup; $\tau^{W^R}=s^R$ presented as a result | $\tau^W=p^P(1-d^W)$ under the normalization $\tau^{W^R}=0$; non-uniqueness is a normalization |
| 19 | `subsec:ad:equilibrium` | $\Omega$ endogenous presented as needed to make the market system square | The ledger does that; $\Omega$ is pure reporting unless $\omega^{N,S},\omega^{D,S}>0$ (§1.3) |
| 20 | `eq:aq:r`, `eq:aq:euler` | Depreciation valued at 1 | (Q2)–(Q3) |
| 21 | `eq:aq:pP` | $\zeta_t=C_t^{-\sigma}/(1+\Omega\omega^C MSC^W)$; discounts at $r^{\text{soc}}$ | $\zeta_t=C_t^{-\sigma}$; discounts at $\iota$ (Q5) |
| 22 | `eq:aq:pM`, `eq:aq:pW` | Two nonlinear equations for $(p^W,p^M)$ | One explicit equation (Q11); no simultaneity |
| 23 | `eq:aq:pPhi-discrete` | Sign and timing | (Q6) |
| 24 | `eq:aq:waste` | $W_t=N_t+R^R_t-\phi^I_tI_t+\delta K_t[\phi^K_t-\phi^I_t]$ | Algebraically fine; restate as (Q1), which is explicit in $W_t$ |
| 25 | `eq:aq:H0`–`eq:aq:weights` | Discount factor; undefined $\tau^K_{-1}$ | (Q12)–(Q13); boundary resolved |
| 26 | `rem:aq:scope` | Cost of the $\omega^{N,S},\omega^{D,S}$ split stated as loss of closed form | Also makes $\Omega$ allocation-relevant (§1.3) |
| 27 | `subsec:aq:scenarios` (c) | "Partial regulation" sets $\tau^W=s^R=\tau^{W^R}=0$ | $\tau^{W^R}$ no longer exists; redefine the experiment over $\{\tau^W,s^R\}$ |
| 28 | `var:aq:constant-phi` | $\tau^K_t=\bar\phi^Kp^M_t$ | $\tau^K_t=-\bar\phi^K(p^W_t-p^\Phi_t)$; $\Phi$ still drops as an independent state |

---

## 9. Not verified / open

1. **$p^W<0$ regime.** (X2) admits it, and it implies a negative $\tau^N$. I believe this is a real
   feature — extraction stocks the recycling loop and no private agent internalizes that — but it
   should be checked numerically before it goes in the paper, and the complementarity solver needs
   to tolerate it.
2. **Instantaneous recirculation.** (L$'$) has material passing through production
   $1/(1-a\varpi)$ times *within a period*. In continuous time this is innocuous; in discrete time
   it is a modelling choice that should be stated. An alternative is a one-period lag on recycled
   input, which would change (Q1) and (Q7).
3. **$\Phi$ under two capital pools.** (P13) rests on $K^Y$ and $K^R$ sharing $\phi^K_t$. Relaxing
   that needs two embodied-material stocks, as `rem:ac:Phi-derivation` says. Unchanged by this
   review.
4. **$H_0$ under distorted policy.** (Q13) is derived; but I have not re-checked that $\Pi^H_t+T_t
   -\Lambda^m_tF_{K,t}K_t$ reduces to the intended "pure profits including resource rents" under
   *arbitrary* (non-optimal) policy, which is what scenarios (b) and (c) need.
5. **Second-order conditions / uniqueness.** Not checked. The implementation proposition invokes
   uniqueness of the optimal allocation; with the complementarity structure of (P5) that deserves an
   argument rather than an assertion.
6. **$\varpi\le1$.** Still binding as a genuine restriction (`rem:ac:varpi`), unchanged.
