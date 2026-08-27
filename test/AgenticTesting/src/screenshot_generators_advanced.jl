# screenshot_generators_advanced.jl

function set_input_value(session::Bonito.Session, selector::String, value::String)
    Bonito.evaljs(session, js"""
        (function() {
            const el = document.querySelector($(selector));
            if (el) {
                el.value = $(value);
                el.dispatchEvent(new Event('input', {bubbles: true}));
                el.dispatchEvent(new Event('change', {bubbles: true}));
                el.dispatchEvent(new Event('blur', {bubbles: true}));
            }
        })()
    """)
end

"""
    generate_format_tab_barplot_dodged_screenshot
"""
function generate_format_tab_barplot_dodged_screenshot(
    filename="format_tab_barplot_dodged.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    Core.eval(Main, quote
        using DataFrames
        SampleScores = DataFrame(
            :Name => ["Ann", "Bob", "Charlie", "Dennis"],
            Symbol("Score 1") => [9.0, 7.8, 7.1, 14.6],
            Symbol("Score 2") => [8.8, 12.0, 15.2, 5.3]
        )
    end)

    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
        # Source Tab
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
        select_dropdown_value(session, "#dropdown-dataframe", "SampleScores")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "SampleScores")

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
end

"""
    generate_line_symbol_plot_screenshot
"""
function generate_line_symbol_plot_screenshot(
    filename="line+symbol_plot.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    # The required DataFrame `caspl_df_simple` is already provided by `CasualPlots.@populate()`
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
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
end
