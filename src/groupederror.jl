##### List of functions to analyze data

function extend_axis(df::AbstractDataFrame, xlabel, ylabel, xaxis, val)
    aux = DataFrame()
    aux[xlabel] = xaxis
    extended = join(aux, df, on = xlabel, kind = :left)
    sort!(extended, cols = [xlabel])
    return convert(Array, extended[ylabel], val)
end

function extend_axis(xsmall, ysmall, xaxis, val)
    df = DataFrame(x = xsmall, y = ysmall)
    return extend_axis(df, :x, :y, xaxis, val)
end

"""
    `_locreg(df, xaxis::LinSpace, x, y; kwargs...)`

Apply loess regression, training the regressor with `x` and `y` and
predicting `xaxis`
"""
function _locreg(df, xaxis::LinSpace, x, y; kwargs...)
    predicted = fill(NaN,length(xaxis))
    within = Plots.ignorenan_minimum(df[x]).<= xaxis .<= Plots.ignorenan_maximum(df[x])
    if any(within)
        model = Loess.loess(convert(Vector{Float64},df[x]),convert(Vector{Float64},df[y]); kwargs...)
        predicted[within] = Loess.predict(model,xaxis[within])
    end
    return predicted
end


"""
    `_locreg(df, xaxis, x, y; kwargs...)`

In the discrete case, the function computes the conditional expectation of `y` for
a given value of `x`
"""
function _locreg(df, xaxis, x,  y)
  ymean = by(df, x) do dd
      DataFrame(m = mean(dd[y]))
  end
  return extend_axis(ymean, x, :m, xaxis, NaN)
end

"""
    `_density(df,xaxis::LinSpace, x; kwargs...)`

Kernel density of `x`, computed along `xaxis`
"""
_density(df,xaxis::LinSpace, x; kwargs...) = pdf(KernelDensity.kde(df[x]; kwargs...),xaxis)

"""
    `_density(df, xaxis, x)`

Normalized histogram of `x` (which is discrete: every value is its own bin)
"""
function _density(df,xaxis, x)
    xhist = by(df, x) do dd
        DataFrame(length = size(dd,1)/size(df,1))
    end
    return extend_axis(xhist, x, :length, xaxis, 0.)
end

"""
    `_cumulative(df, xaxis, x) = ecdf(df[x])(xaxis)`

Cumulative density function of `x`, computed along `xaxis`
"""
_cumulative(df, xaxis, x) = ecdf(df[x])(xaxis)


#### Method to compute and plot grouped error plots using the above functions

mutable struct GroupedError{S, T<:AbstractString}
    x::Vector{Vector{S}}
    y::Vector{Vector{Float64}}
    err::Vector{Vector{Float64}}
    group::Vector{T}
    axis_type::Symbol
    show_error::Bool
end

get_axis(column) = sort!(union(column))
get_axis(column, npoints::Int64) = linspace(Plots.ignorenan_minimum(column),Plots.ignorenan_maximum(column),npoints)

function get_axis(column, axis_type::Symbol)
    if axis_type == :discrete
        return get_axis(column)
    elseif axis_type == :continuous
        return get_axis(column, 100)
    else
        error("Unexpected axis_type: only :discrete and :continuous allowed!")
    end
end

# f is the function used to analyze dataset: define it as nan when it is not defined,
# the input is: dataframe used, points chosen on the x axis, x (and maybe y) column labels
# the output is the y value for the given xvalues

get_symbol(s::Symbol) = s
get_symbol(s) = s[1]

function new_symbol(s, l::AbstractArray{Symbol})
    ns = s
    while ns in l
        ns = Symbol(ns,:_)
    end
    return ns
end

new_symbol(s, df::AbstractDataFrame) = new_symbol(s, names(df))


