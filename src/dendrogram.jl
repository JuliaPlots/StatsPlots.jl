function treepositions(hc::Hclust, useheight::Bool)
    order = StatsBase.indexmap(hc.order)
    nodepos = Dict(-i => (float(order[i]), 0.0) for i in hc.order)

    xs = Array{Float64}(4, size(hc.merge, 1))
    ys = Array{Float64}(4, size(hc.merge, 1))

    for i in 1:size(hc.merge, 1)
        x1, y1 = nodepos[hc.merge[i, 1]]
        x2, y2 = nodepos[hc.merge[i, 2]]

        xpos = (x1 + x2) / 2
        useheight ? h = hc.height[i] : h = 1
        ypos = max(y1, y2) + h

        nodepos[i] = (xpos, ypos)
        xs[:, i] .= [x1, x1, x2, x2]
        ys[:, i] .= [y1, ypos, ypos, y2]
    end

    return xs, ys
end

@recipe function f(hc::Hclust; useheight=true)
    typeof(useheight) <: Bool || error("'useheight' argument must be true or false")

    legend := false
    xforeground_color_axis := :white
    xgrid := false
    xlims := (0.5, length(hc.order) + 0.5)

    linecolor --> :black
    xticks --> (1:length(hc.labels), hc.labels[hc.order])
    ylims --> (0, Inf)
    yshowaxis --> useheight

    treepositions(hc, useheight)
end
