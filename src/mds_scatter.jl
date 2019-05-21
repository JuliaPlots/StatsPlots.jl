@recipe function f(mds::MDS{<:Real})
    xticks := false
    yticks := false
    ev = eigvals(mds)
    var_explained = [v / sum(ev) for v in ev]
    xlabel --> "MDS1 ($(round(var_explained[1] * 100, digits = 2))%)"
    ylabel --> "MDS2 ($(round(var_explained[2] * 100, digits = 2))%)"
    seriestype := :scatter
    projection(mds)[:,1], projection(mds)[:,2]
end
