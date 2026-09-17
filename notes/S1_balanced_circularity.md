# S1/S2 — Balanced asymptotic circularity: feasibility and optimality

Working note, 2026-08-18 (consolidated; supersedes the earlier S1 note and its verification
companion). Case S1/S2 of [longrun_sustained_consumption.md](longrun_sustained_consumption.md).
Equation labels refer to `writing/docs/`. The load-bearing algebra (the waste-margin identity
including the $p^P$ cancellation, the tail formulas for $(1-\alpha)/a'$, the $p^M/p^W$
forward-integral ratio) has been checked symbolically; the asymptotic analysis has been carried
with all of $p^W$, $\zeta$, $p^P$, $\Omega$ in full.

Flags: **[docs]** in docs · **[v]** verified here · **[open]** open.

---

## 0. The configuration

The merged balanced path (the original S1 and S2 are not separate cases — see §2.6):

$$N\to 0,\qquad D\to 0,\qquad S\to 0\ \text{(exact exhaustion)},\qquad
X\to\bar X_{\max}\ \text{with}\ C^D_D(0,X)\to\infty,$$

all asymptotic, none reached; $C_t\to\infty$ (there is no bounded-consumption version, §1.3);
$R_t\ge\underline R>0$, with essentiality of $R$ in $F$ assumed (S7 handles the alternative).

Tail notation: $N\sim\bar Ne^{-gt}$, $S\sim N/g$; recycling tail $1-a(x)\sim\gamma_ax^{-\psi}$
(exponential tail $=$ the limit $\psi\to\infty$); extraction cost $C^N_N(0,S)\sim\kappa S^{-\chi}$;
treatment cost $c^{T\prime}(\varpi)$ finite or $\sim(1-\varpi)^{-\nu}$ at $\varpi=1$; wedges
$w_j\equiv 1\pm\zeta\Omega^j$; $A_\infty\equiv\lim_{K\to\infty}F_K(K,\bar R,0)$;
$e_R\equiv\lim(d\ln F_R/dt)/\gamma\in(0,1]$ (CES: $e_R=1/s$).

---

## 1. Feasibility

### 1.1 Rate lock and unbounded recycling capital **[v]**

The ledger `eq:sp:ledger` with vanishing virgin inflow forces the circularity gap to close at the
rate extraction dies:

$$1-a(x_t)\varpi_t\;\sim\;\frac{\left(1+\Omega^{N,S}\right)N_t}{\bar W},$$

with $W\to\bar W>0$ required to keep $R$ bounded away from zero. Since $a<1$ and $\varpi\le 1$
separately, both $\varpi\to 1$ and $a\to 1$, hence $x\to\infty$ and $K^R=x\varpi W\to\infty$:
**there is no balanced circular path with bounded recycling capital.** Implied growth of $K^R$:
linear in $t$ for the exponential tail, exponential at rate $g/\psi$ for the power tail.

### 1.2 Only dematerializing capital admits the path **[v]**

The growing capital stock must not absorb material on net, since the ledger caps net absorption by
$(1+\Omega^{N,S})N\to 0$. This holds only under the baseline $\Phi^I=\Omega\phi^I$ *with*
$\delta>0$: depreciation releases embodied material while $\Omega\to 0$ dilutes the intensity of
new capital, so $M^K\to\sigma\bar R/\delta$ stays bounded and $\dot M^K\to 0$ even as $K\to\infty$.

- With $\delta=0$ there is no release channel; net absorption equals gross storage
  $\Phi^IG\approx$ order $G$, so $G\lesssim N$ and $\int G\,dt<\infty$: $K^R$ bounded —
  infeasible. (Exception: $\phi^I=0$, immaterial capital.)
- With constant or exogenous $\Phi^I$ (the appendix variants), $M^K\to\bar\Phi K$ and
  $\dot M^K\to\bar\Phi\dot K>0$ permanently — ledger violated for any $\delta$. **The circular
  limit does not exist under the appendix $\Phi^I$ treatments.**

(Mild residual rate condition on the transition: $\dot M^K\le(1+\Omega^{N,S})N_t$ at every date.
**[open]**)

### 1.3 Growth is mandatory: $A_\infty-\delta>\rho$ **[v]**

Maintenance $\delta K^R\to\infty$ requires unbounded output, and holding unbounded capital must
be worth the discount: with $q\to 1$, the return is $A_\infty-\delta$, and the Euler equation
gives asymptotic growth $\gamma=(A_\infty-\delta-\rho)/\eta$. So the path exists iff

$$\boxed{\;A_\infty-\delta>\rho\;}$$

