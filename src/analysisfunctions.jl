function extend_axis(df::AbstractDataFrame, xlabel, ylabel, xaxis, val)
    aux = DataFrame()
    aux[xlabel] = xaxis
    extended = join(aux, df, on = xlabel, kind = :left)
    sort!(extended, cols = [xlabel])
    return convert(Array, extended[ylabel], val)
end

function extend_axis(xsmall, ysmall, xaxis, val)
    df = DataFrame(x = xsmall, y = ysmall)
    return extend_axis(df, :x, :y, xaxis, val)
end

"""
    `_locreg(df, xaxis::LinSpace, x, y; kwargs...)`

Apply loess regression, training the regressor with `x` and `y` and
predicting `xaxis`
"""
function _locreg(df, xaxis::LinSpace, x, y; kwargs...)
    predicted = fill(NaN,length(xaxis))
    within = minimum(df[x]).< xaxis .< maximum(df[x])
    if any(within)
        model = Loess.loess(convert(Vector{Float64},df[x]),convert(Vector{Float64},df[y]); kwargs...)
        predicted[within] = Loess.predict(model,xaxis[within])
    end
    return predicted
end


"""
    `_locreg(df, xaxis, x, y; kwargs...)`

In the discrete case, the function computes the conditional expectation of `y` for
a given value of `x`
"""
function _locreg(df, xaxis, x,  y)
  ymean = by(df, x) do dd
      DataFrame(m = mean(dd[y]))
  end
  return extend_axis(ymean, x, :m, xaxis, NaN)
end

"""
    `_density(df,xaxis::LinSpace, x; kwargs...)`

Kernel density of `x`, computed along `xaxis`
"""
_density(df,xaxis::LinSpace, x; kwargs...) = pdf(KernelDensity.kde(df[x]; kwargs...),xaxis)

"""
    `_density(df, xaxis, x)`

Normalized histogram of `x` (which is discrete: every value is its own bin)
"""
function _density(df,xaxis, x)
    xhist = by(df, x) do dd
        DataFrame(length = size(dd,1)/size(df,1))
    end
    return extend_axis(xhist, x, :length, xaxis, 0.)
end

"""
    `_cumulative(df, xaxis, x) = ecdf(df[x])(xaxis)`

Cumulative density function of `x`, computed along `xaxis`
"""
_cumulative(df, xaxis, x) = ecdf(df[x])(xaxis)
#
# function cumulative(df, x, xaxis)
#   vect = kdensity(df, x, xaxis)
#   return cumsum(vect)
# end
