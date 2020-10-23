using StatsPlots
using Test
using StableRNGs
using NaNMath

@testset "Grouped histogram" begin
    rng = StableRNG(1337)
    gpl = groupedhist( rand(rng, 1000), yscale=:log10, ylims=(1e-2, 1e4), bar_position = :stack)
    @test NaNMath.minimum(gpl[1][1][:y]) <= 1e-2
    @test NaNMath.minimum(gpl[1][1][:y]) > 0
    rng = StableRNG(1337)
    gpl = groupedhist( rand(rng, 1000), yscale=:log10, ylims=(1e-2, 1e4), bar_position = :dodge)
    @test NaNMath.minimum(gpl[1][1][:y]) <= 1e-2
    @test NaNMath.minimum(gpl[1][1][:y]) > 0


    data = [1,1,1,1,2,1]
    mask = (collect(1:6) .< 5)
    gpl1 = groupedhist(data[mask], group = mask[mask], color = 1)
    gpl2 = groupedhist(data[.!mask], group = mask[.!mask], color = 2)
    gpl12 = groupedhist(data, group = mask, nbins = 5, bar_position = :stack)
    @test NaNMath.maximum(gpl12[1][2][:y]) == NaNMath.maximum(gpl1[1][1][:y])
    data=[10 12; 1 1; 0.25 0.25]
    gplr = groupedbar(data)
    @test NaNMath.maximum(gplr[1][1][:y]) == 10
    @test NaNMath.maximum(gplr[1][2][:y]) == 12
    gplr = groupedbar(data, bar_position = :stack)
    @test NaNMath.maximum(gplr[1][1][:y]) == 22
    @test NaNMath.maximum(gplr[1][2][:y]) == 12
end # testset
