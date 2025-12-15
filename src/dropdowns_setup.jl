"""
    create_x_dropdown(state)

Create the X variable selection dropdown.
Populates based on `state.dims_dict_obs`.
"""
function create_x_dropdown(state)
    (; dims_dict_obs, selected_x) = state
    dropdown_x_node = Observable(DOM.div("Click to load X variables"))
    
    # Setup X dropdown to update when data changes
    on(dims_dict_obs) do dims_dict
        array_names = extract_x_candidates(dims_dict)
        if isempty(array_names)
            array_names = [""]
        end
        dropdown_x_node[] = create_dropdown(array_names, selected_x; placeholder="Select X")
    end
    notify(dims_dict_obs)
    return dropdown_x_node
end

"""
    create_y_dropdown()

Create the Y variable selection dropdown (initially disabled).
"""
function create_y_dropdown()
    # The actual options will be populated dynamically by setup_x_callback()
    return create_dropdown([], nothing; 
        placeholder="Select Y after you selected X", 
        disabled=true) |> Observable
end

"""
    create_dataframe_dropdown(state)

Create the DataFrame selection dropdown.
Populates from `state.dataframes_dict_obs` and `state.opened_file_df`.
"""
function create_dataframe_dropdown(state)
    (; dataframes_dict_obs, opened_file_df, selected_dataframe) = state
    dropdown_dataframe_node = Observable(DOM.div("Click to load DataFrames"))
    
    # Update DataFrame dropdown when dataframes_dict_obs or opened_file_df changes
    onany(dataframes_dict_obs, opened_file_df) do df_names, opened_df
        df_names_strings = string.(df_names) |> sort!
        
        options = []
        
        # Add "opened file" option
        opened_file_enabled = !isnothing(opened_df)
        opened_file_option = DOM.option(
            "opened file";
            value="__opened_file__",
            disabled=!opened_file_enabled,
            style=opened_file_enabled ? "" : "color: #999;"
        )
        push!(options, opened_file_option)
        
        # Add regular DataFrame options
        for name in df_names_strings
            if !isempty(name)
                push!(options, DOM.option(name; value=name))
            end
        end
        
        dropdown_dataframe_node[] = create_dropdown(options, selected_dataframe; placeholder="Select DataFrame")
    end
    notify(dataframes_dict_obs)
    return dropdown_dataframe_node
end

"""
    create_dropdown(options, selected_val_obs; placeholder=nothing, disabled=false)

Create a generic dropdown menu.

# Arguments
- `options`: Vector of `DOM.option` elements or strings.
- `selected_val_obs`: Observable to update when selection changes.
- `placeholder`: Optional placeholder text (if string) or `DOM.option` (if element).
- `disabled`: Whether the dropdown is disabled.

# Returns
DOM.select element
"""
function create_dropdown(options, selected_val_obs::Union{Observable, Nothing}=nothing; placeholder=nothing, disabled=false)
    
    final_options = []
    current_val = isnothing(selected_val_obs) ? nothing : selected_val_obs[]
    
    # Handle placeholder
    if !isnothing(placeholder)
        if placeholder isa AbstractString
            # Select placeholder if current_val is nothing or empty
            is_selected = isnothing(current_val) || current_val == ""
            push!(final_options, DOM.option(placeholder, value="", selected=is_selected, disabled=true))
        else
            push!(final_options, placeholder)
        end
    end
    
    # Handle options
    for opt in options
        if opt isa AbstractString
            is_selected = !isnothing(current_val) && opt == current_val
            push!(final_options, DOM.option(opt, value=opt, selected=is_selected))
        else
            push!(final_options, opt)
        end
    end
    
    # Setup onchange handler if observable provided
    attributes = Dict{Symbol, Any}()
    if disabled
        attributes[:disabled] = true
    end
    
    if !isnothing(selected_val_obs)
        attributes[:onchange] = js"event => $(selected_val_obs).notify(event.target.value)"
    end
    
    return DOM.select(final_options...; attributes...)
end
