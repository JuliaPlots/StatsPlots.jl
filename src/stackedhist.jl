@userplot StackedHist

@recipe function f(h::StackedHist)
    arrays = reverse(h.args[1])
    elt = eltype(arrays)
    if elt <: Histogram 
        bins = arrays[1].edges[1] # edges is a tuple
        weights_ary = hcat([x.weights for x in arrays]...) #reverse so it stacks from top to bottom
    elseif elt <: Array{<:Real} # if raw datas
        # if no bins given, guess by fitting first data array
        bins = pop!(plotattributes, :bins, fit(Histogram, arrays[1]).edges[1])
        hist_wgts = pop!(plotattributes, :weights, [nothing]) |> reverse
        weights_ary = (
            hist_wgts == [nothing] ?
                [fit(Histogram, x, bins).weights for x in arrays] :
                [fit(Histogram, x, weights(y), bins).weights for (x, y) in zip(arrays, hist_wgts)]
            )
        weights_ary = hcat(weights_ary...)
            
    else
        error("args[1] should be collection of data arrays or of histograms")
    end
    
    stacked_data = abs.(reverse(cumsum(weights_ary, dims = 2), dims=2))
    ymin = 10^floor(log10(minimum(stacked_data)))
    stacked_data = vcat(stacked_data, zeros(1, size(stacked_data)[2])) # FIXME janky make the last bin visible
        
    fillrange --> 10^-6
    ylim --> (ymin>=1 ? (10^0, Inf) : (ymin/10, Inf))
    seriestype := :steppost
    bins, stacked_data
end
