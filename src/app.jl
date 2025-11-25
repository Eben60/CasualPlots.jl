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
    # Initialize application state
    state = initialize_app_state()
    
    # Setup dropdown menus
    dropdowns = setup_dropdowns(state.dims_dict_obs, state.selected_x, state.selected_art)
    
    # Initialize output observables
    outputs = initialize_output_observables()
    
    # Setup reactive callbacks
    setup_x_callback(state.dims_dict_obs, state.selected_x, state.selected_y, 
                     dropdowns.y_node, outputs.plot, outputs.table)
    setup_source_callback(state.selected_x, state.selected_y, state.selected_art, 
                          state.show_legend, outputs.current_x, outputs.current_y,
                          outputs.plot, outputs.table,
                          state.xlabel_text, state.ylabel_text, state.title_text)
    setup_format_callback(state.selected_art, state.show_legend, 
                          outputs.current_x, outputs.current_y, outputs.plot,
                          state.xlabel_text, state.ylabel_text, state.title_text)
    
    # Create UI components
    control_panel = create_control_panel_ui(dropdowns, state.show_legend, state.trigger_update,
                                             state.xlabel_text, state.ylabel_text, state.title_text)
    tabs = create_tab_content(control_panel)
    help = setup_help_section(outputs.plot)
    
    # Assemble and return final layout
    return assemble_layout(tabs, help.visibility, outputs.plot, outputs.table)
end

