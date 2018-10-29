
# ---------------------------------------------------------------------------
# Box Plot

notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

@recipe function f(::Type{Val{:boxplot}}, x, y, z; notch=false, range=1.5, outliers=true, whisker_width=:match)
    # if only y is provided, then x will be UnitRange 1:length(y)

    if typeof(x) <: AbstractRange
        if step(x) == first(x) == 1
            x = plotattributes[:series_plotindex]
        else
            x = [getindex(x, plotattributes[:series_plotindex])]
        end
    end
    xsegs, ysegs = Segments(), Segments()
    glabels = sort(collect(unique(x)))
    warning = false
    outliers_x, outliers_y = zeros(0), zeros(0)
    bw = plotattributes[:bar_width]
    bw == nothing && (bw = 0.8)
    @assert whisker_width == :match || whisker_width >= 0 "whisker_width must be :match or a positive number"
    ww = whisker_width == :match ? bw : whisker_width

    isa(plotattributes[:group], Nothing) ? ngroups = 1 : ngroups = length(unique(plotattributes[:group]))
    thisgroup = plotattributes[:series_plotindex]

    outercenter = 0.5 * bw - bw / 2ngroups
    offsets = collect(-outercenter:(bw / ngroups):outercenter)
    bw = bw / ngroups
    ww = ww / ngroups

    for (i,glabel) in enumerate(glabels)
        # filter y
        values = y[filter(i -> _cycle(x,i) == glabel, 1:length(y))]
        # compute quantiles
        q1,q2,q3,q4,q5 = quantile(values, Base.range(0,stop=1,length=5))

        # notch
        n = notch_width(q2, q4, length(values))

        # warn on inverted notches?
        if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
            warn("Boxplot's notch went outside hinges. Set notch to false.")
            warning = true # Show the warning only one time
        end

        # make the shape
        center = Plots.discrete_value!(plotattributes[:subplot][:xaxis], glabel)[1]
        center = center + offsets[thisgroup]

        hw = 0.5_cycle(bw, i) # Box width
        HW = 0.5_cycle(ww, i) # Whisker width
        l, m, r = center - hw, center, center + hw
        lw, rw = center - HW, center + HW

        # internal nodes for notches
        L, R = center - 0.5 * hw, center + 0.5 * hw

        # outliers
        if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
            limit = range*(q4-q2)
            inside = Float64[]
            for value in values
                if (value < (q2 - limit)) || (value > (q4 + limit))
                    if outliers
                        push!(outliers_y, value)
                        push!(outliers_x, center)
                    end
                else
                    push!(inside, value)
                end
            end
            # change q1 and q5 to show outliers
            # using maximum and minimum values inside the limits
            q1, q5 = Plots.ignorenan_extrema(inside)
        end

        # Box
        if notch
            push!(xsegs, m, lw, rw, m, m)       # lower T
            push!(xsegs, l, l, L, R, r, r, l) # lower box
            push!(xsegs, l, l, L, R, r, r, l) # upper box
            push!(xsegs, m, lw, rw, m, m)       # upper T

            push!(ysegs, q1, q1, q1, q1, q2)             # lower T
            push!(ysegs, q2, q3-n, q3, q3, q3-n, q2, q2) # lower box
            push!(ysegs, q4, q3+n, q3, q3, q3+n, q4, q4) # upper box
            push!(ysegs, q5, q5, q5, q5, q4)             # upper T
        else
            push!(xsegs, m, lw, rw, m, m)         # lower T
            push!(xsegs, l, l, r, r, l)         # lower box
            push!(xsegs, l, l, r, r, l)         # upper box
            push!(xsegs, m, lw, rw, m, m)         # upper T

            push!(ysegs, q1, q1, q1, q1, q2)    # lower T
            push!(ysegs, q2, q3, q3, q2, q2)    # lower box
            push!(ysegs, q4, q3, q3, q4, q4)    # upper box
            push!(ysegs, q5, q5, q5, q5, q4)    # upper T
        end
    end

    # To prevent linecolor equal to fillcolor (It makes the median visible)
    if plotattributes[:linecolor] == plotattributes[:fillcolor]
        plotattributes[:linecolor] = plotattributes[:markerstrokecolor]
    end

    # Outliers
    if outliers
		primary := false
        @series begin
            seriestype  := :scatter
		    if get!(plotattributes, :markershape, :circle) == :none
	            	plotattributes[:markershape] = :circle
		    end

            fillrange   := nothing
            x           := outliers_x
            y           := outliers_y
            primary     := true
            ()
        end
    end

    seriestype := :shape
    x := xsegs.pts
    y := ysegs.pts
    ()
end
Plots.@deps boxplot shape scatter
