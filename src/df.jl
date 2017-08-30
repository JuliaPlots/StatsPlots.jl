"""
    `@df d x`

Convert every symbol in the expression `x` with the respective column in `d` if it exists.

If you want to avoid replacing the symbol, escape it with `^`.

`NA` values are replaced with `NaN` for columns of `Float64` and `""` or `Symbol()`
for strings and symbols respectively.
"""
macro df(d, x)
    esc(_df(d,x))
end

_df(d, x) = x

function _df(d, x::Expr)
    (x.head == :quote) && return :(StatPlots.select_column($d, $x))
    if x.head == :call
        x.args[1] == :^ && length(x.args) == 2 && return x.args[2]
        x.args[1] == :cols && return :(hcat((StatPlots.select_column($d, i) for i in $(x.args[2]))...))
    end
    return Expr(x.head, _df.(d, x.args)...)
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

function select_column(df, s)
    v = try
            [getfield(i, s) for i in getiterator(df)]
        catch
            s
        end
    return convert_column(v)
end

convert_column(col) = col

function convert_column(col::AbstractArray{T}) where T<:DataValue
    try
        get.(col)
    catch
        error("Missing data of type $T is not supported")
    end
end

convert_column(col::AbstractArray{DataValue{<:AbstractString}}) = get.(col, "")
convert_column(col::AbstractArray{DataValue{Symbol}}) = get.(col, Symbol())
convert_column(col::AbstractDataArray{DataValue{<:Real}}) = get.(convert.(DataValue{Float64}, col), NaN)
