using Test
using AgenticTesting

@testset "Agent Verification Utils" begin
    app = Main.app
    session = @eval Main begin AgenticTesting.get_active_session() end

    @testset "verify_session_active" begin
        pass, msg = verify_session_active("test_id")
        @test pass == true
        @test occursin("Session is active", msg)
    end

    @testset "verify_observable_value" begin
        app.state.plotting.format.selected_theme[] = "theme_dark"
        pass, msg = verify_observable_value(app.state.plotting.format.selected_theme, "theme_dark", "test_id")
        @test pass == true
        
        pass, msg = verify_observable_value(app.state.plotting.format.selected_theme, "theme_light", "test_id")
        @test pass == false
        @test occursin("expected \"theme_light\"", msg)
    end

    @testset "set_opened_file_path" begin
        test_path = joinpath(@__DIR__, "dummy.csv")
        pass, msg = set_opened_file_path(app, test_path, "test_id")
        @test pass == true
        @test app.state.file_opening.opened_file_path[] == abspath(test_path)
    end

    @testset "verify_file_loaded" begin
        # Currently nothing
        pass, msg = verify_file_loaded(app, "test_id")
        @test pass == false
        
        # Mock a file load
        app.state.file_opening.opened_file_df[] = Main.CasualPlots.DataFrame(x=[1])
        pass, msg = verify_file_loaded(app, "test_id")
        @test pass == true
    end

    @testset "verify_x_selected" begin
        # Switch to array mode
        set_radio_value(session, "source_type", "X, Y Arrays")
        sleep(0.5)
        # Select an X var
        select_dropdown_value(session, "#dropdown-x", "caspl_x_10")
        sleep(0.5)
        
        pass, msg = verify_x_selected(app, "caspl_x_10", "test_id")
        @test pass == true
    end

    @testset "verify_format_is_default" begin
        # The key is marked false when edited
        app.state.misc.format_is_default[:title] = true
        pass, msg = verify_format_is_default(app, :title, "test_id")
        @test pass == true
    end

    @testset "verify_format_is_custom" begin
        app.state.misc.format_is_default[:title] = false
        pass, msg = verify_format_is_custom(app, :title, "test_id")
        @test pass == true
    end

    @testset "verify_file_on_disk" begin
        pass, msg = verify_file_on_disk("nonexistent_file_123.png", "test_id")
        @test pass == false
    end
    
    @testset "log_result" begin
        # Ensure it actually wrote to the results file
        content = read(AgenticTesting.RESULTS_FILE, String)
        @test occursin("[PASS]", content) || occursin("[FAIL]", content)
    end
end
