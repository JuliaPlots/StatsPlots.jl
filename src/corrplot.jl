@userplot CorrPlot

function update_ticks_guides(d::KW, labs, i, j, n)
    d[:title]  = (i==1 ? cycle(labs,j) : "")
    d[:xticks] = (i==n)
    d[:yticks] = (j==1)
    d[:yguide] = (j==1 ? cycle(labs,i) : "")
end

@recipe function f(cp::CorrPlot)
    mat = cp.args[1]
    n = size(mat,2)
    C = cor(mat)
    labs = pop!(d, :label, [""])

    link := :x  # need custom linking for y
    layout := (n,n)
    legend := false
    foreground_color_border := nothing
    margin := 1mm
    titlefont := font(11)
    fillcolor --> Plots.fg_color(d)
    markeralpha := 0.4
    grad = cgrad(get(d, :markercolor, cgrad()))
    indices = reshape(1:n^2, n, n)'

    # histograms on the diagonal
    for i=1:n
        @series begin
            seriestype := :histogram
            subplot := indices[i,i]
            grid := false
            update_ticks_guides(d, labs, i, i, n)
            view(mat,:,i)
        end
    end

    # scatters
    for i=1:n
        ylink := setdiff(vec(indices[i,:]), indices[i,i])
        vi = view(mat,:,i)
        for j = 1:n
            j==i && continue
            vj = view(mat,:,j)
            subplot := indices[i,j]
            update_ticks_guides(d, labs, i, j, n)
            if i > j
                #below diag... scatter
                @series begin
                    seriestype := :scatter
                    markercolor := grad[0.5 + 0.5C[i,j]]
                    smooth := true
                    vj, vi
                end
            else
                #above diag... hist2d
                @series begin
                    seriestype := get(d, :seriestype, :histogram2d)
                    vj, vi
                end
            end
        end
    end
end
