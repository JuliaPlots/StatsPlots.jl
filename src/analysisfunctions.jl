nlreg(df, x, xaxis::LinSpace, y) = KernelEstimator.locallinear(df[x], df[y]; xeval = xaxis)
nlreg(df, x, xaxis::LinSpace, y, bw) = KernelEstimator.locallinear(df[x], df[y]; xeval = xaxis, h = bw)

function nlreg(df, x, xaxis, y)
  ymean = by(df, x) do dd
      DataFrame(m = mean(dd[y]))
  end
  aux = DataFrame()
  aux[x] = xaxis
  ymean_extended = join(aux, ymean, on = x, kind = :left)
  sort!(ymean_extended, cols = [x])
  return ymean_extended[:m]
end

kdensity(df,x,xaxis::LinSpace) = KernelEstimator.kerneldensity(df[x]; xeval = xaxis)
kdensity(df,x,xaxis::LinSpace, bw) = KernelEstimator.kerneldensity(df[x]; xeval = xaxis, h = bw)

function kdensity(df,x,xaxis)
    xhist = by(df, x) do dd
        DataFrame(length = size(dd,1))
    end
    aux = DataFrame()
    aux[x] = xaxis
    xhist_extended = sort!(join(aux, xhist, on = x, kind = :left),cols = [x])
    return convert(Array, xhist_extended[:length], 0)/size(df,1)
end

cumulative(df, x, xaxis::LinSpace) = ecdf(df[x])(xaxis)

function cumulative(df, x, xaxis)
  vect = kdensity(df, x, xaxis)
  return cumsum(vect)
end
