
# ---------------------------------------------------------------------------
# empirical CDF

@recipe function f(ecdf::StatsBase.ECDF)
    seriestype --> :path
    linetype := :steppost
    legend --> :topleft
    x = [ecdf.sorted_values[1]; ecdf.sorted_values]
    if :weights in propertynames(ecdf) && !isempty(ecdf.weights)
         # support StatsBase versions >v0.32.0
        y = [0; cumsum(ecdf.weights) ./ sum(ecdf.weights)]
    else
        y = range(0, 1; length = length(x))
    end
    x, y
end

@userplot ECDFPlot
recipetype(::Val{:ecdfplot}, args...) = ECDFPlot(args)
@recipe f(p::ECDFPlot) = ecdf(p.args[1])
