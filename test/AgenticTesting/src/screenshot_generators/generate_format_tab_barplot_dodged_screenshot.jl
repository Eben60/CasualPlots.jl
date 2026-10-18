"""
    generate_format_tab_barplot_dodged_screenshot
"""
generate_format_tab_barplot_dodged_screenshot() = "format_tab_barplot_dodged.png"
function generate_format_tab_barplot_dodged_screenshot(session, local_app)
        # Source Tab
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_scores")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_scores")

        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

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

        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        # Format Tab
        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-plottype", "BarPlot")
        wait_for_observable(local_app.state.plotting.format.selected_plottype, "BarPlot")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-bar_direction", "Vertical")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:bar_direction][] == "Vertical")

        select_dropdown_value(session, "#dropdown-bar_mode", "Dodged")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:bar_mode][] == "Dodged")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-theme", "theme_black")
        wait_for_observable(local_app.state.plotting.format.selected_theme, "theme_black")

        select_dropdown_value(session, "#dropdown-group_by", "Color")
        wait_for_ui_settle(session; delay=0.5) # Wait for websocket message to trigger do_replot
        wait_for_observable(local_app.state.misc.block_format_update, false; timeout=15.0)

        local_app.state.plotting.handles.xlabel_text[] = "Name"
        local_app.state.plotting.handles.ylabel_text[] = "Score"
        local_app.state.plotting.handles.title_text[] = "Students scores"
        
        wait_for_ui_settle(session; delay=1.0)
        wait_for_ui_settle(session; delay=1.0)
end
