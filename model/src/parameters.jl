"""
Parameters of the quantitative model.

Naming follows `writing/docs/Appendix_workhorse.tex`.  Symbols that clash in the
paper are disambiguated here: `mu_h` is the handling share of the waste stock
(paper `mu`), `mu_F` the returns exponent of the final-goods technology, and
`beta_s` the CES share on capital (paper `beta`); the discount factor is derived
from `rho` and never called `beta`.

All rates are *per period*; `dt` is the number of years in a period.  Use
`annualise` / `perperiod` to convert.
"""

Base.@kwdef struct Params
    # ---- timing -----------------------------------------------------------
    dt::Float64 = 1.0            # years per period

    # ---- preferences ------------------------------------------------------
    rho::Float64 = 0.015         # pure rate of time preference, per period
    eta::Float64 = 1.5           # elasticity of marginal utility
    psi_v::Float64 = 0.0         # scale of pollution disutility
    varphi::Float64 = 1.0        # curvature of pollution disutility

    # ---- final-goods technology ------------------------------------------
    A0::Float64 = 1.0            # TFP level at t = 0
    gA::Float64 = 0.0            # TFP growth, per period
    B0::Float64 = 1.0            # material-augmenting level at t = 0
    gB::Float64 = 0.0            # material-augmenting growth, per period
    beta_s::Float64 = 0.7        # CES share on capital
    mu_F::Float64 = 0.9          # returns exponent (fixed factor)
    sigma_s::Float64 = 1.0       # elasticity of substitution (1 = Cobb-Douglas)
    kappa::Float64 = 0.0         # pollution damage in production, exp(-kappa*P)
    delta::Float64 = 0.05        # depreciation, per period
    Rbar::Float64 = 0.0          # minimum material requirement (the floor)

    # ---- recycling technology --------------------------------------------
    abar::Float64 = 0.9          # yield ceiling; == 1.0 is the soft ceiling
    xi::Float64 = 1.0            # tail rate
    tail::Symbol = :exp          # :exp  -> abar*(1 - exp(-xi*x))
                                 # :power-> abar*(xi*x)^p /(1 + (xi*x)^p)
    psi_a::Float64 = 2.0         # power-tail exponent p

    # ---- extraction -------------------------------------------------------
    cN0::Float64 = 1.0
    cN_inf::Float64 = 1.0
    gcN::Float64 = 0.0           # convergence rate of cN(t) towards cN_inf
    mu_N::Float64 = 1.5          # stock-effect elasticity
    kap_N::Float64 = 0.1         # linear term: positive marginal cost at N = 0
    chi_N::Float64 = 1.0         # convexity of extraction effort
    Sref::Float64 = 1.0          # normalising reserve level

    # ---- exploration ------------------------------------------------------
    cD0::Float64 = 1.0
    cD_inf::Float64 = 1.0
    gcD::Float64 = 0.0
    mu_D::Float64 = 1.5
    kap_D::Float64 = 0.1
    chi_D::Float64 = 1.0
    Xmax::Float64 = 10.0         # ceiling on cumulative discovery
    Xref::Float64 = 0.0          # X_0, the reference in the cost function

    # ---- waste handling ---------------------------------------------------
    mu_h::Float64 = 0.05         # handling share of the waste stock, per period
    cc0::Float64 = 0.05          # collection charge per treated tonne
    cc_inf::Float64 = 0.05
    gcc::Float64 = 0.0
    cT0::Float64 = 0.10          # treatment cost scale
    cT_inf::Float64 = 0.10
    gcT::Float64 = 0.0
    chi_T::Float64 = 1.0         # convexity of treatment cost
    dW::Float64 = 0.2            # leakage of the treated stream to environment

    # ---- pollution decay --------------------------------------------------
    theta0::Float64 = 0.05       # decay at P = 0
    theta_min::Float64 = 0.01    # regeneration floor
    thetaP::Float64 = 0.0        # saturation rate (0 => constant decay)

    # ---- materials accounting --------------------------------------------
    omY::Float64 = 0.4           # relative waste intensity of production
    omN::Float64 = 0.4           # ... of extraction effort
    omD::Float64 = 0.4           # ... of exploration effort
    omW::Float64 = 0.4           # ... of waste handling
    omC::Float64 = 0.4           # ... of consumption
    phiI::Float64 = 1.0          # relative material intensity of gross formation
    OmNS::Float64 = 2.0          # overburden per tonne extracted
    OmDS::Float64 = 0.05         # mass displaced per tonne discovered

    # ---- policy dials (1 = Pigouvian; the planner is (1,1,1,1)) ----------
    phiW::Float64 = 1.0          # property rights over the waste stock
    phiz::Float64 = 1.0          # material-content instrument
    phiP::Float64 = 1.0          # emission tax
    phiX::Float64 = 1.0          # discovery tax
end

# ---------------------------------------------------------------------------
# derived scalars
# ---------------------------------------------------------------------------

discount(p::Params) = 1 / (1 + p.rho)

"Copy of `p` with the named fields replaced."
function with(p::Params; kwargs...)
    flds = fieldnames(Params)
    vals = map(f -> haskey(kwargs, f) ? kwargs[f] : getfield(p, f), flds)
    return Params(; NamedTuple{flds}(vals)...)
end

