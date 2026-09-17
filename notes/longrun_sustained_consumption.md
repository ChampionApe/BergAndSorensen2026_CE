# Long-run states with sustained consumption

Working note, 2026-08-18, **revised** after the S1 analysis
([S1_balanced_circularity.md](S1_balanced_circularity.md), where the results referenced below are
stated with their conditions). Collection I: candidate long-run configurations of the Part 1
planner's problem with $\liminf_{t\to\infty}C(t)>0$, classified by the limiting behavior of the
resource triple $(N,D,S)$. Configurations where consumption is not sustained belong in a second
collection, to be written.

Status flags: **[docs]** stated/proved in docs · **[S1]** established in the S1 note ·
**[conj]** conjectured, to be verified · **[open]** open.

---

## 0. Requirements common to every case

1. **Materials.** If $R$ is essential in $F$, sustained $Y$ requires $R$ bounded away from zero.
   Essentiality is still not pinned down in the docs (case S7 exploits the gap), and the S1
   analysis raised the stakes: the circular limit also needs $A_\infty\equiv\lim_{K\to\infty}
   F_K(K,\bar R,0)>0$ — output asymptotically linear in capital *at fixed material input* — which
   sits close to inessentiality. Families like $F=A(R)K+\text{lower order}$, $A(0)=0$, deliver
   both. An explicit assumption on $F$ is needed either way. **[open]**

2. **The ledger in the limit.** From `eq:sp:setup:ledger-collected`, keeping $R$ bounded away from
   zero while virgin inflow dies requires $a\varpi\to 1$ at the rate $N$ falls (the *rate lock*).
   Corrected by the S1 analysis: whether $\dot M^K\to 0$ is available depends on the
   materials-accounting specification. With $\delta>0$ and the dematerializing baseline
   $\Phi^I=\Omega\phi^I$, net absorption into capital vanishes even as $K\to\infty$; with
   $\delta=0$, or with constant/exogenous $\Phi^I$, a growing capital stock absorbs material
   forever and the circular limit is *infeasible*. **The choice of $\Phi^I$ treatment decides
   which cases exist.** **[S1]**

3. **Pollution stabilizes.** Any candidate optimum needs $\Xi\to\bar\Xi$ with
   $\theta(\bar P)\bar P=\bar\Xi$ and no tipping. Circular limits deliver $\Xi\to 0$, $P\to 0$ for
   free; stationary-extraction limits carry $\bar P>0$. New from S1: on growing paths the damage
   function must be tame at zero — $v'(0)=0$ — else the pollution price outruns the material
   prices and destroys the circular limit. **[S1]**

4. **Growth vs. bounded consumption.** The case split acquired a sharp new axis. The circular
   limit exists only in an *endogenous-growth* economy, $A_\infty-\delta>\rho$: there is no
   bounded-consumption version of it, since $K^R\to\infty$ must be maintained and held willingly.
   Generically the growth is exponential, $\gamma=(A_\infty-\delta-\rho)/\eta$; sub-exponential
   growth survives only on the knife-edge $A_\infty-\delta=\rho$ (measure zero, set aside). The
   growth is *dematerialized*: the material side ($R$, $W$) stays bounded while output grows, so
   material productivity $Y/R\to\infty$. Under standard neoclassical assumptions
   ($F_K\to 0$, or $A_\infty-\delta<\rho$), the circular limit does not exist and the stationary
   case S5 is the only sustained-consumption candidate. **[S1]**

---

## 1. The classification axes

Each of $(N,D,S)$ can vanish asymptotically, hit zero in finite time, or converge to a positive
level, pruned by $\dot S=D-N$ as before. One pruning rule is now much stronger than the original
draft's:

- **Flows cannot simply "end".** On any deep-circularity path the scarcity price $p^S$ diverges,
  so a corner $D=0$ sustained against *finite* marginal discovery cost eventually violates its own
  corner condition — exploration revives. The behavior of $D$ in the long run is therefore not an
  assumption choice: optimality forces the discovery margin to stay asymptotically active, and
  the coherent circular limit has $D\to 0$ never reached, with cumulative discovery approaching
  a level where marginal discovery cost diverges. **[S1]** The same price logic re-opens the
  extraction margin whenever virgin costs stay bounded (see S3, S4 below).
