# Symbols

A lookup table, consulted while reading `src/`. `writing/docs/notation.tex` is the authority on what a
symbol means; this file is the only place the symbol and the identifier are written beside each other,
and `code_style.md` section 1 fixes the transliteration rules that generated it. A source file that
needs a symbol not on this list adds a row here in the same change.

| document | source | |
|---|---|---|
| $K,S,X,P,M^K,\mathcal W$ | `K, S, X, P, MK, Wst` | the six states, in layout order |
| $C,I,N,D,\varpi,x$ | `C, I, N, D, vw, x` | the six controls as the solver carries them: the sixth unknown is the intensity, and `KR` is derived in the block |
| $x=K^R/T$ | `x` (slot `IXR`) | recycling capital per treated tonne; the unknown in place of $K^R$, because at the no-treatment corner $K^R$ and $T$ vanish together and $x$ is what stays determined (`period.jl`) |
| $q,p^S,p^X,p^P,p^M,p^{\mathcal W}$ | `q, pS, pX, pP, pM, pWst` | the six costates |
| $\rho,\eta$ | `rho, eta` | time preference, elasticity of marginal utility |
| $\delta$ | `delta` | depreciation |
| $\bar R$ | `Rbar` | the material floor |
| $\bar a$ | `abar` | the yield ceiling |
| $\xi,\psi$ | `xi, psi_a` | tail rate, power-tail exponent |
| $\mu$ | `mu_h` | **handling share** of the waste stock |
| $\mu_F$ | `mu_F` | returns exponent of the final-goods technology |
| $\beta$ | `beta_s` | **CES share on capital** |
| $\sigma$ | `sigma_s` | elasticity of substitution |
| $c^c,c^T$ | `cc0, cT0` (and `_inf`, `g*`) | collection and treatment cost paths |
| $d^W$ | `dW` | leakage of the treated stream |
| $\theta(P)$ | `theta0, theta_min, thetaP` | pollution decay |
| $\omega^j$ | `omY, omN, omD, omW, omC` | relative waste intensities |
| $\phi^I$ | `phiI` | durables coefficient |
| $\Omega^{N,S},\Omega^{D,S}$ | `OmNS, OmDS` | nature-attributable intensities |
| $\bar X_{\max}$ | `Xmax` | exhaustion point of discovery |
| $\mathcal M_\infty$ | `Minf` | retained material endowment, `M^K + W` in the limit |
| $\mathcal T$ | `residence` (`Tres` locally) | residence time $1/\mu+\sigma_\infty/\delta$ of Little's law |
| — | `phiW, phiz, phiP, phiX` | the four policy dials; no document symbol |

**Three clashes are broken here and nowhere else.** The document's $\mu$, $\beta$ and
$\sigma$ each name a second object in the quantitative specialisation, so the source
takes `mu_h` / `mu_F`, `beta_s` (with the discount factor derived from `rho` and never
called `beta`), and `sigma_s` / the storage share. Never resolve one of these a second
way in a second file.
