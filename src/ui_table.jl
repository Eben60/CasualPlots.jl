"""
    create_table_with_info(table_content, info_text)

Wrap table content with a source info line displayed above it.

# Arguments
- `table_content`: The table DOM element (e.g., Bonito.Table(df))
- `info_text`: Text describing the data source (filepath, DataFrame name, or "x vs y")

# Returns
DOM.div with vertically divided pane: info line on top, table below
"""
function create_table_with_info(table_content, info_text)
    # Info line with light blue background, 10px font
    info_line = DOM.div(
        info_text;
        class="info-line"
    )
    
    # Container: vertical layout with info on top, table below
    DOM.div(
        info_line,
        DOM.div(table_content; class="table-scroll-wrapper");
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
function create_data_table(x, y; range_from=nothing, range_to=nothing)
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
        info_text = "$x vs $y"
    else
        info_text = "$x vs $y [$(from_idx):$(to_idx)]"
    end
    
    return create_table_with_info(Bonito.Table(df), info_text)
end
