
# ---------------------------------------------------------------------------
# empirical CDF

@recipe function f(ecdf::StatsBase.ECDF; npoints=nothing)
    seriestype --> :steppost
    legend --> :topleft
    xunique = unique(ecdf.sorted_values)
    if npoints !== nothing
        x = [-Inf; range(extrema(ecdf)...; length=npoints)]
    else
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
