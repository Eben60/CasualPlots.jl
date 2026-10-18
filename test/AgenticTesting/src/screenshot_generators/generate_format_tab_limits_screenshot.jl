"""
    generate_format_tab_limits_screenshot(filename::String="format_tab_limits.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
generate_format_tab_limits_screenshot() = "format_tab_limits.png"
function generate_format_tab_limits_screenshot(session, local_app)
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_large")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_large")

        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        cols_to_check = ["time", "sqrt_val", "col2", "col3"]
        for col in cols_to_check
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

        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        set_input_value(session, "#axis-x-min-input", "2")
        wait_for_observable(local_app.state.plotting.format.x_min, 2.0)
        
        set_input_value(session, "#axis-x-max-input", "15")
        wait_for_observable(local_app.state.plotting.format.x_max, 15.0)

        Bonito.evaljs(session, js"""
            var cb = document.querySelector('input[type="checkbox"][id="axis-x-reversed-checkbox"]');
            if (cb && !cb.checked) {
                cb.checked = true;
                cb.dispatchEvent(new Event('change', {bubbles: true}));
            }
        """)
        wait_until(() -> local_app.state.plotting.format.xreversed[] == true)
        wait_for_ui_settle(session; delay=1.0)
end
