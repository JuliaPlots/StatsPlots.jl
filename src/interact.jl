@widget wdg function interactstats(t; throttle = 0.1)
    cols, colnames = create_columns_from_iterabletable(getiterator(t))
    :names = colnames
    d = Dict((key, convert_missing.(val)) for (key, val)  in zip(colnames, cols))
    :x =  @nodeps dropdown(:names, placeholder = "First axis", multiple = true)
    :y =  @nodeps dropdown(:names, placeholder = "Second axis", multiple = true)
    wdg[:y_toggle] = @nodeps togglecontent(wdg[:y], value = false, label = "Second axis")
    :plot_type = @nodeps dropdown(
        OrderedDict(
            "line"         => plot,
            "scatter"      => scatter,
            "bar"          => groupedbar,
            "boxplot"      => boxplot,
            "corrplot"     => corrplot,
            "cornerplot"   => cornerplot,
            "density"      => density,
            "histogram"    => histogram,
            "marginalhist" => marginalhist,
            "violin"       => violin
        ),
        placeholder = "Plot type")
    :nbins =  @nodeps slider(1:100, value = 30, label = "number of bins")
    :nbins_throttle = Observables.throttle(throttle, :nbins)
    :by = @nodeps dropdown(:names, multiple = true, placeholder="Group by")
    wdg[:by_toggle] = @nodeps togglecontent(wdg[:by], value = false, label = "Split data")
    :plot = @nodeps button("plot")
    @output! wdg begin
        $(:plot)
        y = (:y_toggle[] && !isempty(:y[])) ? [:y[]] : []
        by = (:by_toggle[] && !isempty(:by[])) ? [(^(:group), :by[])] : []
        if (:plot[] == 0)
            plot()
        else
            x = hcat(getindex.(d, :x[])...)
            y = (:y_toggle[] && !isempty(:y[])) ? [hcat(getindex.(d, :y[])...)] : []
            by = (:by_toggle[] && !isempty(:by[])) ? [(^(:group), Tuple(getindex.(d, :by[])))] : []
            :plot_type[](x, y...; nbins = $(:nbins_throttle), by...)
        end
    end
    @layout! wdg Widgets.div(
        Widgets.div(
            :x,
            :y_toggle,
            :plot_type,
            :by_toggle,
            :plot,
            className = "column is-4"
        ),
        Widgets.div(
            _.output,
            :nbins,
            className = "column is-8"
        ),
        className = "columns"
    )
end
