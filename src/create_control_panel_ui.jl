
"""
    create_control_panel_ui(dropdowns, state)

Create UI elements for the control panel (data source and format controls).

Returns a NamedTuple with:
- `source_type_selector`: Radio buttons for source type selection
- `source_content`: Dynamic content area that changes based on source type
- `plot_kind`: Plot type selection UI
- `legend_control`: Legend visibility checkbox UI
- `xlabel_input`: X-axis label text field
- `ylabel_input`: Y-axis label text field
- `title_input`: Plot title text field
"""
function create_control_panel_ui(dropdowns, state)
    (; trigger_update, plot_format, plot_handles, source_type, selected_dataframe, selected_columns, opened_file_df) = state
    (; show_legend) = plot_format
    (; xlabel_text, ylabel_text, title_text, legend_title_text) = plot_handles
    
    # Create plot trigger observable for DataFrame mode
    plot_trigger = Observable(0)
    
    # Create UI components using helper functions
    source_type_selector = create_source_type_selector(source_type)
    
    array_mode_content = create_array_mode_content(dropdowns, trigger_update)
    
    dataframe_mode_content = create_dataframe_mode_content(
        dropdowns, selected_dataframe, selected_columns, plot_trigger, opened_file_df
    )
    
    # Dynamic source content that switches based on source_type
    source_content = map(source_type) do st
        if st == "DataFrame"
            return dataframe_mode_content
        else
            return array_mode_content
        end
    end
    
    plot_kind = create_plot_kind_selector(dropdowns)
    
    legend_control = create_legend_control(show_legend, legend_title_text)
    
    # Text input fields for plot labels
    xlabel_input = create_label_input("X-Axis:", "xlabel", xlabel_text)
    ylabel_input = create_label_input("Y-Axis:", "ylabel", ylabel_text)
    title_input = create_label_input("Title:", "title", title_text)
    
    return (; source_type_selector, source_content, plot_kind, legend_control,
              xlabel_input, ylabel_input, title_input, plot_trigger)
end