and it is an **asymptotically-AK growth path**: $C,K,Y,G\sim e^{\gamma t}$, $r\to A_\infty-\delta$,
$\Omega\sim e^{-\gamma t}\to 0$, $\sigma\to\bar\sigma\in(0,1)$. Growth is generically
*exponential*; sub-exponential growth survives only on the knife-edge $A_\infty-\delta=\rho$
(where a hyperbolic extraction-decline variant exists — measure zero, set aside). The growth is
dematerialized: $R$, $W$ bounded while $Y/R\to\infty$. A second, independent reason growth is
necessary: the wedges $\zeta\Omega^j$ survive the diverging $\zeta$ only because $\Omega\to 0$
(§2.2); in a bounded economy $1+\zeta\Omega^C$ turns negative and the consumption FOC fails.

**Headline: under standard neoclassical assumptions — $F_K\to 0$, or $A_\infty-\delta<\rho$, or
fixed material intensity of investment — the balanced circular path does not exist.**

Structural tension to resolve in the docs: $A_\infty>0$ at fixed $\bar R$ is a strong
capital-for-materials substitution statement, close to inessentiality of $R$; families
$F=A(R)K+\text{lower order}$ with $A(0)=0$ reconcile the two. **[open]**

### 1.4 Remaining feasibility conditions **[v]**

- **Treatment:** $c^T(1)<\infty$ — full treatment must have finite total cost.
- **Pollution:** no feasibility condition — $\Xi\to 0$ and $P\to 0$ come free with circularity
  (given $\theta(P)P>0$ for $P>0$).
- **Extraction cost flow:** affordable automatically at the matched tail of §2.4.

---

## 2. Optimality: the balanced-path price system

### 2.1 The identity backbone **[v]**

At $\varpi=1$ the waste margin `eq:sp:sum:W` collapses ($p^P$ cancels exactly) to
$V=[\Psi-c^Ww_W]/(1-\alpha)$; combined with the interior capital margin $a'(x)V=F_Kw_Y$ and
$(1-\alpha)/a'\approx c_ax$ ($c_a=1$ exp, $(1{+}\psi)/\psi$ power):

$$\Psi-c^Ww_W\;=\;c_a\,x_t\,F_K\,w_Y\;\longrightarrow\;\infty\ \text{like }x_t,
\qquad
p^W\;\sim\;-\frac{\Psi}{1-\alpha}\;\longrightarrow\;-\infty\ \text{at rate }
\hat g=g\,\frac{\psi+1}{\psi}.$$

**The waste price is the carrier of the divergence**: $-p^W$ equals the marginal circularity
multiplier $1/(1-\alpha)$ times the per-pass surplus of a tonne of waste. In deep circularity
waste is the economy's asset — the mine above ground.

### 2.2 Wedges survive through dematerialization **[v]**

$\zeta=\sigma(p^W-p^M)$ diverges with $p^W$ (the forward ratio is
$p^M/p^W\to\delta/(r+\delta-\hat g)$), but every wedge
$\zeta\Omega^j\sim e^{(\hat g-\gamma)t}$ stays bounded because $\gamma\ge\hat g$, with all
$w_j\to 1$ when strict ($e_R<1$) and convergence to nonunit constants at $e_R=1$ (regularity:
$1-\kappa_\zeta\omega^Y>0$). $q\to 1$, $u'/\lambda\to 1$.

### 2.3 The rates are pinned **[v]**

$\Psi=F_Rw_Y+\zeta$ must grow only like $x_t$, so the leading exponentials of $F_R$
($\sim e^{e_R\gamma t}$) and $\zeta$ ($\sim -Ze^{\hat gt}$) must cancel: $e_R\gamma=\hat g$, hence

$$\gamma=\frac{A_\infty-\delta-\rho}{\eta},
\qquad
\hat g=e_R\gamma,
\qquad
g=\frac{e_R\,\gamma\,\psi}{\psi+1}\ \ (\text{CES, exp tail: }g=\gamma/s),
\qquad
r\to A_\infty-\delta .$$

**The extraction decline rate is an equilibrium outcome pinned by technology and preferences, not
a choice.** All material prices — $-p^W$, $-\zeta$, $p^S$, $C^N_N$ — diverge together at rate
$\hat g$ (regularity: $r>\hat g$, i.e. $\rho+\eta\gamma>e_R\gamma$; automatic for $\eta\ge 1$).

### 2.4 Matching condition on the extraction-cost tail **[v]**

The interior extraction FOC `eq:sp:sum:N` requires the scarcity block $C^N_Nw_N+p^S$ (the two move
together: $|C^N_S|\approx|C^N_{NS}|N$, same order; $p^S$ finite iff $r>\chi g$) to cancel
$p^W(1+\Omega^{N,S})$, giving $\chi g=\hat g$:

$$\boxed{\;\chi=\frac{\psi+1}{\psi}\;}\qquad(\text{exp tail: }\chi=1).$$

