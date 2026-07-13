using CasualPlots
using Test

validate = CasualPlots.validate_save_path

# Valid paths tests
@testset "validate_save_path - valid paths" begin
    # Test valid extensions
    val = validate("plot.png")
    @test val.valid == true
    @test val.error_message == ""
    @test val.path == "plot.png"

    val = validate("output/plot.svg")
    @test val.valid == true
    @test val.error_message == ""
    @test val.path == "output/plot.svg"

    val = validate("/absolute/path/to/figure.pdf")
    @test val.valid == true
    @test val.error_message == ""
    @test val.path == "/absolute/path/to/figure.pdf"

    # Test case insensitivity and warnings
    @test_logs (:warn, r"requires lowercase extensions") begin
        val = validate("PLOT.PNG")
        @test val.valid == true
        @test val.path == "PLOT.png"
    end

    @test_logs (:warn, r"requires lowercase extensions") begin
        val = validate("plot.SVG")
        @test val.valid == true
        @test val.path == "plot.svg"
    end

    @test_logs (:warn, r"requires lowercase extensions") begin
        val = validate("plot.Pdf")
        @test val.valid == true
        @test val.path == "plot.pdf"
    end
end

# Invalid paths tests
@testset "validate_save_path - invalid paths" begin
    # Empty path
    val = validate("")
    @test val.valid == false
    @test occursin("specify", lowercase(val.error_message))

    # Whitespace only
    val = validate("   ")
    @test val.valid == false
    @test occursin("specify", lowercase(val.error_message))

    # No extension
    val = validate("plotfile")
    @test val.valid == false
    @test occursin("extension", lowercase(val.error_message))

    # Unsupported extension
    val = validate("plot.jpg")
    @test val.valid == false
    @test occursin("unsupported", lowercase(val.error_message))

    val = validate("plot.jpeg")
    @test val.valid == false
    @test occursin("unsupported", lowercase(val.error_message))

    val = validate("plot.gif")
    @test val.valid == false

    val = validate("plot.bmp")
    @test val.valid == false

    val = validate("data.csv")
    @test val.valid == false
end

# Edge cases tests
@testset "validate_save_path - edge cases" begin
    # Path with spaces
    val = validate("  plot.png  ")
    @test val.valid == true
    @test val.path == "plot.png"

    # Multiple dots in filename
    val = validate("my.plot.output.png")
    @test val.valid == true
    @test val.path == "my.plot.output.png"

    # Dot in directory name
    val = validate("path.to/output.svg")
    @test val.valid == true
    @test val.path == "path.to/output.svg"
end

@testset "SUPPORTED_SAVE_FORMATS constant" begin
    @test "png" in CasualPlots.SUPPORTED_SAVE_FORMATS
    @test "svg" in CasualPlots.SUPPORTED_SAVE_FORMATS
    @test "pdf" in CasualPlots.SUPPORTED_SAVE_FORMATS
    @test length(CasualPlots.SUPPORTED_SAVE_FORMATS) == 3
end
