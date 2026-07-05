# gui_test_bonito_driven.jl — Julia-driven GUI test via Bonito WebSocket
#
# Prerequisites: 
#   include("src/scripts/casualplots_test_setup.jl")
#   app = casualplots_app()
#   server = Bonito.Server(app, "127.0.0.1", 9385)
#   # Then open http://localhost:9385/ in browser
#
# Usage: include("src/scripts/gui_test_bonito_driven.jl")

using Test

session = get_active_session()
@info "Session acquired" session.id session.status

# ============================================================
# Phase 1: Array Mode — Select X, Y, Plot
# ============================================================
@testset "Array Mode: X/Y Selection and Plot" begin
    
    # Step 1: Verify initial state — Source mode should be "X, Y Arrays"
    radio_info = get_element_info(session, "input[type=radio][name=source_type][value=\"X, Y Arrays\"]")
    @test radio_info["checked"] == true
    @info "✓ Source mode is 'X, Y Arrays'"
    
    # Step 2: Read X dropdown options
    x_opts = get_dropdown_options(session; css_selector="#dropdown-x")
    x_values = [o["value"] for o in x_opts if o["value"] != ""]
    @test "caspl_x_100" in x_values
    @info "✓ X dropdown contains caspl_x_100" x_values
    
    # Step 3: Select X = caspl_x_100
    select_dropdown_value(session, "#dropdown-x", "caspl_x_100")
    sleep(1.0)  # Wait for Y dropdown to populate
    
    # Step 4: Verify Y dropdown populated with congruent options
    y_opts = get_dropdown_options(session; css_selector="#dropdown-y")
    y_values = [o["value"] for o in y_opts if o["value"] != ""]
    @test "caspl_z100" in y_values
    @info "✓ Y dropdown populated" y_values
    
    # Step 5: Select Y = caspl_z100
    select_dropdown_value(session, "#dropdown-y", "caspl_z100")
    sleep(0.5)
    
    # Step 6: Click (Re-)Plot
    click_button(session, "button.btn.btn-success")
    sleep(2.0)  # Wait for plot to render
    @info "✓ (Re-)Plot clicked in Array mode"
    
    # Step 7: Verify plot rendered (check that cp_figure is defined)
    @test cp_figure !== nothing
    @info "✓ Plot rendered successfully"
end

# ============================================================
# Phase 2: DataFrame Mode — Switch, Select DF, Columns, Plot
# ============================================================
@testset "DataFrame Mode: Column Selection and Plot" begin
    
    # Step 1: Switch to DataFrame mode
    set_radio_value(session, "source_type", "DataFrame")
    sleep(1.0)
    
    # Step 2: Verify mode switched
    radio_df = get_element_info(session, "input[type=radio][name=source_type][value=\"DataFrame\"]")
    @test radio_df["checked"] == true
    @info "✓ Switched to DataFrame mode"
    
    # Step 3: Select caspl_df_exp from DataFrame dropdown
    select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
    sleep(1.5)  # Wait for columns to populate
    
    # Step 4: Verify checkboxes appeared
    cbs = get_checkboxes_state(session)
    @test length(cbs) > 0
    cb_names = [cb["value"] for cb in cbs]
    @test "x" in cb_names
    @test "y2" in cb_names
    @test "y4" in cb_names
    @info "✓ Column checkboxes populated" cb_names
    
    # Step 5: Toggle checkboxes for x, y2, y4
    for col in ["x", "y2", "y4"]
        toggle_checkbox(session, ".column-checkbox[value=\"$col\"]")
        sleep(0.2)
    end
    
    # Step 6: Verify checkboxes are checked
    cbs_after = get_checkboxes_state(session)
    checked = [cb["value"] for cb in cbs_after if cb["checked"]]
    @test "x" in checked
    @test "y2" in checked
    @test "y4" in checked
    @info "✓ Columns selected" checked
    
    # Step 7: Click (Re-)Plot
    click_button(session, "button.btn.btn-success")
    sleep(2.0)
    @info "✓ (Re-)Plot clicked in DataFrame mode"
    
    # Step 8: Verify plot rendered
    @test cp_figure !== nothing
    @info "✓ DataFrame plot rendered successfully"
end

@info "All GUI tests passed!"
