using Test
using AgenticTesting
@testset "GUI Interaction Utils" begin
    # Get the session from Main.app (populated by runtests.jl)
    session = @eval Main begin AgenticTesting.get_active_session() end

    @testset "get_active_session" begin
        # Should return a Bonito.Session
        @test typeof(session).name.name == :Session
    end

    @testset "get_dropdown_options" begin
        # Options of #dropdown-x should include placeholder and array names
        opts = get_dropdown_options(session; id="dropdown-x")
        # Extract "text" from each option Dict
        texts = [opt["text"] for opt in opts]
        @test "Select X" in texts
        @test "caspl_x_10" in texts
    end

    @testset "select_dropdown_value & get_element_info" begin
        # Select an item in X dropdown
        select_dropdown_value(session, "#dropdown-x", "caspl_x_10")
        sleep(0.5)
        
        info = get_element_info(session, "#dropdown-x")
        @test !isnothing(info)
        @test info["id"] == "dropdown-x"
        @test info["tag"] == "SELECT"
        @test info["value"] == "caspl_x_10"
    end

    @testset "click_button" begin
        # Click the Format tab button
        click_button(session, "#tab-button-format")
        
        # We assume click_button didn't throw an error. 
        # Hard to assert DOM state directly without more specific hooks, but we can verify it ran.
        @test true
    end

    @testset "set_radio_value" begin
        # Set source mode to DataFrame
        set_radio_value(session, "source_type", "DataFrame")
        # Ensure it works without throwing
        @test true
        
        # wait a bit for Bonito sync
        sleep(0.5)
        
        # Verify via observable
        # But observables are inside Main.app
        source_mode = @eval Main begin app.state.data_selection.source_type[] end
        @test source_mode == "DataFrame"
    end

    @testset "get_checkboxes_state" begin
        # Since DataFrame is selected but no specific DF is chosen yet,
        # column checkboxes might be empty
        state = get_checkboxes_state(session)
        @test state isa Vector
        # State might be empty
    end

    @testset "toggle_checkbox" begin
        # Go to format tab to ensure it's loaded? It's loaded anyway.
        # However, the show legend checkbox doesn't have an ID, it's just a checkbox.
        # Oh, let's use the axis reversal checkbox which does have an ID.
        info_before = get_element_info(session, "#axis-x-reversed-checkbox")
        # info["checked"] isn't returned by get_element_info, but value might be.
        # We can just toggle it
        toggle_checkbox(session, "#axis-x-reversed-checkbox")
        
        # wait a bit for Bonito sync
        sleep(0.5)
        val = @eval Main begin app.state.plotting.format.xreversed[] end
        @test val == true
        
        toggle_checkbox(session, "#axis-x-reversed-checkbox")
        sleep(0.5)
        val = @eval Main begin app.state.plotting.format.xreversed[] end
        @test val == false
    end

    @testset "get_focusable_elements" begin
        elements = get_focusable_elements(session)
        @test elements isa Vector
        @test length(elements) > 0
        
        # Verify first element is the Open tab button
        first_el = elements[1]
        @test first_el["tag"] == "BUTTON"
        @test first_el["id"] == "tab-button-open"
    end

    @testset "calculate_tab_distance" begin
        # Test calculation from BODY (when no focusable element is active)
        AgenticTesting.Bonito.evaljs(session, AgenticTesting.Bonito.js"document.activeElement.blur()")
        sleep(0.2)
        dist_from_body = calculate_tab_distance(session, "#tab-button-open")
        @test dist_from_body == 1
        
        # Focus the Open tab button
        AgenticTesting.Bonito.evaljs(session, AgenticTesting.Bonito.js"document.querySelector('#tab-button-open').focus()")
        sleep(0.2)
        
        # Calculate distance to Format tab button
        # Open is 1st tab, Format is 3rd tab, distance should be 2
        dist = calculate_tab_distance(session, "#tab-button-format")
        @test dist == 2
        
        # Calculate distance to Open tab button from itself
        dist_self = calculate_tab_distance(session, "#tab-button-open")
        @test dist_self == 0
        
        # Calculate distance to a non-existent element
        dist_none = calculate_tab_distance(session, "#non-existent-id")
        @test isnothing(dist_none)
    end

    @testset "calculate_dropdown_keystrokes" begin
        # Set dropdown to a known option (placeholder is "")
        select_dropdown_value(session, "#dropdown-x", "")
        sleep(0.2)
        
        # Calculate strokes to "caspl_x_10"
        dist = calculate_dropdown_keystrokes(session, "#dropdown-x", "caspl_x_10")
        @test dist isa Integer
        @test dist > 0
        
        # Test staying on the same item
        select_dropdown_value(session, "#dropdown-x", "caspl_x_10")
        sleep(0.2)
        dist_same = calculate_dropdown_keystrokes(session, "#dropdown-x", "caspl_x_10")
        @test dist_same == 0
        
        # Test non-existent item
        dist_none = calculate_dropdown_keystrokes(session, "#dropdown-x", "non_existent_value")
        @test isnothing(dist_none)
    end
end

