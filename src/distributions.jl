
# pick a nice default x range given a distribution
# TODO: account for min/max values of the distribution and maybe skew
function default_range(dist::Distribution, n = 4)
    μ, σ = mean(dist), std(dist)
    linspace(μ - n*σ,μ + n*σ, 100)
end

# this "user recipe" adds a default x vector based on the distribution's μ and σ
@recipe f(dist::Distribution) = (dist, default_range(dist))

# this "type recipe" replaces any instance of a distribution with a function mapping xi to yi
@recipe function f{T<:Distribution}(::Type{T}, dist::T; func = pdf)
    xi -> func(dist, xi)
end

