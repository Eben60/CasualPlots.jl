"""
    create_dataframe_column_checkboxes(columns, selected_columns)

Create checkboxes for DataFrame column selection.

# Arguments
- `columns::Vector{String}`: Column names
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns

# Returns
DOM.div containing vertical list of checkboxes with column names
"""
function create_dataframe_column_checkboxes(columns::Vector{String}, selected_columns)
    if isempty(columns)
        return DOM.div("No columns available")
    end
    
    # Create checkboxes - NOT reactive on selected_columns
    # Checkboxes only rebuild when DataFrame changes (via the outer map on selected_dataframe)
    # Individual checkbox state is managed by native HTML + onchange events
    checkboxes = map(columns) do col_name
        checkbox = DOM.input(
            type="checkbox",
            class="column-checkbox",  # CSS class for easier identification
            checked=false,  # Always start unchecked when rebuilding
            value=col_name,
            onchange=js"""
                event => {
                    const checked = event.target.checked;
                    const value = event.target.value;
                    let current = $(selected_columns).value;
                    if (checked) {
                        if (!current.includes(value)) {
                            current.push(value);
                        }
                    } else {
                        const index = current.indexOf(value);
                        if (index > -1) {
                            current.splice(index, 1);
                        }
                    }
                    $(selected_columns).notify(current);
                }
            """,
            style=Styles("margin-right" => "5px")  # Space between checkbox and label
        )
        
        # Horizontal layout: checkbox followed by label
        DOM.div(
            checkbox, col_name;
            style=Styles(
                "margin-bottom" => "3px",
                "display" => "flex",
                "align-items" => "center"
            )
        )
    end
    
    # Wrap in scrollable container
    return DOM.div(
        checkboxes...;
        style=Styles(
            "display" => "flex",
            "flex-direction" => "column",
            "max-height" => "200px",
            "overflow-y" => "auto",
            "border" => "1px solid #ccc",
            "padding" => "5px",
            "border-radius" => "4px"
        )
    )
