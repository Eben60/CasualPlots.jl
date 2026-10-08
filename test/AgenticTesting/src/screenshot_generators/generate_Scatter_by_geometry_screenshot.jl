"""
    generate_Scatter_by_geometry_screenshot(filename::String="Scatter_by_geometry.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates creating a basic Scatter plot with geometry-based grouping.
"""
generate_Scatter_by_geometry_screenshot() = "Scatter_by_geometry.png"
function generate_Scatter_by_geometry_screenshot(session, local_app)
        
        # Navigate to "Source" Tab
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select DataFrame mode
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        # Select caspl_df_simple
        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_simple")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_simple")

        # Click Deselect All
        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        # Check columns x, y1, y2
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

        # Click (Re-)Plot
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        # Format Tab
        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        # Set Scatter
        select_dropdown_value(session, "#dropdown-plottype", "Scatter")
        wait_for_observable(local_app.state.plotting.format.selected_plottype, "Scatter")
        wait_for_ui_settle(session; delay=1.0)

        # Set Theme (Makie default is usually the default, but just in case)
        select_dropdown_value(session, "#dropdown-theme", "Makie default")
        wait_for_observable(local_app.state.plotting.format.selected_theme, "Makie default")
        wait_for_ui_settle(session; delay=1.0)

        # Set Show group by Geometry
        current_plot2 = local_app.state.plotting.handles.current_figure[]
        select_dropdown_value(session, "#dropdown-group_by", "Geometry")
        wait_until(() -> local_app.state.plotting.format.dynamic_attributes[:group_by][] == "Geometry")
        
        # wait for replot
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot2)
        wait_for_observable(local_app.state.misc.block_format_update, false; timeout=15.0)
        wait_for_ui_settle(session; delay=3.0)

        # Set labels to match reference image
        set_input_value(session, "#input-xlabel", "X")
        wait_for_observable(local_app.state.plotting.handles.xlabel_text, "X")
        
        set_input_value(session, "#input-ylabel", "Y")
        wait_for_observable(local_app.state.plotting.handles.ylabel_text, "Y")
        
        set_input_value(session, "#input-title", "Y vs X")
        wait_for_observable(local_app.state.plotting.handles.title_text, "Y vs X")
        
        wait_for_ui_settle(session; delay=3.0)
        
        # Force a WebGL render flush by triggering a trivial visual change
        Bonito.evaljs_value(session, js"document.title")
        sleep(2.0)
end
