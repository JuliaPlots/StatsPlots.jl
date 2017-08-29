"""
    `@df d x`

Convert every symbol in the expression `x` with the respective column in `d` if it exists.

If you want to avoid replacing the symbol, escape it with `^`.

`NA` values are replaced with `NaN` for columns of `Float64` and `""` or `Symbol()`
for strings and symbols respectively.
"""
macro df(d, x)
    argnames = _argnames(d, x)
    plot_call = _df(d,x)
    for i in 1:length(argnames)
        if isa(argnames[i], Expr) || isa(argnames[i], AbstractArray)
            insert_kw!(plot_call, :label, argnames[i])
        else
            insert_kw!(plot_call, kw_list[i], argnames[i])
        end
    end
    esc(plot_call)
end

_df(d, x) = x

function _df(d, x::Expr)
    (x.head == :quote) && return :(StatPlots.select_column($d, $x))
    if x.head == :call
        x.args[1] == :^ && length(x.args) == 2 && return x.args[2]
        x.args[1] == :cols && return :(hcat((convert_column($d[i]) for i in $(x.args[2]))...))
    end
    return Expr(x.head, _df.(d, x.args)...)
end

function insert_kw!(x::Expr, s::Symbol, v)
    index = x.args[2].head == :parameters ? 3 : 2
    x.args = vcat(x.args[1:index-1], Expr(:kw, s, v), x.args[index:end])
end

const kw_list = [:xlabel, :ylabel, :zlabel]

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


select_column(df, s) = haskey(df, s) ? convert_column(df[s]) : s

convert_column(col) = col

function convert_column(col::AbstractDataArray{T}) where T
    try
        convert(Array, col)
    catch
        error("Missing data of type $T is not supported")
    end
end

convert_column(col::AbstractDataArray{<:AbstractString}) = convert(Array, col, "")
convert_column(col::AbstractDataArray{Symbol}) = convert(Array, col, Symbol())
convert_column(col::AbstractDataArray{<:Real}) = convert(Array, convert(DataArray{Float64}, col), NaN)
