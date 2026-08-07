"""
    assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)

Assemble the application layout using BonitoWidgets.Workspace.

Default arrangement: Controls (left) + Plot (right) docked side-by-side.
Data Table starts as a floating window.

# Returns
Complete DOM structure for the application including modal overlay
"""
function assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, table_title, state, overwrite_trigger, cancel_trigger)
    # Control pane: tabs on top, help section at bottom
    ctrlpane_split = DOM.div(
        DOM.div(ctrlpane_content; class="ctrl-pane-content"),
        help_section(help_visibility);
        class="ctrl-pane-split"
    )
    
    # --- Define Grid Cells (Top Row Only) ---
    ctrlpane = Card(ctrlpane_split; class="pane-card pane-card-ctrl")
    pltpane = Card(plot_observable; class="pane-card pane-card-plot")
    
    # Grid layout (only top row needed)
    container = Grid(ctrlpane, pltpane; columns="350px 810px", rows="610px", gap="5px", style=Styles("height"=>"610px"))
    
    # --- Floating Window ---
    # Wrap table_observable in a div with auto overflow to allow internal scrolling
    table_content = DOM.div(table_observable; class="table-float-content")
    
    fw = FloatingWindow(
        table_content;
        title=table_title,
        # Positioned right below the 610px high grid (padding 5px + height 610px + gap 5px = 620px)
        x=5, y=620, width=1165, height=305
    )
    
    # --- Modal dialog (must sit ABOVE BonitoWidgets floating layer) ---
    modal = create_modal_container(state, overwrite_trigger, cancel_trigger)
    
    # --- Global CSS (our custom styles for inputs, buttons, format tab, etc.) ---
    global_style = DOM.style(GLOBAL_CSS)
    
    return DOM.div(
        global_style,
        container,
        fw,
        modal;
        class="main-layout-container",
        style=Styles("height" => "100vh", "position" => "relative", "box-sizing"=>"border-box")
    )
end
