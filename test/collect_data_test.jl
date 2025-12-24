using CasualPlots
using Test
using DataFrames

# Ensure DataFrames is available in Main for the tests that need it
if !isdefined(Main, :DataFrames)
    Main.eval(:(using DataFrames))
end

@testset "get_dims_of_arrays" begin
    # Create test data in Main module using eval
    Main.eval(:(test_vec = [1, 2, 3]))
    Main.eval(:(test_mat = [1 2; 3 4; 5 6]))
    Main.eval(:(test_scalar = 42))
    
    dims_dict = CasualPlots.get_dims_of_arrays()
    
    @test haskey(dims_dict, :test_vec)
    @test dims_dict[:test_vec] == (3,)
    
    @test haskey(dims_dict, :test_mat)
    @test dims_dict[:test_mat] == (3, 2)
    
    # Scalar shouldn't be included (it's not an array)
    @test !haskey(dims_dict, :test_scalar)
end

@testset "get_congruent_y_names" begin
    # Setup test data
    dims_dict = Dict{Symbol, Tuple}(
        :x1 => (10,),
        :y1 => (10,),
        :y2 => (10, 2),
        :z1 => (5,),
        :z2 => (5, 3)
    )
    
    # Find all variables with first dimension = 10
    result = CasualPlots.get_congruent_y_names("x1", dims_dict)
    @test "y1" in result
    @test "y2" in result
    @test !("z1" in result)
    @test !("z2" in result)
    @test !("x1" in result)  # Should exclude self
    
    # Find all variables with first dimension = 5
    result = CasualPlots.get_congruent_y_names("z1", dims_dict)
    @test "z2" in result
    @test !("x1" in result)
    @test !("y1" in result)
    
    # Empty or nothing input
    result = CasualPlots.get_congruent_y_names("", dims_dict)
    @test isempty(result)
    
    result = CasualPlots.get_congruent_y_names(nothing, dims_dict)
    @test isempty(result)
    
    # Non-existent variable
    result = CasualPlots.get_congruent_y_names("nonexistent", dims_dict)
    @test isempty(result)
end

@testset "collect_dataframes_from_main" begin
    # Create test DataFrames in Main using eval
    Main.eval(:(test_df1 = DataFrame(a = 1:3, b = 4:6)))
    Main.eval(:(test_df2 = DataFrame(x = [" a", "b"], y = [1.0, 2.0])))
    Main.eval(:(test_not_df = [1, 2, 3]))
    
    df_names = CasualPlots.collect_dataframes_from_main()
    
    @test :test_df1 in df_names
    @test :test_df2 in df_names
    @test !(:test_not_df in df_names)
end

@testset "get_dataframe_columns" begin
    # Create test DataFrame in Main using eval
    Main.eval(:(test_df = DataFrame(col1 = 1:3, col2 = 4:6, col3 = 7:9)))
    
    columns = CasualPlots.get_dataframe_columns("test_df")
    @test columns == ["col1", "col2", "col3"]
    
    # Non-existent DataFrame should return empty and log a warning
    @test_logs (:warn, r"Could not get columns for DataFrame `nonexistent_df`") begin
        columns = CasualPlots.get_dataframe_columns("nonexistent_df")
        @test isempty(columns)
    end
end

@testset "extract_x_candidates" begin
    # Test 1: Mixed dimensions - should only return 1D arrays
    dims_dict = Dict{Symbol, Tuple}(
        :vec1 => (10,),
        :vec2 => (5,),
        :mat1 => (10, 3),
        :mat2 => (5, 2),
        :tensor => (3, 4, 5)
    )
    
    result = CasualPlots.extract_x_candidates(dims_dict)
    @test length(result) == 2
    @test "vec1" in result
    @test "vec2" in result
    @test !("mat1" in result)
    @test !("mat2" in result)
    @test !("tensor" in result)
    
    # Test 2: Result should be sorted
    @test issorted(result)
    
    # Test 3: Empty dictionary
    empty_dict = Dict{Symbol, Tuple}()
    result = CasualPlots.extract_x_candidates(empty_dict)
    @test isempty(result)
    
    # Test 4: All matrices (no vectors)
    no_vectors = Dict{Symbol, Tuple}(
        :mat1 => (10, 3),
        :mat2 => (5, 2)
    )
    result = CasualPlots.extract_x_candidates(no_vectors)
    @test isempty(result)
    
    # Test 5: All vectors
    all_vectors = Dict{Symbol, Tuple}(
        :a => (10,),
        :b => (20,),
        :c => (5,)
    )
    result = CasualPlots.extract_x_candidates(all_vectors)
    @test length(result) == 3
    @test result == ["a", "b", "c"]  # sorted
end
