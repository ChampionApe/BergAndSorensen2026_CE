"""
Parameter sets: the illustrative one written here, and the calibrated one read
from the data pipeline.

`baseline_params` / `baseline_states` are **illustrative and not calibrated**.
They are internally consistent, order-of-magnitude plausible numbers whose only
job is to exercise the solver and the long-run blocks while the data work of
`notes/data_plan_global_1850.md` is done.  Nothing reported from them is a
result.  Units of the illustrative set: one unit of goods is roughly 100
trillion constant dollars, one unit of material roughly 100 gigatonnes, one
period one year.  Prices are therefore in goods units per material unit.

`calibrated_params` / `calibrated_states` read `data/processed/calibration.json`,
which the pipeline writes.  Unit conversion happens in the pipeline and never
here, so that one file states the units of every number: the JSON carries the
model's own units, those of `writing/quant/quant_model.tex`, Section "Period
length and units".  Field names in that file are the Julia identifiers of
`model/SYMBOLS.md`, which is what makes the file checkable against the symbol
table rather than against this source.
"""

"""
    baseline_params(; kwargs...) -> Params

The **illustrative** parameter set: trending technology, a soft yield ceiling,
no material floor, and not a calibration.  Keyword arguments override any field.
Useful variants:

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

"Illustrative initial states `[K, S, X, P, MK, W]` matching `baseline_params`."
baseline_states(; K = 3.0, S = 20.0, X = 25.0, P = 0.5, MK = 2.0, W = 1.0) =
    [K, S, X, P, MK, W]

# ---------------------------------------------------------------------------
# the calibrated set, read from the pipeline
# ---------------------------------------------------------------------------

"""
The keys of the `states` object, in the layout order of `period.jl`.

The JSON names the base-year stock, so it carries the `0`; the vector it builds
is indexed by `IK, IS, IX, IP, IMK, IWS`.
"""
const STATE_KEYS = ("K0", "S0", "X0", "P0", "MK0", "W0")

"""
    read_calibration(path) -> Dict{String,Any}

The calibration file as written, parsed and not interpreted.  The schema is one
JSON object with four members:

    meta    base year, units, who built it and when
    params  one entry per Params field: a number, or an object
            {"value": x, "low": x, "high": x, "source": "..."}
    states  the six base-year stocks, keyed K0 S0 X0 P0 MK0 W0
    cases   abar, Rbar_grid, xi_range, muN_range -- the grids the experiments run

Every other accessor in this file takes either a path or an already parsed
dictionary, so that reading a file once and building several objects from it
does not parse it several times.
"""
function read_calibration(path::AbstractString)
    d = json_parse_file(path)
    d isa AbstractDict ||
        error("read_calibration: $path is valid JSON but its top level is a " *
              "$(typeof(d)); the schema is one object")
    return d
end

_calibration(d::AbstractDict) = d
_calibration(path::AbstractString) = read_calibration(path)

"Pull `{\"value\": x, ...}` down to `x`; a bare number is already the value."
_entry(v::AbstractDict, what) = haskey(v, "value") ? v["value"] :
    error("calibration: $what is an object without a \"value\" member")
_entry(v, what) = v

function _float(v, what)
    x = _entry(v, what)
    x isa Real || error("calibration: $what is $(repr(x)), which is not a number")
    return float(x)
end

"""
    calibrated_params(src; check = true, kwargs...) -> Params

`Params` from the `params` object of the calibration file.  A field the file
does not name keeps its `Params` default; a name that is not a field of `Params`
is an error rather than a silent omission, because that is how a typo in the
pipeline would otherwise reach a result.  Keyword arguments override the file,
as in `baseline_params`, and are applied last.