end

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
    (; trigger_update, plot_format, plot_handles, source_type, selected_dataframe, selected_columns) = state
    (; show_legend) = plot_format
    (; xlabel_text, ylabel_text, title_text) = plot_handles
    
    # Radio buttons for source type selection (no title)
    source_type_selector = DOM.div(
        DOM.input(
            type="radio", name="source_type", value="X, Y Arrays", 
            checked=(source_type[] == "X, Y Arrays"),
            onchange=js"event => $(source_type).notify(event.target.value)"
        ), " X, Y Arrays  ",
        DOM.input(
            type="radio", name="source_type", value="DataFrame",
            checked=(source_type[] == "DataFrame"),
            onchange=js"event => $(source_type).notify(event.target.value)"
        ), " DataFrame";
        style=Styles("margin-bottom" => "10px")
    )
    
    # Array mode UI
    x_source = DOM.div(
        "Select X:", 
        DOM.div(dropdowns.x_node; onclick=js"() => $(trigger_update).notify(true)");
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    y_source = DOM.div(
        "Select Y:", dropdowns.y_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    array_mode_content = DOM.div(x_source, y_source)
    
    # DataFrame mode UI - reactive based on selected DataFrame
    dataframe_dropdown_node = dropdowns.dataframe_node
    
    column_checkboxes_node = map(selected_dataframe) do df_name
        # Clear selections when DataFrame changes to avoid stale state
        selected_columns[] = String[]
        
        if isnothing(df_name) || df_name == ""
            return DOM.div("Select a DataFrame first")
        end
        columns = get_dataframe_columns(df_name)
        return create_dataframe_column_checkboxes(columns, selected_columns)
    end
    
    # Plot button - enabled only when >= 2 columns selected
    plot_button_enabled = map(selected_columns) do cols
        length(cols) >= 2
    end
    
    plot_button_style = map(plot_button_enabled) do enabled
        base_style = Styles(
            "padding" => "5px 15px",
            "cursor" => enabled ? "pointer" : "not-allowed",
            "background-color" => enabled ? "#4CAF50" : "#cccccc",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px"
        )
        return base_style
    end
    
    plot_trigger = Observable(0)  # Increment to trigger plot
    
    # Select All button
    select_all_button = map(selected_dataframe) do df_name
        enabled = !isnothing(df_name) && df_name != ""
        # Get columns from Julia side instead of scraping DOM
        columns = enabled ? get_dataframe_columns(df_name) : String[]
        DOM.button(
            "Select All",
            onclick=enabled ? js"""() => {
                // Pass column list from Julia side - no DOM scraping needed
                const allCols = $(columns);
                // 1. Update Julia state
                $(selected_columns).notify(allCols);
                // 2. Manually sync UI (since checkboxes aren't reactive on selected_columns)
                document.querySelectorAll('.column-checkbox').forEach(cb => {
                    cb.checked = true;
                });
            }""" : js"() => {}",
            disabled=!enabled,
            style=Styles(
                "padding" => "5px 15px",
                "margin-right" => "5px",
                "cursor" => enabled ? "pointer" : "not-allowed",
                "background-color" => enabled ? "#2196F3" : "#cccccc",
                "color" => "white",
                "border" => "none",
                "border-radius" => "4px"
            )
        )
    end
    
    # Deselect All button
    deselect_all_button = DOM.button(
        "Deselect All",
        onclick=js"""() => {
            // 1. Update Julia state
            $(selected_columns).notify([]);
            // 2. Manually sync UI (since checkboxes aren't reactive on selected_columns)
            document.querySelectorAll('.column-checkbox').forEach(cb => {
                cb.checked = false;
            });
        }""",
        style=Styles(
            "padding" => "5px 15px",
            "margin-right" => "5px",
            "cursor" => "pointer",
            "background-color" => "#FF9800",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px"
        )
    )
    
    plot_button = map(plot_button_enabled, plot_button_style) do enabled, style
        DOM.button(
            "(Re-)Plot",
            onclick=enabled ? js"() => $(plot_trigger).notify($(plot_trigger).value + 1)" : js"() => {}",
            disabled=!enabled,
            style=style
        )
    end
    
    # Button row: Select All, Deselect All, and Plot buttons
    button_row = map(select_all_button, plot_button) do sel_all, plot_btn
        DOM.div(
            sel_all, deselect_all_button, plot_btn;
            style=Styles("display" => "flex", "align-items" => "center", "margin-bottom" => "10px", "margin-top" => "10px")
        )
    end
    
    dataframe_mode_content = DOM.div(
        DOM.div(
            "Select Source:", dataframe_dropdown_node;
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "10px")
        ),
        button_row,
        column_checkboxes_node;
        style=Styles("display" => "flex", "flex-direction" => "column")
    )
    
    # Dynamic source content that switches based on source_type
    source_content = map(source_type) do st
        if st == "DataFrame"
            return dataframe_mode_content
        else
            return array_mode_content
        end
    end
    
    plot_kind = DOM.div(
        "Plot type:", dropdowns.plottype_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    legend_checkbox = DOM.input(type="checkbox", checked=show_legend;
        onchange = js"event => $(show_legend).notify(event.target.checked)"
    )
    
    # Legend title input
    legend_title_style = map(show_legend) do show
        return Styles(
            "width" => "100px", 
            "padding" => "2px 5px", 
            "margin-left" => "10px",
            "display" => show ? "block" : "none"
        )
    end

    legend_title_input = DOM.input(
        type="text", 
        value=state.plot_handles.legend_title_text,
        placeholder="Legend Title",
        onkeydown=js"""
            event => {
                if (event.key === 'Enter') {
                    event.preventDefault();
                    $(state.plot_handles.legend_title_text).notify(event.target.value);
                }
            }
        """,
        style=legend_title_style
    )

    legend_control = DOM.div(
        legend_checkbox, " Show Legend", legend_title_input;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
    )
    
    # Text input fields for plot labels - editable with Enter/Tab support
    xlabel_input = DOM.div(
        DOM.label("X-Axis:", style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=xlabel_text,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter') {
                        event.preventDefault();
                        $(xlabel_text).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center", 
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    ylabel_input = DOM.div(
        DOM.label("Y-Axis:", style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=ylabel_text,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter') {
                        event.preventDefault();
                        $(ylabel_text).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center",
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    title_input = DOM.div(
        DOM.label("Title:", style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=title_text,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter') {
                        event.preventDefault();
                        $(title_text).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center",
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    return (; source_type_selector, source_content, plot_kind, legend_control,
              xlabel_input, ylabel_input, title_input, plot_trigger)
end