"Output elasticity of capital, Cobb-Douglas case."
beta_K(p::Params) = p.mu_F * p.beta_s
"Output elasticity of effective materials, Cobb-Douglas case."
gamma_R(p::Params) = p.mu_F * (1 - p.beta_s)

"""
    cbgp_growth(p)

Per-period log growth rate of the goods block on a circular balanced growth
path, `g = (gA + gamma*gB) / (1 - beta_K)`  (workhorse eq. cbgp:g).
"""
cbgp_growth(p::Params) = (p.gA + gamma_R(p) * p.gB) / (1 - beta_K(p))

"""
    bdp_rates(p)

Solved balanced-dematerialization rates `(g, nu)` (workhorse eq. bdp-solution).
Returns `nothing` when the exponential family admits no solution.
"""
function bdp_rates(p::Params)
    bk, ga = beta_K(p), gamma_R(p)
    den = (p.mu_N - 1) * (1 - bk) + ga
    den <= 0 && return nothing
    nu = (p.gA + ga * p.gB) / den
    return ((p.mu_N - 1) * nu, nu)
end

"Interest factor implied by the Euler equation at growth factor `Gam`."
interest_factor(p::Params, Gam::Real) = Gam^p.eta * (1 + p.rho)

"""
    check_params(p) -> Vector{String}

Non-fatal consistency checks.  Returns a list of warnings; empty means the
parameter vector satisfies every restriction the theory maintains.
"""
function check_params(p::Params)
    w = String[]
    p.rho > 0 || push!(w, "rho must be > 0")
    p.eta > 0 || push!(w, "eta must be > 0")
    0 < p.delta < 1 || push!(w, "delta must lie in (0,1)")
    # mu_h = 1 is admissible: it is the one-period buffer, W_{t+1} = W_t, where
    # the stockpile holds exactly last period's waste flow.  Nothing in the code
    # divides by 1 - mu_h, the stockpile costate recursion collapses to
    # pW_t = h_{t+1}/(1+r) and Little's law to a residence time of 1 + sigma/delta.
    0 < p.mu_h <= 1 || push!(w, "mu_h must lie in (0,1]")
    0 < p.mu_F < 1 || push!(w, "mu_F must lie in (0,1)")
    0 < p.beta_s < 1 || push!(w, "beta_s must lie in (0,1)")
    0 < p.abar <= 1 || push!(w, "abar must lie in (0,1]")
    p.xi > 0 || push!(w, "xi must be > 0")
    p.chi_T > 0 || push!(w, "chi_T must be > 0")
    0 < p.dW < 1 || push!(w, "dW must lie in (0,1)")
    0 < p.theta_min <= p.theta0 < 1 || push!(w, "need 0 < theta_min <= theta0 < 1")
    p.Rbar >= 0 || push!(w, "Rbar must be >= 0")
    p.Xmax > p.Xref || push!(w, "Xmax must exceed Xref")
    p.tail in (:exp, :power) || push!(w, "tail must be :exp or :power")
    # The power form a = abar*u/(1+u) with u = (xi*x)^psi behaves like
    # abar*(xi*x)^psi near the origin, so it is *convex* there for psi > 1: the
    # maintained assumption a'' < 0 fails, a' is non-monotone, and the marginal
    # recycling yield alpha = a - a'x is negative for small x.  Global
    # concavity requires psi <= 1.  psi > 1 is still a legitimate description
    # of the *tail*, and the closure criterion is unaffected, but the corner
    # test on the recycling-capital margin is no longer decided by a'(0).
    if p.tail === :power && p.psi_a > 1
        push!(w, "power tail with psi_a = $(p.psi_a) > 1 is S-shaped: a'' > 0 near " *
                 "the origin, alpha < 0 there, and the recycling-capital margin has " *
                 "two roots. Use psi_a <= 1 for a globally concave yield function.")
    end

    # Assumption "bounded accumulation and finite values": ln(1+rho) > (1-eta)g
    g = cbgp_growth(p)
    if log(1 + p.rho) <= (1 - p.eta) * g
        push!(w, "utility diverges on the circular path: need log(1+rho) > (1-eta)*g " *
                 "(g = $(round(g, digits=5)))")
    end
    # no-tipping (workhorse eq. notipping), only binds when thetaP > 0
    if p.thetaP > 0 && p.rho + p.theta_min < (p.theta0 - p.theta_min) / MathConstants.e
        push!(w, "tipping condition may fail: need rho + theta_min >= (theta0 - theta_min)/e")
    end
    # Post-shutdown cake-eating.  The two conditions of the workhorse --- a
    # positive consumption rate, gamma_C < 1 - delta, and a finite value,
    # beta * gamma_C^(1-eta) < 1 --- are algebraically the same restriction,
    # (1-delta)^(1-eta) < 1 + rho.  It binds only on collapse paths, where it
    # is what makes the value of stopping well defined at all.
    if (1 - p.delta)^(1 - p.eta) >= 1 + p.rho
        need = (1 - p.delta)^(1 - p.eta) - 1
        push!(w, "the post-shutdown cake-eating problem has no interior solution: " *
                 "need (1-delta)^(1-eta) < 1+rho, i.e. rho > $(round(need, digits=4)) " *
                 "at delta = $(p.delta), eta = $(p.eta). Collapse paths cannot be ranked.")
    end
    return w
end
