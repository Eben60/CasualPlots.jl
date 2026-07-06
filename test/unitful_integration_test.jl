using Test
using DataFrames
using Unitful
using CasualPlots
using Observables


@testset "Identical units" begin
    state = CasualPlots.initialize_app_state()
    df = DataFrame(A = [1.0u"m", 2.0u"m"], B = [3.0u"m", 4.0u"m"])
    df_out = CasualPlots.unify_units!(df, ["A", "B"], state)
    
    @test df_out.A[1] isa typeof(1.0u"m") || df_out.A[1] isa Quantity
    @test df_out.B[1] isa typeof(1.0u"m") || df_out.B[1] isa Quantity
    @test Unitful.unit(df_out.A[1]) == u"m"
    @test !state.dialogs.show_modal[]
end

@testset "Mixed compatible units (Metric)" begin
    state = CasualPlots.initialize_app_state()
    df = DataFrame(A = [1.0u"cm", 2.0u"cm"], B = [10.0u"mm", 20.0u"mm"], C = [0.1u"m", 0.2u"m"])
    df_out = CasualPlots.unify_units!(df, ["A", "B", "C"], state)
    
    # Largest unit here is 'm'
    @test Unitful.unit(df_out.A[1]) == u"m"
    @test Unitful.unit(df_out.B[1]) == u"m"
    @test Unitful.unit(df_out.C[1]) == u"m"
    @test df_out.A[1] ≈ 0.01u"m"
    @test df_out.B[1] ≈ 0.01u"m"
    @test !state.dialogs.show_modal[]
end

@testset "Mixed compatible units (Non-Metric fallback)" begin
    state = CasualPlots.initialize_app_state()
    df = DataFrame(A = [1.0u"inch", 2.0u"inch"], B = [1.0u"ft", 2.0u"ft"])
    df_out = CasualPlots.unify_units!(df, ["A", "B"], state)
    
    # Largest overall unit is 'ft'
    @test Unitful.unit(df_out.A[1]) == u"ft"
    @test Unitful.unit(df_out.B[1]) == u"ft"
    @test df_out.A[1] ≈ (1.0/12.0)u"ft"
    @test !state.dialogs.show_modal[]
end

@testset "Mixed metric and non-metric units" begin
    state = CasualPlots.initialize_app_state()
    df = DataFrame(A = [1.0u"inch", 2.0u"inch"], B = [1.0u"m", 2.0u"m"])
    df_out = CasualPlots.unify_units!(df, ["A", "B"], state)
    
    # Largest METRIC unit is 'm'
    @test Unitful.unit(df_out.A[1]) == u"m"
    @test Unitful.unit(df_out.B[1]) == u"m"
    @test df_out.A[1] ≈ 0.0254u"m"
    @test !state.dialogs.show_modal[]
end

@testset "Incompatible units" begin
    state = CasualPlots.initialize_app_state()
    df = DataFrame(A = [1.0u"m", 2.0u"m"], B = [1.0u"m^2", 2.0u"m^2"])
    
    df_out = @test_logs (:warn, r"Incompatible physical dimensions") CasualPlots.unify_units!(df, ["A", "B"], state)
    
    # Should strip units to fallback float/int
    @test !(df_out.A[1] isa Unitful.Quantity)
    @test !(df_out.B[1] isa Unitful.Quantity)
    @test df_out.A[1] == 1.0
    @test df_out.B[1] == 1.0
    
    # Should trigger warning
    @test state.dialogs.show_modal[]
    @test state.dialogs.modal_type[] == :warning
    @test occursin("Incompatible", state.file_saving.save_status_message[])
end

@testset "Internal Mixed Compatible Units" begin
    df = DataFrame(A = Any[1.0u"m", 2.0u"cm", 3.0u"mm"])
    df_out = CasualPlots.unify_internal_column_units!(df, ["A"])
    
    @test Unitful.unit(df_out.A[1]) == u"m"
    @test Unitful.unit(df_out.A[2]) == u"m"
    @test Unitful.unit(df_out.A[3]) == u"m"
    @test df_out.A[2] ≈ 0.02u"m"
    @test df_out.A[3] ≈ 0.003u"m"
end

@testset "Internal Unit Compatibility" begin
    # 1. Compatible but different units (should be unified)
    df_compat = DataFrame(A = Any[1.0u"m", 2.0u"cm", missing])
    df_out = CasualPlots.unify_internal_column_units!(df_compat, ["A"])
    @test Unitful.unit(df_out.A[1]) == u"m"
    @test Unitful.unit(df_out.A[2]) == u"m"

    # 2. Incompatible units in the same column (should throw ArgumentError)
    df_incompat = DataFrame(A = Any[1.0u"m", 2.0u"m^2"])
    @test_throws ArgumentError CasualPlots.check_internal_unit_compatibility!(df_incompat, ["A"])

    # 3. Mixed numbers and units (incompatible)
    df_mixed = DataFrame(A = Any[1.0u"m", 2.0])
    @test_throws ArgumentError CasualPlots.check_internal_unit_compatibility!(df_mixed, ["A"])

    # 4. Strings and missing should be ignored
    df_strings = DataFrame(A = Any[1.0u"m", 2.0u"m", "N/A", missing, "error"])
    @test isnothing(CasualPlots.check_internal_unit_compatibility!(df_strings, ["A"]))
end
