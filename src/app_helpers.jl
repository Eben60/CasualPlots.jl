# Helper functions for casualplots_app()
# These functions break down the main app into allegedly logical, testable units
# Organized in top-down order as called from the main app

# ============================================================================
# 1. STATE INITIALIZATION
# ============================================================================

"""
    initialize_app_state()

Initialize all Observable state variables for the application.

Returns a NamedTuple with:
- `dims_dict_obs`: Observable tracking available arrays
- `trigger_update`: Observable for triggering data refresh
- `selected_x`, `selected_y`: Observables for selected variables
- `selected_plottype`: Observable for plot type
- `show_legend`: Observable for legend visibility
- `last_update`: Ref for tracking last data refresh time
"""
function initialize_app_state()
    last_update = Ref(time())
    dims_dict_obs = Observable(get_dims_of_arrays())
    trigger_update = Observable(true)
    
    # Setup auto-refresh callback
    on(trigger_update) do val
        current_time = time()
        if current_time - last_update[] > 30
            dims_dict_obs[] = get_dims_of_arrays()
            dataframes_dict_obs[] = collect_dataframes_from_main()
            last_update[] = current_time
        end
    end
    
    # Array source observables
    selected_x = Observable{Union{Nothing, String}}(nothing)
    selected_y = Observable{Union{Nothing, String}}(nothing)
    selected_plottype = Observable("Scatter")
    show_legend = Observable(true)
    
    # DataFrame source observables
    source_type = Observable("X, Y Arrays")  # Default to array mode
    dataframes_dict_obs = Observable(collect_dataframes_from_main())
    selected_dataframe = Observable{Union{Nothing, String}}(nothing)
    selected_columns = Observable{Vector{String}}(String[])
    
    # Text field observables for plot labels
    xlabel_text = Observable("")
    ylabel_text = Observable("")
    title_text = Observable("")
    legend_title_text = Observable("")
    
    # Store figure and axis for direct label manipulation
    current_figure = Observable{Union{Nothing, Figure}}(nothing)
    current_axis = Observable{Union{Nothing, Axis}}(nothing)
    
    plot_format = (; selected_plottype, show_legend)
    plot_handles = (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis)
    
    block_format_update = Observable(false)

    # Save functionality observables
    save_file_path = Observable("")  # Persists across plots
    save_status_message = Observable("")
    save_status_type = Observable(:none)  # :none, :success, :warning, :error
    show_overwrite_confirm = Observable(false)
    
    # Modal dialog observables
    show_modal = Observable(false)  # Controls modal visibility
    modal_type = Observable(:none)  # :success, :error, :warning, :confirm

    return (; dims_dict_obs, trigger_update, selected_x, selected_y, last_update,
              plot_format, plot_handles, block_format_update,
              source_type, dataframes_dict_obs, selected_dataframe, selected_columns,
              save_file_path, save_status_message, save_status_type, show_overwrite_confirm,
              show_modal, modal_type)
end

# ============================================================================
# 2. DROPDOWN SETUP
# ============================================================================

# include("dropdowns_setup.jl")

# ============================================================================
# 3. OUTPUT OBSERVABLES
# ============================================================================

"""
    initialize_output_observables()

Create observables for plot and table output display.

Returns a NamedTuple with:
- `plot`: Observable for plot display
- `table`: Observable for table display
- `current_x`, `current_y`: Observables tracking currently plotted data
"""
function initialize_output_observables()
    plot_observable = Observable{Any}(DOM.div("Plot Pane"))
    table_observable = Observable{Any}(DOM.div("Table Pane"))
    current_x = Observable{Union{Nothing, String}}(nothing)
    current_y = Observable{Union{Nothing, String}}(nothing)
    
    return (; plot=plot_observable, table=table_observable, 
              current_x, current_y)
end

# ============================================================================
# 4. UI COMPONENT CREATION
# ============================================================================

# include("create_control_panel_ui.jl")

