
# ---------------------------------------------------------------------------
# Dot Plot (strip plot, beeswarm)

@recipe function f(::Type{Val{:dotplot}}, x, y, z; mode = :none, side=:both, dy = 0.1)
    # if only y is provided, then x will be UnitRange 1:length(y)
    if typeof(x) <: AbstractRange
        if step(x) == first(x) == 1
            x = plotattributes[:series_plotindex]
        else
            x = [getindex(x, plotattributes[:series_plotindex])]
        end

        x = repeat([x], length(y))
    end
    x = Float64.(x)

    if mode != :none
        grouplabels = sort(collect(unique(x)))
        barwidth = plotattributes[:bar_width]
        barwidth == nothing && (barwidth = 0.8)

        if mode == :jitter
            points_x, points_y = zeros(0), zeros(0)

            for (i,grouplabel) in enumerate(grouplabels)
                # filter y
                groupy = y[filter(i -> _cycle(x,i) == grouplabel, 1:length(y))]

                center = Plots.discrete_value!(plotattributes[:subplot][:xaxis], grouplabel)[1]
                halfwidth = 0.5_cycle(barwidth, i)

                offsets = (rand(length(groupy)) .* 2 .- 1) .* halfwidth

                if side == :left
                    offsets = -abs.(offsets)
                elseif side == :right
                    offsets = abs.(offsets)
                end

                append!(points_y, groupy)
                append!(points_x, center .+ offsets)
            end

            x = points_x
            y = points_y
        elseif mode == :densityjitter
            0.0 ≤ dy ≤ 1.0 || throw(ArgumentError("$(:dy) must be in the range [0,1]"))
            points_x, points_y = zeros(0), zeros(0)

            for (i,grouplabel) in enumerate(grouplabels)
                # filter y
                groupy = y[filter(i -> _cycle(x,i) == grouplabel, 1:length(y))]

                # compute quantiles
                q2,q1 = quantile(groupy, [0.25, 0.75])

                center = Plots.discrete_value!(plotattributes[:subplot][:xaxis], grouplabel)[1]
                halfwidth = 0.5_cycle(barwidth, i)

                nearby = dy * abs(q2 - q1)
                nearbycount = [count((groupy .< (x + nearby)) .& (groupy .> (x - nearby))) for x ∈ groupy]

                localwidth = halfwidth / maximum(nearbycount)
                offsets = [(rand() * 2 - 1) * localwidth * x for x ∈ nearbycount]

                if side == :left
                    offsets = -abs.(offsets)
                elseif side == :right
                    offsets = abs.(offsets)
                end

                append!(points_y, groupy)
                append!(points_x, center .+ offsets)
            end

            x = points_x
            y = points_y
        elseif mode == :violinjitter
            points_x, points_y = zeros(0), zeros(0)

            for (i,grouplabel) in enumerate(grouplabels)
                # filter y
                groupy = y[filter(i -> _cycle(x,i) == grouplabel, 1:length(y))]

                center = Plots.discrete_value!(plotattributes[:subplot][:xaxis], grouplabel)[1]
                violinwidths, violincenters = violin_coords(groupy)

                # normalize widths
                halfwidth = 0.5_cycle(barwidth, i)
                violinwidths = halfwidth * violinwidths / Plots.ignorenan_maximum(violinwidths)

                uppercenters = findmin.([violincenters[violincenters .> yval] for yval ∈ groupy])
                lowercenters = findmax.([violincenters[violincenters .≤ yval] for yval ∈ groupy])
                upperbounds, lowerbounds = first.(uppercenters), first.(lowercenters)
                upperindexes, lowerindexes = last.(uppercenters), last.(lowercenters)
                upperwidths = [violinwidths[violincenters .> groupy[i]][upperindexes[i]] for i ∈ 1:length(groupy)]
                lowerwidths = [violinwidths[violincenters .≤ groupy[i]][lowerindexes[i]] for i ∈ 1:length(groupy)]
                δs = (upperbounds .- groupy) ./ (upperbounds .- lowerbounds)
                localwidths = upperwidths .* (1 .- δs) .+ lowerwidths .* δs
                offsets = (rand(length(groupy)) .* 2 .- 1) .* localwidths

                if side == :left
                    offsets = -abs.(offsets)
                elseif side == :right
                    offsets = abs.(offsets)
                end

                append!(points_y, groupy)
                append!(points_x, center .+ offsets)
            end

            x = points_x
            y = points_y
        end
    elseif mode == :nooverlap
        points_x, points_y = zeros(0), zeros(0)

        for (i,grouplabel) in enumerate(grouplabels)
            groupy = y[filter(i -> _cycle(x,i) == grouplabel, 1:length(y))]
            center = Plots.discrete_value!(plotattributes[:subplot][:xaxis], grouplabel)[1]
            offsets, yi = nooverlap_coords(groupy, side)
            append!(points_y, yi)
            append!(points_x, center .+ offsets)
        end

        x = points_x
        y = points_y
    end

    seriestype := :scatter
    x := x
    y := y
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
