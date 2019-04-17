
# ---------------------------------------------------------------------------
# Dot Plot

@recipe function f(::Type{Val{:dotplot}}, x, y, z)
    # if only y is provided, then x will be UnitRange 1:length(y)
    if typeof(x) <: AbstractRange
        if step(x) == first(x) == 1
            x = plotattributes[:series_plotindex]
        else
            x = [getindex(x, plotattributes[:series_plotindex])]
        end
    end
    glabels = sort(collect(unique(x)))
    warning = false
    points_x, points_y = zeros(0), zeros(0)
    bw = plotattributes[:bar_width]
    bw == nothing && (bw = 0.8)
    for (i,glabel) in enumerate(glabels)
        # filter y
        values = y[filter(i -> _cycle(x,i) == glabel, 1:length(y))]

        # compute quantiles
        q1,q2,q3,q4,q5 = quantile(values, Base.range(0,stop=1,length=5))

        # make the shape
        center = Plots.discrete_value!(plotattributes[:subplot][:xaxis], glabel)[1]
        hw = 0.5_cycle(bw, i) # Box width

        nearby = 0.01 * abs(q5 - q1)
        countnear = [count((values .< (x + nearby)) .& (values .> (x - nearby))) for x ∈ values]

        pw = hw / maximum(countnear)
        offsets = [(rand() * 2 - 1) * pw * x for x ∈ countnear]
        append!(points_y, values)
        append!(points_x, center .+ offsets)
    end

    seriestype  := :scatter
    x := points_x
    y := points_y
    ()
end
Plots.@deps dotplot scatter
Plots.@shorthands dotplot


# ------------------------------------------------------------------------------
# Grouped dotplot

@userplot GroupedDotplot

recipetype(::Val{:groupeddotplot}, args...) = GroupedDotplot(args)

@recipe function f(g::GroupedDotplot; spacing = 0.1)
    x, y = grouped_xy(g.args...)

    # extract xnums and set default bar width.
    # might need to set xticks as well
    x = if eltype(x) <: Number
        bar_width --> (0.8 * mean(diff(x)))
        float.(x)
    else
        bar_width --> 0.8
        ux = unique(x)
        xnums = [findfirst(isequal(xi), ux) for xi in x] .- 0.5
        xticks --> (eachindex(ux) .- 0.5, ux)
        xnums
    end

    # shift x values for each group
    group = get(plotattributes, :group, nothing)
    if group != nothing
        gb = Plots.extractGroupArgs(group)
        labels, idxs = getfield(gb, 1), getfield(gb, 2)
        n = length(labels)
        bws = plotattributes[:bar_width] / n
        bar_width := bws * clamp(1 - spacing, 0, 1)
        for i in 1:n
            groupinds = idxs[i]
            Δx = _cycle(bws, i) * (i - (n + 1) / 2)
            x[groupinds] .+= Δx
        end
    end

    seriestype := :dotplot
    x, y
end

Plots.@deps groupeddotplot dotplot
