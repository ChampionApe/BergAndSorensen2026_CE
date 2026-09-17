"""
Minimal JSON reader.

One file crosses from the data pipeline into the model: the calibration file of
`calibration.jl`, written in Python and read here.  The project pins no package
outside the standard library, so the reader lives here rather than in a
dependency.

It is a complete recursive-descent parser for the grammar -- objects, arrays,
strings with escapes, numbers, `true`, `false`, `null` -- and not a pattern
match on the expected schema.  That division is deliberate: a file that is valid
JSON but the wrong shape must fail in `calibration.jl`, with a message naming
the field the pipeline got wrong, and never here.

Objects become `Dict{String,Any}`, arrays `Vector{Any}`, a number `Int64` when
its literal carries no decimal point or exponent and `Float64` otherwise, and
`null` becomes `nothing`.  Escapes outside the basic multilingual plane
(surrogate pairs) are refused rather than silently mangled.
"""

"Position of byte index `i`, reported as line and column so a pipeline bug points at a line."
function json_where(s::AbstractString, i::Int)
    line, col = 1, 1
    j = firstindex(s)
    while j < i && j <= lastindex(s)
        if s[j] == '\n'
            line += 1
            col = 1
        else
            col += 1
        end
        j = nextind(s, j)
    end
    return "line $line, column $col"
end

json_error(s::AbstractString, i::Int, msg::AbstractString) =
    error("JSON: $msg at $(json_where(s, i))")

function json_skipws(s::AbstractString, i::Int)
    n = lastindex(s)
    while i <= n
        c = s[i]
        (c == ' ' || c == '\t' || c == '\n' || c == '\r') || break
        i = nextind(s, i)
    end
    return i
end

"""
    json_parse(s) -> Any
    json_parse_file(path) -> Any

Parse a JSON document.  `json_parse_file` also strips a leading byte-order mark,
which is what Windows tooling writes by default and is not part of the grammar.
"""
function json_parse(s::AbstractString)
    v, i = json_value(s, json_skipws(s, firstindex(s)))
    i = json_skipws(s, i)
    i <= lastindex(s) && json_error(s, i, "trailing characters after the top-level value")
    return v
end

function json_parse_file(path::AbstractString)
    isfile(path) || error("json_parse_file: no such file: $path")
    s = read(path, String)
    # "\ufeff" is written as an escape, not as the character: `model/src/` is
    # ASCII only, and a byte-order mark in the source would be invisible.
    startswith(s, "\ufeff") && (s = s[nextind(s, firstindex(s)):end])
    return json_parse(s)
end

function json_value(s::AbstractString, i::Int)
    i > lastindex(s) && json_error(s, i, "unexpected end of input")
    c = s[i]
    c == '{' && return json_object(s, i)
    c == '[' && return json_array(s, i)
    c == '"' && return json_string(s, i)
    c == 't' && return (true, json_literal(s, i, "true"))
    c == 'f' && return (false, json_literal(s, i, "false"))
    c == 'n' && return (nothing, json_literal(s, i, "null"))
    return json_number(s, i)
end

function json_literal(s::AbstractString, i::Int, lit::AbstractString)
    j = i
    for ch in lit
        (j <= lastindex(s) && s[j] == ch) || json_error(s, i, "expected `$lit`")
        j = nextind(s, j)
    end
    return j
end

function json_string(s::AbstractString, i::Int)
    buf = IOBuffer()
    n = lastindex(s)
    i = nextind(s, i)                     # past the opening quote
    while i <= n
        c = s[i]
        if c == '"'
            return (String(take!(buf)), nextind(s, i))
        elseif c == '\\'
            i = nextind(s, i)
            i <= n || json_error(s, i, "unterminated escape")
            e = s[i]
            if e == 'u'
                hex = IOBuffer()
                for _ in 1:4
                    i = nextind(s, i)
                    i <= n || json_error(s, i, "truncated \\u escape")
                    print(hex, s[i])
                end
                cp = tryparse(UInt16, String(take!(hex)); base = 16)
                cp === nothing && json_error(s, i, "malformed \\u escape")
                0xD800 <= cp <= 0xDFFF && json_error(s, i,
                    "surrogate-pair \\u escapes are not supported; write the character directly")
                print(buf, Char(cp))
            else
                d = e == 'n' ? '\n' : e == 't' ? '\t' : e == 'r' ? '\r' :
                    e == 'b' ? '\b' : e == 'f' ? '\f' : e == '/' ? '/' :
                    e == '"' ? '"' : e == '\\' ? '\\' :
                    json_error(s, i, "unknown escape `\\$e`")
                print(buf, d)
            end
            i = nextind(s, i)
        else
            print(buf, c)
            i = nextind(s, i)
        end
    end
    return json_error(s, i, "unterminated string")
end

function json_number(s::AbstractString, i::Int)
    n = lastindex(s)
    j = i
    isfloat = false
    (j <= n && (s[j] == '-' || s[j] == '+')) && (j = nextind(s, j))
    while j <= n
        c = s[j]
        if '0' <= c <= '9'
            j = nextind(s, j)
        elseif c == '.' || c == 'e' || c == 'E' || c == '+' || c == '-'
            # `+` and `-` can only belong to an exponent here: no JSON token may
            # follow a number without a separator, so a permissive scan cannot
            # swallow the next value.
            isfloat = true
            j = nextind(s, j)
        else
            break
        end
    end
    j > i || json_error(s, i, "expected a value")
    txt = SubString(s, i, prevind(s, j))
    v = isfloat ? tryparse(Float64, txt) : tryparse(Int64, txt)
    # an integer literal too large for Int64 is still a number
    v === nothing && (v = tryparse(Float64, txt))
    v === nothing && json_error(s, i, "cannot parse the number `$txt`")
    return (v, j)
end

function json_object(s::AbstractString, i::Int)
    d = Dict{String,Any}()
    i = json_skipws(s, nextind(s, i))
    (i <= lastindex(s) && s[i] == '}') && return (d, nextind(s, i))
    while true
        i = json_skipws(s, i)
        (i <= lastindex(s) && s[i] == '"') || json_error(s, i, "expected a key")
        k, i = json_string(s, i)
        i = json_skipws(s, i)
        (i <= lastindex(s) && s[i] == ':') || json_error(s, i, "expected `:` after the key `$k`")
        v, i = json_value(s, json_skipws(s, nextind(s, i)))
        haskey(d, k) && json_error(s, i, "duplicate key `$k`")
        d[k] = v
        i = json_skipws(s, i)
        i <= lastindex(s) || json_error(s, i, "unterminated object")
        if s[i] == ','
            i = nextind(s, i)
        elseif s[i] == '}'
            return (d, nextind(s, i))
        else
            json_error(s, i, "expected `,` or `}`")
        end
    end
end

function json_array(s::AbstractString, i::Int)
    v = Any[]
    i = json_skipws(s, nextind(s, i))
    (i <= lastindex(s) && s[i] == ']') && return (v, nextind(s, i))
    while true
        e, i = json_value(s, json_skipws(s, i))
        push!(v, e)
        i = json_skipws(s, i)
        i <= lastindex(s) || json_error(s, i, "unterminated array")
        if s[i] == ','
            i = nextind(s, i)
        elseif s[i] == ']'
            return (v, nextind(s, i))
        else
            json_error(s, i, "expected `,` or `]`")
        end
    end
end
