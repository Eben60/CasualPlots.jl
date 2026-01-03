function var_to_string(t)
    s = t |> Symbol |> string
    parts = split(s, '.')
    return parts[end]
end

function create_plot(x_data::AbstractVector, y_data, x_name, y_name; 
    plot_format = (; plottype=Scatter, show_legend=nothing, legend_title="")) # x, y AbstractString or Symbol 
    (; show_legend) = plot_format 
    if length(x_data) != size(y_data, 1)
        println("Error: Dimension mismatch. X has length $(length(x_data)) but Y has $(size(y_data, 1)) rows.")
        return nothing
    end

    n_cols = size(y_data, 2)    
    # If show_legend is nothing, default to showing legend only for multi-column data
    # Otherwise, use the explicit value (from checkbox)
    updated_show_legend = isnothing(show_legend) ? (n_cols > 1) : plot_format.show_legend
    plot_format = merge(plot_format, (; show_legend=updated_show_legend))

    m = hcat(x_data, y_data)
    ys = ["y_name_$n" for n in 1:n_cols]
    nms = vcat("x", ys)
    dfw = DataFrame(m, nms)
    return create_plot(dfw; x_name, y_name, plot_format)
end

function select_cols(dfw; xcol=nothing, cols=nothing) 
    if !isnothing(cols)
        isnothing(xcol) || error("Either first column, or all columns can be provided, not both simultaneously")
        return select(dfw, cols)
    end
    if isnothing(xcol)
        xcol = 1
    end
    if xcol isa Integer
        x_pos = xcol
    else
        x_pos = columnindex(dfw, xcol)
    end
    return dfw[!, x_pos:end]
end

function create_plot(df_w::AbstractDataFrame ; xcol=1, x_name=nothing, y_name, plot_format)
    dfw = select_cols(df_w; xcol)
    
    x_col = names(dfw)[1] |> Symbol
    if isnothing(x_name)
        x_name = String(x_col)
    end
    ys = names(dfw)[2:end]
    
    # Handle show_legend like in array version - convert nothing to boolean based on num columns
    n_cols = length(ys)
    (; show_legend) = plot_format
    updated_show_legend = isnothing(show_legend) ? (n_cols > 1) : show_legend
    plot_format = merge(plot_format, (; show_legend=updated_show_legend))

    df = stack(dfw, ys;
        variable_name=:group, value_name=:y)

    mappings = (; x_col, y_col=:y, group_col=:group)
    return create_plot_df_long(df, x_name, y_name, plot_format; mappings)
end

function create_plot_df_long(df, x_name, y_name, plot_format; mappings=nothing)
    WGLMakie.activate!()
    
    if isnothing(mappings) 
        mappings=(; x_col=:x, y_col=:y, group_col=:group)
    end
    (; x_col, y_col, group_col) = mappings
    (; plottype, legend_title, show_legend) = plot_format
    
    # Check if custom labels were provided in plot_format
    custom_title = get(plot_format, :title, nothing)
    custom_xlabel = get(plot_format, :xlabel, nothing)
    custom_ylabel = get(plot_format, :ylabel, nothing)

    # Use custom labels if provided, otherwise use the data column names
    final_x_name = if !isnothing(custom_xlabel) && custom_xlabel != ""
        custom_xlabel
    else
        x_name
    end
    
    final_y_name = if !isnothing(custom_ylabel) && custom_ylabel != ""
        custom_ylabel
    else
        y_name
    end

    plt = data(df) * mapping(x_col => final_x_name, y_col => final_y_name; color=group_col => legend_title) * visual(plottype)
    
    # Use custom title if provided, otherwise generate default
    title = if !isnothing(custom_title) && custom_title != ""
        custom_title
    else
        "$(var_to_string(plottype)) Plot of $final_y_name vs $final_x_name"
    end
    
    fg = draw(plt;
        figure=(; size=(800, 600)), 
        legend=(show=show_legend, ),
        axis=(; title)
    )

    fig = fg.figure
    # Extract axis from FigureGrid - AlgebraOfGraphics stores AxisEntries in grid
    # The AxisEntries object has the axis as its first field
    axis_entries = fg.grid[1, 1]
    axis = axis_entries.axis  # Access the axis field from AxisEntries
    Makie.update_state_before_display!(fig) # Force render to complete without needing a display
    global cp_figure = fig
    global cp_figure_ax = axis
    return (; fig, axis, fig_params = (; title, x_name, y_name, updated_show_legend=show_legend))
