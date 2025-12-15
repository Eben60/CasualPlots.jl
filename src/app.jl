"""
    casualplots_app()

Create and return the main CasualPlots application.

This function assembles the complete interactive plotting application with:
- Data source selection (X and Y variables)
- Plot formatting controls (plot type, legend)
- Label text fields (X-axis, Y-axis, title)
- Real-time plot and table display
- Tabbed interface for organized controls
"""
casualplots_app() = App() do session
    supported_plot_types = ["Lines", "Scatter", "BarPlot"]

    # Initialize application state
    state = initialize_app_state() # reviewed 1 pass
   
    # Setup dropdown menus
    x_node = create_x_dropdown(state)
    y_node = create_y_dropdown()
    dataframe_node = create_dataframe_dropdown(state)
    plottype_node = create_plottype_dropdown(supported_plot_types, state.plot_format.selected_plottype)
    
    # Initialize output observables
    outputs = initialize_output_observables() # reviewed 1 pass
    
    # Setup reactive callbacks
    setup_x_callback(state, y_node, outputs) # reviewed 1 pass
    setup_source_callback(state, outputs)
    setup_format_callback(state, outputs)
    
    # Setup label update callbacks for editable text fields
    setup_label_update_callbacks(state, outputs)
    
    # Create UI components
    control_panel = create_control_panel_ui(x_node, y_node, dataframe_node, plottype_node, state)
    setup_dataframe_callbacks(state, outputs, control_panel.plot_trigger) # DataFrame mode callbacks
    
    tabs_result = create_tab_content(control_panel, state, outputs)
    help_visibility = setup_help_section(outputs.plot)
    
    # Assemble and return final layout (with modal dialog)
    return assemble_layout(tabs_result.tabs, help_visibility, outputs.plot, outputs.table, 
                           state, tabs_result.overwrite_trigger, tabs_result.cancel_trigger)
end

