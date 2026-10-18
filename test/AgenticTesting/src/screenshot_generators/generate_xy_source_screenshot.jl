"""
    generate_xy_source_screenshot(filename::String="xy_source_selection.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates opening the CasualPlots app, selecting X, Y Arrays mode, selecting `caspl_x_10` and `caspl_ys10`,
setting range from 1 to 10, and plotting.
"""
generate_xy_source_screenshot() = "xy_source_selection.png"
function generate_xy_source_screenshot(session, local_app)
        # Navigate to "Source" Tab
        println("Clicking 'Source' tab...")
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select X, Y Arrays mode
        println("Selecting 'X, Y Arrays' source type...")
        set_radio_value(session, "source_type", "X, Y Arrays")
        wait_for_observable(local_app.state.data_selection.source_type, "X, Y Arrays")
        
        # Select caspl_x_10
        println("Selecting 'caspl_x_10' for X...")
        select_dropdown_value(session, "#dropdown-x", "caspl_x_10")
        wait_for_observable(local_app.state.data_selection.selected_x, "caspl_x_10")

        # Select caspl_ys10
        println("Selecting 'caspl_ys10' for Y...")
        select_dropdown_value(session, "#dropdown-y", "caspl_ys10")
        wait_for_observable(local_app.state.data_selection.selected_y, "caspl_ys10")

        # Set range
        println("Setting range 1 to 10...")
        Bonito.evaljs(session, js"""
            (function() {
                const fromInput = document.getElementById('range-from-input');
                if (fromInput) {
                    fromInput.value = '1';
                    fromInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
                const toInput = document.getElementById('range-to-input');
                if (toInput) {
                    toInput.value = '10';
                    toInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
        wait_until(() -> local_app.state.data_selection.range_from[] == 1 && local_app.state.data_selection.range_to[] == 10)

        # Click (Re-)Plot
        println("Clicking '(Re-)Plot' button...")
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)
end
