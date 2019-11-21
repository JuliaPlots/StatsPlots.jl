function treepositions(hc::Hclust, useheight::Bool, orientation=:v)

    order = StatsBase.indexmap(hc.order)
    nodepos = Dict(-i => (float(order[i]), 0.0) for i in hc.order)

    xs = Array{Float64}(undef, 4, size(hc.merges, 1))
    ys = Array{Float64}(undef, 4, size(hc.merges, 1))

    for i in 1:size(hc.merges, 1)
        x1, y1 = nodepos[hc.merges[i, 1]]
        x2, y2 = nodepos[hc.merges[i, 2]]

        xpos = (x1 + x2) / 2
        useheight ? h = hc.heights[i] : h = 1
        ypos = max(y1, y2) + h

        nodepos[i] = (xpos, ypos)
        xs[:, i] .= [x1, x1, x2, x2]
        ys[:, i] .= [y1, ypos, ypos, y2]
    end
    if orientation == :h
        return ys, xs
    else
        return xs, ys
    end
end

@recipe function f(hc::Hclust; useheight=true, orientation=:v )
    typeof(useheight) <: Bool || error("'useheight' argument must be true or false")

    legend := false
    linecolor --> :black

    if orientation == :h
        if useheight
            hs=sum(hc.heights)
            xlims --> (0, hs+hs*0.01)
        else
            xlims --> (0, Inf)
        end
        xshowaxis --> useheight
        yforeground_color_axis := :white
        ygrid := false
        ylims := (0.5, length(hc.order) + 0.5)
        yticks --> (1:nnodes(hc), (1:nnodes(hc))[hc.order])
    else
        xforeground_color_axis := :white
        xgrid := false
        xlims := (0.5, length(hc.order) + 0.5)
        xticks --> (1:nnodes(hc), (1:nnodes(hc))[hc.order])
        ylims --> (0, Inf)
        yshowaxis --> useheight
    end

    treepositions(hc, useheight, orientation)
end
