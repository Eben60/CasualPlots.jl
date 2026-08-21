using CasualPlots
using CSV
using XLSX
using Test
using DataFrames

const ASSETS_DIR = joinpath(@__DIR__, "assets")

# CSV Extension Tests
@testset "read_csv basic functionality" begin
    using CasualPlots: read_csv

    csv_path = joinpath(ASSETS_DIR, "sample_data.csv")
    df = read_csv(csv_path)
    
    @test df isa DataFrame
    @test size(df, 1) == 5  # 5 rows
    @test size(df, 2) == 4  # 4 columns
    @test names(df) == ["id", "name", "value", "active"]
    @test df.id == [1, 2, 3, 4, 5]
    @test df.name == ["Alice", "Bob", "Charlie", "Diana", "Eve"]
end

@testset "read_csv with kwargs" begin
    using CasualPlots: read_csv

    csv_path = joinpath(ASSETS_DIR, "sample_data.csv")
    # Test selecting specific columns
    df = read_csv(csv_path; select=[:id, :name])
    
    @test size(df, 2) == 2
    @test names(df) == ["id", "name"]
end

@testset "read_csv with header on row 2" begin
    using CasualPlots: read_csv

    # empty_rows_sample.csv has header on row 2
    csv_path_header2 = joinpath(ASSETS_DIR, "empty_rows_sample.csv")
    df = read_csv(csv_path_header2; header=2, skipto=3)
    
    @test df isa DataFrame
    @test "id" in names(df)
    @test "val1" in names(df)
    @test "val2" in names(df)
end

@testset "read_csv skip empty rows" begin
    using CasualPlots: read_csv

    csv_path_empty = joinpath(ASSETS_DIR, "empty_rows_headerfirst.csv")
    
    # With ignoreemptyrows=true - ignores completely blank lines, but ",," rows are read as missing
    # File has: header, 2 empty-value rows, 2 data rows, 1 empty-value row, 2 data rows = 7 data rows
    df = read_csv(csv_path_empty; ignoreemptyrows=true)
    @test nrow(df) == 7  # 3 rows with all missing + 4 data rows
    @test collect(skipmissing(df.id)) == [1, 2, 3, 4]
    
    # With ignoreemptyrows=false - same result since ",," rows are not truly blank
    df_with_empty = read_csv(csv_path_empty; ignoreemptyrows=false)
    @test nrow(df_with_empty) == 7
end


@testset "read_csv with skip after header" begin
    using CasualPlots: read_csv

    csv_path_empty = joinpath(ASSETS_DIR, "empty_rows_headerfirst.csv")
    # Skip 2 rows after header (the two ",," rows)
    df = read_csv(csv_path_empty; header=1, skipto=4, ignoreemptyrows=true)
    @test nrow(df) == 5  # Remaining: 2 data, 1 empty-value, 2 data
end


# XLSX Extension Tests
@testset "open_xlsx functionality" begin
    xlsx_path = joinpath(ASSETS_DIR, "sample_data.xlsx")
    # Test that open_xlsx returns a valid XLSX file object
    XLSX.openxlsx(xlsx_path) do xf
        @test length(XLSX.sheetnames(xf)) >= 1
        @test "TestData" in XLSX.sheetnames(xf)
    end
end

@testset "sheetnames_xlsx" begin
    using CasualPlots: sheetnames_xlsx

    xlsx_multisheet = joinpath(ASSETS_DIR, "sample_data-multisheet.xlsx")
    sheets = sheetnames_xlsx(xlsx_multisheet)
    @test sheets isa Vector{String}
    @test length(sheets) >= 1
end

@testset "readtable_xlsx" begin
    using CasualPlots: readtable_xlsx

    xlsx_simple = joinpath(ASSETS_DIR, "sample_data.xlsx")
    df = readtable_xlsx(xlsx_simple, "TestData")
    @test df isa DataFrame
    @test size(df) == (3, 3)
    @test names(df) == ["id", "name", "value"]
    @test eltype(df.id) == Int64
    @test eltype(df.name) == String
    @test eltype(df.value) == Float64

    xlsx_header2 = joinpath(ASSETS_DIR, "row2-header_sample.xlsx")
    df1 = readtable_xlsx(xlsx_header2, "Sheet1"; first_row=2)
    @test nrow(df1) == 4

    xlsx_empty = joinpath(ASSETS_DIR, "empty_rows_sample.xlsx")
    # Reading with keep_empty_rows=false should skip empty rows
    df2 = readtable_xlsx(xlsx_empty, "Sheet1"; 
        first_row=2, keep_empty_rows=false)
    @test nrow(df2) == 4
    df3 = readtable_xlsx(xlsx_empty, "Sheet1"; 
        first_row=2, keep_empty_rows=true)
    @test nrow(df3) == 7

    xlsx_top_header = joinpath(ASSETS_DIR, "empty_rows_top-header_sample.xlsx")
    # File has empty row, then header, then data with some empty rows
    df4 = readtable_xlsx(xlsx_top_header, "Sheet1"; 
        keep_empty_rows=false)
    @test nrow(df4) == 4
end

# Utility function tests
@testset "build_file_filter" begin
    using CasualPlots: build_file_filter

    # When both CSV and XLSX extensions are loaded, should return all formats
    filter_str = build_file_filter()
    @test occursin("csv", filter_str)
    @test occursin("tsv", filter_str)
    @test occursin("xlsx", filter_str)
end

@testset "is_extension_available" begin
    using CasualPlots: is_extension_available

    # Since we've loaded CSV and XLSX, both should be available
    @test is_extension_available(:CSV) == true
    @test is_extension_available(:XLSX) == true
    
    # Unknown extension should throw
    @test_throws Exception is_extension_available(:Unknown)
end

@testset "load_xlsx_sheet_to_table with error states" begin
    using CasualPlots: load_xlsx_sheet_to_table
    
    state = CasualPlots.CasualPlotsState()
    outputs = CasualPlots.OutputObservables()
    
    xlsx_path = joinpath(ASSETS_DIR, "sample_data.xlsx")
    
    # Test valid load updates opened_file_df and table_title
    load_xlsx_sheet_to_table(xlsx_path, "TestData", outputs, state)
    @test state.file_opening.opened_file_df[] isa DataFrame
    @test size(state.file_opening.opened_file_df[]) == (3, 3)
    @test occursin("sample_data.xlsx", outputs.table_title[])
    @test occursin("TestData", outputs.table_title[])
    
    # Test invalid sheet name triggers error pop-up states
    state.dialogs.show_modal[] = false
    load_xlsx_sheet_to_table(xlsx_path, "NonexistentSheet", outputs, state)
    
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :error
    @test occursin("Error loading XLSX sheet", state.file_saving.save_status_message[])
end