"""
    is_csv_extension_available()

Check if the CSV extension is loaded (i.e., read_csv has a method defined).
"""
is_csv_extension_available() = length(methods(read_csv)) > 0

"""
    is_xlsx_extension_available()

Check if the XLSX extension is loaded (i.e., readtable_xlsx has a method defined).
"""
is_xlsx_extension_available() = length(methods(readtable_xlsx)) > 0

"""
    build_file_filter()

Build filterlist string for file dialog based on available extensions.
Returns comma-separated extensions (e.g., "csv,tsv,xlsx" or "csv,tsv" or "xlsx").
"""
function build_file_filter()
    filters = String[]
    if is_csv_extension_available()
        push!(filters, "csv", "tsv")
    end
    if is_xlsx_extension_available()
        push!(filters, "xlsx")
    end
    return join(filters, ",")
end

"""
    load_file_to_table(filepath, table_observable)

Load a CSV/TSV or XLSX file and display it in the table pane.

# Arguments
- `filepath`: Path to the file to load
- `table_observable`: Observable for table display

# Returns
`true` on success, `false` on error
"""
function load_file_to_table(filepath, table_observable)
    isempty(filepath) && return false
    
    ext = lowercase(splitext(filepath)[2])
    
    try
        df = if ext in [".csv", ".tsv"]
            if !is_csv_extension_available()
                @warn "CSV extension not available"
                return false
            end
            read_csv(filepath)
        elseif ext == ".xlsx"
            if !is_xlsx_extension_available()
                @warn "XLSX extension not available"
                return false
            end
            # Read first sheet (index 1)
            readtable_xlsx(filepath, 1)
        else
            @warn "Unsupported file extension: $ext"
            return false
        end
        
        # Convert InlineString columns to regular String for Bonito.Table compatibility
        # CSV.jl uses InlineString which Bonito.Table may not handle properly
        for col in names(df)
            if eltype(df[!, col]) <: AbstractString
                df[!, col] = String.(df[!, col])
            end
        end
        
        # Update table display
        table_observable[] = DOM.div(Bonito.Table(df), style=Styles("overflow" => "auto", "height" => "100%"))
        return true
    catch e
        @warn "Error loading file: $e"
        table_observable[] = DOM.div("Error loading file: $(basename(filepath))")
        return false
    end
end

"""
    create_extension_status_row(name, available, available_text, unavailable_text)

Create a DOM row showing extension status with green tick or red cross icon.
"""
function create_extension_status_row(name, available, available_text, unavailable_text)
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
    create_open_tab_content(refresh_trigger, table_observable)

Create reactive content for the Open tab with:
- Top section: Open File button (left) and extension status (right)
- Bottom section: Sheet selector dropdown for XLSX files

Content updates each time the refresh_trigger changes.
Button click opens file dialog. CSV files load immediately, XLSX files wait for sheet selection.

# Arguments
- `refresh_trigger`: Observable that triggers content refresh when changed
- `table_observable`: Observable for table display
"""
function create_open_tab_content(refresh_trigger, table_observable)
    # Create trigger for Open File button clicks
    open_file_trigger = Observable(0)
    
    # Observables for XLSX sheet selection
    current_xlsx_path = Observable("")  # Currently selected XLSX file path
    sheet_names = Observable(String[])  # Sheet names from current XLSX
    selected_sheet = Observable("")     # Currently selected sheet name
    
    # Setup callback for Open File button
    on(open_file_trigger) do _
        # Check if any extension is available
        csv_ok = is_csv_extension_available()
        xlsx_ok = is_xlsx_extension_available()
        
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
            load_file_to_table(filepath, table_observable)
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
    
    # Callback for sheet selection
    on(selected_sheet) do sheet
        xlsx_path = current_xlsx_path[]
        if !isempty(sheet) && !isempty(xlsx_path)
            load_xlsx_sheet_to_table(xlsx_path, sheet, table_observable)
        end
    end
    
    # Use map to create reactive content that updates when trigger fires
    map(refresh_trigger) do _
        csv_available = is_csv_extension_available()
        xlsx_available = is_xlsx_extension_available()
        button_enabled = csv_available || xlsx_available
        
        csv_row = create_extension_status_row(
            "CSV",
            csv_available,
            "CSV extension available",
            "Import CSV to be able to read CSV files",
        )
        
        xlsx_row = create_extension_status_row(
            "XLSX", 
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

"""
    load_xlsx_sheet_to_table(filepath, sheet, table_observable)

