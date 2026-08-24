"""
    generate_format_tab_barplot_stacked_screenshot(filename::String="format_tab_barplot_stacked.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates creating a horizontal stacked barplot of SampleScores.
"""
function generate_format_tab_barplot_stacked_screenshot(
    filename="format_tab_barplot_stacked.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    # Define SampleScores in Main
    Core.eval(Main, :(
        using DataFrames;
        SampleScores = DataFrame(
            "Name" => ["Ann", "Bob", "Charlie", "Dennis"],
            "Score 1" => [9.0, 7.8, 7.1, 14.6],
            "Score 2" => [8.8, 12.0, 15.2, 5.3]
        )
    ))

    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
        # Ensure SampleScores is picked up
        local_app.state.data_selection.dataframes_dict_obs[] = CasualPlots.collect_dataframes_from_main()
        
        # Navigate to "Source" Tab
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select DataFrame mode
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

        # Select SampleScores
        select_dropdown_value(session, "#dropdown-dataframe", "SampleScores")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "SampleScores")

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
end

"""
    generate_format_tab_limits_screenshot(filename::String="format_tab_limits.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
function generate_format_tab_limits_screenshot(
    filename="format_tab_limits.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
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
end

"""
    generate_format_tab_lines_screenshot(filename::String="format_tab_lines.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
function generate_format_tab_lines_screenshot(
    filename="format_tab_lines.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
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
end

"""
    generate_plot_pane_maximized_screenshot(filename::String="plot_pane_maximized.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
function generate_plot_pane_maximized_screenshot(
    filename="plot_pane_maximized.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
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
end

"""
    generate_save_tab_script_screenshot(filename::String="save_tab_script.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
function generate_save_tab_script_screenshot(
    filename="save_tab_script.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
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
end

"""
    generate_table_view_screenshot(filename::String="table_view.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String
"""
function generate_table_view_screenshot(
    filename="table_view.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
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
end
