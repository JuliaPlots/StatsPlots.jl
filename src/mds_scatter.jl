@recipe function f(mds::MDS{<:Real}; mds_axes=(1,2))
    length(mds_axes) in [2,3] || throw(ArgumentError("Can only accept 2 or 3 mds axes"))
    xax = mds_axes[1]
    yax = mds_axes[2]
    ev = eigvals(mds)
    var_explained = [v / sum(ev) for v in ev]
    proj = projection(mds)

    xlabel --> "MDS$xax ($(round(var_explained[xax] * 100, digits = 2))%)"
    ylabel --> "MDS$yax ($(round(var_explained[yax] * 100, digits = 2))%)"
    seriestype := :scatter
    xticks := false
    yticks := false

    if length(mds_axes) == 3
        zax = mds_axes[3]
        zlabel --> "MDS$zax ($(round(var_explained[zax] * 100, digits = 2))%)"
        proj[:,xax], proj[:,yax], proj[:,zax]
    else
        proj[:,xax], proj[:,yax]
    end
end
