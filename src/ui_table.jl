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
    create_data_table(x, y)

Create a formatted data table displaying X and Y data.

# Arguments
- `x::String`: Name of X variable in Main module
- `y::String`: Name of Y variable in Main module

# Returns
DOM.div containing a Bonito.Table with the data
"""
function create_data_table(x::AbstractString, y::AbstractString)
    x_data = getfield(Main, Symbol(x))
    y_data = getfield(Main, Symbol(y))
    if y_data isa AbstractVector
        y_data = reshape(y_data, :, 1)
    end
    
    num_rows = size(x_data, 1)
    num_y_cols = size(y_data, 2)
    
    df = DataFrame()
    df.Row = 1:num_rows
    df[!, x] = x_data
    
    for i in 1:num_y_cols
        col_name = num_y_cols > 1 ? "$(y)_$i" : y
        df[!, col_name] = y_data[:, i]
    end
    
    # Build source info text: "x_name vs y_name"
    info_text = "$x vs $y"
    
    return create_table_with_info(Bonito.Table(df), info_text)
end
