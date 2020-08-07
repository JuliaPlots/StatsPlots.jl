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
end # testset