`check = true` runs `check_params` and warns on what it returns: a calibration
that violates a maintained restriction should say so where it is loaded, not
where it later fails to solve.
"""
function calibrated_params(src; check::Bool = true, kwargs...)
    d = _calibration(src)
    pj = get(d, "params", nothing)
    pj isa AbstractDict ||
        error("calibration: no \"params\" object in the file")
    flds = fieldnames(Params)
    vals = Dict{Symbol,Any}()
    unknown = String[]
    for (k, v) in pj
        f = Symbol(k)
        if !(f in flds)
            push!(unknown, k)
            continue
        end
        vals[f] = _field_value(f, v)
    end
    isempty(unknown) ||
        error("calibration: params names $(length(unknown)) field(s) that Params does " *
              "not have: " * join(sort(unknown), ", ") * ". The field names are the " *
              "Julia identifiers of model/SYMBOLS.md.")
    for (k, v) in kwargs
        vals[k] = v
    end
    p = Params(; vals...)
    if check
        for w in check_params(p)
            @warn "calibrated_params: $w"
        end
    end
    return p
end

"Convert one JSON entry to the declared type of the `Params` field it fills."
function _field_value(f::Symbol, v)
    x = _entry(v, "params.$f")
    Ty = fieldtype(Params, f)
    if Ty === Symbol
        # `tail` is the one non-numeric field; JSON has no symbol, so the
        # pipeline writes "exp" or ":exp" and both are accepted.
        x isa AbstractString ||
            error("calibration: params.$f must be a string naming a symbol, got $(repr(x))")
        return Symbol(lstrip(x, ':'))
    end
    x isa Real ||
        error("calibration: params.$f is $(repr(x)), which is not a number")
    return convert(Ty, x)
end

"""
    calibrated_states(src) -> Vector{Float64}

The six base-year stocks `[K, S, X, P, MK, W]`, in the layout order of
`period.jl`.  All six are required: there is no sensible default for a stock.
"""
function calibrated_states(src)
    d = _calibration(src)
    sj = get(d, "states", nothing)
    sj isa AbstractDict || error("calibration: no \"states\" object in the file")
    extra = setdiff(collect(keys(sj)), collect(STATE_KEYS))
    isempty(extra) ||
        error("calibration: states names " * join(sort(extra), ", ") *
              ", which are not states; the six are " * join(STATE_KEYS, ", "))
    s = Vector{Float64}(undef, NS)
    for (i, k) in enumerate(STATE_KEYS)
        haskey(sj, k) || error("calibration: states is missing \"$k\"")
        s[i] = _float(sj[k], "states.$k")
    end
    return s
end

"""
    calibration_cases(src) -> NamedTuple

The grids the experiments of `scripts/run_experiments.jl` run over: `abar` (the
ceiling cases), `Rbar_grid` (the floor surface), and `xi_range` / `muN_range`,
each a two-element `[lo, hi]` for the two parameters the data leave as a range.
A member the file omits comes back empty, so a caller can supply its own.
"""
function calibration_cases(src)
    d = _calibration(src)
    cj = get(d, "cases", Dict{String,Any}())
    cj isa AbstractDict || error("calibration: \"cases\" is not an object")
    nums(k) = haskey(cj, k) ?
        Float64[_float(e, "cases.$k") for e in cj[k]] : Float64[]
    return (; abar = nums("abar"), Rbar_grid = nums("Rbar_grid"),
             xi_range = nums("xi_range"), muN_range = nums("muN_range"))
end

"The `meta` object: base year, units, who built the file and when."
function calibration_meta(src)
    d = _calibration(src)
    m = get(d, "meta", Dict{String,Any}())
    m isa AbstractDict || error("calibration: \"meta\" is not an object")
    return m
end

"""
    calibration_sources(src) -> Dict{Symbol,String}

The `source` of each parameter entry, as the acceptance criterion of
`notes/plan_calibration_experiments.md` Phase C states it: every parameter has
one.  A parameter written as a bare number has none and is absent here, which is
what makes the gap visible.
"""
function calibration_sources(src)
    d = _calibration(src)
    pj = get(d, "params", Dict{String,Any}())
    out = Dict{Symbol,String}()
    for (k, v) in pj
        v isa AbstractDict && haskey(v, "source") || continue
        out[Symbol(k)] = string(v["source"])
    end
    return out
end

"""
    calibration_bounds(src) -> Dict{Symbol,NamedTuple}

`(value, low, high)` per parameter, with `low = high = value` where the file
gives a point.  This is what a sensitivity run perturbs over: the two
least-identified parameters of the plan, `mu_N` and `xi`, are ranges here and
points nowhere.
"""
function calibration_bounds(src)
    d = _calibration(src)
    pj = get(d, "params", Dict{String,Any}())
    out = Dict{Symbol,NamedTuple{(:value, :low, :high),NTuple{3,Float64}}}()
    for (k, v) in pj
        f = Symbol(k)
        (f in fieldnames(Params) && fieldtype(Params, f) === Float64) || continue
        val = _float(v, "params.$k")
        lo = v isa AbstractDict && haskey(v, "low") ? _float(v["low"], "params.$k.low") : val
        hi = v isa AbstractDict && haskey(v, "high") ? _float(v["high"], "params.$k.high") : val
        out[f] = (; value = val, low = lo, high = hi)
    end
    return out
end
