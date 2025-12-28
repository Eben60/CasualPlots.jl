
"""
    create_control_panel_ui(x_node, y_node, dataframe_node, plottype_node, state)

Create UI elements for the control panel (data source and format controls).

Returns a NamedTuple with:
- `source_type_selector`: Radio buttons for source type selection
- `source_content`: Dynamic content area that changes based on source type
- `plot_kind`: Plot type selection UI
- `legend_control`: Legend visibility checkbox UI
- `xlabel_input`: X-axis label text field
- `ylabel_input`: Y-axis label text field
- `title_input`: Plot title text field
- `axis_limits`: Axis limits input row (X min, X max, Y min, Y max)
"""
function create_control_panel_ui(x_node, y_node, dataframe_node, plottype_node, state)
    (; trigger_update) = state.misc
    (; format, handles) = state.plotting
    (; show_legend, x_min, x_max, y_min, y_max) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text) = handles
    (; source_type, selected_dataframe, selected_columns, selected_x, selected_y, 
       range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
    (; opened_file_df) = state.file_opening
    
    # Create plot trigger observable for DataFrame mode
    plot_trigger = Observable(0)
    
    # Create UI components using helper functions
    source_type_selector = create_source_type_selector(source_type)
    
    # Create array mode content (X/Y dropdowns only)
    array_dropdowns = create_array_mode_content(x_node, y_node, trigger_update)
    
    # Create dataframe mode content (dropdown row and column controls separately)
    dataframe_dropdown = create_dataframe_dropdown_row(dataframe_node)
    dataframe_column_controls = create_dataframe_column_controls(
        selected_dataframe, selected_columns, opened_file_df
    )
    
    # Create the plot button (enabled when any data source is selected)
    plot_button = create_plot_button(source_type, selected_x, selected_y, selected_columns, plot_trigger)
    
    # Create range input row with plot button and bounds observables
    range_row = create_range_input_row(range_from, range_to, data_bounds_from, data_bounds_to, plot_button)
    
    # Dynamic source content that switches based on source_type
    # Array mode: X/Y dropdowns + range row
    # DataFrame mode: DataFrame dropdown + range row + column selection controls
    source_content = map(source_type) do st
        if st == "DataFrame"
            # Layout: dropdown -> range row -> column controls
            return DOM.div(dataframe_dropdown, range_row, dataframe_column_controls; class="flex-col")
        else
            # Layout: X/Y dropdowns -> range row
            return DOM.div(array_dropdowns, range_row; class="flex-col")
        end
    end
    
    plot_kind = create_plot_kind_selector(plottype_node)
    
    legend_control = create_legend_control(show_legend, legend_title_text)
    
    # Text input fields for plot labels
    xlabel_input = create_label_input("X-Axis:", "xlabel", xlabel_text)
    ylabel_input = create_label_input("Y-Axis:", "ylabel", ylabel_text)
    title_input = create_label_input("Title:", "title", title_text)
    
    # Axis limits input row
    axis_limits = create_axis_limits_row(x_min, x_max, y_min, y_max)
    
    return (; source_type_selector, source_content, plot_kind, legend_control,
              xlabel_input, ylabel_input, title_input, axis_limits, plot_trigger)
end

