"""
    is_extension_available(x::Symbol) --> Bool

Check if the CSV of XLSX extension is loaded.
"""
function is_extension_available(s::Symbol)
    s == :CSV && return (length(methods(read_csv)) > 0)
    s == :XLSX && return (length(methods(readtable_xlsx)) > 0)
    throw("Unknown extension $x")
end

"""
    build_file_filter()

Build filterlist string for file dialog based on available extensions.
Returns comma-separated extensions (e.g., "csv,tsv,xlsx" or "csv,tsv" or "xlsx").
"""
function build_file_filter()
    filters = String[]
    if is_extension_available(:CSV)
        push!(filters, "csv", "tsv")
    end
    if is_extension_available(:XLSX)
        push!(filters, "xlsx")
    end
    return join(filters, ",")
end

"""
    normalize_strings!(df)

Normalize string columns for compatibility with Bonito.Table display.

Converts:
- AbstractString (e.g., InlineString from CSV.jl) → String
- Any columns: replaces InlineString values with String equivalents

Modifies the DataFrame in-place and returns it.
"""
function normalize_strings!(df)
    for col in names(df)
        col_eltype = eltype(df[!, col])
        base_type = nonmissingtype(col_eltype)
        
        if base_type <: AbstractString
            # Convert to String (handles InlineString from CSV.jl)
            df[!, col] = [ismissing(v) ? missing : String(v) for v in df[!, col]]
            
        elseif base_type === Any
            # Check for InlineStrings in Any columns and convert to String
            df[!, col] = [
                ismissing(v) ? missing : 
                (v isa AbstractString ? String(v) : v) 
                for v in df[!, col]
            ]
        end
    end
    return df
end

"""
    normalize_numeric_columns!(df, cols)

Normalize numeric columns for plotting compatibility.

For each specified column:
- AbstractString and Dates.AbstractTime → unchanged
- Concrete numeric types (Float64, Int, etc.) and Bool → unchanged
- Abstract Integer subtypes → Int (preserving missing)
- Abstract Real subtypes → Float64 (preserving missing)
- Any/unknown types:
  - If >90% of non-missing values are numeric → Float64 (non-numeric become missing)
  - Otherwise → unchanged

# Arguments
- `df`: DataFrame to normalize
- `cols`: Vector of column names to normalize

# Returns
`(df, dirty_cols)` - the modified DataFrame and a vector of column names where 
non-numeric values were converted to missing.
"""
function normalize_numeric_columns!(df, cols)
    dirty_cols = String[]
    
    for col in cols
        col ∉ names(df) && continue
        
        col_eltype = eltype(df[!, col])
        base_type = nonmissingtype(col_eltype)
        has_missing = col_eltype !== base_type
        
        if base_type <: AbstractString || base_type <: Dates.AbstractTime
            # Leave as is
            continue
        
        elseif base_type <: Real && isconcretetype(base_type)
            continue
            
        elseif base_type <: Integer 
            # Convert Integer subtypes to Int
            if has_missing
                df[!, col] = [ismissing(v) ? missing : Int(v) for v in df[!, col]]
            else
                df[!, col] = Int.(df[!, col])
            end
            
        elseif base_type <: Real
            # Convert Real subtypes to Float64
            if has_missing
                df[!, col] = [ismissing(v) ? missing : Float64(v) for v in df[!, col]]
            else
                df[!, col] = Float64.(df[!, col])
            end
            
        else
            # Any or unknown type - analyze content
            values = df[!, col]
            non_missing = filter(!ismissing, values)
            
            if isempty(non_missing)
                # All missing - leave as is
                continue
            end
            
            # Count numeric values
            n_numeric = count(v -> v isa Number, non_missing)
            numeric_ratio = n_numeric / length(non_missing)
            
            if numeric_ratio > 0.9
                # >90% numeric: convert to Float64, others become missing
                original_missing_count = count(ismissing, values)
                new_values = [ismissing(v) ? missing : (v isa Number ? Float64(v) : missing) for v in values]
                new_missing_count = count(ismissing, new_values)
                
                df[!, col] = new_values
                
                # Track if we converted non-numeric to missing
                if new_missing_count > original_missing_count
                    push!(dirty_cols, col)
                end
            end
            # If not mostly numeric, leave as is (will likely cause plot error, but user should fix data)
        end
    end
    return (df, dirty_cols)
end

