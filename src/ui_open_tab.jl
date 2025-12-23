"""
    create_extension_status_row(available, available_text, unavailable_text)

Create a DOM row showing extensions (CSV, XLSX) status with green tick or red cross icon.
"""
function create_extension_status_row(available, available_text, unavailable_text)
    icon = available ? "✓" : "✗"
    icon_color = available ? "#28A745" : "#DC3545"
    text = available ? available_text : unavailable_text
    
    # We keep color inline because it's data-dependent and specific
    # But we use classes for font/margin
    DOM.div(
        DOM.span(icon; class="extension-icon", style=Styles("color" => icon_color)),
        DOM.span(text; class=available ? "extension-text" : "extension-text-disabled");
        class="status-row"
    )
end

"""
    create_open_file_button(trigger, enabled)

Create the "Open File" button.
"""
function create_open_file_button(trigger, enabled)
    DOM.button(
        "Open File";
        disabled=!enabled,
        onclick=js"() => { window.CasualPlots.incrementObservable($(trigger)); }",
        class=enabled ? "btn btn-primary" : "btn btn-disabled"
    )
end

"""
    create_sheet_selector(sheet_names, selected_sheet)

Create the reactive dropdown for selecting XLSX sheets.
"""
function create_sheet_selector(sheet_names, selected_sheet)
    map(sheet_names) do sheets
        if isempty(sheets)
            # No XLSX file selected - show disabled placeholder
            DOM.select(
                DOM.option("Select sheet"; value="", selected=true);
                disabled=true,
                class="select-standard"
            )
        else
            # XLSX file selected - show sheet options
            options = [DOM.option("Select sheet"; value="", selected=true, disabled=true)]
            for sheet in sheets
                push!(options, DOM.option(sheet; value=sheet))
            end
            DOM.select(
                options...;
                onchange=js"(e) => { window.CasualPlots.updateObservableValue(e, $(selected_sheet)); }",
                class="select-standard"
            )
        end
    end
end

"""
    create_extensions_status_panel(csv_available, xlsx_available)

Create the panel showing status of CSV and XLSX extensions.
"""
function create_extensions_status_panel(csv_available, xlsx_available)
    csv_row = create_extension_status_row(
        csv_available,
        "CSV extension available",
        "Import CSV to be able to read CSV files",
    )
    
    xlsx_row = create_extension_status_row(
        xlsx_available,
        "XLSX extension available",
        "Import XLSX to be able to read excel files",
    )
    
    DOM.div(
        csv_row,
        xlsx_row;
        class="flex-col"
    )
end

"""
    create_reload_button(reload_trigger, enabled)

Create the "Reload" button for re-reading the currently loaded file/sheet.
"""
function create_reload_button(reload_trigger, enabled)
    map(enabled) do is_enabled
        DOM.button(
            "Reload";
            disabled=!is_enabled,
            onclick=is_enabled ? js"() => { window.CasualPlots.incrementObservable($(reload_trigger)); }" : js"() => {}",
            class=is_enabled ? "btn btn-primary" : "btn btn-disabled"
        )
    end
end

"""
    create_header_input(header_row)

Create the input field for specifying the header row number.
Returns a tuple of (control, label, info) for grid placement.
"""
function create_header_input(header_row)
    control = DOM.input(
        type="text",
        value=string(header_row[]),
        onchange=js"(e) => { window.CasualPlots.updateObservableInteger(e, $(header_row)); }",
        onblur=js"(e) => { window.CasualPlots.updateObservableInteger(e, $(header_row)); }",
        class="input-number option-control"
    )
    label = DOM.span("Header"; class="option-label")
    info = DOM.span("Type 0 if no headers"; class="option-info")
    return (control, label, info)
end

