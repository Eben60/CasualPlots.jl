using CasualPlots
using Test

@testset "create_data_matrix" begin
    # Basic functionality
    x = 1:5
    n = 3
    result = create_data_matrix(x, n)
    
    @test size(result) == (5, 3)
    @test result isa Matrix{Float64}
    
    # Check that columns are monotonically increasing with x
    for col in 1:n
        @test issorted(result[:, col])
    end
    
    # Check specific values for first column (exponent = 0.5)
    @test result[1, 1] ≈ 1.0^0.5
    @test result[2, 1] ≈ 2.0^0.5
    
    # Single column case
    result_single = create_data_matrix(x, 1)
    @test size(result_single) == (5, 1)
    
    # Empty input
    result_empty = create_data_matrix(Float64[], 3)
    @test size(result_empty) == (0, 3)
end

@testset "make_y" begin
    v = 1.0:5.0
    n = 4
    result = make_y(v, n)
    
    @test size(result) == (5, 4)
    @test result isa Matrix{Float64}
    
    # Check that exponents range from 0.2 to 1.2
    # First column should be v.^0.2, last should be v.^1.2
    @test result[2, 1] ≈ 2.0^0.2
    @test result[2, end] ≈ 2.0^1.2
    
    # All columns should be monotonically increasing
    for col in 1:n
        @test issorted(result[:, col])
    end
    
    # Test with n=2 (minimum for range)
    result_two = make_y(v, 2)
    @test size(result_two) == (5, 2)
    @test result_two[1, 1] ≈ 1.0^0.2
    @test result_two[1, 2] ≈ 1.0^1.2
end