end

function check_data_create_plot(x_name, y_name; plot_format, range_from=nothing, range_to=nothing) # x, y AbstractString or Symbol
    try
        x_data = getfield(Main, Symbol(x_name))
        y_data = getfield(Main, Symbol(y_name))

        if y_data isa AbstractVector
            y_data = reshape(y_data, :, 1)
        end

        if y_data isa AbstractMatrix && x_data isa AbstractVector
            # Apply range slicing if specified
            if !isnothing(range_from) || !isnothing(range_to)
                x_first = firstindex(x_data)
                x_last = lastindex(x_data)
                from_idx = isnothing(range_from) ? x_first : range_from
                to_idx = isnothing(range_to) ? x_last : range_to
                
                # Clamp to valid range
                from_idx = clamp(from_idx, x_first, x_last)
                to_idx = clamp(to_idx, x_first, x_last)
                
                # Slice X data
                x_data = x_data[from_idx:to_idx]
                
                # Convert X indices to linear positions for Y
                y_first = firstindex(y_data, 1)
                pos_from = from_idx - x_first + y_first
                pos_to = to_idx - x_first + y_first
                
                # Slice Y data
                y_data = y_data[pos_from:pos_to, :]
            end
            
            return create_plot(x_data, y_data, x_name, y_name; plot_format)
        else
            println("Error: Unsupported data types for plotting. x must be a vector, and y can be a vector or a matrix.")
            return nothing
        end
    catch e
        println("An error occurred during plotting: ", e)
        println("\nStack trace:")
        for (exc, bt) in Base.catch_stack()
            showerror(stdout, exc, bt)
            println()
        end
        return nothing
    end

end
"""
    update_plot_format!(fig, axis; kwargs...)

Update plot format properties (title, xlabel, ylabel) on an existing figure 
WITHOUT rebuilding the plot. This preserves pan/zoom state.

Note: Legend visibility and title are now handled by full replot.

# Arguments
- `fig`: The Makie Figure object
- `axis`: The Makie Axis object  

# Keyword Arguments
- `title::Union{String,Nothing}=nothing`: New title (if provided)
- `xlabel::Union{String,Nothing}=nothing`: New X-axis label (if provided)
- `ylabel::Union{String,Nothing}=nothing`: New Y-axis label (if provided)

# Returns
- `true` if update was successful
- `false` if no valid axis/figure was provided
"""
function update_plot_format!(fig, axis; 
                              title::Union{String,Nothing}=nothing,
                              xlabel::Union{String,Nothing}=nothing,
                              ylabel::Union{String,Nothing}=nothing,
                              kwargs...)  # Accept but ignore other kwargs like legend_title
    
    # Validate inputs
    if isnothing(fig) || isnothing(axis)
        return false
    end
    
    # === Handle axis properties (title, xlabel, ylabel) ===
    axis_props = (; title, xlabel, ylabel)
    
    for (prop_name, new_value) in pairs(axis_props)
        update_axis_property!(axis, prop_name, new_value)
    end
    
    return true
end

"""
    update_axis_property!(axis, prop_name::Symbol, new_value)

Update a single axis property and notify if changed.
Uses `axis[prop_name]` to access the property dynamically.
"""
function update_axis_property!(axis, prop_name::Symbol, new_value)
    # Skip if no value provided or empty string
    if isnothing(new_value) || new_value == ""
        return false
    end
    
    # Get the property observable
    prop_observable = getproperty(axis, prop_name)
    
    # Only update and notify if value actually changed
    if prop_observable[] != new_value
        prop_observable[] = new_value
        return true
    end
    
    return false
end