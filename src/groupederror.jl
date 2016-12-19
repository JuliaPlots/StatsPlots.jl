type GroupedError
    x
    y
    err
    group
    xaxis
end

get_axis(column::PooledDataArray) = sort!(unique(column))
get_axis(column::AbstractArray) = linspace(minimum(column),maximum(column),200)

# f is the function used to analyze dataset: define it as nan when it is not defined,
# the input is: dataframe used, points chosen on the x axis, x (and maybe y) column labels
# the output is the y value for the given xvalues

function get_mean_sem(trend,variation, f, df, population, args...; xaxis = false, kwargs...)
    # define points on x axis
    if xaxis == false
        xvalues = get_axis(df[args[1]])
    else
        xvalues = xaxis
    end

    if population == []
        mean_across_pop = f(df,xvalues, args...; kwargs...)
        sem_across_pop = zeros(length(xvalues));
        valid = ~isnan(mean_across_pop)
    else
        # get mean value and sem of function of interest
        splitdata = groupby(df, population)
        v = Array(Float64, length(xvalues), length(splitdata));
        for i in 1:length(splitdata)
            v[:,i] = f(splitdata[i],xvalues, args...; kwargs...)
        end
        mean_across_pop = Array(Float64, length(xvalues));
        sem_across_pop = Array(Float64, length(xvalues));
        for j in 1:length(xvalues)
            notnan = !isnan(v[j,:])
            mean_across_pop[j] = trend(v[j,notnan])
            sem_across_pop[j] = variation(v[j,notnan])
        end
        valid = !isnan(mean_across_pop) & !isnan(sem_across_pop)
    end
    if xaxis == false
        return xvalues[valid], mean_across_pop[valid], sem_across_pop[valid]
    else
        return xvalues, mean_across_pop, sem_across_pop
    end
end

function groupapply(f::Function, df, args...;
                    shared_xaxis = false, across = [], group = [], summarize = (mean, sem), kwargs...)
    g = GroupedError(
                    Array(Vector{eltype(df[args[1]])},0),
                    Array(Vector{Float64},0),
                    Array(Vector{Float64},0),
                    Array(AbstractString,0),
                    false
                    )
    xaxis = shared_xaxis ? get_axis(df[args[1]]) : false
    g.xaxis = xaxis
    if group == []
        xvalues,yvalues,shade = get_mean_sem(summarize..., f, df, across, args...; xaxis = xaxis, kwargs...)
        push!(g.x, xvalues)
        push!(g.y, yvalues)
        push!(g.err, shade)
        push!(g.group, "")
    else
        #group_array = isa(group, AbstractArray) ? group : [group]
        by(df,group) do dd
            label = isa(group, AbstractArray) ?
                    string(["$(dd[1,column]) " for column in group]...) : string(dd[1,group])
            xvalues,yvalues,shade = get_mean_sem(summarize...,f, dd, across, args...; xaxis = xaxis, kwargs...)
            push!(g.x, xvalues)
            push!(g.y, yvalues)
            push!(g.err, shade)
            push!(g.group, label)
            return
        end
    end
    return g
end

builtin_funcs = Dict(zip([:locreg, :density, :cumulative], [_locreg, _density, _cumulative]))

function groupapply(s::Symbol, df, args...; kwargs...)
    if s in keys(builtin_funcs)
        analysisfunction = builtin_funcs[s]
        return groupapply(analysisfunction, df, args...; kwargs...)
    else
        return groupapply(_locreg, df, args[1], s; kwargs...)
    end
end

groupapply(df::AbstractDataFrame, x, y; kwargs...) = groupapply(_locreg, df, x, y; kwargs...)

@recipe function f(g::GroupedError)
    if !(:seriestype in keys(d)) || (d[:seriestype] == :line)
        if g.xaxis != false
            warn("shared_xaxis = false is recommended for line plots")
        end
        for i = 1:length(g.group)
            @series begin
                seriestype := :shadederror
                x := cycle(g.x,i)
                y := cycle(g.y, i)
                shade := cycle(g.err,i)
                label --> cycle(g.group,i)
                ()
            end
        end
    elseif d[:seriestype] == :scatter
        if g.xaxis != false
            warn("shared_xaxis = false is recommended for scatter plots")
        end
        for i = 1:length(g.group)
            @series begin
                seriestype := :scatter
                x := cycle(g.x,i)
                y := cycle(g.y, i)
                err := cycle(g.err,i)
                label --> cycle(g.group,i)
                ()
            end
        end
    elseif d[:seriestype] == :bar
        if g.xaxis == false
            error("Bar Plot requires shared_xaxis = true")
        else
            err := hcat(g.err...)
            label --> hcat(g.group...)
            StatPlots.GroupedBar((g.xaxis,hcat(g.y...)))
        end
    end
end

@shorthands GroupedError
