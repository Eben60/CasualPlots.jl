"""
    generate_format_tab_lines_screenshot(filename::String="format_tab_lines.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
generate_format_tab_lines_screenshot() = "format_tab_lines.png"
function generate_format_tab_lines_screenshot(session, local_app)
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_unitmix")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_unitmix")



        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        cols_to_check = ["index", "area", "linear", "unimiss"]
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

        wait_for_ui_settle(session; delay=1.0)
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")

        println("Waiting for modal to appear")
        wait_for_observable(local_app.state.dialogs.show_modal, true)
        wait_for_ui_settle(session; delay=1.0)
        println("Clicking modal ok")
        click_button(session, "#btn-modal-ok")
        println("Waiting for modal to disappear")
        wait_for_observable(local_app.state.dialogs.show_modal, false)

        println("Waiting for current_figure to change")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        println("Setting plottype")
        select_dropdown_value(session, "#dropdown-plottype", "Lines")
        wait_for_observable(local_app.state.plotting.format.selected_plottype, "Lines")
        wait_for_ui_settle(session; delay=1.0)

        println("Setting theme")
        select_dropdown_value(session, "#dropdown-theme", "theme_ggplot2")
        wait_for_observable(local_app.state.plotting.format.selected_theme, "theme_ggplot2")
        wait_for_ui_settle(session; delay=1.0)

        println("Setting group_by")
        select_dropdown_value(session, "#dropdown-group_by", "Geometry")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:group_by][] == "Geometry")

        println("Setting legend title")
        set_input_value(session, "#input-legend-title", "Some Legend")
        wait_for_observable(local_app.state.plotting.handles.legend_title_text, "Some Legend")

        println("Setting xlabel")
        set_input_value(session, "#input-xlabel", "Custom X axis title")
        wait_for_observable(local_app.state.plotting.handles.xlabel_text, "Custom X axis title")

        println("Setting ylabel")
        set_input_value(session, "#input-ylabel", "Custom Y title")
        wait_for_observable(local_app.state.plotting.handles.ylabel_text, "Custom Y title")

        println("Setting x_min")
        set_input_value(session, "#axis-x-min-input", "-5")
        wait_for_observable(local_app.state.plotting.format.x_min, -5.0)

        println("Setting x_max")
        set_input_value(session, "#axis-x-max-input", "30")
        wait_for_observable(local_app.state.plotting.format.x_max, 30.0)

        wait_for_ui_settle(session; delay=1.0)
end
