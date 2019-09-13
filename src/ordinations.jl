@recipe function f(mds::MDS{<:Real}; mds_axes=(1,2))
    length(mds_axes) in [2,3] || throw(ArgumentError("Can only accept 2 or 3 mds axes"))
    xax = mds_axes[1]
    yax = mds_axes[2]
    ev = eigvals(mds)
    var_explained = [v / sum(ev) for v in ev]
    tfm = collect(transform(mds)')

    xlabel --> "MDS$xax"
    ylabel --> "MDS$yax"
    seriestype := :scatter
    aspect_ratio --> 1

    if length(mds_axes) == 3
        zax = mds_axes[3]
        zlabel --> "MDS$zax"
        tfm[:,xax], tfm[:,yax], tfm[:,zax]
    else
        tfm[:,xax], tfm[:,yax]
    end
end

@recipe function f(pca::PCA{<:Real}; pca_axes=(1,2))
    length(pca_axes) in [2,3] || throw(ArgumentError("Can only accept 2 or 3 pca axes"))
    xax = pca_axes[1]
    yax = pca_axes[2]
    vars = principalvars(pca)
    var_explained = [v / sum(vars) for v in vars] .* principalratio(pca)
    proj = projection(pca)

    xlabel --> "PCA$xax"
    ylabel --> "PCA$yax"
    seriestype := :scatter
    aspect_ratio --> 1

    if length(pca_axes) == 3
        zax = pca_axes[3]
        zlabel --> "PCA$zax"
        proj[:,xax], proj[:,yax], proj[:,zax]
    else
        proj[:,xax], proj[:,yax]
    end
end
