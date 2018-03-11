"""
    `@df d x`

Convert every symbol in the expression `x` with the respective column in `d` if it exists.

If you want to avoid replacing the symbol, escape it with `^`.

`NA` values are replaced with `NaN` for columns of `Float64` and `""` or `Symbol()`
for strings and symbols respectively.

`x` can be either a plot command or a block of plot commands.
"""
macro df(d, x)
    esc(df_helper(d, x))
end

"""
    `@df x`

Curried version of `@df d x`. Outputs an anonymous function `d -> @df d x`.
"""
macro df(x)
    i = gensym()
    esc(Expr(:(->), i, df_helper(i, x))
end

function df_helper(d, x)
    if isa(x, Expr) && x.head == :block
        commands = [:(@df($d, $x)) for xx in x.args if !(isa(xx, Expr) && xx.head == :line)]
        return Expr(:block, commands...)
    elseif isa(x, Expr) && x.head == :call
        syms = Any[]
        vars = Symbol[]
        plot_call = parse_iterabletable_call!(d, x, syms, vars)
        compute_vars = Expr(:(=), Expr(:tuple, vars...),
            Expr(:call, :(StatPlots.extract_columns_from_iterabletable), d, syms...))
        argnames = _argnames(d, x)
        if (length(plot_call.args) >= 2) && isa(plot_call.args[2], Expr) && (plot_call.args[2].head == :parameters)
            label_plot_call = Expr(:call, :(StatPlots.add_label), plot_call.args[2], argnames,
                plot_call.args[1], plot_call.args[3:end]...)
        else
            label_plot_call = Expr(:call, :(StatPlots.add_label), argnames, plot_call.args...)
        end
        return Expr(:block, compute_vars, label_plot_call)
    else
        error("Second argument can only be a block or function call")
    end
end

parse_iterabletable_call!(d, x, syms, vars) = x

function parse_iterabletable_call!(d, x::Expr, syms, vars)
    if x.head == :. && length(x.args) == 2
        isa(x.args[2], Expr) && (x.args[2].head == :quote) && return x
    elseif x.head == :quote
        new_var = gensym(x.args[1])
        push!(syms, x)
        push!(vars, new_var)
        return new_var
    elseif x.head == :call
        x.args[1] == :^ && length(x.args) == 2 && return x.args[2]
        if x.args[1] == :cols
            range = x.args[2]
            new_vars = gensym("range")
            push!(syms, range)
            push!(vars, new_vars)
            return new_vars
        end
    end
    return Expr(x.head, (parse_iterabletable_call!(d, arg, syms, vars) for arg in x.args)...)
end

function _argnames(d, x::Expr)
    Expr(:vect, [_arg2string(d, s) for s in x.args[2:end] if not_kw(s)]...)
end

not_kw(x) = true
not_kw(x::Expr) = !(x.head in [:kw, :parameters])

function insert_kw!(x::Expr, s::Symbol, v)
    index = isa(x.args[2], Expr) && x.args[2].head == :parameters ? 3 : 2
    x.args = vcat(x.args[1:index-1], Expr(:kw, s, v), x.args[index:end])
end

_arg2string(d, x) = stringify(x)
function _arg2string(d, x::Expr)
    if x.head == :call && x.args[1] == :cols
        return :(StatPlots.compute_name($d, $(x.args[2])))
    elseif x.head == :call && x.args[1] == :hcat
        return hcat(stringify.(x.args[2:end])...)
    elseif x.head == :hcat
        return hcat(stringify.(x.args)...)
    else
        return stringify(x)
    end
end

stringify(x) = filter(t -> t != ':', string(x))

compute_name(df, i::Int) = column_names(getiterator(df))[i]
compute_name(df, i::Symbol) = i
compute_name(df, i) = reshape([compute_name(df, ii) for ii in i], 1, :)

function add_label(argnames, f, args...; kwargs...)
    i = findlast(t -> isa(t, Expr) || isa(t, AbstractArray), argnames)
    if (i == 0)
        return f(args...; kwargs...)
    else
        return f(label = argnames[i], args...; kwargs...)
    end
end

get_col_from_dict(s::Int, col_dict, name2index) = col_dict[s]
get_col_from_dict(s::Symbol, col_dict, name2index) =
    haskey(name2index, s) ? col_dict[name2index[s]] : s

get_col_from_dict(s, col_dict, name2index) =
    hcat(get_col_from_dict.(s, col_dict, name2index)...)

function extract_columns_from_iterabletable(df, syms...)
    isiterabletable(df) || error("Only iterable tables are supported")
    iter = getiterator(df)
    name2index = Dict(zip(column_names(iter), 1:length(column_names(iter))))

    col_indices = union(Iterators.filter(t -> t != 0,
        (isa(s, Integer) ? s : get(name2index, s, 0) for s in vcat(syms...))))
    col_values = create_columns_from_iterabletable(df, col_indices)[1]
    col_dict = Dict(zip(col_indices, [convert_missing.(t) for t in col_values]))

    return Tuple(get_col_from_dict(s, col_dict, name2index) for s in syms)
end

convert_missing(el) = el
convert_missing(el::DataValue{T}) where {T} = isnull(el) ? error("Missing data of type $T is not supported") : el.value
convert_missing(el::DataValue{<:AbstractString}) = get(el, "")
convert_missing(el::DataValue{Symbol}) = get(el, Symbol())
convert_missing(el::DataValue{<:Real}) = get(convert(DataValue{Float64}, el), NaN)