"""
    create_skip_after_header_input(skip_after_header)

Create the input field for specifying rows to skip after header, if any, of from table top otherwise.
Returns a tuple of (control, label, info) for grid placement.
"""
function create_skip_after_header_input(skip_after_header)
    control = DOM.input(
        type="text",
        value=string(skip_after_header[]),
        onchange=js"(e) => { window.CasualPlots.updateObservableInteger(e, $(skip_after_header)); }",
        onblur=js"(e) => { window.CasualPlots.updateObservableInteger(e, $(skip_after_header)); }",
        class="input-number option-control"
    )
    label = DOM.span("Skip subheaders"; class="option-label")
    info = DOM.span(""; class="option-info")  # Empty placeholder for grid alignment
    return (control, label, info)
end

"""
    create_skip_empty_rows_checkbox(skip_empty_rows)

Create the checkbox for skip empty rows option.
Returns a tuple of (control, label, info) for grid placement.
"""
function create_skip_empty_rows_checkbox(skip_empty_rows)
    control = DOM.input(
        type="checkbox",
        checked=skip_empty_rows[],
        onchange=js"(e) => { window.CasualPlots.updateObservableChecked(e, $(skip_empty_rows)); }",
        class="checkbox-option option-control"
    )
    label = DOM.span("Skip empty rows"; class="option-label")
    info = DOM.span(""; class="option-info")  # Empty placeholder for grid alignment
    return (control, label, info)
end

"""
    create_delimiter_dropdown(delimiter)

Create the dropdown for selecting CSV delimiter.
Returns a tuple of (control, label, info) for grid placement.
"""
function create_delimiter_dropdown(delimiter)
    options = ["Auto", "Comma", "Tab", "Space", "Semicolon", "Pipe"]
    current = delimiter[]
    
    control = DOM.select(
        [DOM.option(opt; value=opt, selected=(opt == current)) for opt in options]...;
        onchange=js"(e) => { window.CasualPlots.updateObservableValue(e, $(delimiter)); }",
        class="select-option option-control"
    )
    label = DOM.span("Delimiter"; class="option-label")
    info = DOM.span("In effect for CSV only"; class="option-info")
    return (control, label, info)
end

"""
    create_decimal_separator_dropdown(decimal_separator)

Create the dropdown for selecting decimal/thousands separator.
Returns a tuple of (control, label, info) for grid placement.
"""
function create_decimal_separator_dropdown(decimal_separator)
    options = ["Dot", "Comma", "Dot / Comma", "Comma / Dot"]
    current = decimal_separator[]
    
    control = DOM.select(
        [DOM.option(opt; value=opt, selected=(opt == current)) for opt in options]...;
        onchange=js"(e) => { window.CasualPlots.updateObservableValue(e, $(decimal_separator)); }",
        class="select-option option-control"
    )
    label = DOM.span("Decimal / Thousands Separator"; class="option-label")
    info = DOM.span("In effect for CSV only"; class="option-info")
    return (control, label, info)
end

"""
    create_options_section(state)

Create the complete options section for file reading configuration.
Uses CSS Grid layout with 3 columns: control, label, info.
"""
function create_options_section(state)
    (; header_row, skip_after_header, skip_empty_rows, delimiter, decimal_separator) = state.file_opening
    
    # Get tuples of (control, label, info) for each option
    header = create_header_input(header_row)
    skip_header = create_skip_after_header_input(skip_after_header)
    skip_empty = create_skip_empty_rows_checkbox(skip_empty_rows)
    delim = create_delimiter_dropdown(delimiter)
    decimal = create_decimal_separator_dropdown(decimal_separator)
    
    # Build grid: header row has empty cell, "Options" text, empty cell
    # Then each option row has 3 cells: control, label, info
    DOM.div(
        # Header row: empty | "Options" | empty
        DOM.div(; class="options-empty"),
        DOM.div("Options"; class="options-header"),
        DOM.div(; class="options-empty"),
        # Row 1: Header input
        header[1], header[2], header[3],
        # Row 2: Skip after header
        skip_header[1], skip_header[2], skip_header[3],
        # Row 3: Skip empty rows
        skip_empty[1], skip_empty[2], skip_empty[3],
        # Row 4: Delimiter
        delim[1], delim[2], delim[3],
        # Row 5: Decimal separator
        decimal[1], decimal[2], decimal[3];
        class="options-grid"
    )
