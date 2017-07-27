
# pick a nice default x range given a distribution
function default_range(dist::Distribution, n = 4)
    μ, σ = mean(dist), std(dist)
    max(minimum(dist), μ - n*σ),
             min(maximum(dist), μ + n*σ)
end

# this "user recipe" adds a default x vector based on the distribution's μ and σ
@recipe f(dist::Distribution) = (dist, default_range(dist)...)

# this "type recipe" replaces any instance of a distribution with a function mapping xi to yi
@recipe function f{T<:Distribution}(::Type{T}, dist::T; func = pdf)
    xi -> func(dist, xi)
end
