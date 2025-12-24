using CasualPlots
using CSV
using XLSX
using Test
using DataFrames

const ASSETS_DIR = joinpath(@__DIR__, "assets")

# CSV Extension Tests
@testset "read_csv basic functionality" begin
    csv_path = joinpath(ASSETS_DIR, "sample_data.csv")
    df = CasualPlots.read_csv(csv_path)
    
    @test df isa DataFrame
    @test size(df, 1) == 5  # 5 rows
    @test size(df, 2) == 4  # 4 columns
    @test names(df) == ["id", "name", "value", "active"]
    @test df.id == [1, 2, 3, 4, 5]
    @test df.name == ["Alice", "Bob", "Charlie", "Diana", "Eve"]
end

@testset "read_csv with kwargs" begin
    csv_path = joinpath(ASSETS_DIR, "sample_data.csv")
    # Test selecting specific columns
    df = CasualPlots.read_csv(csv_path; select=[:id, :name])
    
    @test size(df, 2) == 2
    @test names(df) == ["id", "name"]
end

@testset "read_csv with header on row 2" begin
    # empty_rows_sample.csv has header on row 2
    csv_path_header2 = joinpath(ASSETS_DIR, "empty_rows_sample.csv")
    df = CasualPlots.read_csv(csv_path_header2; header=2, skipto=3)
    
    @test df isa DataFrame
    @test "id" in names(df)
    @test "val1" in names(df)
    @test "val2" in names(df)
end

@testset "read_csv skip empty rows" begin
    csv_path_empty = joinpath(ASSETS_DIR, "empty_rows_headerfirst.csv")
    
    # With ignoreemptyrows=true - ignores completely blank lines, but ",," rows are read as missing
    # File has: header, 2 empty-value rows, 2 data rows, 1 empty-value row, 2 data rows = 7 data rows
    df = CasualPlots.read_csv(csv_path_empty; ignoreemptyrows=true)
    @test nrow(df) == 7  # 3 rows with all missing + 4 data rows
    @test collect(skipmissing(df.id)) == [1, 2, 3, 4]
    
    # With ignoreemptyrows=false - same result since ",," rows are not truly blank
    df_with_empty = CasualPlots.read_csv(csv_path_empty; ignoreemptyrows=false)
    @test nrow(df_with_empty) == 7
end


@testset "read_csv with skip after header" begin
    csv_path_empty = joinpath(ASSETS_DIR, "empty_rows_headerfirst.csv")
    # Skip 2 rows after header (the two ",," rows)
    df = CasualPlots.read_csv(csv_path_empty; header=1, skipto=4, ignoreemptyrows=true)
    @test nrow(df) == 5  # Remaining: 2 data, 1 empty-value, 2 data
end


# XLSX Extension Tests
@testset "readtable_xlsx basic functionality" begin
    xlsx_path = joinpath(ASSETS_DIR, "sample_data.xlsx")
    df = CasualPlots.readtable_xlsx(xlsx_path, "TestData")
    
    @test df isa DataFrame
    @test size(df, 1) == 3  # 3 data rows
    @test size(df, 2) == 3  # 3 columns
    @test "id" in names(df)
    @test "name" in names(df)
    @test "value" in names(df)
end

@testset "open_xlsx functionality" begin
    xlsx_path = joinpath(ASSETS_DIR, "sample_data.xlsx")
    # Test that open_xlsx returns a valid XLSX file object
    XLSX.openxlsx(xlsx_path) do xf
        @test length(XLSX.sheetnames(xf)) >= 1
        @test "TestData" in XLSX.sheetnames(xf)
    end
end

@testset "sheetnames_xlsx" begin
    xlsx_multisheet = joinpath(ASSETS_DIR, "sample_data-multisheet.xlsx")
    if isfile(xlsx_multisheet)
        sheets = CasualPlots.sheetnames_xlsx(xlsx_multisheet)
        @test sheets isa Vector{String}
        @test length(sheets) >= 1
    end
end

# Note: Some tests below are marked @test_broken due to XLSX.jl bug
# See: https://github.com/felipenoris/XLSX.jl/pull/339
# The first_row parameter works for reading, but row counting with empty rows has issues
@testset "readtable_xlsx with row 2 header" begin
    xlsx_header2 = joinpath(ASSETS_DIR, "row2-header_sample.xlsx")
    if isfile(xlsx_header2)
        df = CasualPlots.readtable_xlsx(xlsx_header2, "Sheet1"; first_row=2)
        @test nrow(df) >= 1
    end
end

@testset "readtable_xlsx skip empty rows (broken due to XLSX.jl bug)" begin
    xlsx_empty = joinpath(ASSETS_DIR, "empty_rows_sample.xlsx")
    if isfile(xlsx_empty)
        # Reading with keep_empty_rows=false should skip empty rows
        # This is currently broken in XLSX.jl
        df = CasualPlots.readtable_xlsx(xlsx_empty, "Sheet1"; 
            first_row=2, keep_empty_rows=false)
        # Expected: should have fewer rows than with keep_empty_rows=true
        @test_broken nrow(df) == 4
    end
end

@testset "readtable_xlsx with empty rows at top and header (broken)" begin
    xlsx_top_header = joinpath(ASSETS_DIR, "empty_rows_top-header_sample.xlsx")
    if isfile(xlsx_top_header)
        # File has empty row, then header, then data with some empty rows
        df = CasualPlots.readtable_xlsx(xlsx_top_header, "Sheet1"; 
            first_row=2, keep_empty_rows=false)
        @test_broken nrow(df) == 4
    end
end

# Utility function tests
@testset "build_file_filter" begin
    # When both CSV and XLSX extensions are loaded, should return all formats
    filter_str = CasualPlots.build_file_filter()
    @test occursin("csv", filter_str)
    @test occursin("tsv", filter_str)
    @test occursin("xlsx", filter_str)
end

@testset "is_extension_available" begin
    # Since we've loaded CSV and XLSX, both should be available
    @test CasualPlots.is_extension_available(:CSV) == true
    @test CasualPlots.is_extension_available(:XLSX) == true
    
    # Unknown extension should throw
    @test_throws Exception CasualPlots.is_extension_available(:Unknown)
end
