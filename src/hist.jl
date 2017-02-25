
# ---------------------------------------------------------------------------
# density

@recipe function f(::Type{Val{:density}}, x, y, z; trim=false)
    newx, newy = violin_coords(y, trim=trim)
    if Plots.isvertical(d)
        newx, newy = newy, newx
    end
    x := newx
    y := newy
    seriestype := :path
    ()
end
Plots.@deps density path


# ---------------------------------------------------------------------------
# cumulative density

@recipe function f(::Type{Val{:cdensity}}, x, y, z; trim=false,
                   npoints = 200)
    newx, newy = violin_coords(y, trim=trim)

    if Plots.isvertical(d)
        newx, newy = newy, newx
    end

    newy = [sum(newy[1:i]) for i = 1:length(newy)] / sum(newy)

    x := newx
    y := newy
    seriestype := :path
    ()
end
Plots.@deps cdensity path

# ---------------------------------------------------------------------------
# bins

_bins_outline(edge, weights) = begin
    nbins = length(linearindices(weights))
    if length(linearindices(edge)) != nbins + 1
        error("Edge vector must be 1 longer than weight vector")
    end

    it_e, it_w = start(edge), start(weights)
    px, it_e = next(edge, it_e)
    py = zero(eltype(weights))

    npathpts = 2 * nbins + 2
    x = Vector{eltype(px)}(npathpts)
    y = Vector{eltype(py)}(npathpts)

    x[1], y[1] = px, py
    i = 2
    while (i < npathpts - 1)
        py, it_w = next(weights, it_w)
        x[i], y[i] = px, py
        i += 1
        px, it_e = next(edge, it_e)
        x[i], y[i] = px, py
        i += 1
    end
    assert(i == npathpts)
    x[end], y[end] = px, zero(py)

    (x, y)
end


@recipe function f(::Type{Val{:bins}}, x, y, z)
    edge, weights = x, y

    axis = d[:subplot][Plots.isvertical(d) ? :xaxis : :yaxis]

    xpts, ypts = _bins_outline(edge, weights)
    if !Plots.isvertical(d)
        xpts, ypts = ypts, xpts
    end

    # create a secondary series for the markers
    if d[:markershape] != :none
        @series begin
            seriestype := :scatter
            x := Plots.centers(edge)
            y := weights
            fillrange := nothing
            label := ""
            primary := false
            ()
        end
        markershape := :none
        xerror := :none
        yerror := :none
    end

    x := xpts
    y := ypts
    seriestype := :path
    ylims --> [0, 1.1 * maximum(weights)]
    ()
end
Plots.@deps bins path


# ---------------------------------------------------------------------------
# bins2d

@recipe function f(::Type{Val{:bins2d}}, x, y, z)
    edge_x, edge_y, weights = x, y, z.surf

    float_weights = float(weights)
    if is(float_weights, weights)
        float_weights = deepcopy(float_weights)
    end
    for (i, c) in enumerate(float_weights)
        if c == 0
            float_weights[i] = NaN
        end
    end

    x := Plots.centers(edge_x)
    y := Plots.centers(edge_y)
    z := Surface(float_weights)

    match_dimensions := true
    seriestype := :heatmap
    ()
end
Plots.@deps bins2d heatmap


# ---------------------------------------------------------------------------
# StatsBase.Histogram

@recipe function f{T, E}(h::StatsBase.Histogram{T, 1, E})
    edge, weights = h.edges[1], h.weights
    seriestype --> :bins

    if d[:seriestype] == :stephist
        seriestype := :bins
    end

    if d[:seriestype] == :scatter
        xerror --> diff(edge)/2
        (Plots.centers(edge), weights)
    else
        (edge, weights)
    end
end

@recipe function f{H <: StatsBase.Histogram}(hv::AbstractVector{H})
    for h in hv
        @series begin
            h
        end
    end
end


@recipe function f{T, E}(h::StatsBase.Histogram{T, 2, E})
    seriestype --> :bins2d
    (h.edges[1], h.edges[2], Surface(h.weights))
end
