
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

@userplot ECDFPlot
recipetype(::Val{:ecdfplot}, args...) = ECDFPlot(args)
@recipe function f(p::ECDFPlot)
    x = p.args[1]
    if !isa(x, StatsBase.ECDF)
        x = StatsBase.ecdf(x)
    end
    x
end
