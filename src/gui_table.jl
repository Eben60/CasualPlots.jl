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
    create_data_table(x::AbstractString, y=nothing; range_from=nothing, range_to=nothing)

Creates a table representation of X and optional Y data with an Index column.

# Arguments
- `x::AbstractString`: Name of the X variable in Main
- `y`: Optional name of the Y variable in Main (if nothing, only X is included)
- `range_from::Union{Nothing,Int}`: Starting index for data range (uses firstindex if nothing)
- `range_to::Union{Nothing,Int}`: Ending index for data range (uses lastindex if nothing)

# Returns
NamedTuple `(; table, info_text)`
"""
function create_data_table(x::AbstractString, y=nothing; range_from=nothing, range_to=nothing)
    x_data = getfield(Main, Symbol(x))

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
    x_slice = from_idx <= to_idx ? x_data[from_idx:to_idx] : eltype(x_data)[]

    # Build DataFrame with actual X indices as the Index column
    df = DataFrame()
    df.Index = from_idx:to_idx
    df[!, x] = x_slice

    has_y = !isnothing(y) && !isempty(y) && isdefined(Main, Symbol(y))
    if has_y
        y_data = getfield(Main, Symbol(y))
        if y_data isa AbstractVector
            y_data = reshape(y_data, :, 1)
        end

        y_first = firstindex(y_data, 1)  # Y's first row index
        pos_from = from_idx - x_first + y_first
        pos_to = to_idx - x_first + y_first

        y_last_row = lastindex(y_data, 1)
        pos_from = clamp(pos_from, y_first, y_last_row)
        pos_to = clamp(pos_to, y_first, y_last_row)

        if y_data isa AbstractMatrix
            y_slice = from_idx <= to_idx ? y_data[pos_from:pos_to, :] : y_data[1:0, :]
        else
            y_slice = from_idx <= to_idx ? y_data[pos_from:pos_to] : y_data[1:0]
        end

        num_y_cols = size(y_slice, 2)
        for i in 1:num_y_cols
            col_name = num_y_cols > 1 ? "$(y)_$i" : y
            df[!, col_name] = y_slice[:, i]
        end
    end

    # Build source info text with range info
    base_info = has_y ? "$y vs $x" : x
    if from_idx == x_first && to_idx == x_last
        info_text = base_info
    else
        info_text = "$base_info [$(from_idx):$(to_idx)]"
    end

    return (;
        table = create_table_with_info(Bonito.Table(df; row_renderer=cp_render_value); has_generated_index=true),
        info_text = info_text,
    )
end

"""
    create_dataframe_table(df::AbstractDataFrame, cols::AbstractVector=String[]; range_from=nothing, range_to=nothing, display_name::AbstractString="")

Creates a table representation of a DataFrame or column subset with an Index column.

# Arguments
- `df::AbstractDataFrame`: Source DataFrame
- `cols`: Vector of column names to display (empty for Index-only)
- `range_from`: Starting row index (1-based)
- `range_to`: Ending row index (1-based)
- `display_name`: Display title for source

# Returns
NamedTuple `(; table, info_text)`
"""
function create_dataframe_table(
    df::AbstractDataFrame,
    cols::AbstractVector=String[];
    range_from=nothing,
    range_to=nothing,
    display_name::AbstractString="",
)
    n_rows = nrow(df)

    from_idx = isnothing(range_from) ? 1 : clamp(range_from, 1, max(1, n_rows))
    to_idx = isnothing(range_to) ? n_rows : clamp(range_to, 1, max(1, n_rows))

    if from_idx == 1 && to_idx == n_rows
        info_text = isempty(display_name) ? "DataFrame" : display_name
    else
        info_text = isempty(display_name) ? "DataFrame [$(from_idx):$(to_idx)]" : "$display_name [$(from_idx):$(to_idx)]"
    end

    available = names(df)
    valid_cols = filter(c -> c in available, cols)

    row_indices = from_idx <= to_idx && n_rows > 0 ? (from_idx:to_idx) : Int[]
    if isempty(valid_cols)
        df_with_index = DataFrame(; Index = row_indices)
    else
        df_sliced = from_idx <= to_idx && n_rows > 0 ? select(df, valid_cols)[from_idx:to_idx, :] : DataFrame([c => eltype(df[!, c])[] for c in valid_cols])
        df_with_index = df_sliced
        insertcols!(df_with_index, 1, :Index => row_indices)
    end

    return (;
        table = create_table_with_info(Bonito.Table(df_with_index; row_renderer=cp_render_value); has_generated_index=true),
        info_text = info_text,
    )
end

