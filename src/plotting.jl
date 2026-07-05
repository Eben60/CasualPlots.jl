function var_to_string(t)
    s = t |> Symbol |> string
    parts = split(s, '.')
    return parts[end]
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
    
    # Get axis reversal options (default to false)
    xreversed = get(plot_format, :xreversed, false)
    yreversed = get(plot_format, :yreversed, false)
    
    # Get axis limits (nothing means auto)
    x_min = get(plot_format, :x_min, nothing)
    x_max = get(plot_format, :x_max, nothing)
    y_min = get(plot_format, :y_min, nothing)
    y_max = get(plot_format, :y_max, nothing)

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

    # Determine group differentiation style (Color vs Geometry)
    group_by = get(plot_format, :group_by, "Color")
    
    # Build the appropriate group mapping based on group_by setting
    group_mapping = if group_by == "Geometry" && plottype != BarPlot
        # Use linestyle for Lines, marker for Scatter
        if plottype == Lines
            (; linestyle = group_col => legend_title)
        else  # Scatter
            (; marker = group_col => legend_title)
        end
    else
        # Default to color (also fallback for BarPlot with Geometry)
        (; color = group_col => legend_title)
    end
    
    plt = data(df) * mapping(x_col => final_x_name, y_col => final_y_name; group_mapping...) * visual(plottype)
    
    # Use custom title if provided, otherwise generate default
    title = if !isnothing(custom_title) && custom_title != ""
        custom_title
    else
        "$(var_to_string(plottype)) Plot of $final_y_name vs $final_x_name"
    end
    
    # Build axis kwargs with limits and reversal
    fg = draw(plt;
        figure=(; size=(800, 600)), 
        legend=(show=show_legend, ),
        axis=(; title, limits=(x_min, x_max, y_min, y_max), xreversed, yreversed),
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