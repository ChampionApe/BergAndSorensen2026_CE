"""
    CircularEconomy

Quantitative implementation of the model in *The Environmental Macroeconomics
of the Circular Economy*: a Ramsey economy with exhaustible resources, a full
materials balance, an anthropogenic waste stock and a minimum material
requirement, solved as a deterministic perfect-foresight path.

The social planner's problem and the decentralised market economy are the same
residual system evaluated at different points of a four-dimensional policy
space; the planner is the corner `(phiW, phiz, phiP, phiX) = (1,1,1,1)`.  Both
transcriptions are implemented separately and checked against each other.

Dependencies are standard-library only.

Layout
------
  `parameters.jl`  parameter set, derived rates, consistency checks
  `primitives.jl`  functional forms and their derivatives
  `period.jl`      within-period definitions, accounting, price block
  `residuals.jl`   the stacked residual system, market and planner forms
  `terminal.jl`    terminal closure and the value of the shutdown state
  `longrun.jl`     analytic rest point, circular growth path, closure criterion,
                   long-run classifier
  `solver.jl`      Newton with a structured sparse finite-difference Jacobian
  `guess.jl`       starting values
  `diagnostics.jl` verification checks, welfare, series accessors
  `json.jl`        minimal JSON reader, for the calibration file only
  `calibration.jl` the illustrative set, and the calibrated set read from JSON
"""
module CircularEconomy

using LinearAlgebra, SparseArrays, Printf, Random

include("parameters.jl")
include("primitives.jl")
include("period.jl")
include("residuals.jl")   # defines Model, so it must precede terminal.jl
include("terminal.jl")
include("longrun.jl")
include("solver.jl")
include("guess.jl")
include("diagnostics.jl")
include("sufficiency.jl")
include("json.jl")         # defines the reader calibration.jl uses
include("calibration.jl")

# parameters and derived quantities
export Params, with, check_params, discount, beta_K, gamma_R,
       cbgp_growth, bdp_rates, interest_factor

# primitives
export production, production_dematerialized, recycling_yield, tail_elasticity,
       extraction, exploration, handling_cost, decay,
       util, uprime, disutil, vprime

# model and system
export Model, nvar, period_block, price_block, effective_survival,
       residual_market!, residual_planner!, mcp

# long run
export restpoint_stationary, cbgp, survival_ratio, closure_check, invert_aprime,
       classify_longrun

# terminal / shutdown
export cake_policy, value_stop, value_stop_gradient, legacy_emissions,
       legacy_emissions_value, successor_state

# solving
export initial_guess, simulate_quantities, solve_path, newton!, jacobian,
       continuate, solve_with_shutdown, extend_horizon, solve_long

# diagnostics
export unpack, series, pseries, check_path, welfare, compare_residuals

# sufficiency
export convexity_report, wellposed_report, tvc_report, perturbation_test, deviation_profile,
       absorbing_shutdown,
       simulate_from_controls, test_value

# illustrative parameter sets (not calibrated)
export baseline_params, baseline_states

# the calibrated set, read from the pipeline's JSON
export read_calibration, calibrated_params, calibrated_states, calibration_cases,
       calibration_meta, calibration_sources, calibration_bounds

# index constants, exported because scripts index the packed vectors
export NS, NC, NM, IK, IS, IX, IP, IMK, IWS,
       IC, II, IN, ID, IVW, IKR, IQ, IPS, IPX, IPP, IPM, IPW

end # module

