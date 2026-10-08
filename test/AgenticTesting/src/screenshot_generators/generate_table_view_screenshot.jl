"""
    generate_table_view_screenshot(filename::String="table_view.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
generate_table_view_screenshot() = "table_view.png"
function generate_table_view_screenshot(session, local_app)
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

        # Wait for warning modal to appear and dismiss it
        wait_for_observable(local_app.state.dialogs.show_modal, true)
        wait_for_ui_settle(session; delay=1.0)
        click_button(session, "#btn-modal-ok")
        wait_for_observable(local_app.state.dialogs.show_modal, false)

        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)

        println("Maximizing table pane...")
        Bonito.evaljs(session, js"""
            (function() {
                const maxBtn = document.querySelector('.cp-table-fw .bw-icon-btn[title="Maximize"]');
                if (maxBtn) {
                    maxBtn.click();
                }
            })()
        """)
        wait_for_ui_settle(session; delay=3.0)
end
