function border(x,y,rib)
    rib1, rib2 = if Plots.istuple(rib)
        first(rib), last(rib)
    else
        rib, rib
    end
    yline = vcat(y-rib1,(y+rib2)[end:-1:1])
    xline = vcat(x,x[end:-1:1])
    return xline, yline
end

@recipe function f(::Type{Val{:shadederror}},plt::Plot; shade = 0.)

    # set up the subplots
    x,y = d[:x],d[:y]
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

## Define a more general shadederror function that can take as input:
## - a function to be applied to your dataframe
## - a dataframe
## - the x-variable of the plot
## - the categorical variable used to compute s.e.m. across population
## - optionally, another categorical variable used to split the data

get_axis(column::PooledDataArray) = sort!(union(column))
get_axis(column::AbstractArray) = linspace(minimum(column),maximum(column),100)

# f is the function used to analyze dataset: define it as NA when it is not defined,
# the input is: dataframe used, x variable and points chosen on the x axis
# the output is the y value for the given xvalues

function get_mean_sem(f, df, x, population)
    # define points on x axis
    xvalues = get_axis(df[x])

    # get mean value and sem of function of interest
    splitdata = groupby(df, population)
    v = DataArray(Float64, length(xvalues), length(splitdata));
    for i in 1:length(splitdata)
        v[:,i] = f(splitdata[i],x, xvalues)
    end

    mean_across_pop = DataArray(Float64, length(xvalues));
    sem_across_pop = DataArray(Float64, length(xvalues));
    valid = Array(Bool, length(xvalues));
    for j in 1:length(xvalues)
        mean_across_pop[j] = mean(dropna(v[j,:]))
        sem_across_pop[j] = sem(dropna(v[j,:]))
        valid[j] = (length(dropna(v[j,:]))>1)
    end

    return xvalues[valid], mean_across_pop[valid], sem_across_pop[valid]
end

function shadederror(f, df, x, population; kwargs...)
    x,y, shade = get_mean_sem(f, df, x, population)
    shadederror(x,y; shade = shade, kwargs...)
end

function shadederror!(f, df, x, population; kwargs...)
    x,y, shade = get_mean_sem(f, df, x, population)
    shadederror!(x,y; shade = shade, kwargs...)
    return
end

function shadederror(f, df, x, population, conditioned; kwargs...)
    s = plot()
    shadederror!(f, df, x, population, conditioned; kwargs...)
    return s
end

function shadederror!(f, df, x, population, conditioned; kwargs...)
    if isempty(conditioned)
        shadederror!(f, df, x, population; kwargs...)
    else
        by(df,conditioned) do dd
            shadederror!(f,dd,x,population; kwargs...)
            return
        end
    end
    return
end
