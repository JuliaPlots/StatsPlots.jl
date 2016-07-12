@userplot CornerPlot
# adapted from CorrPlot

function update_ticks_guides(d::KW, labs, i, j, n, k)
    d[:xticks] = (i==n-1)
    d[:yticks] = (j==2)
    d[:xguide] = (i==n-1 && j>1 ? cycle(labs,j-1) : "")
    d[:yguide] = (j==2 && i<n ? cycle(labs,i+k) : "")
end

@recipe function f(cp::CornerPlot; compact=false, maxvariables=30)
    # Plots.dumpdict(d, "corner", true)
    mat = cp.args[1]
    N = size(mat,2)
    nsamples = size(mat,1)
    if N>maxvariables
        error("Requested to plot $N variables in $(N^2) subplots!  Likely, the first input needs transposing, otherwise increase maxvariables.")
    end
    delete!(d, :maxvariables)
    labs = pop!(d, :label, [""])
    if labs!=[""] && length(labs)!=N
        error("Number of labels not identical to number of datasets")
    end
    n = compact ? N : N+1 # nxn is the plot-grid size
    colrange = 1:n-1
    rowrange = 2:n

    delete!(d, :compact)

    # Make the layout.  Note that the subplots are numbered in
    # row-major order.
    cell = GridLayout(n,n)
    sz = 1/4n
    indices = zeros(Int,n,n)
    pltnr = 1
    for i=1:n
        for j=1:n
            if j==1 # first column: hists
                if i<n
                    indices[i,j] = pltnr; pltnr +=1
                    cell[i,j] = EmptyLayout(width=sz*pct, height=:auto)
                else # bottom left: empty
                    cell[i,j] = EmptyLayout(width=sz*pct, height=sz*pct, blank=true)
                end
            elseif i==n # last row: hists
                indices[i,j] = pltnr; pltnr +=1
                cell[i,j] = EmptyLayout(height=sz*pct, width=:auto)
            elseif compact && j-1>i # top right empty if compact
                cell[i,j] = EmptyLayout(width=:auto, height=:auto, blank=true)
            else
                indices[i,j] = pltnr; pltnr +=1
                cell[i,j] = EmptyLayout(width=:auto, height=:auto)
            end
        end
    end
    layout := cell
    legend := false
    foreground_color_border := nothing
    margin := 1mm
    titlefont := font(11)
    fillcolor := :black

    # figure out good defaults for scatter plot dots:
    pltarea = 1/2n
    ms = pltarea*1000/sqrt(nsamples)
    markersize --> max(min(10, ms), 0.5)
    ma = pltarea*100/nsamples^0.42
    markeralpha --> max(min(0.4, ma), 0.05)

    # histograms in the left column
    k = compact ? 1 : 0
    for i=1:n-1
        @series begin
            orientation := :h
            xflip := true
            link := :none
            seriestype := :histogram
            subplot := indices[i,1]
            grid := false
            xticks := false
            yticks := false
            sub(mat,:,i+k)
        end
    end
    # histograms in the bottom row
    for j=2:n
        @series begin
            yflip := true
            seriestype := :histogram
            subplot := indices[end,j]
            grid := false
            xticks := false
            yticks := false
            sub(mat,:,j-1)
        end
    end

    # scatters
    for i=1:n-1
        vi = sub(mat,:,i+k)
        tmp = vec(indices[i,:])
        ylink := tmp[tmp.>0] # remove 0s
        for j = 2:n
            if !(compact && j-1>i) # top right empty if compact
                vj = sub(mat,:,j-1)
                subplot := indices[i,j]
                tmp = vec(indices[:,j])
                xlink := tmp[tmp.>0]
                update_ticks_guides(d, labs, i, j, n, k)
                @series begin
                    seriestype := :scatter
                    smooth := true
                    markerstrokewidth --> 0
                    vj, vi
                end
            end
        end
    end
end
