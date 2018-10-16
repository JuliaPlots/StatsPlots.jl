
# ---------------------------------------------------------------------------
# Violin Plot

const _violin_warned = [false]

function violin_coords(y; trim::Bool=false)
    kd = KernelDensity.kde(y, npoints = 200)
    if trim
        xmin, xmax = Plots.ignorenan_extrema(y)
        inside = Bool[ xmin <= x <= xmax for x in kd.x]
        return(kd.density[inside], kd.x[inside])
    end
    kd.density, kd.x
end


@recipe function f(::Type{Val{:violin}}, x, y, z; trim=true, side=:both)
    # if only y is provided, then x will be UnitRange 1:length(y)
    if typeof(x) <: AbstractRange
        if step(x) == first(x) == 1
            x = plotattributes[:series_plotindex]
        else
            x = [getindex(x, plotattributes[:series_plotindex])]
        end
    end
    xsegs, ysegs = Segments(), Segments()
    glabels = sort(collect(unique(x)))
    bw = plotattributes[:bar_width]
    bw == nothing && (bw = 0.8)

    isa(plotattributes[:group], Nothing) ? ngroups = 1 : ngroups = length(unique(plotattributes[:group]))
    thisgroup = plotattributes[:series_plotindex]

    outercenter = 0.5 * bw - bw / 2ngroups
    offsets = collect(-outercenter:(bw / ngroups):outercenter)
    bw = bw / ngroups

    for (i,glabel) in enumerate(glabels)
        widths, centers = violin_coords(y[filter(i -> _cycle(x,i) == glabel, 1:length(y))], trim=trim)
        isempty(widths) && continue

        # normalize
        hw = 0.5_cycle(bw, i)
        widths = hw * widths / Plots.ignorenan_maximum(widths)

        # make the violin
        xcenter = Plots.discrete_value!(plotattributes[:subplot][:xaxis], glabel)[1]
        xcenter = xcenter + offsets[thisgroup]

        if (side==:right)
          xcoords = vcat(widths, zeros(length(widths))) .+ xcenter
        elseif (side==:left)
          xcoords = vcat(zeros(length(widths)), -reverse(widths)) .+ xcenter
        else
          xcoords = vcat(widths, -reverse(widths)) .+ xcenter
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
