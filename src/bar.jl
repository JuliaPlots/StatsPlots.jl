@userplot GroupedBar

if isdefined(Plots, :group_as_matrix)
    Plots.group_as_matrix(g::GroupedBar) = true
end

grouped_xy(x::AbstractVector, y::AbstractMatrix) = x, y
grouped_xy(y::AbstractMatrix) = 1:size(y,1), y

constant_sign(x) = all(t -> t >= 0, x) || all(t -> t <= 0, x)
function constant_sign_rowwise(x::AbstractMatrix)
    nr, nc = size(x)
    all(constant_sign(x[i, j] for j in 1:nc) for i in 1:nr)
end

function groupedbar_fillrange(y::AbstractMatrix)
    nr, nc = size(y)
    y = copy(y)
    y[.!isfinite.(y)] .= 0
    fr = zeros(nr, nc)
    for c=2:nc
        for r=1:nr
            fr[r,c] = y[r,c-1]
            y[r,c] += fr[r,c]
        end
    end
    y, fr
end

@recipe function f(g::GroupedBar)
    x, y = grouped_xy(g.args...)

    nr, nc = size(y)
    isstack = pop!(plotattributes, :bar_position, :dodge) == :stack

    # if :stack, check if the signs are constant within each group
    constant_signs = isstack ? constant_sign_rowwise(y) : true
    # if not, split the data into a positive and negative parts
    if isstack && !constant_signs    
        y_neg = y .* (y .< 0)
        y_pos = y .* (y .> 0)
    end

    # extract xnums and set default bar width.
    # might need to set xticks as well
    xnums = if eltype(x) <: Number
        bar_width --> (0.8 * mean(diff(x)))
        x
    else
        bar_width --> 0.8
        ux = unique(x)
        xnums = (1:length(ux)) .- 0.5
        xticks --> (xnums, ux)
        xnums
    end
    @assert length(xnums) == nr

    # compute the x centers.  for dodge, make a matrix for each column
    x = if isstack
        x
    else
        bws = plotattributes[:bar_width] / nc
        bar_width := bws
        xmat = zeros(nr,nc)
        for r=1:nr
            bw = _cycle(bws, r)
            farleft = xnums[r] - 0.5 * (bw * nc)
            for c=1:nc
                xmat[r,c] = farleft + 0.5bw + (c-1)*bw
            end
        end
        xmat
    end

    # compute fillrange
    if isstack
        if constant_signs
            y, fr = groupedbar_fillrange(y)
        else
            y_neg, fr_neg = groupedbar_fillrange(y_neg)
            y_pos, fr_pos = groupedbar_fillrange(y_pos)
            y = [y_neg, y_pos]
            fr = [fr_neg, fr_pos]
        end
    end

    fillrange := if isstack
        fr
    else
        get(plotattributes, :fillrange, nothing)
    end

    seriestype := :bar
    x, y
end
