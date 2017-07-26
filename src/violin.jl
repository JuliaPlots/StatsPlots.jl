# ---------------------------------------------------------------------------
# Utility functions

const _violin_warned = [false]

"""
**Use kde to return an envelope for the violin and beeswarm plots**

    violin_coords(y; trim::Bool=false, n::Int64=200)

- `y`: points to estimate the distribution from
- `trim`: whether to remove the extreme values
- `n`: number of points to use in kde (defaults to 200)

"""
function violin_coords(y; trim::Bool=false, n::Int64=200)
    kd = KernelDensity.kde(y, npoints = n)
    if trim
        xmin, xmax = Plots.ignorenan_extrema(y)
        inside = Bool[ xmin <= x <= xmax for x in kd.x]
        return(kd.density[inside], kd.x[inside])
    end
    kd.density, kd.x
end

"""
**Check that the side is correct**

    check_side(side::Symbol)

`side` can be `:both`, `:left`, or `:right`. Any other value will default to
`:both`.
"""
function check_side(side::Symbol)
    if !(side in [:both, :left, :right])
        warn("side (you gave :$side) must be one of :both, :left, or :right")
        side = :both
        info("side set to :$side")
    end
    return side
end

# ---------------------------------------------------------------------------
# Violin plot
@recipe function f(::Type{Val{:violin}}, x, y, z; trim=false, side=:both)

    side = check_side(side)

    xsegs, ysegs = Segments(), Segments()
    glabels = sort(collect(unique(x)))
    bw = d[:bar_width]
    bw == nothing && (bw = 0.8)
    for (i,glabel) in enumerate(glabels)
        widths, centers = violin_coords(y[filter(i -> _cycle(x,i) == glabel, 1:length(y))], trim=trim)
        isempty(widths) && continue

        # normalize
        hw = 0.5_cycle(bw, i)
        widths = hw * widths / Plots.ignorenan_maximum(widths)

        # make the violin
        xcenter = Plots.discrete_value!(d[:subplot][:xaxis], glabel)[1]
        if (side==:right)
          xcoords = vcat(widths, zeros(length(widths))) + xcenter
        elseif (side==:left)
          xcoords = vcat(zeros(length(widths)), -reverse(widths)) + xcenter
        else
          xcoords = vcat(widths, -reverse(widths)) + xcenter
        end
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
