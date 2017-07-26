@shorthands beeswarm

# ---------------------------------------------------------------------------
# Beeswarm plot
@recipe function f(::Type{Val{:beeswarm}}, x, y, z; trim=false, side=:both)

  side = check_side(side)

  xp, yp = Float64[], Float64[]
  glabels = sort(collect(unique(x)))
  bw = d[:bar_width]
  bw == nothing && (bw = 0.8)

  for (i,glabel) in enumerate(glabels)
    # We get the values for this label
    lab_y = y[filter(i -> _cycle(x,i) == glabel, 1:length(y))]
    lab_x = zeros(lab_y)

    # Number of bins (defaults to sturges)
    binning_mode = d[:bins]
    if binning_mode == :auto
      binning_mode = :sturges
    end
    n = Plots._auto_binning_nbins(tuple(lab_y), 1, mode=binning_mode)

    # Get the widths and the coordinates
    widths, centers = StatPlots.violin_coords(lab_y, trim=trim, n=n)
    isempty(widths) && continue

    # normalize
    hw = 0.5Plots._cycle(bw, i)
    widths = hw * widths / Plots.ignorenan_maximum(widths)

    # make the violin
    xcenter = Plots.discrete_value!(d[:subplot][:xaxis], glabel)[1]

    for i in 2:length(centers)
      inside = Bool[centers[i-1] < u <= centers[i] for u in lab_y]
      if sum(inside) > 1
        if (side==:right)
          start == 0.0
          stop = widths[i]
        elseif (side==:left)
          start = -widths[i]
          stop = 0.0
        elseif (side == :both)
          start = -widths[i]
          stop = widths[i]
        end
        lab_x[inside] = lab_x[inside] .+ linspace(start, stop, sum(inside)) .+ xcenter
      end
    end

    append!(xp, lab_x)
    append!(yp, lab_y)

  end

  x := xp
  y := yp
  seriestype := :scatter
  ()

end

Plots.@deps beeswarm scatter