- $S\to 0$ asymptotically requires exact exhaustion $\int N=S_0+\int D$; stopping short is a
  priori feasible but now ruled out by optimality (S3 below). **[S1]**

---

## 2. The candidate list, revised

| # | Name | Status after S1 analysis |
|---|---|---|
| S1/S2 | Balanced asymptotic circularity (merged) | The intended limit; exists only under the S1 conditions (growth, dematerializing capital, matched cost tails) |
| S2 (standalone) | Reserves maintained while $N\to 0$ | **Ruled out** |
| S3 | Stranded reserves | **Ruled out** |
| S4 | Finite-time extraction shutdown | **Ruled out** as terminal (unchanged, strengthened) |
| S5 | Stationary extraction–exploration | Upgraded: the generic case in a neoclassical economy |
| S6 | Flow-through at zero stock | Excluded under the extraction-cost Inada that S1/S2 needs anyway |
| S7 | Dematerialized consumption | Unchanged; boundary with S1/S2 subtler than before |

### S1/S2 — Balanced asymptotic circularity *(merged; the intended limit)*

The original list separated S1 ($D$ ends at a finite date) from S2 ($D>0$ forever). **Optimality
merges them.** On the balanced path all material prices diverge together (at rate
$\hat g=e_R\gamma$, see the S1 note); in particular
$p^S\to\infty$, so exploration cannot terminate at any date where marginal discovery cost is
finite — the corner inequality fails in finite time. The coherent configuration is:

$$N\to 0,\quad D\to 0,\quad S\to 0 \text{ (exact exhaustion)},\quad
X\to\bar X_{\max}\ \text{with}\ C^D_D(0,X)\to\infty,$$

all asymptotic, none reached: extraction *and* discovery die together, each priced against a
diverging cost, with the discovery-cost blow-up at finite cumulative discovery
($\bar X_{\max}<\infty$) as a required primitive. Both margins hold with equality forever; the
"balanced" in the name now covers four coupled decays ($N$, $D$, $1-a\varpi$, $\Xi$) rate-locked
to one another. Conditions C1–C7 and the pinned rate structure are in the S1 note. **[S1]**

The *standalone* S2 variant — reserves maintained or growing while extraction vanishes — is ruled
out separately: with $N\to 0$ and $S$ bounded away from zero, the reserve's dividend
$|C^N_S|\approx|C^N_{NS}|N\to 0$, so $p^S$ stays bounded while exploration still costs; discovery
without prospective extraction cannot pay. **[conj]** (direction clear, one-line writeup pending)

### S3 — Stranded reserves: ruled out

Killed by the S1 price system. Any deep-circularity path has $p^W\to-\infty$ (the waste price is
the carrier of the divergence, $-p^W\sim$ marginal multiplier × per-pass surplus). The extraction
FOC then requires the scarcity block $C^N_N w_N+p^S$ to diverge in step. With a stranded reserve
$\bar S>0$, $C^N_N(0,\bar S)$ is bounded and $p^S$ bounded (dividend $\propto N\to 0$): the block
cannot keep pace, the FOC fails in the direction of *more* extraction, and the $N=0$ corner
condition fails for the same reason ($\Psi\to+\infty$ against a right-hand side dragged to
$-\infty$ by $p^W$). Extraction is self-reviving against any bounded virgin cost; exhaustion, not
stranding, is what optimality selects. This settles the S1-vs-S3 question from the original list.
**[S1]** (formal statement pending, but it is a direct corollary of the verified price
asymptotics)

### S4 — Finite-time extraction shutdown: ruled out as terminal (unchanged, strengthened)

The ledger argument stands: with $N=D=0$, positive throughput needs $W(1-a\varpi)=-\dot M^K$,
transient since $M^K\ge 0$; permanent shutdown needs $a\varpi=1$ at finite $x$, excluded by
$\lim_{x\to\infty}a=1$. **[conj→easy]** Strengthened by the S3 logic: even a *temporary* corner
is untenable while circularity deepens, since the corner inequality fails against $p^W\to-\infty$.
The one resurrection scenario — a Part 3 functional form with $a(\bar x)=1$ at finite $\bar x$ —
still deserves a check before functional forms are frozen. **[open]**

