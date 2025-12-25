using CasualPlots
using Test

@testset "map_delimiter" begin
    map_delimiter = CasualPlots.map_delimiter

    @test map_delimiter("Auto") === nothing
    @test map_delimiter("Comma") === ','
    @test map_delimiter("Tab") === '\t'
    @test map_delimiter("Space") === ' '
    @test map_delimiter("Semicolon") === ';'
    @test map_delimiter("Pipe") === '|'

    # Test invalid input throws KeyError
    @test_throws KeyError map_delimiter("invalid")
end

@testset "map_decimal_separator" begin
    map_decimal = CasualPlots.map_decimal_separator

    @test map_decimal("Dot") === '.'
    @test map_decimal("Comma") === ','
    @test map_decimal("Dot / Comma") === '.'
    @test map_decimal("Comma / Dot") === ','

    # Test invalid input throws KeyError
    @test_throws KeyError map_decimal("invalid")
end

@testset "map_thousand_separator" begin
    map_thousand = CasualPlots.map_thousand_separator

    @test map_thousand("Dot") === nothing
    @test map_thousand("Comma") === nothing
    @test map_thousand("Dot / Comma") === ','
    @test map_thousand("Comma / Dot") === '.'

    # Test invalid input throws KeyError
    @test_throws KeyError map_thousand("invalid")
end

@testset "mapping helper function" begin
    mapping_fn = CasualPlots.mp

    # Test generic mapping
    options = ["a", "b", "c"]
    vals = [1, 2, 3]

    @test mapping_fn("a", options, vals) == 1
    @test mapping_fn("b", options, vals) == 2
    @test mapping_fn("c", options, vals) == 3

    # Test with different types
    @test mapping_fn("x", ["x", "y"], [true, false]) == true
    @test mapping_fn("y", ["x", "y"], [true, false]) == false

    # Test invalid key
    @test_throws KeyError mapping_fn("d", options, vals)
end
