"""
    create_dataframe_column_checkboxes(columns, selected_columns)

Create checkboxes for DataFrame column selection.

# Arguments
- `columns::Vector{String}`: Column names
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns

# Returns
DOM.div containing vertical list of checkboxes with column names
"""
function create_dataframe_column_checkboxes(columns, selected_columns)
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
    create_source_type_selector(source_type)

Create radio buttons for source type selection (X,Y Arrays vs DataFrame).

# Arguments
- `source_type::Observable{String}`: Observable tracking the selected source type

# Returns
DOM.div containing radio buttons for source type selection
"""
function create_source_type_selector(source_type)
    DOM.div(
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
end

"""
    create_array_mode_content(dropdowns, trigger_update)

Create UI content for array mode (X and Y dropdowns).

# Arguments
- `dropdowns`: NamedTuple containing dropdown nodes
- `trigger_update::Observable`: Observable to trigger plot updates

# Returns
DOM.div containing X and Y selection dropdowns
"""
function create_array_mode_content(dropdowns, trigger_update)
    x_source = DOM.div(
        "Select X:", 
        DOM.div(dropdowns.x_node; onclick=js"() => $(trigger_update).notify(true)");
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    y_source = DOM.div(
        "Select Y:", dropdowns.y_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    DOM.div(x_source, y_source)
end

"""
    create_select_all_button(selected_dataframe, selected_columns, opened_file_df)

Create a "Select All" button for DataFrame column selection.

# Arguments
- `selected_dataframe::Observable`: Observable tracking the selected DataFrame
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns
- `opened_file_df::Observable`: Observable containing the opened file DataFrame (optional)

# Returns
Observable DOM.button that selects all columns when clicked
"""
function create_select_all_button(selected_dataframe, selected_columns, opened_file_df=nothing)
    # Helper function to create the button
    function make_button(df_name, opened_df)
        enabled = !isnothing(df_name) && df_name != ""
        
        # Get columns - from opened file or from Main module
        columns = if enabled
            if df_name == "__opened_file__" && !isnothing(opened_df)
                names(opened_df)
            else
                get_dataframe_columns(df_name)
            end
        else
            String[]
        end
        
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
    
    # Use map with both observables if opened_file_df is provided
    if isnothing(opened_file_df)
        map(selected_dataframe) do df_name
            make_button(df_name, nothing)
        end
    else
        map(selected_dataframe, opened_file_df) do df_name, opened_df
            make_button(df_name, opened_df)
        end
    end
end

"""
    create_deselect_all_button(selected_columns)

Create a "Deselect All" button for DataFrame column selection.

# Arguments
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns

# Returns
DOM.button that deselects all columns when clicked
"""
function create_deselect_all_button(selected_columns)
    DOM.button(
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
end

"""
    create_plot_button(selected_columns, plot_trigger)

Create a plot button that is enabled only when >= 2 columns are selected.

# Arguments
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns
- `plot_trigger::Observable{Int}`: Observable to trigger plot generation

# Returns
Observable DOM.button for triggering plot generation
"""
function create_plot_button(selected_columns, plot_trigger)
    plot_button_enabled = map(selected_columns) do cols
        length(cols) >= 2
    end
    
    plot_button_style = map(plot_button_enabled) do enabled
        Styles(
            "padding" => "5px 15px",
            "cursor" => enabled ? "pointer" : "not-allowed",
            "background-color" => enabled ? "#4CAF50" : "#cccccc",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px"
        )
    end
    
    map(plot_button_enabled, plot_button_style) do enabled, style
        DOM.button(
            "(Re-)Plot",
            onclick=enabled ? js"() => $(plot_trigger).notify($(plot_trigger).value + 1)" : js"() => {}",
            disabled=!enabled,
            style=style
        )
    end
end

"""
    create_dataframe_mode_content(dropdowns, selected_dataframe, selected_columns, plot_trigger, opened_file_df)

Create UI content for DataFrame mode.

# Arguments
- `dropdowns`: NamedTuple containing dropdown nodes
- `selected_dataframe::Observable`: Observable tracking the selected DataFrame
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns
- `plot_trigger::Observable{Int}`: Observable to trigger plot generation
- `opened_file_df::Observable`: Observable containing the opened file DataFrame

# Returns
DOM.div containing DataFrame selection UI and column checkboxes
"""
function create_dataframe_mode_content(dropdowns, selected_dataframe, selected_columns, plot_trigger, opened_file_df)
    dataframe_dropdown_node = dropdowns.dataframe_node
    
    # Column checkboxes - reactive to both selected_dataframe and opened_file_df
    column_checkboxes_node = map(selected_dataframe, opened_file_df) do df_name, opened_df
        if isnothing(df_name) || df_name == ""
            return DOM.div("Select a DataFrame first")
        end
        
        # Get columns - from opened file or from Main module
        columns = if df_name == "__opened_file__" && !isnothing(opened_df)
            names(opened_df)
        else
            get_dataframe_columns(df_name)
        end
        
        return create_dataframe_column_checkboxes(columns, selected_columns)
    end
    
    select_all_button = create_select_all_button(selected_dataframe, selected_columns, opened_file_df)
    deselect_all_button = create_deselect_all_button(selected_columns)
    plot_button = create_plot_button(selected_columns, plot_trigger)
    
    # Button row: Select All, Deselect All, and Plot buttons
    button_row = map(select_all_button, plot_button) do sel_all, plot_btn
        DOM.div(
            sel_all, deselect_all_button, plot_btn;
            style=Styles("display" => "flex", "align-items" => "center", "margin-bottom" => "10px", "margin-top" => "10px")
        )
    end
    
    DOM.div(
        DOM.div(
            "Select Source:", dataframe_dropdown_node;
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "10px")
        ),
        button_row,
        column_checkboxes_node;
        style=Styles("display" => "flex", "flex-direction" => "column")
    )
end

"""
    create_plot_kind_selector(dropdowns)

Create plot type selection UI.

# Arguments
- `dropdowns`: NamedTuple containing dropdown nodes

# Returns
DOM.div containing plot type dropdown
"""
function create_plot_kind_selector(dropdowns)
    DOM.div(
        "Plot type:", dropdowns.plottype_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
end

"""
    create_legend_control(show_legend, legend_title_text)

Create legend visibility checkbox and title input UI.

# Arguments
- `show_legend::Observable{Bool}`: Observable tracking legend visibility
- `legend_title_text::Observable{String}`: Observable tracking legend title text

# Returns
DOM.div containing legend checkbox and title input
"""
function create_legend_control(show_legend, legend_title_text)
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
        value=legend_title_text,
        placeholder="Legend Title",
        onkeydown=js"""
            event => {
                if (event.key === 'Enter') {
                    event.preventDefault();
                    $(legend_title_text).notify(event.target.value);
                }
            }
        """,
        style=legend_title_style
    )

    DOM.div(
        legend_checkbox, " Show Legend", legend_title_input;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
    )
end

"""
    create_label_input(label_text, label_name, label_observable)

Create a text input field for plot labels (xlabel, ylabel, or title).

# Arguments
- `label_text::String`: Display label for the input field
- `label_name::String`: Name/identifier for the label
- `label_observable::Observable{String}`: Observable tracking the label text

# Returns
DOM.div containing labeled text input field
"""
function create_label_input(label_text, label_name, label_observable)
    DOM.div(
        DOM.label(label_text, style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=label_observable,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter') {
                        event.preventDefault();
                        $(label_observable).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center", 
                     "gap" => "5px", "margin-bottom" => "5px")
    )
end