end

"""
    render_open_tab_view(open_file_trigger, reload_trigger, reload_enabled, sheet_names, selected_sheet, state)

Render the complete view for the Open tab, checking extension status and assembling components.
"""
function render_open_tab_view(open_file_trigger, reload_trigger, reload_enabled, sheet_names, selected_sheet, state)
    # Check extension availability
    csv_available = is_extension_available(:CSV)
    xlsx_available = is_extension_available(:XLSX)
    button_enabled = csv_available || xlsx_available
    
    # Create valid UI elements
    open_button = create_open_file_button(open_file_trigger, button_enabled)
    extension_status = create_extensions_status_panel(csv_available, xlsx_available)
    sheet_dropdown = create_sheet_selector(sheet_names, selected_sheet)
    reload_button = create_reload_button(reload_trigger, reload_enabled)
    options_section = create_options_section(state)
    
    # Layout Assembly
    top_section = DOM.div(
        open_button,
        extension_status;
        class="flex-row align-start gap-3"
    )
    
    # Sheet selector row with reload button
    sheet_row = DOM.div(
        sheet_dropdown,
        reload_button;
        class="flex-row align-center gap-2 mt-2"
    )
    
    DOM.div(
        top_section,
        sheet_row,
        options_section;
        class="flex-col p-1",
        style=Styles("height" => "100%") # Keep height:100% just in case
    )
end

"""
    create_open_tab_content(refresh_trigger, table_observable, state)

Create reactive content for the Open tab.
"""
function create_open_tab_content(refresh_trigger, table_observable, state)
    (; opened_file_name) = state.file_opening
    
    # Create trigger for Open File button clicks
    open_file_trigger = Observable(0)
    
    # Create trigger for Reload button clicks
    reload_trigger = Observable(0)
    
    # Observables for XLSX sheet selection
    current_xlsx_path = Observable("")
    sheet_names = Observable(String[])
    selected_sheet = Observable("")
    
    # Reload button enabled state: true when file is loaded (CSV) or sheet is selected (XLSX)
    reload_enabled = map(opened_file_name, selected_sheet) do file_name, sheet
        !isempty(file_name) || !isempty(sheet)
    end
    
    # Setup callbacks
    on(open_file_trigger) do _
        handle_open_file_click(table_observable, state, current_xlsx_path, sheet_names, selected_sheet)
    end
    
    on(selected_sheet) do sheet
        xlsx_path = current_xlsx_path[]
        if !isempty(sheet) && !isempty(xlsx_path)
            load_xlsx_sheet_to_table(xlsx_path, sheet, table_observable, state)
        end
    end
    
    # Callback for reload button - reloads the currently loaded file/sheet with current options
    on(reload_trigger) do _
        filepath = state.file_opening.opened_file_path[]
        if isempty(filepath)
            @warn "No file loaded to reload"
            return
        end
        
        ext = lowercase(splitext(filepath)[2])
        
        if ext in [".csv", ".tsv"]
            # Reload CSV/TSV file
            load_csv_to_table(filepath, table_observable, state)
            @info "Reloaded CSV file: $(basename(filepath))"
        elseif ext == ".xlsx"
            # Reload XLSX sheet (use currently selected sheet)
            sheet = selected_sheet[]
            if !isempty(sheet)
                load_xlsx_sheet_to_table(filepath, sheet, table_observable, state)
                @info "Reloaded XLSX sheet: $(basename(filepath)):$sheet"
            else
                @warn "No sheet selected for XLSX reload"
            end
        else
            @warn "Unknown file type for reload: $ext"
        end
    end
    
    # Render view on refresh
    return map(refresh_trigger) do _
        render_open_tab_view(open_file_trigger, reload_trigger, reload_enabled, sheet_names, selected_sheet, state)
    end
end
