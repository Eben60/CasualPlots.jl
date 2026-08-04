"""
    assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)

Assemble the application layout using BonitoWidgets.Workspace.

Default arrangement: Controls (left) + Plot (right) docked side-by-side.
Data Table starts as a floating window (closable). A restore button in the
controls pane brings it back if closed.

# Returns
Complete DOM structure for the application including modal overlay
"""
function assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)
    # --- Restore-table button (placed at bottom of controls pane) ---
    restore_table_trigger = Observable(false)
    restore_btn = DOM.button("Show Data Table"; 
        class="btn btn-primary",
        onclick=js"() => { $(restore_table_trigger).notify(true) }"
    )
    
    # Control pane: tabs on top, restore button + help section at bottom
    ctrlpane_split = DOM.div(
        DOM.div(ctrlpane_content; class="ctrl-pane-content"),
        DOM.div(restore_btn; style=Styles(
            "padding" => "8px 10px", "text-align" => "center", "border-top" => "1px solid #ccc"
        )),
        help_section(help_visibility);
        class="ctrl-pane-split"
    )
    
    # --- Define panels ---
    tbl_panel = Panel("table", table_observable; label="Data Table", closable=true)
    
    ws = Workspace(
        Panel("controls", ctrlpane_split; label="Controls", closable=false),
        Panel("plot", plot_observable; label="Plot", closable=false),
        tbl_panel;
        layout=workspacelayout(
            hsplit(tabgroup("controls"), tabgroup("plot"); fractions=[0.3, 0.7]);
            floating=[floatpanel("table"; x=100, y=60, width=800, height=300)]
        )
    )
    
    # WORKAROUND: BonitoWidgets JS `clone` function turns TypedArrays into Dict-like Objects,
    # causing `ws.layout` updates to corrupt `fractions` into a Dict and crash `remove_panel!`.
    # We convert `fractions` to `Vector{Any}` so it serializes as a standard JS Array.
    function fix_fractions_for_js!(node)
        if haskey(node, "fractions") && node["fractions"] isa AbstractVector
            node["fractions"] = Any[node["fractions"]...]
        end
        if haskey(node, "children")
            for c in node["children"]
                fix_fractions_for_js!(c)
            end
        end
    end
    fix_fractions_for_js!(ws.layout[]["root"])

    on(ws.layout) do lay
        function repair_dict_fractions!(node)
            if haskey(node, "fractions") && node["fractions"] isa AbstractDict
                dict = node["fractions"]
                arr = Any[]
                for i in 0:(length(dict)-1)
                    push!(arr, get(dict, string(i), 0.5))
                end
                node["fractions"] = arr
            end
            if haskey(node, "children")
                for c in node["children"]
                    repair_dict_fractions!(c)
                end
            end
        end
        repair_dict_fractions!(lay["root"])
    end
    
    # --- Restore-table callback ---
    # When ws.closed fires for "table", remove_panel! is called automatically by
    # Workspace internals. To restore, we re-add and float it.
    on(restore_table_trigger) do _
        add_panel!(ws, tbl_panel; active=false)   # no-op if already present
        float_panel!(ws, "table"; x=100, y=60, width=800, height=300)
    end
    
    # --- Modal dialog (must sit ABOVE BonitoWidgets floating layer) ---
    modal = create_modal_container(state, overwrite_trigger, cancel_trigger)
    
    # --- Global CSS (our custom styles for inputs, buttons, format tab, etc.) ---
    global_style = DOM.style(GLOBAL_CSS)
    
    # Container needs explicit height for Workspace to fill.
    # BonitoWidgets Workspace renders with height:100%, so its parent must have a defined height.
    return DOM.div(
        global_style,
        ws,
        modal;
        class="main-layout-container",
        style=Styles("height" => "100vh", "position" => "relative")
    )
end
