"""
    `@df d x`

Convert every symbol in the expression `x` with the respective column in `d` if it exists.

If you want to avoid replacing the symbol, escape it with `^`.

`NA` values are replaced with `NaN` for columns of `Float64` and `""` or `Symbol()`
for strings and symbols respectively.
"""
macro df(d, x)
    syms = Expr[]
    vars = Symbol[]
    plot_call = _df(d, x, syms, vars)
    compute_vars = Expr(:(=), Expr(:tuple, vars...),
        Expr(:call, :(StatPlots.compute_all), d, syms...))
    esc(Expr(:block, compute_vars, plot_call))
end

_df(d, x, syms, vars) = x

function _df(d, x::Expr, syms, vars)
    if x.head == :quote
        new_var = gensym(x.args[1])
        push!(syms, x)
        push!(vars, new_var)
        return new_var
    end
    if x.head == :call
        x.args[1] == :^ && length(x.args) == 2 && return x.args[2]
        x.args[1] == :cols && return :(hcat((StatPlots.select_column($d, i) for i in $(x.args[2]))...))
    end
    return Expr(x.head, (_df(d, arg, syms, vars) for arg in x.args)...)
end

function _argnames(d, x::Expr)
    [_arg2string(d, s) for s in x.args[2:end] if not_kw(s)]
end

not_kw(x) = true
not_kw(x::Expr) = !(x.head in [:kw, :parameters])

_arg2string(d, x) = stringify(x)
function _arg2string(d, x::Expr)
    if x.head == :call && x.args[1] == :cols
        return :(reshape([(DataFrames.names($d)[i]) for i in $(x.args[2])], 1, :))
    elseif x.head == :call && x.args[1] == :hcat
        return hcat(stringify.(x.args[2:end])...)
    elseif x.head == :hcat
        return hcat(stringify.(x.args)...)
    else
        return stringify(x)
    end
end

stringify(x) = filter(t -> t != ':', string(x))

#compute_all(d, s...) = [StatPlots.select_column(d, ss) for ss in s]

function compute_all(df, syms...)
    iter = IterableTables.getiterator(df)
    type_info = Dict(zip(column_names(iter), column_types(iter)))
    is_col = [s in column_names(iter) for s in syms]
    cols = Tuple(s in column_names(iter) ? Array{type_info[s]}(0) : s for s in syms)
    for i in iter
        for ind in eachindex(syms)
            is_col[ind] && push!(cols[ind], getfield(i, syms[ind]))
        end
    end
    return Tuple(convert_missing.(t) for t in cols)
end

function select_column(df, s)
    iter = IterableTables.getiterator(df)
    isa(s, Symbol) && !(s in column_names(iter)) && return s
    [convert_missing(getfield(i, s)) for i in iter]
end

convert_missing(el) = el
convert_missing(el::DataValue{T}) where {T} = get(el, error("Missing data of type $T is not supported"))
convert_missing(el::DataValue{<:AbstractString}) = get(el, "")
convert_missing(el::DataValue{Symbol}) = get(el, Symbol())
convert_missing(el::DataValue{<:Real}) = get(convert(DataValue{Float64}, el), NaN)
