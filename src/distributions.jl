
# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha = 0.01)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1-alpha)
    minval, maxval
end

# this "user recipe" adds a default x vector based on the distribution's μ and σ
@recipe f(dist::Distribution) = (dist, default_range(dist)...)

# this "type recipe" replaces any instance of a distribution with a function mapping xi to yi
@recipe function f{T<:Distribution}(::Type{T}, dist::T; func = pdf)
    xi -> func(dist, xi)
end
