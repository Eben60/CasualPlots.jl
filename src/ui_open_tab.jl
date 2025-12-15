"""
    create_extension_status_row(available, available_text, unavailable_text)

Create a DOM row showing extensions (CSV, XLSX) status with green tick or red cross icon.
"""
function create_extension_status_row(available, available_text, unavailable_text)
    icon = available ? "✓" : "✗"
    icon_color = available ? "#28A745" : "#DC3545"
    text = available ? available_text : unavailable_text
    text_color = available ? "#333" : "#666"
    
    DOM.div(
        DOM.span(icon; style=Styles(
            "color" => icon_color,
            "font-size" => "10px",
            "font-weight" => "bold",
            "margin-right" => "6px",
        )),
        DOM.span(text; style=Styles(
            "color" => text_color,
            "font-size" => "10px",
        ));
        style=Styles(
            "display" => "flex",
            "align-items" => "center",
            "margin-bottom" => "3px",
        )
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
        onclick=js"() => { $(trigger).notify($(trigger).value + 1); }",
        style=Styles(
            "padding" => "8px 16px",
            "background-color" => enabled ? "#2196F3" : "#cccccc",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px",
            "cursor" => enabled ? "pointer" : "not-allowed",
            "font-size" => "12px",
            "white-space" => "nowrap",
        )
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
                style=Styles(
                    "padding" => "6px 12px",
                    "font-size" => "12px",
                    "border-radius" => "4px",
                    "border" => "1px solid #ccc",
                    "background-color" => "#f5f5f5",
                    "color" => "#999",
                    "cursor" => "not-allowed",
                )
            )
        else
            # XLSX file selected - show sheet options
            options = [DOM.option("Select sheet"; value="", selected=true, disabled=true)]
            for sheet in sheets
                push!(options, DOM.option(sheet; value=sheet))
            end
            DOM.select(
                options...;
                onchange=js"(e) => { $(selected_sheet).notify(e.target.value); }",
                style=Styles(
                    "padding" => "6px 12px",
                    "font-size" => "12px",
                    "border-radius" => "4px",
                    "border" => "1px solid #2196F3",
                    "background-color" => "white",
                    "cursor" => "pointer",
                )
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
        "Import XLSX to be able to read Excel files",
    )
    
    DOM.div(
        csv_row,
        xlsx_row;
        style=Styles(
            "display" => "flex",
            "flex-direction" => "column",
        )
    )
end

"""
    render_open_tab_view(open_file_trigger, sheet_names, selected_sheet)

Render the complete view for the Open tab, checking extension status and assembling components.
"""
function render_open_tab_view(open_file_trigger, sheet_names, selected_sheet)
    # Check extension availability
    csv_available = is_extension_available(:CSV)
    xlsx_available = is_extension_available(:XLSX)
    button_enabled = csv_available || xlsx_available
    
    # Create valid UI elements
    open_button = create_open_file_button(open_file_trigger, button_enabled)
    extension_status = create_extensions_status_panel(csv_available, xlsx_available)
    sheet_dropdown = create_sheet_selector(sheet_names, selected_sheet)
    
    # Layout Assembly
    top_section = DOM.div(
        open_button,
        extension_status;
        style=Styles(
            "display" => "flex",
            "flex-direction" => "row",
            "align-items" => "flex-start",
            "gap" => "15px",
        )
    )
    
    bottom_section = DOM.div(
        sheet_dropdown;
        style=Styles(
            "margin-top" => "10px",
        )
    )
    
    DOM.div(
        top_section,
        bottom_section;
        style=Styles(
            "display" => "flex",
            "flex-direction" => "column",
            "padding" => "5px",
            "height" => "100%",
        )
    )
end

"""
    create_open_tab_content(refresh_trigger, table_observable, state)

Create reactive content for the Open tab.
"""
function create_open_tab_content(refresh_trigger, table_observable, state)
    # Create trigger for Open File button clicks
    open_file_trigger = Observable(0)
    
    # Observables for XLSX sheet selection
    current_xlsx_path = Observable("")
    sheet_names = Observable(String[])
    selected_sheet = Observable("")
    
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
    
    # Render view on refresh
    return map(refresh_trigger) do _
        render_open_tab_view(open_file_trigger, sheet_names, selected_sheet)
    end
end
