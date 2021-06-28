
# ---------------------------------------------------------------------------
# empirical CDF

function allsortedunique(x)
    return all(eachindex(x)[1:end-1]) do i
        @inbounds x[i] < x[i + 1]
    end
end

@recipe function f(ecdf::StatsBase.ECDF; npoints=nothing)
    seriestype --> :steppost
    legend --> :topleft
    if npoints !== nothing
        x = [-Inf; range(extrema(ecdf)...; length=npoints)]
    else
        xnonunique = ecdf.sorted_values
        xunique = allsortedunique(xnonunique) ? xnonunique : unique(xnonunique)
        x = [-Inf; xunique]
    end
    y = ecdf(x)
    x, y
end


"""
    ecdfplot(x; npoints = nothing)

Plot the empirical cumulative distribution function (ECDF) of `x`.

By default, the ECDF is evaluated at the unique points in `x`. If `npoints` is provided,
it is instead evaluated on a uniform grid of length `npoints` between the extrema of `x`.
This is useful when `x` is large.

```julia-repl
julia> ecdfplot(randn(100))

julia> ecdfplot(randn(1_000_000); npoints=100, seriestype=:path)
```
"""
@userplot ECDFPlot

recipetype(::Val{:ecdfplot}, args...) = ECDFPlot(args)
@recipe function f(p::ECDFPlot)
    x = p.args[1]
    if !isa(x, StatsBase.ECDF)
        x = StatsBase.ecdf(x)
    end
    x
end
