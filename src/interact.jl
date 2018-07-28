@widget wdg function interactstats(t; throttle = 0.1)
    :names = StatPlots.column_names(StatPlots.getiterator(t))
    :x =  @nodeps dropdown(:names, placeholder = "First axis", multiple = true)
    :y =  @nodeps dropdown(:names, placeholder = "Second axis", multiple = true)
    wdg[:y_toggle] = @nodeps togglecontent(wdg[:y], value = false, label = "Second axis")
    :plot_type = @nodeps dropdown(
        [
            plot,
            scatter,
            groupedbar,
            boxplot,
            corrplot,
            cornerplot,
            density,
            histogram,
            marginalhist,
            violin
        ],
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
            @df t :plot_type[](:x[], y..., by..., nbins = $(:nbins_throttle))
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
