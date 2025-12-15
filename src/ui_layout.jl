"""
    assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)

Assemble the final application layout with all panes and grids.

# Arguments
- `ctrlpane_content`: Tabbed control panel content
- `help_visibility`: Observable controlling help section visibility
- `plot_observable`: Observable containing plot display
- `table_observable`: Observable containing table display
- `state`: Application state NamedTuple (for modal dialog)
- `overwrite_trigger`: Observable for overwrite button clicks
- `cancel_trigger`: Observable for cancel button clicks

# Returns
Complete DOM structure for the application including modal overlay
"""
function assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)
    # Split ctrlpane vertically: tabs on top, help on bottom
    ctrlpane_split = DOM.div(
        DOM.div(ctrlpane_content; class="ctrl-pane-content"),
        help_section(help_visibility);
        class="ctrl-pane-split"
    )
    
    ctrlpane = Card(ctrlpane_split; class="pane-card pane-card-ctrl")
    tblpane = Card(table_observable; class="pane-card pane-card-table")
    pltpane = Card(plot_observable; class="pane-card pane-card-plot")
    
    top_row = Grid(ctrlpane, pltpane; columns="350px 810px", gap="5px")
    container = Grid(top_row, tblpane; rows="610px auto", gap="5px")
    
    # Create modal dialog overlay (placed last to be on top of everything)
    modal = create_modal_container(state, overwrite_trigger, cancel_trigger)
    
    # Inject Global CSS
    global_style = DOM.style(GLOBAL_CSS)
    
    return DOM.div(global_style, container, modal; class="main-layout-container")
end
