"""
	silhouetteplot(C,X[,D];...)
Make a silhouette plot to assess the quality of a clustering. `C` must be a `ClusteringResult` (see the `Clustering` package), and `X` is a matrix in which each column represents a data point. If supplied, `D` should be a distance matrix (as in `Distances`); otherwise, pairwise Euclidean distances are used.

Each data point has a silhouette score between -1 and 1 indicating how unambiguously the point belongs to its assigned cluster. These are sorted within each cluster and portrayed using horizontal bars. Also shown is a dashed line at the average score. Typically a high-quality clustering has significant numbers of bars within each cluster that cross the line, and few negative scores overall.

See also: [`Clustering.silhouettes`](@ref), [`Distances`](@ref).

# Examples

```
using Clustering, LinearAlgebra, Random
Random.seed!(123);

X = reduce(hcat,[2*randn(5,1) .+ randn(5,100+100n) for n=1:3]);  # X is 5x900
D = [ norm(x-y) for x in eachcol(X), y in eachcol(X) ];          # D is 900x900
R = kmeans(D, 3; maxiter=200);
silhouetteplot(R,X,D)
```
"""
silhouetteplot

@userplot SilhouettePlot
@recipe function f(h::SilhouettePlot;yflip=true)#R::ClusteringResult,X::AbstractArray,D::AbstractMatrix=[];distance=Euclidean())
	narg = length(h.args)
	@assert narg > 1 "At least two arguments are required."
	R = h.args[1]
	@assert R isa ClusteringResult "First argument must be a ClusteringResult."
	X = h.args[2]
	@assert X isa AbstractArray "Second argument must be an array."
	if narg > 2
		D = h.args[3]
		@assert D isa AbstractMatrix "Third argument must be a distance matrix."
	else
		D = pairwise(Euclidean(),X,dims=2)
	end

	a = assignments(R)  # assignments to clusters
	c = counts(R)  # cluster sizes
	k = length(c)  # number of clusters
	n = sum(c)     # number of points overall

	s = silhouettes(R,D)

	# Settings for the axes
	legend --> false
	yflip := yflip
	xlims --> [min(-0.1,minimum(s)),1]
	# y ticks used to show cluster boundaries, and labels to show the sizes
	yticks := cumsum([0;c]),["0",["+$z" for z in c]...]

	# Generate the polygons for each cluster.
	offset = 0;
	plt = plot([],label="")
	for i in 1:k
		idx = (a.==i)    # members of cluster i
		si = yflip ? sort(s[idx],rev=true) : sort(s[idx])
		@series begin
			linealpha --> 0
			seriestype := :shape
			label := "$i"
			x = [0;repeat(si,inner=(2));0]
			y = offset .+ repeat(0:c[i],inner=(2))
			x,y
		end
		# text label to the left of the bars
		@series begin
			primary := false
			seriesalpha := 0
			series_annotations := [ Plots.text("$i",:center,:middle,9) ]
			[-0.04], [offset+c[i]/2]
		end
		offset += c[i];
	end

	# Dashed line for overall average.
	savg = sum(s)/n
	@series begin
		primary := false
		linecolor := :black
		linestyle := :dash
		[savg,savg], [0,n]
	end
end
