"""
Illustrative parameter sets.

**These are not calibrated.**  They are internally consistent, order-of-magnitude
plausible numbers whose only job is to exercise the solver and the long-run
blocks while the data work of `notes/data_plan_global_1850.md` is done.  Nothing
reported from these numbers is a result.

Units of the illustrative set: one unit of goods is roughly 100 trillion
constant dollars, one unit of material roughly 100 gigatonnes, one period one
year.  Prices are therefore in goods units per material unit.
"""

"""
    baseline_params(; kwargs...) -> Params

Trending technology, a soft yield ceiling, no material floor.  Keyword
arguments override any field.  Useful variants:

    baseline_params(Rbar = 0.35)                  # a binding floor
    baseline_params(abar = 0.7)                   # a hard ceiling
    baseline_params(gA = 0.0, gB = 0.0)           # stationary technology
    baseline_params(phiP = 0.0)                   # no emission tax
"""
function baseline_params(; kwargs...)
    base = (
        dt = 1.0,
        # preferences
        # eta is held just above 1 so that the post-shutdown cake-eating
        # problem is well posed at delta = 0.05 and rho = 0.015; see
        # check_params.  Raising eta requires raising rho with it.
        rho = 0.015, eta = 1.1, psi_v = 0.002, varphi = 1.0,
        # technology: mu_F is the capital + materials share, so the fixed
        # factor stands in for labour; beta_s then splits it 0.30 / 0.05
        A0 = 0.70, gA = 0.012, B0 = 1.0, gB = 0.010,
        beta_s = 0.857, mu_F = 0.35, sigma_s = 1.0,
        kappa = 0.02, delta = 0.05, Rbar = 0.0,
        # recycling: soft ceiling, exponential tail
        abar = 1.0, xi = 3.0, tail = :exp, psi_a = 2.0,
        # extraction
        cN0 = 0.20, cN_inf = 0.20, gcN = 0.0,
        mu_N = 1.5, kap_N = 0.05, chi_N = 1.0, Sref = 20.0,
        # exploration
        cD0 = 0.13, cD_inf = 0.13, gcD = 0.0,
        mu_D = 1.5, kap_D = 0.10, chi_D = 1.0, Xmax = 60.0, Xref = 25.0,
        # waste handling: the broad reading of the stockpile, mean residence 50y
        mu_h = 0.02,
        cc0 = 0.02, cc_inf = 0.02, gcc = 0.0,
        cT0 = 0.05, cT_inf = 0.05, gcT = 0.0,
        chi_T = 1.0, dW = 0.30,
        # pollution
        theta0 = 0.02, theta_min = 0.005, thetaP = 0.0,
        # accounting
        omY = 0.30, omN = 1.0, omD = 1.0, omW = 1.0, omC = 1.0, phiI = 1.0,
        OmNS = 2.0, OmDS = 0.05,
        # policy: the planner corner
        phiW = 1.0, phiz = 1.0, phiP = 1.0, phiX = 1.0,
    )
    return Params(; base..., kwargs...)
end

"Initial states `[K, S, X, P, MK, W]` matching `baseline_params`."
baseline_states(; K = 3.0, S = 20.0, X = 25.0, P = 0.5, MK = 2.0, W = 1.0) =
    [K, S, X, P, MK, W]
