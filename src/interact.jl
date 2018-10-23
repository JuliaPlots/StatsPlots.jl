function dataviewer(t; throttle = 0.1, nbins = 30, nbins_range = 1:100)
    (t isa AbstractObservable) || (t = Observable{Any}(t))

    columns_and_names = @map create_columns_from_iterabletable(getiterator(&t))

    names = @map (&columns_and_names)[2]

    dict = @map Dict((key, convert_missing.(val)) for (val, key)  in zip((&columns_and_names)...))
    x =  @nodeps dropdown(names, placeholder = "First axis", multiple = true)
    y =  @nodeps dropdown(names, placeholder = "Second axis", multiple = true)
    y_toggle = @nodeps togglecontent(y, value = false, label = "Second axis")
    plot_type = @nodeps dropdown(
        OrderedDict(
            "line"         => Plots.plot,
            "scatter"      => Plots.scatter,
            "bar"          => StatPlots.groupedbar,
            "boxplot"      => StatPlots.boxplot,
            "corrplot"     => StatPlots.corrplot,
            "cornerplot"   => StatPlots.cornerplot,
            "density"      => StatPlots.density,
            "histogram"    => StatPlots.histogram,
            "marginalhist" => StatPlots.marginalhist,
            "violin"       => StatPlots.violin
        ),
        placeholder = "Plot type")

    # Add bins if the plot allows it
    display_nbins = @map (&plot_type) in [corrplot, cornerplot, histogram, marginalhist] ? "block" : "none"
    nbins =  (@nodeps slider(nbins_range, extra_obs = ["display" => display_nbins], value = nbins, label = "number of bins"))
    nbins.scope.dom = Widgets.div(nbins.scope.dom, attributes = Dict("data-bind" => "style: {display: display}"))
    nbins_throttle = Observables.throttle(throttle, nbins)

    by = @nodeps dropdown(names, multiple = true, placeholder="Group by")
    by_toggle = @nodeps togglecontent(by, value = false, label = "Split data")
    plt = @nodeps button("plot")
    output = @map begin
        &plt
        if (plt[] == 0)
            plot()
        else
            x_cols = hcat(getindex.((&dict,), x[])...)
            has_y = y_toggle[] && !isempty(y[])
            has_by = by_toggle[] && !isempty(by[])
            y_cols = has_y ? [hcat(getindex.((&dict,), y[])...)] : []
            by_tup = Tuple(getindex(&dict, b) for b in by[])
            by_kwarg = has_by ? [(:group, NamedTuple{Tuple(by[])}(by_tup))] : []
            label = length(x[]) > 1 ? [(:label, x[])] :
                    (y_toggle[] && length(y[]) > 1) ? [(:label, y[])] : []
            densityplot1D = plot_type[] in [density, histogram]
            xlabel = (length(x[]) == 1 && (densityplot1D || has_y)) ? [(:xlabel, x[][1])] : []
            ylabel = (has_y && length(y[]) == 1) ? [(:ylabel, y[][1])] :
                     (!has_y && !densityplot1D && length(x[]) == 1) ? [(:ylabel, x[][1])] : []
            plot_type[](x_cols, y_cols...; nbins = &nbins_throttle, by_kwarg..., label..., xlabel..., ylabel...)
        end
    end
    wdg = Widget{:dataviewer}(["x" => x, "y" => y, "y_toggle" => y_toggle, "by" => by, "by_toggle" => by_toggle,
        "plot_type" => plot_type, "plot_button" => plt, "nbins" => nbins], output = output)
    @layout! wdg Widgets.div(
        Widgets.div(
            :x,
            :y_toggle,
            :plot_type,
            :by_toggle,
            :plot_button
        ),
        Widgets.div(style = Dict("width" => "3em")),
        Widgets.div(
            Widgets.observe(_),
            :nbins
        ),
        style = Dict("display" => "flex", "direction" => "row")
    )
end
