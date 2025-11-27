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
    # Setup dropdown menus
    dropdowns = setup_dropdowns(state, supported_plot_types)
    
    # Initialize output observables
    outputs = initialize_output_observables()
    
    # Setup reactive callbacks
    setup_x_callback(state, dropdowns.y_node, outputs)
    setup_source_callback(state, outputs)
    setup_format_callback(state, outputs)
    
    # Setup label update callbacks for editable text fields
    setup_label_update_callbacks(state, outputs)
    
    # Create UI components
    control_panel = create_control_panel_ui(dropdowns, state)
    tabs = create_tab_content(control_panel)
    help = setup_help_section(outputs.plot)
    
    # Assemble and return final layout
    return assemble_layout(tabs, help.visibility, outputs.plot, outputs.table)
end

