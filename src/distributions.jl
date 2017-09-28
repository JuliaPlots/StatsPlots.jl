
# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha = 0.0001)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1-alpha)
    minval, maxval
end

# this "user recipe" adds a default x vector based on the distribution's μ and σ
@recipe f(dist::Distribution) = (dist, default_range(dist)...)

# this "type recipe" replaces any instance of a distribution with a function mapping xi to yi
@recipe function f(::Type{T}, dist::T; func = pdf) where T<:Distribution
    xi -> func(dist, xi)
end

#-----------------------------------------------------------------------------
# qqplots

@recipe function f(h::QQPair)
    seriestype --> :scatter
    legend --> false
    h.qx, h.qy
end

@userplot QQPlot
@recipe f(h::QQPlot) = qqbuild(h.args[1], h.args[2])

@userplot QQNorm
@recipe f(h::QQNorm) = qqbuild(Normal(), h.args[1])
