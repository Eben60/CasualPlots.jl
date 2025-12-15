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
    create_open_tab_content(refresh_trigger, table_observable, state)

Create reactive content for the Open tab with:
- Top section: Open File button (left) and extension status (right)
- Bottom section: Sheet selector dropdown for XLSX files

Content updates each time the refresh_trigger changes.
Button click opens file dialog. CSV files load immediately, XLSX files wait for sheet selection.
Loaded DataFrames are stored in state for use in DataFrame mode.

# Arguments
- `refresh_trigger`: Observable that triggers content refresh when changed
- `table_observable`: Observable for table display
- `state`: Application state for storing opened file DataFrame
"""
function create_open_tab_content(refresh_trigger, table_observable, state)
    # Create trigger for Open File button clicks
    open_file_trigger = Observable(0)
    
    # Observables for XLSX sheet selection
    current_xlsx_path = Observable("")  # Currently selected XLSX file path
    sheet_names = Observable(String[])  # Sheet names from current XLSX
    selected_sheet = Observable("")     # Currently selected sheet name
    
    # Setup callback for Open File button
    on(open_file_trigger) do _
        handle_open_file_click(table_observable, state, current_xlsx_path, sheet_names, selected_sheet)
    end
    
    # Callback for sheet selection
    on(selected_sheet) do sheet
        xlsx_path = current_xlsx_path[]
        if !isempty(sheet) && !isempty(xlsx_path)
            load_xlsx_sheet_to_table(xlsx_path, sheet, table_observable, state)
        end
    end
    
    # Use map to create reactive content that updates when trigger fires
    map(refresh_trigger) do _
        csv_available = is_extension_available(:CSV)
        xlsx_available = is_extension_available(:XLSX)
        button_enabled = csv_available || xlsx_available
        
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
        
        # Extension status section (right side of top row)
        extension_status = DOM.div(
            csv_row,
            xlsx_row;
            style=Styles(
                "display" => "flex",
                "flex-direction" => "column",
            )
        )
        
        # Open File button (left side of top row) - disabled if no extensions
        open_button = DOM.button(
            "Open File";
            disabled=!button_enabled,
            onclick=js"() => { $(open_file_trigger).notify($(open_file_trigger).value + 1); }",
            style=Styles(
                "padding" => "8px 16px",
                "background-color" => button_enabled ? "#2196F3" : "#cccccc",
                "color" => "white",
                "border" => "none",
                "border-radius" => "4px",
                "cursor" => button_enabled ? "pointer" : "not-allowed",
                "font-size" => "12px",
                "white-space" => "nowrap",
            )
        )
        
        # Top section: button on left, status on right
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
        
        # Sheet selector dropdown (reactive based on sheet_names)
        sheet_dropdown = map(sheet_names) do sheets
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
        
        # Bottom section: sheet selector
        bottom_section = DOM.div(
            sheet_dropdown;
            style=Styles(
                "margin-top" => "10px",
            )
        )
        
        # Main container: vertical layout
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
end
