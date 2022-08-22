@userplot ErrorLine
""" 
# StatsPlots.errorline(x, y, arg): 
    Function for parsing inputs to easily make a ribbons (https://ggplot2.tidyverse.org/reference/geom_ribbon.html) 
    or errorbar (https://www.mathworks.com/help/matlab/ref/errorbar.html) plot while allowing for easily controlling error
    type and NaN handling.

# Inputs: default values are indicated with *s

    x (vector, unit range) - the values along the x-axis for each y-point

    y (matrix [x, repeat, group]) - values along y-axis wrt x. The first dimension must be of equal length to that of x.
        The second dimension is treated as the repeated observations and error is computed along this dimension. If the 
        matrix has a 3rd dimension this is treated as a new group.

    ErrorStyle (symbol - *:Ribbon* or :Classic) - determines whether to use a ribbon style or stick style error representation.

    CenterType (symbol - *:Mean* or :Median) - which approach to use to represent the central value of y at each x-value.

    ErrorType (symbol - *:STD*, :SEM, :Percentile) - which error metric to use to show the distribution of y at each x-value.

    Percentiles (Vector{Int64} *[25, 75]*) - if using ErrorType == :Percentile then which percentiles to use as bounds.

    GroupColor (Symbol, RGB, Vector of Symbol or RGB) - Declares the color for each group. If no value is passed then will use
        the default colorscheme. If one value is given then it will use that color for all groups. If multiple colors are 
        given then it will use a different color for each group.

    StickColor (Symbol, RGB, :Matched - *:Gray60*) - When using classic mode this will allow for the setting of the stick color.
        If ":Matched" is given then the color of the sticks with match that of the main line.

    StickWidthMultiplier (Float64 *.01*) - How much of the x-axis the horizontal aspect of the error stick should take up.

# Example
    ```julia
    x = 1:10
    y = fill(NaN, 10, 100, 3)
    for i = axes(y,3)
        y[:,:,i] = collect(1:2:20) .+ rand(10,100).*5 .* collect(1:2:20) .+ rand()*100
    end
    errorline(1:10, y)
    ```
"""
errorline

function compute_error(y::AbstractMatrix, CenterType::Symbol, ErrorType::Symbol, Percentiles::Vector{Int64})
    y_central = fill(NaN, size(y,1))
    # First compute the center
    if CenterType == :Mean
        y_central =  mapslices(NaNMath.mean, y, dims=2)
    elseif CenterType == :Median
        y_central =  mapslices(NaNMath.median, y, dims=2)
    end

    # Takes 2d matrix [x,y] and computes the desired error type for each row (value of x)
    if ErrorType == :STD || ErrorType == :SEM
        y_error = mapslices(NaNMath.std, y, dims=2)
        if ErrorType == :SEM
            y_error = y_error ./ sqrt(size(y,2))
        end

    elseif ErrorType == :Percentile
        y_lower = fill(NaN, size(y,1))
        y_upper = fill(NaN, size(y,1))
        if any(isnan.(y)) # NaNMath does not have a percentile function so have to go via StatsBase
            for i = axes(y,1)
                yi = y[i, .!isnan.(y[i,:])]
                y_lower[i] = percentile(yi, Percentiles[1])
                y_upper[i] = percentile(yi, Percentiles[2])
            end
        else
            y_lower = mapslices(Y -> percentile(Y, Percentiles[1]), y, dims=2)
            y_upper = mapslices(Y -> percentile(Y, Percentiles[2]), y, dims=2)
        end

        y_error = (y_central .- y_lower, y_upper .- y_central) # Difference from center value
    else
        error("Invalid error type. Valid symbols include :STD, :SEM, :Percentile")
    end

    return y_central, y_error
end

@recipe function f(e::ErrorLine; ErrorStyle=:Ribbon, CenterType=:Mean, ErrorType=:STD,
     Percentiles = [25, 75], GroupColor = nothing, StickColor = nothing, StickWidthMultiplier=.01)
    if length(e.args) == 1  # If only one input is given assume it is y-values in the form [x,obs]
        y = e.args[1]
        x = 1:size(y,1)
    else # Otherwise assume that the first two inputs are x and y
        x = e.args[1]
        y = e.args[2]

        # Check y orientation
        if ndims(y) > 3
            error("ndims(y) > 3")
        end

        if !any(size(y) .== length(x))
            error("Size of x and y do not match")
        elseif ndims(y) == 2 && size(y,1) != length(x) && size(y,2) == length(x) # Check if y needs to be transposed or transmuted
            y = y'
        elseif ndims(y) == 3 && size(y,1) != length(x) 
            error("When passing a 3 dimensional matrix as y, the axes must be [x, repeat, group]")
        end
    end

    # Parse different color type
    if typeof(GroupColor) == Symbol || typeof(GroupColor) == RGB{Float64}
        GroupColor = [GroupColor] 
    end
    # Check GroupColor format
    if (GroupColor !== nothing && ndims(y) > 2) && length(GroupColor) == 1
        GroupColor = repeat(GroupColor, size(y,3))
    elseif (GroupColor !== nothing && ndims(y) > 2) && length(GroupColor) < size(y,3)
        error("$(length(GroupColor)) colors given for a matrix with $(size(y,3)) groups")
    end

    for g = axes(y,3) # Iterate through 3rd dimension
        # Compute center and distribution for each value of x
        y_central, y_error = compute_error(y[:,:,g], CenterType, ErrorType, Percentiles)

        if ErrorStyle == :Ribbon
            seriestype := :path
            @series begin
                x := x
                y := y_central
                ribbon := y_error
                fillalpha --> .1
                if GroupColor !== nothing
                    linecolor := GroupColor[g]
                    fillcolor := GroupColor[g]
                end
                () # Supress implicit return
            end

        elseif ErrorStyle == :Classic
            x_offset = (extrema(x)[2] - extrema(x)[1]) * StickWidthMultiplier
            seriestype := :path
            for (i, xi) in enumerate(x)
                # Error sticks
                @series begin
                    primary := false
                    x := [xi-x_offset, xi+x_offset, xi, xi, xi+x_offset, xi-x_offset]
                    if ErrorType == :Percentile
                        y := [repeat([y_central[i] - y_error[1][i]],3); repeat([y_central[i] + y_error[2][i]],3)]
                    else
                        y := [repeat([y_central[i] - y_error[i]],3); repeat([y_central[i] + y_error[i]],3)]
                    end
                    # Set the stick color
                    if StickColor === nothing
                        linecolor := :gray60
                    elseif StickColor == :Matched
                        if GroupColor !== nothing
                            linecolor := GroupColor[g]
                        else
                            linecolor := palette(:default)[g]
                        end
                    else
                        linecolor := StickColor
                    end
                    () # Supress implicit return
                end
            end

            # Base line
            seriestype := :line
            @series begin
                primary := true
                x := x
                y := y_central
                if GroupColor !== nothing
                    linecolor := GroupColor[g]
                end
                ()
            end
        else
            error("Invalid error style. Valid symbols include :Ribbon or :Classic")
        end
    end
end