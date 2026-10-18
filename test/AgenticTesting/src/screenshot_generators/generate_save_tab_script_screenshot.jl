"""
    generate_save_tab_script_screenshot(filename::String="save_tab_script.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
generate_save_tab_script_screenshot() = "save_tab_script.png"
function generate_save_tab_script_screenshot(session, local_app)
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")

        click_element_by_text(session, "Select All")
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

        select_dropdown_value(session, "#dropdown-theme", "theme_ggplot2")
        wait_for_observable(local_app.state.plotting.format.selected_theme, "theme_ggplot2")
        wait_for_ui_settle(session; delay=1.0)

        set_input_value(session, "#input-legend-title", "Column")
        wait_for_observable(local_app.state.plotting.handles.legend_title_text, "Column")

        set_input_value(session, "#input-xlabel", "Ex")
        wait_for_observable(local_app.state.plotting.handles.xlabel_text, "Ex")

        set_input_value(session, "#input-ylabel", "Why")
        wait_for_observable(local_app.state.plotting.handles.ylabel_text, "Why")

        set_input_value(session, "#input-title", "Why vs Ex")
        wait_for_observable(local_app.state.plotting.handles.title_text, "Why vs Ex")
        
        local_app.state.plotting.format.x_min[] = -3.0
        local_app.state.plotting.format.x_max[] = 9.0
        local_app.state.plotting.format.y_min[] = -5.0
        local_app.state.plotting.format.y_max[] = 15.0
        wait_for_ui_settle(session; delay=1.0)

        click_element_by_text(session, "Save")
        wait_for_ui_settle(session; delay=1.0)

        set_input_value(session, "#save-path-input", "/Volumes/V2/tmp/Why-vs-Ex_script.jl")
        wait_for_observable(local_app.state.file_saving.save_file_path, "/Volumes/V2/tmp/Why-vs-Ex_script.jl")
        
        Bonito.evaljs(session, js"""
            (function() {
                const el = document.querySelector('#save-path-input');
                if (el) { el.focus(); }
            })()
        """)
        wait_for_ui_settle(session; delay=1.0)
end