"""
    get_groupederror(trend,variation, f, splitdata::GroupedDataFrame, xvalues, args...; kwargs...)

Apply function `f` to `splitdata`, then compute summary statistics
`trend` and `variation` of those values. A shared x axis `xvalues` is needed: use
`LinSpace` for continuous x variable and a normal vector for the discrete case. Remaining arguments
are label of x axis variable and extra arguments for function `f`. `kwargs...` are passed
to `f`
"""
function get_groupederror(trend,variation, f, splitdata::GroupedDataFrame, xvalues::AbstractArray, args...; kwargs...)
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
    return xvalues[valid], mean_across_pop[valid], sem_across_pop[valid]
end

"""
    get_groupederror(trend,variation, f, df::AbstractDataFrame, xvalues::AbstractArray, ce, args...; kwargs...)

Get `GropedDataFrame` from `df` according to `ce`. `ce = (:across, col_name)` will split
across column `col_name`, whereas `ce = (:bootstrap, n_samples)` will generate `n_samples`
fake datasets distributed like the real dataset (nonparametric bootstrapping).
Then compute `get_groupederror` of the `GroupedDataFrame`.
"""
function get_groupederror(trend,variation, f, df::AbstractDataFrame, xvalues::AbstractArray, ce, args...; kwargs...)

    if ce == :none
        mean_across_pop = f(df,xvalues, args...; kwargs...)
        sem_across_pop = zeros(length(xvalues));
        valid = ~isnan(mean_across_pop)
        return xvalues[valid], mean_across_pop[valid], sem_across_pop[valid]
    elseif ce[1] == :across
        # get mean value and sem of function of interest
        splitdata = groupby(df, ce[2])
        return get_groupederror(trend,variation, f, splitdata, xvalues, args...; kwargs...)
    elseif ce[1] == :bootstrap
        n_samples = ce[2]
        indexes = Array(Int64,0)
        split_var = Array(Int64,0)
        for i = 1:n_samples
            append!(indexes, rand(1:size(df,1),size(df,1)))
            append!(split_var, fill(i,size(df,1)))
        end
        split_col = new_symbol(:split_col, df)
        bootstrap_data = df[indexes,:]
        bootstrap_data[split_col] = split_var
        ends = collect(size(df,1)*(1:n_samples))
        starts = ends - size(df,1) + 1
        splitdata = GroupedDataFrame(bootstrap_data,[split_col],collect(1:ends[end]), starts, ends)
        return get_groupederror(trend,variation, f, splitdata, xvalues, args...; kwargs...)
    else
        error("compute_error can only be equal to :none, :across,
        (:across, col_name), :bootstrap or (:bootstrap, n_samples)")
    end
end


"""
    get_groupederror(trend,variation, f, df::AbstractDataFrame, axis_type, ce, args...; kwargs...)

Choose shared axis according to `axis_type` (`:continuous` or `:discrete`) then
compute `get_groupederror`.
"""
function get_groupederror(trend,variation, f, df::AbstractDataFrame, axis_type, ce,  args...; kwargs...)
    # define points on x axis
    xvalues = get_axis(df[args[1]], axis_type)
    return get_groupederror(trend,variation, f, df::AbstractDataFrame, xvalues, ce, args...; kwargs...)
end

"""

    groupapply(f::Function, df, args...;
                axis_type = :auto, compute_error = :none, group = [],
                summarize = (get_symbol(compute_error) == :bootstrap) ? (mean, std) : (mean, sem),
                kwargs...)

Split `df` by `group`. Then apply `get_groupederror` to get a population summary of the grouped data.
Output is a `GroupedError` with error computed according to the keyword `compute_error`.
It can be plotted using `plot(g::GroupedError)`
Seriestype can be specified to be `:path`, `:scatter` or `:bar`
"""
function groupapply(f::Function, df, args...;
                    axis_type = :auto, compute_error = :none, group = [],
                    summarize = (get_symbol(compute_error) == :bootstrap) ? (mean, std) : (mean, sem),
                    compute_axis = :separate,
                    kwargs...)
    if !(axis_type in [:discrete, :continuous])
        axis_type = (typeof(df[args[1]])<:PooledDataArray) ? :discrete : :continuous
    end
    if (axis_type == :continuous) & !(eltype(df[args[1]])<:Real)
        warn("Changing to discrete axis, x values are not real numbers!")
        axis_type = :discrete
    end
    mutated_xtype = (axis_type == :continuous) ? Float64 : eltype(df[args[1]])

    # Add default for :across and :bootstrap
    if compute_error == :across
        row_name = new_symbol(:rows, df)
        df[row_name] = 1:size(df,1)
        ce = (:across, row_name)
    elseif compute_error == :bootstrap
        ce = (:bootstrap, 1000)
    else
        ce = compute_error
    end

    g = GroupedError(
                    Array(Vector{mutated_xtype},0),
                    Array(Vector{Float64},0),
                    Array(Vector{Float64},0),
                    Array(AbstractString,0),
                    axis_type,
                    ce != :none
                    )
    if group == []
        xvalues,yvalues,shade = get_groupederror(summarize..., f, df, axis_type, ce, args...; kwargs...)
        push!(g.x, xvalues)
        push!(g.y, yvalues)
        push!(g.err, shade)
        push!(g.group, "")
    else
        #group_array = isa(group, AbstractArray) ? group : [group]
        by(df,group) do dd
            label = isa(group, AbstractArray) ?
                    string(["$(dd[1,column]) " for column in group]...) : string(dd[1,group])
            xvalues,yvalues,shade = get_groupederror(summarize...,f, dd, axis_type, ce, args...; kwargs...)
            push!(g.x, xvalues)
            push!(g.y, yvalues)
            push!(g.err, shade)
            push!(g.group, label)
            return
        end
    end
    if compute_error == :across; delete!(df, row_name); end

    return g
end

builtin_funcs = Dict(zip([:locreg, :density, :cumulative], [_locreg, _density, _cumulative]))

"""
    groupapply(s::Symbol, df, args...; kwargs...)

`s` can be `:locreg`, `:density` or `:cumulative`, in which case the corresponding built in
analysis function is used. `s` can also be a symbol of a column of `df`, in which case the call
is equivalent to `groupapply(:locreg, df, args[1], s; kwargs...)`
"""
function groupapply(s::Symbol, df, args...; kwargs...)
    if s in keys(builtin_funcs)
        analysisfunction = builtin_funcs[s]
        return groupapply(analysisfunction, df, args...; kwargs...)
    else
        return groupapply(_locreg, df, args[1], s; kwargs...)
    end
end

"""
    groupapply(df::AbstractDataFrame, x, y; kwargs...)

Equivalent to `groupapply(:locreg, df::AbstractDataFrame, x, y; kwargs...)`
"""

groupapply(df::AbstractDataFrame, x, y; kwargs...) = groupapply(_locreg, df, x, y; kwargs...)

@recipe function f(g::GroupedError)
    if !(:seriestype in keys(plotattributes)) || (plotattributes[:seriestype] == :path)
        for i = 1:length(g.group)
            @series begin
                seriestype := :shadederror
                x := _cycle(g.x,i)
                y := _cycle(g.y, i)
                shade := _cycle(g.err,i)
                label --> _cycle(g.group,i)
                ()
            end
        end
    elseif plotattributes[:seriestype] == :scatter
        for i = 1:length(g.group)
            @series begin
                seriestype := :scatter
                x := _cycle(g.x,i)
                y := _cycle(g.y, i)
                if g.show_error
                    err := _cycle(g.err,i)
                end
                label --> _cycle(g.group,i)
                ()
            end
        end
    elseif plotattributes[:seriestype] == :bar
        if g.axis_type == :continuous
            warn("Bar plot with continuous x axis doesn't make sense!")
        end
        xaxis = sort!(union((g.x)...))
        ys = extend_axis.(g.x, g.y, [xaxis], [NaN])
        y = hcat(ys...)
        if g.show_error
            errs = extend_axis.(g.x, g.err, [xaxis], [NaN])
            err := hcat(errs...)
        end
        label --> hcat(g.group...)
        StatPlots.GroupedBar((xaxis,y))
    end
end

@shorthands GroupedError
