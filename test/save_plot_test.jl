using CasualPlots
using Test

validate = CasualPlots.validate_save_path

# Valid paths tests
@testset "validate_save_path - valid paths" begin
    # Test valid extensions
    (valid, msg) = validate("plot.png")
    @test valid == true
    @test msg == ""

    (valid, msg) = validate("output/plot.svg")
    @test valid == true
    @test msg == ""

    (valid, msg) = validate("/absolute/path/to/figure.pdf")
    @test valid == true
    @test msg == ""

    # Test case insensitivity
    (valid, msg) = validate("PLOT.PNG")
    @test valid == true

    (valid, msg) = validate("plot.SVG")
    @test valid == true

    (valid, msg) = validate("plot.Pdf")
    @test valid == true
end

# Invalid paths tests
@testset "validate_save_path - invalid paths" begin
    # Empty path
    (valid, msg) = validate("")
    @test valid == false
    @test occursin("specify", lowercase(msg))

    # Whitespace only
    (valid, msg) = validate("   ")
    @test valid == false
    @test occursin("specify", lowercase(msg))

    # No extension
    (valid, msg) = validate("plotfile")
    @test valid == false
    @test occursin("extension", lowercase(msg))

    # Unsupported extension
    (valid, msg) = validate("plot.jpg")
    @test valid == false
    @test occursin("unsupported", lowercase(msg))

    (valid, msg) = validate("plot.jpeg")
    @test valid == false
    @test occursin("unsupported", lowercase(msg))

    (valid, msg) = validate("plot.gif")
    @test valid == false

    (valid, msg) = validate("plot.bmp")
    @test valid == false

    (valid, msg) = validate("data.csv")
    @test valid == false
end

# Edge cases tests
@testset "validate_save_path - edge cases" begin
    # Path with spaces
    (valid, msg) = validate("  plot.png  ")
    @test valid == true

    # Multiple dots in filename
    (valid, msg) = validate("my.plot.output.png")
    @test valid == true

    # Dot in directory name
    (valid, msg) = validate("path.to/output.svg")
    @test valid == true
end

@testset "SUPPORTED_SAVE_FORMATS constant" begin
    @test "png" in CasualPlots.SUPPORTED_SAVE_FORMATS
    @test "svg" in CasualPlots.SUPPORTED_SAVE_FORMATS
    @test "pdf" in CasualPlots.SUPPORTED_SAVE_FORMATS
    @test length(CasualPlots.SUPPORTED_SAVE_FORMATS) == 3
end
