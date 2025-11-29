using CasualPlots
using Test
using DataFrames

@testset "CasualPlots.jl" begin
    @testset "select_cols function" begin
        # Create test dataframe
        df = DataFrame(A = 1:3, B = 4:6, C = 7:9, D = 10:12)
        
        @testset "Default behavior (no kwargs)" begin
            result = CasualPlots.select_cols(df)
            @test size(result) == (3, 4)
            @test names(result) == ["A", "B", "C", "D"]
            @test result.A == df.A
            # Check it's a shallow copy (new DataFrame, shared data)
            @test result !== df
        end
        
        @testset "xcol as Integer" begin
            # Select from column 2 onwards
            result = CasualPlots.select_cols(df, xcol=2)
            @test size(result) == (3, 3)
            @test names(result) == ["B", "C", "D"]
            @test result.B == df.B
            
            # Select from column 3 onwards
            result = CasualPlots.select_cols(df, xcol=3)
            @test size(result) == (3, 2)
            @test names(result) == ["C", "D"]
        end
        
        @testset "xcol as Symbol" begin
            # Select from column :B onwards
            result = CasualPlots.select_cols(df, xcol=:B)
            @test size(result) == (3, 3)
            @test names(result) == ["B", "C", "D"]
            
            # Select from column :C onwards
            result = CasualPlots.select_cols(df, xcol=:C)
            @test size(result) == (3, 2)
            @test names(result) == ["C", "D"]
        end
        
        @testset "xcol as String" begin
            # Select from column "B" onwards
            result = CasualPlots.select_cols(df, xcol="B")
            @test size(result) == (3, 3)
            @test names(result) == ["B", "C", "D"]
        end
        
        @testset "cols argument (specific columns)" begin
            # Select specific columns
            result = CasualPlots.select_cols(df, cols=[:A, :C])
            @test size(result) == (3, 2)
            @test names(result) == ["A", "C"]
            @test result.A == df.A
            @test result.C == df.C
            
            # Select single column
            result = CasualPlots.select_cols(df, cols=[:B])
            @test size(result) == (3, 1)
            @test names(result) == ["B"]
        end
        
        @testset "Error cases" begin
            # Both xcol and cols provided
            @test_throws ErrorException CasualPlots.select_cols(df, xcol=2, cols=[:A, :B])
            
            # Non-existent column name
            @test_throws Exception CasualPlots.select_cols(df, xcol=:NonExistent)
        end
        
        @testset "Copy semantics" begin
            result = CasualPlots.select_cols(df)
            # Modifying result should modify original (shallow copy)
            result.A[1] = 999
            @test df.A[1] == 999
            # Reset for other tests
            df.A[1] = 1
        end
    end
end
