"""
    generate_non_linear_discharge_screenshot(filename::String="non-linear-discharge.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Generate screenshot for non-linear discharge lines plot.
"""
generate_non_linear_discharge_screenshot() = "non-linear-discharge.png"
function generate_non_linear_discharge_screenshot(session, local_app)
    click_element_by_text(session, "Source")
    wait_for_ui_settle(session; delay=1.0)

    set_radio_value(session, "source_type", "DataFrame")
    wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

    select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_dissip")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_dissip")

    click_element_by_text(session, "Deselect All")
    wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

    cols_to_check = ["time", "U", "I"]
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

    # Dismiss incompatible physical dimensions warning modal
    wait_for_observable(local_app.state.dialogs.show_modal, true)
    wait_for_ui_settle(session; delay=1.0)
    click_button(session, "#btn-modal-ok")
    wait_for_observable(local_app.state.dialogs.show_modal, false)

    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
    wait_for_ui_settle(session; delay=1.0)

    click_element_by_text(session, "Format")
    wait_for_ui_settle(session; delay=1.0)

    select_dropdown_value(session, "#dropdown-plottype", "Lines")
    wait_for_observable(local_app.state.plotting.format.selected_plottype, "Lines")
    wait_for_ui_settle(session; delay=1.0)
    wait_for_observable(local_app.state.misc.block_format_update, false; timeout=15.0)

    # set_input_value(session, "#input-xlabel", "time [s]")
    # wait_for_observable(local_app.state.plotting.handles.xlabel_text, "time [s]")

    set_input_value(session, "#input-ylabel", "U[V], I[nA]")
    wait_for_observable(local_app.state.plotting.handles.ylabel_text, "U[V], I[nA]")

    set_input_value(session, "#input-title", "Discharge onto non-linear load")
    wait_for_observable(local_app.state.plotting.handles.title_text, "Discharge onto non-linear load")

    set_input_value(session, "#axis-x-min-input", "0")
    wait_for_observable(local_app.state.plotting.format.x_min, 0.0)

    set_input_value(session, "#axis-y-min-input", "0")
    wait_for_observable(local_app.state.plotting.format.y_min, 0.0)

    wait_for_ui_settle(session; delay=1.0)
    return nothing
end
