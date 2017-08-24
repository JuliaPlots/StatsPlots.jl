"""
    `@given d x`

Convert every symbol in the expression `x` with the respective column in `d` if it exists.

If you want to avoid replacing the symbol, escape it with `^`.

`NA` values are replaced with `NaN` for columns of `Float64` and `""` or `Symbol()`
for strings and symbols respectively.
"""
macro given(d, x)
    esc(_given(d,x))
end

_given(d, x) = x

function _given(d, x::Expr)
    (x.head == :quote) && return :(StatPlots.select_column($d, $x))
    (x.head == :call) && x.args[1] == :^ && length(x.args) == 2 && return x.args[2]
    return Expr(x.head, _given.(d, x.args)...)
end


select_column(df, s) = haskey(df, s) ? convert_column(df[s]) : s


convert_column(col) = col

function convert_column(col::AbstractDataArray{T}) where T
    try
        convert(Array, col)
    catch
        error("Missing data of type $T is not supported")
    end
end

convert_column(col::AbstractDataArray{String})  = convert(Array, col, "")
convert_column(col::AbstractDataArray{Symbol})  = convert(Array, col, Symbol())
convert_column(col::AbstractDataArray{Float64}) = convert(Array, col, NaN)
