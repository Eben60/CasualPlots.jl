using CasualPlots
using CSV
using XLSX
using Test
using DataFrames

const ASSETS_DIR = joinpath(@__DIR__, "assets")

@testset "CSV Extension" begin
    csv_path = joinpath(ASSETS_DIR, "sample_data.csv")
    
    @testset "read_csv basic functionality" begin
        df = CasualPlots.read_csv(csv_path)
        
        @test df isa DataFrame
        @test size(df, 1) == 5  # 5 rows
        @test size(df, 2) == 4  # 4 columns
        @test names(df) == ["id", "name", "value", "active"]
        @test df.id == [1, 2, 3, 4, 5]
        @test df.name == ["Alice", "Bob", "Charlie", "Diana", "Eve"]
    end
    
    @testset "read_csv with kwargs" begin
        # Test selecting specific columns
        df = CasualPlots.read_csv(csv_path; select=[:id, :name])
        
        @test size(df, 2) == 2
        @test names(df) == ["id", "name"]
    end
end

@testset "XLSX Extension" begin
    xlsx_path = joinpath(ASSETS_DIR, "sample_data.xlsx")
    
    # # Generate test XLSX file if it doesn't exist
    # if !isfile(xlsx_path)
    #     XLSX.openxlsx(xlsx_path; mode="w") do xf
    #         sheet = xf[1]
    #         XLSX.rename!(sheet, "TestData")
    #         sheet["A1"] = "id"
    #         sheet["B1"] = "name"
    #         sheet["C1"] = "value"
    #         for (i, (id, name, val)) in enumerate([(1, "Alice", 10.5), (2, "Bob", 20.3), (3, "Charlie", 15.7)])
    #             sheet["A$(i+1)"] = id
    #             sheet["B$(i+1)"] = name
    #             sheet["C$(i+1)"] = val
    #         end
    #     end
    # end
    
    @testset "readtable_xlsx basic functionality" begin
        df = CasualPlots.readtable_xlsx(xlsx_path, "TestData")
        
        @test df isa DataFrame
        @test size(df, 1) == 3  # 3 data rows
        @test size(df, 2) == 3  # 3 columns
        @test "id" in names(df)
        @test "name" in names(df)
        @test "value" in names(df)
    end
    
    @testset "open_xlsx functionality" begin
        # Test that open_xlsx returns a valid XLSX file object
        XLSX.openxlsx(xlsx_path) do xf
            @test length(XLSX.sheetnames(xf)) >= 1
            @test "TestData" in XLSX.sheetnames(xf)
        end
    end
end
