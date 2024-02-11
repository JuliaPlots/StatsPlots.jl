using StatsPlots
using Test
using StableRNGs
using NaNMath
using Clustering
using Distributions
using MultivariateStats
using DataFrames
using CategoricalArrays
using GLM
using StatsModels: DummyCoding

@testset "Grouped histogram" begin
    rng = StableRNG(1337)
    gpl = groupedhist(
        rand(rng, 1000),
        yscale = :log10,
        ylims = (1e-2, 1e4),
        bar_position = :stack,
    )
    @test NaNMath.minimum(gpl[1][1][:y]) <= 1e-2
    @test NaNMath.minimum(gpl[1][1][:y]) > 0
    rng = StableRNG(1337)
    gpl = groupedhist(
        rand(rng, 1000),
        yscale = :log10,
        ylims = (1e-2, 1e4),
        bar_position = :dodge,
    )
    @test NaNMath.minimum(gpl[1][1][:y]) <= 1e-2
    @test NaNMath.minimum(gpl[1][1][:y]) > 0

    data = [1, 1, 1, 1, 2, 1]
    mask = (collect(1:6) .< 5)
    gpl1 = groupedhist(data[mask], group = mask[mask], color = 1)
    gpl2 = groupedhist(data[.!mask], group = mask[.!mask], color = 2)
    gpl12 = groupedhist(data, group = mask, nbins = 5, bar_position = :stack)
    @test NaNMath.maximum(gpl12[1][end][:y]) == NaNMath.maximum(gpl1[1][1][:y])
    data = [10 12; 1 1; 0.25 0.25]
    gplr = groupedbar(data)
    @test NaNMath.maximum(gplr[1][1][:y]) == 10
    @test NaNMath.maximum(gplr[1][end][:y]) == 12
    gplr = groupedbar(data, bar_position = :stack)
    @test NaNMath.maximum(gplr[1][1][:y]) == 22
    @test NaNMath.maximum(gplr[1][end][:y]) == 12
end # testset

@testset "dendrogram" begin
    # Example from https://en.wikipedia.org/wiki/Complete-linkage_clustering
    wiki_example = [
        0 17 21 31 23
        17 0 30 34 21
        21 30 0 28 39
        31 34 28 0 43
        23 21 39 43 0
    ]
    clustering = hclust(wiki_example, linkage = :complete)

    xs, ys = StatsPlots.treepositions(clustering, true, :vertical)

    @test xs == [
        2.0 1.0 4.0 1.75
        2.0 1.0 4.0 1.75
        3.0 2.5 5.0 4.5
        3.0 2.5 5.0 4.5
    ]

    @test ys == [
        0.0 0.0 0.0 23.0
        17.0 23.0 28.0 43.0
        17.0 23.0 28.0 43.0
        0.0 17.0 0.0 28.0
    ]
end

@testset "Histogram" begin
    data = randn(1000)
    @test 0.2 < StatsPlots.wand_bins(data) < 0.4
end