### S5 — Stationary extraction–exploration: upgraded to the generic neoclassical case

Steady state with $\bar N=\bar D>0$, $\bar S>0$, $\bar a\bar\varpi<1$ strictly, $\bar P>0$.
Adjustments from the S1 analysis:

- **Selection is now clean.** S1/S2 requires *all* of: $A_\infty-\delta>\rho$, discovery cost
  blowing up at finite $\bar X_{\max}$, matched extraction-cost tail $\chi=(\psi{+}1)/\psi$,
  $v'(0)=0$, $\Phi^I=\Omega\phi^I$. If **any** fails, the circular limit does not exist, and S5 is
  the remaining sustained-consumption candidate (or consumption is not sustained → Collection II).
  In particular, in a bounded neoclassical economy S5 is not one option among several — it is the
  *only* interior long-run configuration on the table. **[S1]**
- **S5 is robust where S1/S2 is fragile**: with bounded $K$, all prices bounded, the
  $\Phi^I$ treatment and the $v'(0)$ question are innocuous, and no tail matching is needed. The
  empirically relevant calibration target, as suspected.
- Still to settle: existence/uniqueness of the interior steady state (S5a), the $K^R=0$ sub-case
  (S5b), comparative statics. This is now the natural next case to work through. **[open]**

### S6 — Flow-through at zero stock: excluded alongside S1's conditions

S6 needs $C^N(N,0)$ finite. The S1/S2 matching condition requires $C^N_N(0,S)\to\infty$ as
$S\to 0$ — so wherever the circular limit is on the table, S6 is automatically off it. S6
survives only in specifications with bounded virgin costs at exhaustion, which are exactly the
specifications where the balanced path fails anyway (the $\chi$-too-small exit: extraction
expands, $S$ hits zero in finite time, and the economy continues on just-in-time discovery if
$C^D$ permits — an S5-flavored flow equilibrium, or collapse). Cleanest resolution unchanged:
impose $S\ge 0$ with an Inada condition on $C^N_N$ at $S=0$ and record the choice as substantive.
**[open]** (assumption choice)

### S7 — Dematerialized consumption: unchanged, boundary subtler

Still the "$R\to 0$ with $C$ sustained" configuration, admissible only if $R$ is inessential, and
still best sorted out by an explicit essentiality assumption. New nuance from S1: even the
*materially sustained* balanced path is asymptotically dematerialized in the relative sense
($Y/R\to\infty$, $\Omega\to 0$), and its growth condition $A_\infty>0$ is itself a strong
capital-for-materials substitution statement. The substantive line between S1/S2 and S7 is whether
the *level* of $R$ stays bounded away from zero, i.e. whether the recycling loop is worth
maintaining — not whether materials "matter" asymptotically in the intensity sense. Keep S7 in the
list until the essentiality assumption is fixed. **[open]**

---

## 3. Order of attack, revised

1. **S5** — existence and characterization of the interior steady state; now doing double duty as
   the generic neoclassical outcome and the likely Part 3 target.
2. Write the short formal statements for the rulings-out that piggyback on the S1 price system:
   standalone S2, S3, S4-corner. Each is a paragraph, not a computation.
3. Assumption decisions to put to the docs, collected from S1: essentiality of $R$ and the
   $A_\infty$ family; $\Phi^I$ treatment (baseline vs. appendices is no longer a matter of
   convenience); $v'(0)=0$; $S\ge 0$ / extraction-cost Inada; discovery-cost blow-up at
   $\bar X_{\max}<\infty$ vs. bounded $C^D_D$ — the last being the primitive that selects
   S1/S2 vs. S5.
4. Collection II (unsustained consumption), once S5 is done: the $\chi$-mismatch exits and the
   $A_\infty-\delta<\rho$-without-S5 configurations need a home.
