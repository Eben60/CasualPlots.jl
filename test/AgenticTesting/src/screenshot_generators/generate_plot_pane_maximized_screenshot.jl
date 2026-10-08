"""
    generate_plot_pane_maximized_screenshot(filename::String="plot_pane_maximized.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
generate_plot_pane_maximized_screenshot() = "plot_pane_maximized.png"
function generate_plot_pane_maximized_screenshot(session, local_app)
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")

        click_element_by_text(session, "Select All")
        # Wait until columns are populated
        wait_for_ui_settle(session; delay=1.0)

        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        click_element_by_text(session, "Format")
        wait_for_ui_settle(session; delay=1.0)

        select_dropdown_value(session, "#dropdown-plottype", "Lines")
        wait_for_observable(local_app.state.plotting.format.selected_plottype, "Lines")
        wait_for_ui_settle(session; delay=1.0)

        println("Maximizing plot pane...")
        Bonito.evaljs(session, js"""
            (function() {
                const maxBtn = document.querySelector('.cp-plot-fw .bw-icon-btn[title="Maximize"]');
                if (maxBtn) {
                    maxBtn.click();
                }
            })()
        """)
        wait_for_ui_settle(session; delay=3.0)
end
