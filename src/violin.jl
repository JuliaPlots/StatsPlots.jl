
# ---------------------------------------------------------------------------
# Violin Plot

const _violin_warned = [false]

# if the user has KernelDensity installed, use this for violin plots.
# otherwise, just use a histogram
function violin_coords(y; trim::Bool=false)
    kd = KernelDensity.kde(y, npoints = 200)
    if trim
        xmin, xmax = extrema(y)
        inside = Bool[ xmin <= x <= xmax for x in kd.x]
        return(kd.density[inside], kd.x[inside])
    end
    kd.density, kd.x
end


@recipe function f(::Type{Val{:violin}}, x, y, z; trim=true)
    xsegs, ysegs = Segments(), Segments()
    glabels = sort(collect(unique(x)))
    for glabel in glabels
        widths, centers = violin_coords(y[filter(i -> cycle(x,i) == glabel, 1:length(y))], trim=trim)
        isempty(widths) && continue

        # normalize
        widths = _box_halfwidth * widths / maximum(widths)

        # make the violin
        xcenter = Plots.discrete_value!(d[:subplot][:xaxis], glabel)[1]
        xcoords = vcat(widths, -reverse(widths)) + xcenter
        ycoords = vcat(centers, reverse(centers))

        push!(xsegs, xcoords)
        push!(ysegs, ycoords)
    end

    seriestype := :shape
    x := xsegs.pts
    y := ysegs.pts
    ()
end
Plots.@deps violin shape