The extraction-cost tail as $S\to 0$ must be tied to the recycling tail as $x\to\infty$.
Mismatches exit the case: for $\chi<(\psi{+}1)/\psi$ virgin costs cannot offset the waste-price
credit to extraction — the marginal virgin tonne stays strictly profitable, extraction expands,
depletion accelerates (toward finite-time exhaustion, S6/S4 territory); for $\chi>(\psi{+}1)/\psi$
scarcity outruns $p^W$ and forces the extraction corner in finite time. (Hyperbolic profiles
patch $\chi>(\psi{+}1)/\psi$ only on the $\gamma=0$ knife-edge. Slowly-varying corrections around
the exponential ansatz were not explored. **[open]**)

### 2.5 The treatment margin **[v]**

With $\alpha\to 1$ and $V\to\infty$: if $c^{T\prime}(1)<\infty$, the corner $\varpi=1$ is reached
in **finite time**; if $c^{T\prime}\sim(1-\varpi)^{-\nu}$, the interior branch gives
$1-\varpi\sim N^{1/\nu}$-type decay, compatible with the rate lock for $\nu<1$ — and $\nu<1$ is
already required by $c^T(1)<\infty$. Binding condition: none beyond feasibility.

### 2.6 The exploration margin: S1 and S2 merge **[v]**

$p^S\sim e^{\hat gt}\to\infty$ while $p^X$ stays bounded, and the $p^W\Omega^{D,S}$ term becomes
a credit once $p^W<0$: a $D=0$ corner sustained against finite marginal discovery cost
$C^D_D(0,\bar X)<\infty$ violates `eq:sp:sum:D-corner` in finite time. **Exploration cannot end
at a finite date: the discovery margin must hold with equality asymptotically.** The balanced path
therefore has $D\to 0$ never reached, $X\to\bar X_{\max}$ where $C^D_D(0,X)\to\infty$, the
blow-up rate-matched to $p^S$ in parallel to §2.4 ($\chi_D$-condition, details **[open]**). This
dissolves the S1-vs-S2 distinction of the collection note: neither "exploration ends" nor
"reserves maintained" survives; discovery opportunities are exhaustible and asymptotically
exhausted alongside the reserves themselves.

### 2.7 Pollution damages must be tame at zero **[v]**

$p^P$ cancels from the §2.1 identities but survives inside $p^W$ and hence the extraction FOC. On
the growth path $\lambda\approx u'(C)\to 0$, so $v'(0)>0$ would make damages in goods units
diverge at rate $\eta\gamma>\hat g$ ($\eta\ge1$), flipping $p^W$ to $+\infty$ and forcing the
extraction corner. Required:

$$v'(0)=0,\qquad \eta\gamma-\min\left(g,\theta(0)\right)\le\hat g,\qquad
|F_P|\ \text{growing slower than } e^{\hat gt}.$$

The docs assume only $v'>0$; an explicit $v'(0)=0$ is needed.

---

## 3. Summary of conditions

| # | Condition | Type |
|---|---|---|
| C1 | $A_\infty-\delta>\rho$: endogenous-growth economy, $\gamma=(A_\infty-\delta-\rho)/\eta>0$ | feasibility + optimality |
| C1′ | $\Phi^I=\Omega\phi^I$ with $\delta>0$ (dematerializing capital); appendix $\Phi^I$ variants infeasible | feasibility |
| C2 | $c^T(1)<\infty$ | feasibility |
| C4 | $\chi=(\psi+1)/\psi$: extraction-cost tail matched to recycling tail | optimality |
| C6 | $C^D_D(0,X)\to\infty$ at $\bar X_{\max}<\infty$, rate-matched to $p^S$ | optimality |
| C7 | $v'(0)=0$ with rate condition; $F_P$ tame | optimality |

If **all** hold: the balanced path exists with the pinned rate structure of §2.3, sustained
(indeed growing) consumption, $P\to 0$, and all four decays ($N$, $D$, $1-a\varpi$, $\Xi$)
rate-locked. If **any** fails, the circular limit does not exist and the economy lands in another
case of the collection — generically S5 (stationary extraction–exploration) or Collection II
(unsustained consumption).

## 4. Open items

1. BGP existence/uniqueness at the level of constants (rate structure is consistent and the
   constant count plausible; confirm via fixed-point argument or the Part 3 computation).
2. The $\chi_D$-matching for the discovery margin, in detail.
3. Slowly-varying profiles off the $\chi$-matching.
4. Transition rate condition $\dot M^K\le(1+\Omega^{N,S})N$.
5. Sharpen C7 once $v$, $\theta$, $F_P$ have functional forms.
6. Docs assumptions to fix: essentiality/$A_\infty$ family for $F$; $\Phi^I$ treatment as
   substantive; $v'(0)=0$; $S\ge0$ + extraction-cost Inada; discovery-cost blow-up.
