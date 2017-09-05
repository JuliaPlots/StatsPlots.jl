"""
    `@df d x`

Convert every symbol in the expression `x` with the respective column in `d` if it exists.

If you want to avoid replacing the symbol, escape it with `^`.

`NA` values are replaced with `NaN` for columns of `Float64` and `""` or `Symbol()`
for strings and symbols respectively.
"""
macro df(d, x)
    syms = Any[]
    vars = Symbol[]
    plot_call = parse_iterabletable_call!(d, x, syms, vars)
    compute_vars = Expr(:(=), Expr(:tuple, vars...),
        Expr(:call, :(StatPlots.extract_columns_from_iterabletable), d, syms...))
    esc(Expr(:block, compute_vars, plot_call))
end

parse_iterabletable_call!(d, x, syms, vars) = x

function parse_iterabletable_call!(d, x::Expr, syms, vars)
    if x.head == :quote
        new_var = gensym(x.args[1])
        push!(syms, x)
        push!(vars, new_var)
        return new_var
    end
    if x.head == :call
        x.args[1] == :^ && length(x.args) == 2 && return x.args[2]
        if x.args[1] == :cols
            range = eval(x.args[2])
            new_vars = gensym.(string.(range))
            append!(syms, range)
            append!(vars, new_vars)
            return Expr(:hcat, new_vars...)
        end
    end
    return Expr(x.head, (parse_iterabletable_call!(d, arg, syms, vars) for arg in x.args)...)
end

function _argnames(d, x::Expr)
    [_arg2string(d, s) for s in x.args[2:end] if not_kw(s)]
end

not_kw(x) = true
not_kw(x::Expr) = !(x.head in [:kw, :parameters])

_arg2string(d, x) = stringify(x)
function _arg2string(d, x::Expr)
    if x.head == :call && x.args[1] == :cols
        return :(reshape([StatPlots.compute_name($d, i) for i in $(x.args[2])], 1, :))
    elseif x.head == :call && x.args[1] == :hcat
        return hcat(stringify.(x.args[2:end])...)
    elseif x.head == :hcat
        return hcat(stringify.(x.args)...)
    else
        return stringify(x)
    end
end

stringify(x) = filter(t -> t != ':', string(x))

compute_name(df, i) = column_names(getiterator(df))[i]

function extract_columns_from_iterabletable(df, syms...)
    isiterabletable(df) || error("Only iterable tables are supported")
    iter = getiterator(df)
    name2index = Dict(zip(column_names(iter), 1:length(column_names(iter))))
    col_index = [isa(s, Integer) ? s : get(name2index, s, 0) for s in syms]
    cols = convert(Array{Any}, collect(syms))
    cols[col_index .!= 0] = create_columns_from_iterabletable(df, filter(t -> t != 0, col_index))[1]
    return Tuple(convert_missing.(t) for t in cols)
end

convert_missing(el) = el
convert_missing(el::DataValue{T}) where {T} = get(el, error("Missing data of type $T is not supported"))
convert_missing(el::DataValue{<:AbstractString}) = get(el, "")
convert_missing(el::DataValue{Symbol}) = get(el, Symbol())
convert_missing(el::DataValue{<:Real}) = get(convert(DataValue{Float64}, el), NaN)
