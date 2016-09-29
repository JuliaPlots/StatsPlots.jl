@userplot GroupedBar

grouped_xy(x::AbstractVector, y::AbstractMatrix) = x, y
grouped_xy(y::AbstractMatrix) = 1:size(y,1), y

@recipe function f(g::GroupedBar)
    x, y = grouped_xy(g.args...)

    nr, nc = size(y)
    isstack = pop!(d, :bar_position, :dodge) == :stack
    bar_width --> (0.8 * mean(diff(x)))

    x = if isstack
        x
    else
        bws = d[:bar_width] / nc
        bar_width := bws
        xmat = zeros(nr,nc)
        for r=1:nr
            bw = cycle(bws, r)
            farleft = x[r] - 0.5 * (bw * nc)
            for c=1:nc
                xmat[r,c] = farleft + 0.5bw + (c-1)*bw
            end
        end
        xmat
    end

    # update
    fillrange := if isstack
        # shift y/fillrange up
        fr = zeros(nr, nc)
        for c=2:nc
            for r=1:nr
                fr[r,c] = y[r,c-1]
                y[r,c] += fr[r,c]
            end
        end
        fr
    else
        get(d, :fillrange, 0)
    end

    seriestype := :bar
    x, y
end
