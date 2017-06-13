function border(x,y,rib)
    rib1, rib2 = if typeof(rib) <: Tuple
        first(rib), last(rib)
    else
        rib, rib
    end
    yline = vcat(y-rib1,(y+rib2)[end:-1:1])
    xline = vcat(x,x[end:-1:1])
    return xline, yline
end

@recipe function f(::Type{Val{:shadederror}},plt::AbstractPlot; shade = 0.)

    # set up the subplots
    x,y = plotattributes[:x],plotattributes[:y]
    xline, yline = border(x,y,shade)

    # line plot
    @series begin
        primary := true
        x := x
        y := y
        seriestype := :path
        ()
    end

    @series begin
        # shaded error bar
        primary := false
        fillrange := 0
        fillalpha --> 0.5
        linewidth := 0
        x := xline
        y := yline
        seriestype := :path
        ()
    end
end

@shorthands shadederror
