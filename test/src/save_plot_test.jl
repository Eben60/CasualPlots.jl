using CasualPlots
using Test

# Valid paths tests
@testset "validate_save_path - valid paths" begin
    using CasualPlots: validate_save_path

    # Test valid extensions
    val = validate_save_path("plot.png")
    @test val.valid == true
    @test val.error_message == ""
    @test val.path == "plot.png"

    val = validate_save_path("output/plot.svg")
    @test val.valid == true
    @test val.error_message == ""
    @test val.path == "output/plot.svg"

    val = validate_save_path("/absolute/path/to/figure.pdf")
    @test val.valid == true
    @test val.error_message == ""
    @test val.path == "/absolute/path/to/figure.pdf"

    # Test case insensitivity and warnings
    @test_logs (:warn, r"requires lowercase extensions") begin
        val = validate_save_path("PLOT.PNG")
        @test val.valid == true
        @test val.path == "PLOT.png"
    end

    @test_logs (:warn, r"requires lowercase extensions") begin
        val = validate_save_path("plot.SVG")
        @test val.valid == true
        @test val.path == "plot.svg"
    end

    @test_logs (:warn, r"requires lowercase extensions") begin
        val = validate_save_path("plot.Pdf")
        @test val.valid == true
        @test val.path == "plot.pdf"
    end
end

# Invalid paths tests
@testset "validate_save_path - invalid paths" begin
    using CasualPlots: validate_save_path

    # Empty path
    val = validate_save_path("")
    @test val.valid == false
    @test occursin("specify", lowercase(val.error_message))

    # Whitespace only
    val = validate_save_path("   ")
    @test val.valid == false
    @test occursin("specify", lowercase(val.error_message))

    # No extension
    val = validate_save_path("plotfile")
    @test val.valid == false
    @test occursin("extension", lowercase(val.error_message))

    # Unsupported extension
    val = validate_save_path("plot.jpg")
    @test val.valid == false
    @test occursin("unsupported", lowercase(val.error_message))

    val = validate_save_path("plot.jpeg")
    @test val.valid == false
    @test occursin("unsupported", lowercase(val.error_message))

    val = validate_save_path("plot.gif")
    @test val.valid == false

    val = validate_save_path("plot.bmp")
    @test val.valid == false

    val = validate_save_path("data.csv")
    @test val.valid == false
end

# Edge cases tests
@testset "validate_save_path - edge cases" begin
    using CasualPlots: validate_save_path

    # Path with spaces
    val = validate_save_path("  plot.png  ")
    @test val.valid == true
    @test val.path == "plot.png"

    # Multiple dots in filename
    val = validate_save_path("my.plot.output.png")
    @test val.valid == true
    @test val.path == "my.plot.output.png"

    # Dot in directory name
    val = validate_save_path("path.to/output.svg")
    @test val.valid == true
    @test val.path == "path.to/output.svg"
end

@testset "SUPPORTED_SAVE_FORMATS constant" begin
    using CasualPlots: SUPPORTED_SAVE_FORMATS

    @test "png" in SUPPORTED_SAVE_FORMATS
    @test "svg" in SUPPORTED_SAVE_FORMATS
    @test "pdf" in SUPPORTED_SAVE_FORMATS
    @test length(SUPPORTED_SAVE_FORMATS) == 3
end
