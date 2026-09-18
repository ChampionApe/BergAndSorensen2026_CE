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
| $\psi,\varphi$ | `psi_v, varphi` | scale and curvature of the pollution disutility; $\psi=0$ on the calibrated set, which leaves $\varphi$ undefined |
| $\kappa$ | `kappa` | damage coefficient in production, $e^{-\kappa P}$ |
| $\delta$ | `delta` | depreciation |
| $A_0,g_A,B_0,g_B$ | `A0, gA, B0, gB` | the two technology levels and their growth rates |
| $\bar R$ | `Rbar` | the material floor |
| $\bar a$ | `abar` | the yield ceiling |
| $\xi,\psi$ | `xi, psi_a` | tail rate, power-tail exponent; the tail family is `tail` (`:exp` or `:power`) |
| $\mu$ | `mu_h` | **handling share** of the waste stock |
| $\mu_F$ | `mu_F` | returns exponent of the final-goods technology |
| $\beta$ | `beta_s` | **CES share on capital** |
| $\varsigma$ | `sigma_s` | elasticity of substitution of the CES aggregate |
| $\sigma,\sigma_\infty$ | `sigma`, `sigma_inf` | **storage share** $\Phi^IG/R$ and its limit on the circular path (`longrun.jl`) |
| $c^N,\mu_N,\kappa_N,\chi_N,S_{\mathrm{ref}}$ | `cN0, cN_inf, gcN, mu_N, kap_N, chi_N, Sref` | the extraction cost: level path, stock-effect elasticity, linear term, convexity, normalising reserve |
| $c^D,\mu_D,\kappa_D,\chi_D,X_{\mathrm{ref}}$ | `cD0, cD_inf, gcD, mu_D, kap_D, chi_D, Xref` | the exploration cost, the same shape against $\bar X_{\max}-X$ |
| $c^c,c^T,\chi_T$ | `cc0, cT0` (and `_inf`, `g*`), `chi_T` | collection and treatment cost paths, convexity of treatment |
| $d^W$ | `dW` | leakage of the treated stream |
| $\theta(P)$ | `theta0, theta_min, thetaP` | pollution decay |
| $\omega^j$ | `omY, omN, omD, omW, omC` | relative waste intensities |
| $\phi^I$ | `phiI` | durables coefficient |
| $\Omega^{N,S},\Omega^{D,S}$ | `OmNS, OmDS` | nature-attributable intensities |
| $\bar X_{\max}$ | `Xmax` | exhaustion point of discovery |
| $\mathcal M_\infty$ | `Minf` | retained material endowment, `M^K + W` in the limit |
| $\mathcal T$ | `residence` (`Tres` locally) | residence time $1/\mu+\sigma_\infty/\delta$ of Little's law |
| $\mathcal M_\infty/(\bar R\mathcal T)$ | `survival_ratio` | the survival margin, above one on a state-C path with a floor |
| — | `closes`, `leak_sum` | the closure criterion of `longrun.jl`: does the loop close, and the cumulated leakage against the budget |
| — | `phiW, phiz, phiP, phiX` | the four policy dials; no document symbol |

**Three clashes are broken here and nowhere else.** The document's $\mu$, $\beta$ and
$\sigma$ each name a second object in the quantitative specialisation, so the source
takes `mu_h` / `mu_F`, `beta_s` (with the discount factor derived from `rho` and never
called `beta`), and `sigma_s` for the elasticity of substitution, which the notes now
write $\varsigma$, against `sigma` for the storage share. Never resolve one of these a
second way in a second file. `psi` is the same word twice and is split the same way:
`psi_a` is the power-tail exponent of the yield function, `psi_v` the scale of the
pollution disutility.
