map_delimiter(x) = mp(
    x, 
    ["Auto", "Comma", "Tab", "Space", "Semicolon", "Pipe"],
    [nothing, ',', '\t', ' ', ';', '|'],
    )

map_decimal_separator(x) = mp(
    x, 
    ["Dot", "Comma", "Dot / Comma", "Comma / Dot"] ,
    ['.', ',' ,'.', ','],
    )

map_thousand_separator(x) = mp(
    x, 
    ["Dot", "Comma", "Dot / Comma", "Comma / Dot"] ,
    [nothing, nothing, ',' ,'.'],
    )

function mp(x, options, vals)
    m = Dict(zip(options, vals))
    return m[x]
end   

"""
    process_options(state) -> NamedTuple

Extracts and processes raw observables from `state.file_opening` into a NamedTuple of values
ready for internal logic (converting strings to chars, handling boolean flags).
"""
function process_options(state)
    (;  header_row, 
        skip_after_header, 
        skip_empty_rows, 
        delimiter, 
        decimal_separator,
    ) = state.file_opening

    header_row_val = header_row[] == 0 ? false : header_row[]
    decimal_separator_val = map_decimal_separator(decimal_separator[])
    delimiter_val = map_delimiter(delimiter[])
    groupmark = map_thousand_separator(decimal_separator[])
    return (;  
        header_row = header_row_val, 
        skip_after_header = skip_after_header[], 
        skip_empty_rows = skip_empty_rows[], 
        delimiter = delimiter_val, 
        decimal_separator = decimal_separator_val,
        groupmark,
    )
end

"""
    collect_csv_options(state) -> NamedTuple

Generates keyword arguments for `CSV.read` based on the current application state.
Determines headers, skipto, delimiters, and decimal separators.
"""
function collect_csv_options(state)
    (;  
        header_row, 
        skip_after_header, 
        skip_empty_rows, 
        delimiter, 
        decimal_separator,
        groupmark,
    ) = process_options(state)

        skipto = skip_after_header + 1 + header_row

        kwargs = (; 
            header = header_row, 
            ignoreemptyrows = skip_empty_rows, 
            decimal = decimal_separator,
            skipto,
            )

        isnothing(delimiter) || (kwargs = merge(kwargs, (; delim = delimiter)))
        isnothing(groupmark) || (kwargs = merge(kwargs, (; groupmark)))
        return kwargs
end

"""
    collect_xlsx_options(state) -> NamedTuple

Generates arguments and processing options for `XLSX.readtable`.
Returns `(; kwargs, skip_subheaders, skip_empty_rows)` where `kwargs` are passed to `readtable`.
"""
function collect_xlsx_options(state)
    (;  
        header_row, 
        skip_after_header, 
        skip_empty_rows, 
    ) = process_options(state)

    header = header_row > 0

    if header
        first_row = header_row
        skip_subheaders = skip_after_header
    else
        first_row = skip_after_header + 1
        skip_subheaders = 0
    end

    kwargs = (; header, first_row, keep_empty_rows = !skip_empty_rows)
    return (; kwargs, skip_subheaders, skip_empty_rows)
end