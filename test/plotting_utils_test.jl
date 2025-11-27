using CasualPlots
using Test
using DataFrames

@testset "var_to_string" begin
    # Test with simple symbol
    @test CasualPlots.var_to_string(:myvar) == "myvar"
    
    # Test with qualified name (e.g., Main.myvar)
    @test CasualPlots.var_to_string(Symbol("Main.myvar")) == "myvar"
    @test CasualPlots.var_to_string(Symbol("Some.Module.var")) == "var"
    
    # Test with string input
    @test CasualPlots.var_to_string("myvar") == "myvar"
end

# Note: select_cols is already tested in data_transformations_test.jl