Load a specific sheet from an XLSX file and display it in the table pane.
"""
function load_xlsx_sheet_to_table(filepath, sheet, table_observable)
    try
        df = readtable_xlsx(filepath, sheet)
        
        # Convert InlineString columns to regular String for Bonito.Table compatibility
        for col in names(df)
            if eltype(df[!, col]) <: AbstractString
                df[!, col] = String.(df[!, col])
            end
        end
        
        table_observable[] = DOM.div(Bonito.Table(df), style=Styles("overflow" => "auto", "height" => "100%"))
    catch e
        @warn "Error loading XLSX sheet: $e"
        table_observable[] = DOM.div("Error loading sheet: $sheet")
    end
end


"""
    create_tab_content(control_panel, state, outputs)

Organize control panel elements into tabbed interface.

# Arguments
- `control_panel`: NamedTuple with x_source, y_source, plot_kind, legend_control
- `state`: Application state NamedTuple with save-related observables
- `outputs`: Output observables NamedTuple with table observable

# Returns
NamedTuple with:
- `tabs`: Tabbed component DOM element with Open, Source, Format, and Save tabs (Source is default active)
- `overwrite_trigger`: Observable for overwrite button (passed to modal)
- `cancel_trigger`: Observable for cancel button (passed to modal)
"""
function create_tab_content(control_panel, state, outputs)
    # Create a refresh trigger for the Open tab that fires when it becomes active
    open_tab_refresh = Observable(0)
    
    # Open tab - shows extension availability status (reactive) with file loading
    open_tab_content = create_open_tab_content(open_tab_refresh, outputs.table)
    
    t1_source_content = DOM.div(control_panel.source_type_selector, control_panel.source_content)
    t2_format_content = DOM.div(
        control_panel.plot_kind, 
        control_panel.legend_control,
        control_panel.xlabel_input,
        control_panel.ylabel_input,
        control_panel.title_input,
    )
    save_tab_result = create_save_tab_content(state)
    
    tab_configs = [
        (name="Open", content=open_tab_content),
        (name="Source", content=t1_source_content),
        (name="Format", content=t2_format_content),
        (name="Save", content=save_tab_result.content),
    ]
    
    # default_active=2 keeps "Source" tab as the default (Open is now index 1)
    tabs_result = create_tabs_component(tab_configs; default_active=2)
    
    # Wire up the Open tab refresh: trigger when Open tab (index 1) becomes active
    on(tabs_result.active_tab) do tab_idx
        if tab_idx == 1  # Open tab
            open_tab_refresh[] = open_tab_refresh[] + 1
        end
    end
    
    return (; tabs=tabs_result.dom, overwrite_trigger=save_tab_result.overwrite_trigger, 
              cancel_trigger=save_tab_result.cancel_trigger)
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
    
    return DOM.div(Bonito.Table(df), style=Styles("overflow" => "auto", "height" => "100%"))
end

# ============================================================================
# 5. HELP SECTION
# ============================================================================

"""
    setup_help_section(plot_observable)

Create reactive help section that shows/hides based on plot presence.

Returns a NamedTuple with:
- `has_plot`: Observable tracking if plot is displayed
- `visibility`: Observable controlling help section visibility
"""
function setup_help_section(plot_observable)
    has_plot = Observable(false)
    
    on(plot_observable) do plot_content
        has_plot[] = plot_content isa Figure
    end
    
    help_visibility = map(has_plot) do show_help
        show_help ? "visible" : "hidden"
    end
    
    return (; has_plot, visibility=help_visibility)
end

"""
    mouse_helptext(help_visibility)

