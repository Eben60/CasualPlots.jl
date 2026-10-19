using CasualPlots
using Test

@testset "map_delimiter" begin
    using CasualPlots: map_delimiter

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
    using CasualPlots: map_decimal_separator

    @test map_decimal_separator("Dot") === '.'
    @test map_decimal_separator("Comma") === ','
    @test map_decimal_separator("Dot / Comma") === '.'
    @test map_decimal_separator("Comma / Dot") === ','

    # Test invalid input throws KeyError
    @test_throws KeyError map_decimal_separator("invalid")
end

@testset "map_thousand_separator" begin
    using CasualPlots: map_thousand_separator

    @test map_thousand_separator("Dot") === nothing
    @test map_thousand_separator("Comma") === nothing
    @test map_thousand_separator("Dot / Comma") === ','
    @test map_thousand_separator("Comma / Dot") === '.'

    # Test invalid input throws KeyError
    @test_throws KeyError map_thousand_separator("invalid")
end

@testset "mapping helper function" begin
    using CasualPlots: mp

    # Test generic mapping
    options = ["a", "b", "c"]
    vals = [1, 2, 3]

    @test mp("a", options, vals) == 1
    @test mp("b", options, vals) == 2
    @test mp("c", options, vals) == 3

    # Test with different types
    @test mp("x", ["x", "y"], [true, false]) == true
    @test mp("y", ["x", "y"], [true, false]) == false

    # Test invalid key
    @test_throws KeyError mp("d", options, vals)
end
