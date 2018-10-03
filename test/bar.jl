import StatPlots: constant_sign_rowwise

@testset "groupedbar" begin
    @test constant_sign_rowwise(rand(10,3))
    @test constant_sign_rowwise([-0.5 0.0 0.5; rand(9,3)]) == false
    @test constant_sign_rowwise([rand(9,3); -0.5 0.0 -0.5]) == true
    @test constant_sign_rowwise([-rand(9,3); 0.5 -0.0 0.5]) == true
end
