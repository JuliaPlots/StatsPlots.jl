@widget wdg function dataviewer(t::Observable; throttle = 0.1, nbins = 30, nbins_range = 1:100)
    (t isa Observable) || (t = Observable{Any}(t))
    :table = t
    :columns_and_names = create_columns_from_iterabletable(getiterator($(:table)))

    # hack before dropdown is set to remember value on InteractBase
    :names = Observable{Any}(:columns_and_names[][2])
    on(wdg[:columns_and_names]) do val
        (wdg[:names][] != val[2]) && (wdg[:names][] = val[2])
    end

    :dict = Dict((key, convert_missing.(val)) for (val, key)  in zip($(:columns_and_names)...))
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

    # Add bins if the plot allows it
    :display_nbins = $(:plot_type) in [corrplot, cornerplot, histogram, marginalhist] ? "block" : "none"
    :nbins =  (@nodeps slider(nbins_range, extra_obs = ["display" => :display_nbins], value = nbins, label = "number of bins"))
    wdg[:nbins].scope.dom = Widgets.div(wdg[:nbins].scope.dom, attributes = Dict("data-bind" => "style: {display: display}"))
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
            x = hcat(getindex.($(:dict), :x[])...)
            has_y = (:y_toggle[] && !isempty(:y[]))
            y = has_y ? [hcat(getindex.($(:dict), :y[])...)] : []
            by = (:by_toggle[] && !isempty(:by[])) ? [(^(:group), NamedTuples.make_tuple(:by[])(getindex.($(:dict), :by[])...))] : []
            label = length(:x[]) > 1 ? [(^(:label), :x[])] :
                    (:y_toggle[] && length(:y[]) > 1) ? [(^(:label), :y[])] :
                    isempty(by) ? [(^(:label), "")] : []
            densityplot1D = :plot_type[] in [density, histogram]
            xlabel = (length(:x[]) == 1 && (densityplot1D || has_y)) ? [(^(:xlabel), :x[][1])] : []
            ylabel = (:y_toggle[] && length(:y[]) == 1) ? [(^(:ylabel), :y[][1])] :
                     (!has_y && !densityplot1D && length(:x[]) == 1) ? [(^(:ylabel), :x[][1])] : []
            :plot_type[](x, y...; nbins = $(:nbins_throttle), by..., label..., xlabel..., ylabel...)
        end
    end
    @layout! wdg Widgets.div(
        Widgets.div(
            :x,
            :y_toggle,
            :plot_type,
            :by_toggle,
            :plot
        ),
        Widgets.div(style = Dict("width" => "3em")),
        Widgets.div(
            _.output,
            :nbins
        ),
        style = Dict("display" => "flex", "direction" => "row")
    )
end
