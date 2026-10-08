"""
    generate_format_tab_barplot_stacked_screenshot(filename::String="format_tab_barplot_stacked.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates creating a horizontal stacked barplot of caspl_df_scores.
"""
generate_format_tab_barplot_stacked_screenshot() = "format_tab_barplot_stacked.png"
function generate_format_tab_barplot_stacked_screenshot(session, local_app)
        # Navigate to "Source" Tab
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select DataFrame mode
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        # Select caspl_df_scores
        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_scores")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_scores")

        # Click Deselect All
        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        # Check columns
        cols_to_check = ["Name", "Score 1", "Score 2"]
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

        # Click (Re-)Plot
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        # Format Tab
        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        # Set BarPlot
        select_dropdown_value(session, "#dropdown-plottype", "BarPlot")
        wait_for_observable(local_app.state.plotting.format.selected_plottype, "BarPlot")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-bar_direction", "Horizontal")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:bar_direction][] == "Horizontal")

        select_dropdown_value(session, "#dropdown-bar_mode", "Stacked")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:bar_mode][] == "Stacked")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-theme", "theme_ggplot2")
        wait_for_observable(local_app.state.plotting.format.selected_theme, "theme_ggplot2")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-group_by", "Color")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:group_by][] == "Color")

        # Check Show Legend
        Bonito.evaljs(session, js"""
            var cb = document.querySelector('input[type="checkbox"][id="checkbox-show_legend"]');
            if (cb && !cb.checked) {
                cb.checked = true;
                cb.dispatchEvent(new Event('change', {bubbles: true}));
            }
        """)
        wait_until(() -> local_app.state.plotting.format.show_legend[] == true)

        # Set X Axis
        set_input_value(session, "#input-xlabel", "Name")
        wait_for_observable(local_app.state.plotting.handles.xlabel_text, "Name")
        
        # Set Y Axis
        set_input_value(session, "#input-ylabel", "Score")
        wait_for_observable(local_app.state.plotting.handles.ylabel_text, "Score")

        # Set Title
        set_input_value(session, "#input-title", "Students scores")
        wait_for_observable(local_app.state.plotting.handles.title_text, "Students scores")
        
        wait_for_ui_settle(session; delay=1.0)
end