@testset "Distributions" begin
    @testset "univariate" begin
        @testset "discrete" begin
            pbern = plot(Bernoulli(0.25))
            @test pbern[1][1][:x][1:2] == zeros(2)
            @test pbern[1][1][:x][4:5] == ones(2)
            @test pbern[1][1][:y][[1, 4]] == zeros(2)
            @test pbern[1][1][:y][[2, 5]] == [0.75, 0.25]

            pdirac = plot(Dirac(0.25))
            @test pdirac[1][1][:x][1:2] == [0.25, 0.25]
            @test pdirac[1][1][:y][1:2] == [0, 1]

            ppois_unbounded = plot(Poisson(1))
            @test ppois_unbounded[1][1][:x] isa AbstractVector
            @test ppois_unbounded[1][1][:x][1:2] == zeros(2)
            @test ppois_unbounded[1][1][:x][4:5] == ones(2)
            @test ppois_unbounded[1][1][:y][[1, 4]] == zeros(2)
            @test ppois_unbounded[1][1][:y][[2, 5]] ==
                  pdf.(Poisson(1), ppois_unbounded[1][1][:x][[1, 4]])

            pnonint = plot(Bernoulli(0.75) - 1 // 2)
            @test pnonint[1][1][:x][1:2] == [-1 // 2, -1 // 2]
            @test pnonint[1][1][:x][4:5] == [1 // 2, 1 // 2]
            @test pnonint[1][1][:y][[1, 4]] == zeros(2)
            @test pnonint[1][1][:y][[2, 5]] == [0.25, 0.75]

            pmix = plot(
                MixtureModel([Bernoulli(0.75), Bernoulli(0.5)], [0.5, 0.5]);
                components = false,
            )
            @test pmix[1][1][:x][1:2] == zeros(2)
            @test pmix[1][1][:x][4:5] == ones(2)
            @test pmix[1][1][:y][[1, 4]] == zeros(2)
            @test pmix[1][1][:y][[2, 5]] == [0.375, 0.625]

            dzip = MixtureModel([Dirac(0), Poisson(1)], [0.1, 0.9])
            pzip = plot(dzip; components = false)
            @test pzip[1][1][:x] isa AbstractVector
            @test pzip[1][1][:y][2:3:end] == pdf.(dzip, Int.(pzip[1][1][:x][1:3:end]))
        end
    end
end

@testset "ordinations" begin
    @testset "MDS" begin
        X = randn(4, 100)
        M = fit(MultivariateStats.MDS, X; maxoutdim = 3, distances = false)
        Y = MultivariateStats.predict(M)'

        mds_plt = plot(M)
        @test mds_plt[1][1][:x] == Y[:, 1]
        @test mds_plt[1][1][:y] == Y[:, 2]
        @test mds_plt[1][:xaxis][:guide] == "MDS1"
        @test mds_plt[1][:yaxis][:guide] == "MDS2"

        mds_plt2 = plot(M; mds_axes = (3, 1, 2))
        @test mds_plt2[1][1][:x] == Y[:, 3]
        @test mds_plt2[1][1][:y] == Y[:, 1]
        @test mds_plt2[1][1][:z] == Y[:, 2]
        @test mds_plt2[1][:xaxis][:guide] == "MDS3"
        @test mds_plt2[1][:yaxis][:guide] == "MDS1"
        @test mds_plt2[1][:zaxis][:guide] == "MDS2"
    end
end

@testset "errorline" begin
    rng = StableRNG(1337)
    x = 1:10
    # Test for floats
    y = rand(rng, 10, 100) .* collect(1:2:20)
    @test errorline(1:10, y)[1][1][:x] == x # x-input
    @test all(
        round.(errorline(1:10, y)[1][1][:y], digits = 3) .==
        round.(mean(y, dims = 2), digits = 3),
    ) # mean of y
    @test all(
        round.(errorline(1:10, y)[1][1][:ribbon], digits = 3) .==
        round.(std(y, dims = 2), digits = 3),
    ) # std of y
    # Test for ints
    y = reshape(1:100, 10, 10)
    @test all(errorline(1:10, y)[1][1][:y] .== mean(y, dims = 2))
    @test all(
        round.(errorline(1:10, y)[1][1][:ribbon], digits = 3) .==
        round.(std(y, dims = 2), digits = 3),
    )
    # Test colors
    y = rand(rng, 10, 100, 3) .* collect(1:2:20)
    c = palette(:default)
    e = errorline(1:10, y)
    @test colordiff(c[1], e[1][1][:linecolor]) == 0.0
    @test colordiff(c[2], e[1][2][:linecolor]) == 0.0
    @test colordiff(c[3], e[1][3][:linecolor]) == 0.0
end

@testset "marginalhist" begin
    rng = StableRNG(1337)
    pl = marginalhist(rand(rng, 100), rand(rng, 100))
    @test show(devnull, pl) isa Nothing
end

@testset "marginalscatter" begin
    rng = StableRNG(1337)
    pl = marginalscatter(rand(rng, 100), rand(rng, 100))
    @test show(devnull, pl) isa Nothing
end

@testset "coefplot" begin
    @testset "GLM" begin
        N = 20
        data = DataFrame(x=randn(N), y=randn(N), c=categorical(rand(1:3, N)), d=categorical(rand(1:3, N)))
        m1 = lm(@formula(y ~ x * c), data)

        @test_throws ArgumentError coefplot(data.x)

        cp1 = coefplot(m1; intercept=true)
        @test cp1[1][:yaxis][:ticks] == (
                [5.5, 4.5, 3.5, 2.5, 1.5, 0.5],
                ["(Intercept)", "x", "c: 2", "c: 3", "x & c: 2", "x & c: 3"],
        )
        cp2 = coefplot(m1; headers=true)
        @test cp2[1][:yaxis][:ticks] == (
                [4.5, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5],
                ["x", "c: 1", "2", "3", "x & c: x & 1", "x & 2", "x & 3"],
        )
        cp3 = coefplot(m1; headers=true, term_width=4, incategory_width=1.5, offset=1)
        @test cp3[1][:yaxis][:ticks] == (
                [15.0, 11.0, 9.5, 8.0, 4.0, 2.5, 1.0],
                ["x", "c: 1", "2", "3", "x & c: x & 1", "x & 2", "x & 3"],
        )

        # test headers
        m2 = glm(@formula(y ~ 0 + x & c), data, Normal())
        cp4 = groupedcoefplot(m1, m2; intercept=true, headers=false)
        @test cp4[1][:yaxis][:ticks] == (
                [6.5, 5.5, 4.5, 3.5, 2.5, 1.5, 0.5],
                ["(Intercept)", "x", "c: 2", "c: 3", "x & c: 2", "x & c: 3", "x & c: 1"],
        )
        cp5 = groupedcoefplot(m1, m2; intercept=true, headers=true)
        @test cp5[1][:yaxis][:ticks] == (
                [5.5, 4.5, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5],
                ["(Intercept)", "x", "c: 1", "2", "3", "x & c: x & 1", "x & 2", "x & 3"],
        )

        # test same subcategory ("2" and "3" for terms "c" and "d")
        m3 = lm(@formula(y ~ x + c * d), data)
        cp6 = coefplot(m3; intercept=true, headers=true)
        @test cp6[1][:yaxis][:ticks] == (
                [10.5, 9.5, 8.5, 8.0, 7.5, 6.5, 6.0, 5.5, 4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5],
                ["(Intercept)", "x", "c: 1", "2", "3", "d: 1", "2", "3", "c & d: 1 & 1", "2 & 1", "3 & 1", "1 & 2", "2 & 2", "3 & 2", "1 & 3", "2 & 3", "3 & 3"],
        )
        m4 = lm(@formula(y ~ -1 + c + d), data)
        cp7 = groupedcoefplot(m3, m4; intercept=true, headers=true)
        @test cp7[1][:yaxis][:ticks] == (
                [10.5, 9.5, 8.5, 8.0, 7.5, 6.5, 6.0, 5.5, 4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5],
                ["(Intercept)", "x", "c: 1", "2", "3", "d: 1", "2", "3", "c & d: 1 & 1", "2 & 1", "3 & 1", "1 & 2", "2 & 2", "3 & 2", "1 & 3", "2 & 3", "3 & 3"],
        )
        m5 = lm(@formula(y ~ x * c + d), data)
        cp8 = groupedcoefplot(m3, m5; intercept=true, headers=true)
        @test cp8[1][:yaxis][:ticks] == (
                [12.5, 11.5, 10.5, 10.0, 9.5, 8.5, 8.0, 7.5, 6.5, 6.0, 5.5, 5.0, 4.5, 4.0, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5],
                ["(Intercept)", "x", "c: 1", "2", "3", "d: 1", "2", "3", "c & d: 1 & 1", "2 & 1", "3 & 1", "1 & 2", "2 & 2", "3 & 2", "1 & 3", "2 & 3", "3 & 3", "x & c: x & 1", "x & 2", "x & 3"],
        )

        # Test strict_names_order
        m6 = lm(@formula(y ~ x * c + d), data, contrasts = Dict(:d => DummyCoding(base=3)))
        cp9 = groupedcoefplot(m5, m6; intercept=false, headers=true, strict_names_order=false)
        @test cp9[1][:yaxis][:ticks] == (
                [6.5, 5.5, 5.0, 4.5, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5],
                ["x", "c: 1", "2", "3", "d: 1", "2", "3", "x & c: x & 1", "x & 2", "x & 3"],
        )
        cp10 = groupedcoefplot(m5, m6; intercept=false, headers=true, strict_names_order=true)
        @test cp10[1][:yaxis][:ticks] == (
                [8.5, 7.5, 7.0, 6.5, 5.5, 5.0, 4.5, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5],
                ["x", "c: 1", "2", "3", "d: 1", "2", "3", "x & c: x & 1", "x & 2", "x & 3", "d: 3", "1", "2"],
        )

        # Test groupedcoefplot spacing
        cp11 = groupedcoefplot(m3, m5; intercept=true, headers=true, term_width=4, incategory_width=2.5, offset=3, group_offset=1)
        @test cp11[1][:yaxis][:ticks] == (
                [58.0, 54.0, 50.0, 47.5, 45.0, 41.0, 38.5, 36.0, 32.0, 29.5, 27.0, 24.5, 22.0, 19.5, 17.0, 14.5, 12.0, 8.0, 5.5, 3.0],
                ["(Intercept)", "x", "c: 1", "2", "3", "d: 1", "2", "3", "c & d: 1 & 1", "2 & 1", "3 & 1", "1 & 2", "2 & 2", "3 & 2", "1 & 3", "2 & 3", "3 & 3", "x & c: x & 1", "x & 2", "x & 3"],
        )

        # Test horizontal orientation
        cp12 = coefplot(m1; orientation=:h, headers=true, term_width=4, incategory_width=1.5, offset=1)
        @test cp12[1][:yaxis][:ticks] == :auto
        @test cp12[1][:xaxis][:ticks] == (
                [1.0, 5.0, 6.5, 8.0, 12.0, 13.5, 15.0],
                ["x", "c: 1", "2", "3", "x & c: x & 1", "x & 2", "x & 3"],
        )

    end
end
