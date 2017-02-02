
# ---------------------------------------------------------------------------
# Box Plot

notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

@recipe function f(::Type{Val{:boxplot}}, x, y, z; notch=false, range=1.5, outliers=true)
    xsegs, ysegs = Segments(), Segments()
    glabels = sort(collect(unique(x)))
    warning = false
    outliers_x, outliers_y = zeros(0), zeros(0)
    bw = d[:bar_width]
    bw == nothing && (bw = 0.8)
    for (i,glabel) in enumerate(glabels)
        # filter y
        values = y[filter(i -> cycle(x,i) == glabel, 1:length(y))]

        # compute quantiles
        q1,q2,q3,q4,q5 = quantile(values, linspace(0,1,5))

        # notch
        n = notch_width(q2, q4, length(values))

        # warn on inverted notches?
        if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
            warn("Boxplot's notch went outside hinges. Set notch to false.")
            warning = true # Show the warning only one time
        end

        # make the shape
        center = Plots.discrete_value!(d[:subplot][:xaxis], glabel)[1]
        hw = 0.5cycle(bw, i)
        l, m, r = center - hw, center, center + hw

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
            q1, q5 = extrema(inside)
        end

        # Box
        if notch
            push!(xsegs, m, l, r, m, m)       # lower T
            push!(xsegs, l, l, L, R, r, r, l) # lower box
            push!(xsegs, l, l, L, R, r, r, l) # upper box
            push!(xsegs, m, l, r, m, m)       # upper T

            push!(ysegs, q1, q1, q1, q1, q2)             # lower T
            push!(ysegs, q2, q3-n, q3, q3, q3-n, q2, q2) # lower box
            push!(ysegs, q4, q3+n, q3, q3, q3+n, q4, q4) # upper box
            push!(ysegs, q5, q5, q5, q5, q4)             # upper T
        else
            push!(xsegs, m, l, r, m, m)         # lower T
            push!(xsegs, l, l, r, r, l)         # lower box
            push!(xsegs, l, l, r, r, l)         # upper box
            push!(xsegs, m, l, r, m, m)         # upper T

            push!(ysegs, q1, q1, q1, q1, q2)    # lower T
            push!(ysegs, q2, q3, q3, q2, q2)    # lower box
            push!(ysegs, q4, q3, q3, q4, q4)    # upper box
            push!(ysegs, q5, q5, q5, q5, q4)    # upper T
        end
    end
    
    # Outliers
    if outliers
        @series begin
            seriestype  := :scatter
            markershape := :circle
            markercolor --> d[:fillcolor]
            markeralpha --> d[:fillalpha]
            markerstrokecolor --> d[:linecolor]
            markerstrokealpha --> d[:linealpha]
            fillrange   := nothing
            x           := outliers_x
            y           := outliers_y
            primary     := false
            ()
        end
    end

    seriestype := :shape
    x := xsegs.pts
    y := ysegs.pts
    ()
end
Plots.@deps boxplot shape scatter