"""
    handle_open_file_click(table_observable, state, current_xlsx_path, sheet_names, selected_sheet)

Handle the logic when the "Open File" button is clicked.
Opens a file dialog, handles CSV loading immediately, or sets up XLSX sheet selection.
"""
function handle_open_file_click(table_observable, state, current_xlsx_path, sheet_names, selected_sheet)
    # Check if any extension is available
    csv_ok = is_extension_available(:CSV)
    xlsx_ok = is_extension_available(:XLSX)
    
    if !csv_ok && !xlsx_ok
        @warn "No file extensions available"
        return
    end
    
    # Build filter based on available extensions
    filterlist = build_file_filter()

    # Open file dialog
    filepath = FileDialogWorkAround.pick_file(; filterlist)
    
    if isempty(filepath)
        return  # User cancelled
    end
    
    ext = lowercase(splitext(filepath)[2])
    
    if ext in [".csv", ".tsv"]
        # CSV: Load immediately
        current_xlsx_path[] = ""
        sheet_names[] = String[]
        selected_sheet[] = ""
        load_csv_to_table(filepath, table_observable, state)
    elseif ext == ".xlsx"
        # XLSX: Populate sheet dropdown, wait for selection
        current_xlsx_path[] = filepath
        try
            sheets = sheetnames_xlsx(filepath)
            sheet_names[] = sheets
            selected_sheet[] = ""  # Reset selection
        catch e
            @warn "Error reading XLSX sheets: $e"
            current_xlsx_path[] = ""
            sheet_names[] = String[]
        end
    end
end
"""
    store_and_display_dataframe!(df, filepath, table_observable, state; info_suffix="") --> Nothing

Common helper for processing a loaded DataFrame: normalize strings, store in state, 
and update the table display.

# Arguments
- `df`: The DataFrame to process
- `filepath`: Path to the file to load
- `table_observable::Observable`: Table display observable
- `state::Union{Nothing, NamedTuple}`: Application state (optional, for storing opened file DataFrame)
- `info_suffix`: Optional suffix to append to info text (e.g., ":SheetName" for XLSX)
"""
function store_and_display_dataframe!(df, filepath, table_observable, state; info_suffix="")
    # Normalize string columns for display compatibility
    normalize_strings!(df)
    
    # Store DataFrame in state if provided
    if !isnothing(state)
        # Reset selected_dataframe BEFORE setting opened_file_df
        # This ensures the dropdown rebuild (triggered by opened_file_df change)
        # sees selected_dataframe as nothing and shows placeholder, not "opened file"
        state.data_selection.selected_dataframe[] = nothing
        state.file_opening.opened_file_df[] = df
        # Extract filename without path or extension
        state.file_opening.opened_file_name[] = splitext(basename(filepath))[1]
    end
    
    # Build source info text with normalized absolute path (+ optional suffix)
    info_text = (abspath(filepath) |> normpath) * info_suffix
    
    # Update table display with info line
    table_observable[] = create_table_with_info(Bonito.Table(df), info_text)
    return nothing
end

"""
    load_xlsx_sheet_to_table(filepath, sheet, table_observable, state) --> Nothing

Load a specific sheet from an XLSX file and display it in the table pane.
Also stores the DataFrame in state for use in DataFrame mode.

# Arguments
- `filepath`: Path to the file to load
- `sheet::AbstractString`: excel sheet
- `table_observable::Observable`: Table display observable
- `state::Union{Nothing, NamedTuple}`: Application state (optional, for storing opened file DataFrame)
"""
function load_xlsx_sheet_to_table(filepath, sheet, table_observable, state=nothing)
    try
        df = readtable_xlsx(filepath, sheet)
        store_and_display_dataframe!(df, filepath, table_observable, state; info_suffix=":" * string(sheet))
    catch e
        @warn "Error loading XLSX sheet: $e"
        table_observable[] = DOM.div("Error loading sheet: $sheet")
    end
end

"""
    load_csv_to_table(filepath, table_observable, state) --> Nothing

Load a CSV/TSV file and display it in the table pane.
Also stores the DataFrame in state for use in DataFrame mode.
"""
function load_csv_to_table(filepath, table_observable, state=nothing)
    if !is_extension_available(:CSV)
        @warn "CSV extension not available"
        return nothing
    end
    
    try
        df = read_csv(filepath)
        store_and_display_dataframe!(df, filepath, table_observable, state)
    catch e
        @warn "Error loading file: $e"
        table_observable[] = DOM.div("Error loading file: $(basename(filepath))")
    end
    return nothing
end
