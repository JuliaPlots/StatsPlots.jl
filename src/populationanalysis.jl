## Define a more general shadederror function that can take as input:
## - a function to be applied to your dataframe
## - a dataframe
## - the x-variable of the plot
## - Optional arguments: all the extra arguments of the function to be applied
## Keywords:
## - the categorical variable(s) used to compute s.e.m. across population
## - the categorical variable(s) used to split the data

get_axis(column::PooledDataArray) = sort!(union(column))
get_axis(column::AbstractArray) = linspace(minimum(column),maximum(column),100)

# f is the function used to analyze dataset: define it as NA when it is not defined,
# the input is: dataframe used, x variable and points chosen on the x axis
# the output is the y value for the given xvalues

function get_mean_sem(f, df, x, population)
    # define points on x axis
    xvalues = get_axis(df[x])

    if population == []
        mean_across_pop = convert(DataArray,f(df,x,xvalues))
        mean_across_pop[!isna(mean_across_pop) & isnan(mean_across_pop)] = NA
        sem_across_pop = zeros(length(xvalues));
        valid = ~isna(mean_across_pop)
    else
        # get mean value and sem of function of interest
        splitdata = groupby(df, population)
        v = DataArray(Float64, length(xvalues), length(splitdata));
        for i in 1:length(splitdata)
            v[:,i] = f(splitdata[i],x, xvalues)
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

funcs = [:shadederror, :(Plots.scatter),:(Plots.bar)]
funcs! = [:shadederror!, :(Plots.scatter!),:(Plots.bar!)]
kws = [:shade, :err, :err]

for t in 1:3
    @eval begin
        function $(funcs![t])(f::Function, df::AbstractDataFrame, x;
                                across = [], group = [], kwargs...)
            if group == []
                x,y,shade = get_mean_sem(f, df, x, across)
                $(funcs![t])(x, y; $(kws[t]) = shade, kwargs...)
                return
            else
                group_array = isa(group, AbstractArray) ? group : [group]
                counter = fill(0,())
                by(df,group) do dd
                    label = mapreduce(column-> "$column = $(dd[1,column]) ",string,"",group_array)
                    counter[] += 1
                    cycled_kwargs = [(kw[1], cycle(kw[2], counter[])) for kw in kwargs]
                    $(funcs![t])(f,dd,x; across = across, label = label, cycled_kwargs...)
                    return
                end
            end
        end
    end
end

for t in 1:3
    @eval begin
        function $(funcs[t])(f::Function, df::AbstractDataFrame, x; kwargs...)
            s = plot()
            $(funcs![t])(f::Function, df::AbstractDataFrame, x; kwargs...)
            return s
        end
    end
end

for func in vcat(funcs, funcs!)
    @eval begin
        $func(f::Function, df::AbstractDataFrame, x, args...; kwargs...) =
        $func((a,b,c) -> f(a,b,c,args...),  df::AbstractDataFrame, x; kwargs...)
    end
end
