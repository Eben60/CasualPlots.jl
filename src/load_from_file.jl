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
    handle_open_file_click(outputs, state, current_xlsx_path, sheet_names, selected_sheet)

Handle the logic when the "Open File" button is clicked.
Opens a file dialog, handles CSV loading immediately, or sets up XLSX sheet selection.
"""
function handle_open_file_click(outputs, state, current_xlsx_path, sheet_names, selected_sheet)
    # Check if any extension is available
    csv_ok = is_extension_available(:CSV)
    xlsx_ok = is_extension_available(:XLSX)
    
    if !csv_ok && !xlsx_ok
        msg = "No file extensions available"
        show_modal!(state, msg; type=:warning)
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
        load_csv_to_table(filepath, outputs, state)
    elseif ext == ".xlsx"
        # XLSX: Populate sheet dropdown and load first sheet by default
        current_xlsx_path[] = filepath
        try
            sheets = sheetnames_xlsx(filepath)
            selected_sheet[] = ""
            sheet_names[] = sheets
            selected_sheet[] = first(sheets)
        catch e
            msg = "Error reading XLSX sheets: $e"
            show_modal!(state, msg)
            current_xlsx_path[] = ""
            sheet_names[] = String[]
            selected_sheet[] = ""
        end
    end
end
"""
    store_and_display_dataframe!(df, filepath, outputs, state; info_suffix::AbstractString="") -> Nothing

Common helper for processing a loaded DataFrame: normalize strings, store in state, 
and update the table display.
"""
function store_and_display_dataframe!(df, filepath, outputs, state; info_suffix="")
    # Normalize string columns for display compatibility
    normalize_strings!(df)
    
    # Reset selected_dataframe BEFORE setting opened_file_df
    # This ensures the dropdown rebuild (triggered by opened_file_df change)
    # sees selected_dataframe as nothing and shows placeholder, not "opened file"
    state.data_selection.selected_dataframe[] = nothing
    state.file_opening.opened_file_df[] = df
    # Extract filename without path or extension
    state.file_opening.opened_file_name[] = splitext(basename(filepath))[1]
    # Store the full path for reload functionality
    state.file_opening.opened_file_path[] = abspath(filepath) |> normpath

    
    # Build source info text with normalized absolute path (+ optional suffix)
    info_text = (abspath(filepath) |> normpath) * info_suffix
    
    # Update table title
    outputs.table_title[] = "SOURCE: " * info_text
    
    # Update table display
    outputs.table[] = create_table_with_info(Bonito.Table(df; row_renderer=cp_render_value))
    return nothing
end

"""
    load_xlsx_sheet_to_table(filepath::AbstractString, sheet::AbstractString, outputs::OutputObservables, state::CasualPlotsState) -> Nothing

Load a specific sheet from an XLSX file and display it in the table pane.
Also stores the DataFrame in state for use in DataFrame mode.
"""
function load_xlsx_sheet_to_table(filepath::AbstractString, sheet::AbstractString, outputs, state)
    (; kwargs, skip_subheaders, skip_empty_rows) = collect_xlsx_options(state)
    try
        df = readtable_xlsx(filepath, sheet; infer_eltypes=true, kwargs...)
        skip_rows!(df, skip_subheaders, skip_empty_rows)
        # Store sheet name for code generation
        state.file_opening.sheet_name[] = string(sheet)
        store_and_display_dataframe!(df, filepath, outputs, state; info_suffix=":" * string(sheet))
    catch e
        msg = "Error loading XLSX sheet: $e"
        show_modal!(state, msg)
        outputs.table[] = DOM.div("Error loading sheet: $sheet")
    end
end

"""
    load_csv_to_table(filepath::AbstractString, outputs::OutputObservables, state::CasualPlotsState) -> Nothing

Load a CSV/TSV file and display it in the table pane.
Also stores the DataFrame in state for use in DataFrame mode.
"""
function load_csv_to_table(filepath::AbstractString, outputs, state)
    if !is_extension_available(:CSV)
        msg = "CSV extension not available"
        show_modal!(state, msg; type=:warning)
        return nothing
    end

    kwargs = collect_csv_options(state)

    try
        df = read_csv(filepath; kwargs...)
        skip_rows!(df, 0, kwargs.ignoreemptyrows)
        # Clear sheet name (not an XLSX source)
        state.file_opening.sheet_name[] = ""
        store_and_display_dataframe!(df, filepath, outputs, state)
    catch e
        msg = "Error loading CSV file: $e"
        show_modal!(state, msg)
        outputs.table[] = DOM.div("Error loading file: $(basename(filepath))")
    end
    return nothing
end
