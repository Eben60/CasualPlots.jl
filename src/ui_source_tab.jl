
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
    checkboxes = map(columns) do col_name
        checkbox = DOM.input(
            type="checkbox",
            class="column-checkbox mr-1",
            checked=false,
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
            """
        )
        
        # Horizontal layout: checkbox followed by label
        DOM.div(
            checkbox, col_name;
            class="flex-row align-center",
            style=Styles("margin-bottom" => "3px") # Keep explicit 3px or use mb-1 (5px)
        )
    end
    
    # Wrap in scrollable container
    return DOM.div(
        checkboxes...;
        class="scroll-list"
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
        ), " File/DataFrame";
        class="mb-2"
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
        class="flex-row align-center gap-1 mb-1"
    )
    
    y_source = DOM.div(
        "Select Y:", dropdowns.y_node;
        class="flex-row align-center gap-1 mb-1"
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
            class=enabled ? "btn btn-primary mr-1" : "btn btn-disabled mr-1"
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
        class="btn btn-warning mr-1"
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
    
    map(plot_button_enabled) do enabled
        DOM.button(
            "(Re-)Plot",
            onclick=enabled ? js"() => $(plot_trigger).notify($(plot_trigger).value + 1)" : js"() => {}",
            disabled=!enabled,
            class=enabled ? "btn btn-success" : "btn btn-disabled"
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
            class="flex-row align-center mb-2 mt-2"
        )
    end
    
    DOM.div(
        DOM.div(
            "Select Source:", dataframe_dropdown_node;
            class="flex-row align-center gap-1 mb-2"
        ),
        button_row,
        column_checkboxes_node;
        class="flex-col"
    )
end