Create the mouse controls help text with reactive visibility.

# Arguments
- `help_visibility`: Observable controlling CSS visibility property

# Returns
DOM.div containing formatted help text for mouse controls
"""
mouse_helptext(help_visibility) = map(help_visibility) do visibility_style
    DOM.div(
        DOM.div("Mouse Controls", style=Styles("font-weight" => "bold", "font-size" => "11px", "margin-bottom" => "3px")),
        DOM.div(
            DOM.div("Pan: Right-click + Drag", style=Styles("font-size" => "10px", "margin-bottom" => "1px")),
            DOM.div("Zoom: Mouse Wheel", style=Styles("font-size" => "10px", "margin-bottom" => "1px")),
            DOM.div("Zoom in: Select rectangle by left button", style=Styles("font-size" => "10px", "margin-bottom" => "1px")),
            DOM.div("Reset: Ctrl + Left-click", style=Styles("font-size" => "10px"))
        );
        style=Styles(
            "padding" => "5px", 
            "background-color" => "#f5f5f5",
            "visibility" => visibility_style
        )
    )
end

"""
    help_section(help_visibility)

Create the complete help section with separator line and help text.

# Arguments
- `help_visibility`: Observable controlling help text visibility

# Returns
DOM.div containing separator line and conditionally visible help text
"""
help_section(help_visibility) = DOM.div(
    DOM.div(style=Styles("border-top" => "1px solid #ccc")),  # Permanent separator line
    mouse_helptext(help_visibility);  # Conditionally visible help text
    style=Styles("flex-shrink" => "0")
)

# ============================================================================
# 6. LAYOUT ASSEMBLY
# ============================================================================

"""
    assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)

Assemble the final application layout with all panes and grids.

# Arguments
- `ctrlpane_content`: Tabbed control panel content
- `help_visibility`: Observable controlling help section visibility
- `plot_observable`: Observable containing plot display
- `table_observable`: Observable containing table display
- `state`: Application state NamedTuple (for modal dialog)
- `overwrite_trigger`: Observable for overwrite button clicks
- `cancel_trigger`: Observable for cancel button clicks

# Returns
Complete DOM structure for the application including modal overlay
"""
function assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)
    # Split ctrlpane vertically: tabs on top, help on bottom
    ctrlpane_split = DOM.div(
        DOM.div(ctrlpane_content, style=Styles("flex" => "1", "overflow" => "auto")),
        help_section(help_visibility);
        style=Styles("display" => "flex", "flex-direction" => "column", "height" => "100%")
    )
    
    ctrlpane = Card(ctrlpane_split; style=Styles("background-color" => :whitesmoke, "padding" => "5px"))
    tblpane = Card(table_observable; style=Styles("background-color" => :silver, "padding" => "5px"))
    pltpane = Card(plot_observable; style=Styles("background-color" => :lightgray, "padding" => "5px"))
    
    top_row = Grid(ctrlpane, pltpane; columns="350px 810px", gap="5px")
    container = Grid(top_row, tblpane; rows="610px auto", gap="5px")
    
    # Create modal dialog overlay (placed last to be on top of everything)
    modal = create_modal_container(state, overwrite_trigger, cancel_trigger)
    
    return DOM.div(container, modal; style=Styles("padding" => "5px"))
end

# ============================================================================
# 7. UTILS
# ============================================================================

"""
    force_plot_refresh(plot_observable, fig)

Force a complete render of the plot to ensure updates (like label changes) are reflected in the UI.
This is necessary because ... because this was the only way I could get plot reliably updated after e.g. title change.
"""
function force_plot_refresh(plot_observable, fig)
    # Trigger refresh before
    plot_observable[] = plot_observable[]
    # Force Makie render
    show(IOBuffer(), MIME"text/html"(), fig)
    # Trigger refresh after
    plot_observable[] = plot_observable[]
end
