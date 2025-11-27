"""
    setup_dropdowns(dims_dict_obs, selected_x, selected_plottype)

Create and configure dropdown menus for X, Y, and plot type selection.

Returns a NamedTuple with:
- `x_node`: Observable containing X dropdown DOM element
- `y_node`: Observable containing Y dropdown DOM element  
- `plottype_node`: Observable containing dropdown DOM element
"""
function setup_dropdowns(dims_dict_obs, selected_x, selected_plottype, supported_plot_types)
    dropdown_x_node = Observable(DOM.div("Click to load X variables"))
    
    # Setup X dropdown to update when data changes
    on(dims_dict_obs) do dims_dict
        vectors_only = filter(p -> length(last(p)) == 1, dims_dict)
        array_names = string.(keys(vectors_only)) |> sort!
        if isempty(array_names)
            array_names = [""]
        end
        dropdown_x_node[] = create_dropdown(array_names, selected_x; placeholder="Select X")
    end
    notify(dims_dict_obs)

    # The actual options will be populated dynamically by setup_x_callback()
    # when the user selects an X variable.
    dropdown_y_node = create_dropdown([], nothing; 
        placeholder="Select Y after you selected X", 
        disabled=true) |> Observable
    dropdown_plottype_node = Observable(create_dropdown(supported_plot_types, selected_plottype))
    
    return (; x_node=dropdown_x_node, y_node=dropdown_y_node, plottype_node=dropdown_plottype_node)
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
