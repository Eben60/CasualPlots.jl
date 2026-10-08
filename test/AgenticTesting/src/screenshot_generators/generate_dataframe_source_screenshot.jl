"""
    generate_dataframe_source_screenshot(filename::String="dataframe_source_selection.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates opening the CasualPlots app via Electron, navigating to the 'Source' tab,
selecting the 'DataFrame' mode, choosing 'caspl_df_exp', selecting columns x, y1, y4, y7, y9, y12, y15, y18,
setting the range from 20 to 90, and capturing the screenshot.
"""
generate_dataframe_source_screenshot() = "dataframe_source_selection.png"
function generate_dataframe_source_screenshot(session, local_app)
        # Navigate to "Source" Tab
        println("Clicking 'Source' tab...")
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select DataFrame mode
        println("Selecting 'DataFrame' source type...")
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
        
        # Diagnostic print of dropdown HTML
        html = Bonito.evaljs_value(session, js"document.querySelector('#dropdown-dataframe') ? document.querySelector('#dropdown-dataframe').innerHTML : 'not found'")
        println("DEBUG dropdown HTML: ", html)
        
        # Select caspl_df_exp
        println("Selecting 'caspl_df_exp' from dropdown...")
        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")

        
        # Click Deselect All
        println("Clicking 'Deselect All'...")
        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        # Check columns
        cols_to_check = ["x", "y1", "y4", "y7", "y9", "y12", "y15", "y18"]
        println("Checking columns: ", join(cols_to_check, ", "))
        for col in cols_to_check
            # The value of the checkbox is the column name
            Bonito.evaljs(session, js"""
                (function() {
                    const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
                    if (cb && !cb.checked) {
                        cb.checked = true;
                        cb.dispatchEvent(new Event('change', {bubbles: true}));
                    }
                })()
            """)
        end
        wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], cols_to_check))

        # Set range
        println("Setting range 20 to 90...")
        Bonito.evaljs(session, js"""
            (function() {
                const fromInput = document.getElementById('range-from-input');
                if (fromInput) {
                    fromInput.value = '20';
                    fromInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
                const toInput = document.getElementById('range-to-input');
                if (toInput) {
                    toInput.value = '90';
                    toInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
        wait_until(() -> local_app.state.data_selection.range_from[] == 20 && local_app.state.data_selection.range_to[] == 90)

        # Click (Re-)Plot
        println("Clicking '(Re-)Plot' button...")
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)
end
