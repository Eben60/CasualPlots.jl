using Test
using DataFrames
using Dates
using CasualPlots: normalize_strings!, normalize_numeric_columns!

@testset "Data Normalization Tests" begin

    @testset "normalize_strings!" begin
        # Test 1: Standard String column (unchanged)
        df = DataFrame(A = ["a", "b", "c"])
        normalize_strings!(df)
        @test eltype(df.A) == String
        @test df.A == ["a", "b", "c"]
        
        # Test 2: Any column with Strings (Should narrow to String or at least contain Strings)
        df = DataFrame(A = Any["a", "b", "c"])
        normalize_strings!(df)
        # It narrows to String because the comprehension returns Vector{String}
        @test eltype(df.A) == String 
        @test df.A == ["a", "b", "c"]
        
        # Test 3: Mixed Any column
        df = DataFrame(A = Any["a", 1, "c", missing])
        normalize_strings!(df)
        @test eltype(df.A) == Any
        @test df.A[1] isa String
        @test df.A[2] === 1
        @test ismissing(df.A[4])
    end

    @testset "normalize_numeric_columns!" begin
        # Test 1: Concrete types unchanged
        df = DataFrame(
            Ints = [1, 2, 3],
            Floats = [1.1, 2.2, 3.3],
            Bools = [true, false, true],
            Strs = ["a", "b", "c"]
        )
        old_types = [eltype(col) for col in eachcol(df)]
        df_new, dirty = normalize_numeric_columns!(df, names(df))
        
        @test isempty(dirty)
        @test eltype(df_new.Ints) == Int
        @test eltype(df_new.Floats) == Float64
        @test eltype(df_new.Bools) == Bool
        @test eltype(df_new.Strs) == String
        
        # Test 3: Any column (>90% numeric) -> Float64
        # Need > 90% numeric. 9/10 is exactly 0.9 (not > 0.9).
        # Use 19 numbers and 1 string = 19/20 = 0.95
        vals = Any[i for i in 1:19]
        push!(vals, "bad")
        df = DataFrame(A = vals) 
        df_new, dirty = normalize_numeric_columns!(df, ["A"])
        
        @test eltype(df_new.A) == Union{Float64, Missing}
        @test ismissing(df_new.A[20]) # "bad" becomes missing
        @test df_new.A[1] === 1.0 # 1 becomes 1.0
        @test "A" in dirty
        
        # Test 4: Any column (<90% numeric) -> Unchanged
        df = DataFrame(A = Any[1, "a", "b"]) # 33% numeric
        df_new, dirty = normalize_numeric_columns!(df, ["A"])
        @test eltype(df_new.A) == Any
        @test isempty(dirty)
        
        # Test 5: Dates (unchanged)
        df = DataFrame(D = [Date(2023,1,1), Date(2023,1,2)])
        df_new, dirty = normalize_numeric_columns!(df, ["D"])
        @test eltype(df_new.D) == Date
        @test isempty(dirty)
        
        # Test 6: Missing handling
        df = DataFrame(A = Any[1, 2, missing, 4, 5, 6, 7, 8, 9, 10, 11]) # 10 numeric, 1 missing. Ratio 100% of non-missing.
        df_new, dirty = normalize_numeric_columns!(df, ["A"])
        @test eltype(df_new.A) == Union{Float64, Missing}
        @test ismissing(df_new.A[3])
        @test isempty(dirty)
    end
end
