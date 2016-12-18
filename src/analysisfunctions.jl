function _locreg(df, xaxis::LinSpace, x, y; kwargs...)
    model = Loess.loess(convert(Array{Float64,1},df[x]),convert(Array{Float64,1},df[y]); kwargs...)
    predicted = fill(NaN,length(xaxis))
    within = minimum(df[x]).< xaxis .<maximum(df[x])
    predicted[within] = Loess.predict(model,collect(xaxis)[within])
    return predicted
end

function _locreg(df, xaxis, x,  y)
  ymean = by(df, x) do dd
      DataFrame(m = mean(dd[y]))
  end
  aux = DataFrame()
  aux[x] = xaxis
  ymean_extended = join(aux, ymean, on = x, kind = :left)
  sort!(ymean_extended, cols = [x])
  return convert(Array,ymean_extended[:m],NaN)
end

_density(df,xaxis::LinSpace, x; kwargs...) = pdf(KernelDensity.kde(df[x]; kwargs...),xaxis)

function _density(df,xaxis, x)
    xhist = by(df, x) do dd
        DataFrame(length = size(dd,1))
    end
    aux = DataFrame()
    aux[x] = xaxis
    xhist_extended = sort!(join(aux, xhist, on = x, kind = :left),cols = [x])
    return convert(Array, xhist_extended[:length], 0)/size(df,1)
end

_cumulative(df, xaxis, x) = ecdf(df[x])(xaxis)
#
# function cumulative(df, x, xaxis)
#   vect = kdensity(df, x, xaxis)
#   return cumsum(vect)
# end
