"""
    generate_line_symbol_plot_screenshot
"""
generate_line_symbol_plot_screenshot() = "line+symbol_plot.png"
function generate_line_symbol_plot_screenshot(session, local_app)
        # 1. Source Tab Configuration
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)
        
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
        
        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_simple")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_simple")

        # Select columns x, y1, y2
        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        cols_to_check = ["x", "y1", "y2"]
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

        # 2. Format Tab Configuration
        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-plottype", "Line+Symbol")
        wait_for_observable(local_app.state.plotting.format.selected_plottype, "Line+Symbol")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-group_by", "Color")
        # Wait for do_replot cycle (changing group_by triggers it)
        wait_for_ui_settle(session; delay=0.5) 
        wait_for_observable(local_app.state.misc.block_format_update, false; timeout=15.0)

        select_dropdown_value(session, "#dropdown-theme", "theme_ggplot2")
        wait_for_observable(local_app.state.plotting.format.selected_theme, "theme_ggplot2")
        
        # Legend should be checked by default, but we need to set the legend title
        local_app.state.plotting.handles.legend_title_text[] = "two functions"

        # Labels & Title
        # Wait until block_format_update is false to avoid them being overwritten
        wait_for_observable(local_app.state.misc.block_format_update, false; timeout=15.0)
        local_app.state.plotting.handles.xlabel_text[] = "argument"
        local_app.state.plotting.handles.ylabel_text[] = "functions"
        local_app.state.plotting.handles.title_text[] = "Combined plot of two functions"
        wait_for_ui_settle(session; delay=1.0)

        # Limits
        set_input_value(session, "#axis-x-min-input", "0")
        wait_for_observable(local_app.state.plotting.format.x_min, 0.0)
        
        set_input_value(session, "#axis-x-max-input", "10")
        wait_for_observable(local_app.state.plotting.format.x_max, 10.0)

        set_input_value(session, "#axis-y-min-input", "0")
        wait_for_observable(local_app.state.plotting.format.y_min, 0.0)
        
        set_input_value(session, "#axis-y-max-input", "100")
        wait_for_observable(local_app.state.plotting.format.y_max, 100.0)
        wait_for_ui_settle(session; delay=1.0)
        
        # 3. Minimize table pane
        Bonito.evaljs(session, js"""
            (function() {
                const minBtn = document.querySelector('.cp-table-fw .bw-icon-btn[title="Minimize"]');
                if (minBtn) { minBtn.click(); }
            })()
        """)
        wait_for_ui_settle(session; delay=1.0)
end
