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
    state = initialize_app_state()
   
    # Setup dropdown menus
    x_node = create_x_dropdown(state)
    y_node = create_y_dropdown()
    dataframe_node = create_dataframe_dropdown(state)
    plottype_node = create_plottype_dropdown(supported_plot_types, state.plotting.format.selected_plottype)
    
    # Initialize output observables
    outputs = initialize_output_observables()
    
    # Setup reactive callbacks
    setup_x_callback(state, y_node, outputs)
    setup_source_callback(state, outputs)
    setup_replot_callback(state, outputs)  # Replot button callback (format changes)
    
    # Create UI components
    control_panel = create_control_panel_ui(x_node, y_node, dataframe_node, plottype_node, state)
    setup_dataframe_callbacks(state, outputs, control_panel.plot_trigger) # DataFrame mode callbacks
    setup_range_ui_sync(session, state)  # Sync range input fields with data bounds
    setup_axis_limits_sync(session, state)  # Sync axis limits input fields
    setup_axis_finallimits_listener(state)  # Listen to zoom/pan changes
    setup_axis_limits_input_callbacks(state)  # Apply user-entered axis limits
    
    tabs_result = create_tab_content(control_panel, state, outputs)
    help_visibility = setup_help_section(outputs.plot)
    
    # Load JavaScripts
    js_content = read(joinpath(@__DIR__, "javascripts.js"), String)
    
    # Assemble and return final layout (with modal dialog)
    layout = assemble_layout(tabs_result.tabs, help_visibility, outputs.plot, outputs.table, 
                           state, tabs_result.overwrite_trigger, tabs_result.cancel_trigger)
                           
    return DOM.div(
        DOM.script(js_content),
        layout
    )
end

