"""
    create_table_with_info(table_content)

Wrap table content with proper container styles.

# Arguments
- `table_content`: The table DOM element (e.g., Bonito.Table(df))

# Returns
DOM.div with table container
"""
function cp_render_value(val)
    ismissing(val) && return "n/a"
    val isa Integer && return string(val)
    val isa Unitful.Quantity && return Printf.@sprintf("%.5g %s", ustrip(val), unit(val))
    val isa Real && return Printf.@sprintf("%.5g", Float64(val))
    return string(val)
end

function create_table_with_info(table_content; has_generated_index=false)
    # Generate dynamic header CSS based on column types
    df = table_content.table
    css_rules = String[]
    for (i, col) in enumerate(names(df))
        el_type = eltype(df[!, col])
        base_type = nonmissingtype(el_type)
        
        # Determine background color
        if has_generated_index && i == 1
            bg_color = "#f5f5f5" # Light Gray
        elseif base_type <: Real || base_type <: Bool
            bg_color = "#e8f5e9" # Light Green
        elseif base_type <: Unitful.Quantity
            bg_color = "#e3f2fd" # Light Blue
        else
            bg_color = "#fff9c4" # Light Yellow
        end
        
        # Note: nth-child is 1-based index
        push!(css_rules, ".table-pane-container .table-header:nth-child($i) { background-color: $bg_color !important; }")
    end
    
    dynamic_style = DOM.style(join(css_rules, "\n"))
    
    return DOM.div(
        dynamic_style,
        DOM.div(table_content; class="table-scroll-wrapper"),
        class="table-pane-container"
    )
end

"""
    create_data_table(x, y; range_from=nothing, range_to=nothing)

Create a formatted data table displaying X and Y data.

# Arguments
- `x::String`: Name of X variable in Main module
- `y::String`: Name of Y variable in Main module
- `range_from::Union{Nothing,Int}`: Starting index for data range (uses firstindex if nothing)
- `range_to::Union{Nothing,Int}`: Ending index for data range (uses lastindex if nothing)

# Returns
DOM.div containing a Bonito.Table with the data
"""
function create_data_table(x::AbstractString, y::AbstractString; range_from=nothing, range_to=nothing)
    x_data = getfield(Main, Symbol(x))
    y_data = getfield(Main, Symbol(y))
    if y_data isa AbstractVector
        y_data = reshape(y_data, :, 1)
    end
    
    # Get actual array bounds for X
    x_first = firstindex(x_data)
    x_last = lastindex(x_data)
    
    # Use provided range or default to full bounds (in X's index space)
    from_idx = isnothing(range_from) ? x_first : range_from
    to_idx = isnothing(range_to) ? x_last : range_to
    
    # Clamp to valid X range
    from_idx = clamp(from_idx, x_first, x_last)
    to_idx = clamp(to_idx, x_first, x_last)
    
    # Slice X data using X's indices
    x_slice = x_data[from_idx:to_idx]
    
    # Convert X indices to linear positions for Y
    # For example: if X has indices -50:50 and we want -50:50,
    # the linear positions for Y (1-based) are 1:101
    y_first = firstindex(y_data, 1)  # Y's first row index
    pos_from = from_idx - x_first + y_first
    pos_to = to_idx - x_first + y_first
    
    # Slice Y using linear positions
    if y_data isa AbstractMatrix
        y_slice = y_data[pos_from:pos_to, :]
    else
        y_slice = y_data[pos_from:pos_to]
    end
    
    num_y_cols = size(y_slice, 2)
    
    # Build DataFrame with actual X indices as the Index column
    df = DataFrame()
    df.Index = from_idx:to_idx
    df[!, x] = x_slice
    
    for i in 1:num_y_cols
        col_name = num_y_cols > 1 ? "$(y)_$i" : y
        df[!, col_name] = y_slice[:, i]
    end
    
    # Build source info text with range info
    if from_idx == x_first && to_idx == x_last
        info_text = "$y vs $x"
    else
        info_text = "$y vs $x [$(from_idx):$(to_idx)]"
    end
    
    return (; table = create_table_with_info(Bonito.Table(df; row_renderer=cp_render_value); has_generated_index=true), info_text = info_text)
end

