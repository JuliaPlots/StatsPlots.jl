
# Only allow matrices through, and make it seriestype :spy so the backend can
# optionally handle it natively.

@userplot Spy

@recipe function f(g::Spy)
    @assert length(g.args) == 1 && typeof(g.args[1]) <: AbstractMatrix
    seriestype := :spy
    mat = g.args[1]
    n,m = size(mat)
    Plots.SliceIt, 1:m, 1:n, Surface(mat)
end

@recipe function f(::Type{Val{:spy}}, x,y,z)
    yflip := true
    aspect_ratio := 1
    seriestype := :heatmap
    ()
end
