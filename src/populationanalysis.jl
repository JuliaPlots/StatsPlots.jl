## Define a more general shadederror function that can take as input:
## - a function to be applied to your dataframe
## - a dataframe
## - the x-variable of the plot
## - Optional arguments: all the extra arguments of the function to be applied
## Keywords:
## - the categorical variable(s) used to compute s.e.m. across population
## - the categorical variable(s) used to split the data

get_axis(column::PooledDataArray) = sort!(unique(column))
get_axis(column::AbstractArray) = linspace(minimum(column),maximum(column),100)

# f is the function used to analyze dataset: define it as NA when it is not defined,
# the input is: dataframe used, x variable and points chosen on the x axis
# the output is the y value for the given xvalues

function get_mean_sem(f, df, population, args...; kwargs...)
    # define points on x axis
    xvalues = get_axis(df[args[1]])

    if population == []
        mean_across_pop = convert(DataArray,f(df,xvalues, args...; kwargs...))
        mean_across_pop[!isna(mean_across_pop) & isnan(mean_across_pop)] = NA
        sem_across_pop = zeros(length(xvalues));
        valid = ~isna(mean_across_pop)
    else
        # get mean value and sem of function of interest
        splitdata = groupby(df, population)
        v = DataArray(Float64, length(xvalues), length(splitdata));
        for i in 1:length(splitdata)
            v[:,i] = f(splitdata[i],xvalues, args...; kwargs...)
        end
        v[!isna(v) & isnan(v)] = NA
        mean_across_pop = DataArray(Float64, length(xvalues));
        sem_across_pop = DataArray(Float64, length(xvalues));
        valid = Array(Bool, length(xvalues));
        for j in 1:length(xvalues)
            mean_across_pop[j] = mean(dropna(v[j,:]))
            sem_across_pop[j] = sem(dropna(v[j,:]))
            valid[j] = (length(dropna(v[j,:]))>1)
        end
    end

    return xvalues[valid], mean_across_pop[valid], sem_across_pop[valid]
end

function groupapply(f::Function, df::AbstractDataFrame, args...;
                        across = [], group = [], kwargs...)
    if group == []
        xvalues,yvalues,shade = get_mean_sem(f, df, across, args...; kwargs...)
        return DataFrame(x = xvalues, y = yvalues, err = shade, group = "")
    else
        group_array = isa(group, AbstractArray) ? group : [group]
        by(df,group) do dd
            label = mapreduce(column-> "$column = $(dd[1,column]) ",string,"",group_array)
            xvalues,yvalues,shade = get_mean_sem(f, dd, across, args...; kwargs...)
            return DataFrame(x = xvalues, y = yvalues, err = shade, group = label)
        end
    end
end

builtin_funcs = Dict(zip(["locreg", "kdensity", "cumulative"], [locreg, kdensity, cumulative]))

function groupapply(s::AbstractString, df::AbstractDataFrame, args...; kwargs...)
    analysisfunction = builtin_funcs[s]
    return groupapply(analysisfunction, df::AbstractDataFrame, args...; kwargs...)
end

groupapply(y::Symbol, df::AbstractDataFrame, x; kwargs...) =
groupapply(locreg, df::AbstractDataFrame, x, y; kwargs...)
