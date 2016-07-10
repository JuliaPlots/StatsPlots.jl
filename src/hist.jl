
# ---------------------------------------------------------------------------
# density

@recipe function f(::Type{Val{:density}}, x, y, z; trim=false)
    newx, newy = violin_coords(y, trim=trim)
    if isvertical(d)
        newx, newy = newy, newx
    end
    x := newx
    y := newy
    seriestype := :path
    ()
end
Plots.@deps density path
