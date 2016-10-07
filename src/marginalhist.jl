@shorthands marginalhist

@recipe function f(::Type{Val{:marginalhist}}, plt::Plot; density = false)
    x, y = d[:x], d[:y]
    delete!(d, :density)

    # set up the subplots
    legend --> false
    link := :both
    grid --> false
    layout --> @layout [
        tophist           _
        hist2d{0.9w,0.9h} righthist
    ]

    # main histogram2d
    @series begin
        seriestype := :histogram2d
        right_margin --> 0mm
        top_margin --> 0mm
        subplot := 2
    end

    # these are common to both marginal histograms
    ticks := nothing
    guide := ""
    foreground_color_subplot := RGBA(0,0,0,0)
    fillcolor --> Plots.fg_color(d)
    linecolor --> Plots.fg_color(d)

    if density
        trim := true
        seriestype := :density
    else
        seriestype := :histogram
    end

    # upper histogram
    @series begin
        subplot := 1
        bottom_margin --> 0mm
        y := x
    end

    # right histogram
    @series begin
        orientation := :h
        subplot := 3
        left_margin --> 0mm
        y := y
    end
end

# # now you can plot like:
# marginalhist(rand(1000), rand(1000))
