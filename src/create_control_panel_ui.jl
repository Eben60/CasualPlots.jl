
"""
    create_control_panel_ui(x_node, y_node, dataframe_node, plottype_node, theme_node, state)

Create UI elements for the control panel (data source and format controls).

Returns a NamedTuple with:
- `source_type_selector`: Radio buttons for source type selection
- `source_content`: Dynamic content area that changes based on source type
- `plot_kind`: Plot type selection UI
- `theme_selector`: Theme selection UI
- `legend_control`: Legend visibility checkbox UI
- `xlabel_input`: X-axis label text field
- `ylabel_input`: Y-axis label text field
- `title_input`: Plot title text field
- `plot_trigger`: Observable for triggering (re-)plot
"""
function create_control_panel_ui(x_node, y_node, dataframe_node, plottype_node, theme_node, state)
    (; trigger_update) = state.misc
    (; format, handles) = state.plotting
    (; show_legend) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text) = handles
    (; source_type, selected_dataframe, selected_columns, selected_x, selected_y,
       range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
    (; opened_file_df) = state.file_opening
    
    # Create plot trigger observable for both modes
    plot_trigger = Observable(0)
    
    # Create UI components using helper functions
    source_type_selector = create_source_type_selector(source_type)
    
    # Create plot button (shared between modes)
    plot_button = create_plot_button(source_type, selected_x, selected_y, selected_columns, plot_trigger)
    
    # Create range input row with plot button
    range_input_row = create_range_input_row(range_from, range_to, data_bounds_from, data_bounds_to, plot_button)
    
    # Array mode: X/Y dropdowns
    array_dropdowns = create_array_mode_content(x_node, y_node, trigger_update)
    
    # DataFrame mode: dropdown row + column controls (buttons and checkboxes)
    dataframe_dropdown_row = create_dataframe_dropdown_row(dataframe_node)
    dataframe_column_controls = create_dataframe_column_controls(
        selected_dataframe, selected_columns, opened_file_df
    )
    
    # Dynamic source content that switches based on source_type
    # Layout: [mode-specific dropdowns] -> [range row with plot button] -> [DataFrame controls if applicable]
    source_content = map(source_type) do st
        if st == "DataFrame"
            # DataFrame mode: dropdown + range row + column controls
            DOM.div(
                dataframe_dropdown_row,
                range_input_row,
                dataframe_column_controls;
                class="flex-col"
            )
        else
            # Array mode: X/Y dropdowns + range row
            DOM.div(
                array_dropdowns,
                range_input_row;
                class="flex-col"
            )
        end
    end
    
    plot_kind = create_plot_kind_selector(plottype_node)
    theme_selector = create_theme_selector(theme_node)
    
    legend_control = create_legend_control(show_legend, legend_title_text)
    
    # Text input fields for plot labels
    xlabel_input = create_label_input("X-Axis:", "xlabel", xlabel_text)
    ylabel_input = create_label_input("Y-Axis:", "ylabel", ylabel_text)
    title_input = create_label_input("Title:", "title", title_text)
    
    # Axis limits section
    axis_limits_section = create_axis_limits_section(format)
    
    return (; source_type_selector, source_content, plot_kind, theme_selector, legend_control,
              xlabel_input, ylabel_input, title_input, axis_limits_section, plot_trigger)
end

