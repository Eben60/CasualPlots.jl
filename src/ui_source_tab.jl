
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
            onchange=js"event => window.CasualPlots.handleColumnCheckboxChange(event, $(selected_columns))"
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
            onchange=js"event => window.CasualPlots.updateObservableValue(event, $(source_type))"
        ), " X, Y Arrays  ",
        DOM.input(
            type="radio", name="source_type", value="DataFrame",
            checked=(source_type[] == "DataFrame"),
            onchange=js"event => window.CasualPlots.updateObservableValue(event, $(source_type))"
        ), " File/DataFrame";
        class="mb-2"
    )
end

"""
    create_array_mode_content(x_node, y_node, trigger_update)

Create UI content for array mode (X and Y dropdowns).

# Arguments
- `x_node`: Observable X dropdown node
- `y_node`: Observable Y dropdown node
- `trigger_update::Observable`: Observable to trigger plot updates

# Returns
DOM.div containing X and Y selection dropdowns
"""
function create_array_mode_content(x_node, y_node, trigger_update)
    x_source = DOM.div(
        "Select X:", 
        DOM.div(x_node; onclick=js"() => window.CasualPlots.setObservableValue($(trigger_update), true)");
        class="flex-row align-center gap-1 mb-1"
    )
    
    y_source = DOM.div(
        "Select Y:", y_node;
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
            onclick=enabled ? js"() => window.CasualPlots.selectAllColumns($(columns), $(selected_columns))" : js"() => {}",
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
        onclick=js"() => window.CasualPlots.deselectAllColumns($(selected_columns))",
        class="btn btn-warning mr-1"
    )
end

"""
    create_plot_button(source_type, selected_x, selected_y, selected_columns, plot_trigger)

Create a plot button that is enabled when any data source is selected.
For X,Y Arrays mode: enabled when both X and Y are selected.
For DataFrame mode: enabled when >= 2 columns are selected.

# Arguments
- `source_type::Observable{String}`: Observable tracking the source type
- `selected_x::Observable`: Observable tracking selected X variable
- `selected_y::Observable`: Observable tracking selected Y variable
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns
- `plot_trigger::Observable{Int}`: Observable to trigger plot generation

# Returns
Observable DOM.button for triggering plot generation
"""
function create_plot_button(source_type, selected_x, selected_y, selected_columns, plot_trigger)
    plot_button_enabled = map(source_type, selected_x, selected_y, selected_columns) do st, x, y, cols
        if st == "DataFrame"
            length(cols) >= 2
        else
            # X,Y Arrays mode - enabled when both X and Y are selected
            !isnothing(x) && x != "" && !isnothing(y) && y != ""
        end
    end
    
    map(plot_button_enabled) do enabled
        DOM.button(
            "(Re-)Plot",
            onclick=enabled ? js"() => window.CasualPlots.incrementObservable($(plot_trigger))" : js"() => {}",
            disabled=!enabled,
            class=enabled ? "btn btn-success" : "btn btn-disabled"
        )
    end
end

"""
    create_range_input_row(range_from, range_to, data_bounds_from, data_bounds_to, plot_button_node)

Create a row with range input fields and the plot button.

# Arguments
- `range_from::Observable{Union{Nothing,Int}}`: Observable for range start value
- `range_to::Observable{Union{Nothing,Int}}`: Observable for range end value  
- `data_bounds_from::Observable{Union{Nothing,Int}}`: Observable for data's first index (default)
- `data_bounds_to::Observable{Union{Nothing,Int}}`: Observable for data's last index (default)
- `plot_button_node`: The reactive plot button node

# Returns
DOM.div containing range inputs and plot button in a 3-column layout
"""
function create_range_input_row(range_from, range_to, data_bounds_from, data_bounds_to, plot_button_node)
    # Caption row
    caption_row = DOM.div(
        DOM.div("Range from:"; class="range-caption"),
        DOM.div("Range to:"; class="range-caption"),
        DOM.div();
        class="range-row"
    )
    
    # Create input fields OUTSIDE the reactive map so they persist
    from_input = DOM.input(
        type="number",
        id="range-from-input",
        class="range-input",
        placeholder="",
        onchange=js"event => window.CasualPlots.updateIntObservable(event, $(range_from))",
        onkeydown=js"event => window.CasualPlots.handleIntEnterKey(event, $(range_from))",
    )
    
    to_input = DOM.input(
        type="number",
        id="range-to-input",
        class="range-input",
        placeholder="",
        onchange=js"event => window.CasualPlots.updateIntObservable(event, $(range_to))",
        onkeydown=js"event => window.CasualPlots.handleIntEnterKey(event, $(range_to))",
    )
    
    # Input row - inputs are fixed, only button is reactive
    input_row = DOM.div(
        from_input,
        to_input,
        plot_button_node;  # This is already reactive (Observable)
        class="range-row"
    )
    
    DOM.div(caption_row, input_row; class="range-section mb-2")
end

"""
    create_dataframe_dropdown_row(dataframe_node)

Create the DataFrame source selection dropdown row.

# Arguments
- `dataframe_node`: Observable DataFrame selection dropdown node

# Returns
DOM.div containing the DataFrame dropdown with label
"""
function create_dataframe_dropdown_row(dataframe_node)
    DOM.div(
        "Select Source:", dataframe_node;
        class="flex-row align-center gap-1 mb-2"
    )
end

"""
    create_dataframe_column_controls(selected_dataframe, selected_columns, opened_file_df)

Create UI content for DataFrame column selection (Select All/Deselect All buttons + checkboxes).

# Arguments
- `selected_dataframe::Observable`: Observable tracking the selected DataFrame
- `selected_columns::Observable{Vector{String}}`: Observable tracking selected columns
- `opened_file_df::Observable`: Observable containing the opened file DataFrame

# Returns
DOM.div containing button row and column checkboxes
"""
function create_dataframe_column_controls(selected_dataframe, selected_columns, opened_file_df)
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
    
    # Button row: Select All and Deselect All buttons only
    button_row = map(select_all_button) do sel_all
        DOM.div(
            sel_all, deselect_all_button;
            class="flex-row align-center mb-2 mt-2"
        )
    end
    
    DOM.div(button_row, column_checkboxes_node; class="flex-col")
end

