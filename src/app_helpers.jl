# Helper functions for casualplots_app()
# These functions break down the main app into logical, testable units
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
- `selected_art`: Observable for plot type
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
            last_update[] = current_time
        end
    end
    
    selected_x = Observable{Union{Nothing, String}}(nothing)
    selected_y = Observable{Union{Nothing, String}}(nothing)
    selected_art = Observable("Scatter")
    show_legend = Observable(true)
    
    # Text field observables for plot labels
    xlabel_text = Observable("")
    ylabel_text = Observable("")
    title_text = Observable("")
    
    return (; dims_dict_obs, trigger_update, selected_x, selected_y, 
              selected_art, show_legend, last_update,
              xlabel_text, ylabel_text, title_text)
end

# ============================================================================
# 2. DROPDOWN SETUP
# ============================================================================

"""
    setup_dropdowns(dims_dict_obs, selected_x, selected_art)

Create and configure dropdown menus for X, Y, and plot art selection.

Returns a NamedTuple with:
- `x_node`: Observable containing X dropdown DOM element
- `y_node`: Observable containing Y dropdown DOM element  
- `art_node`: Observable containing Art dropdown DOM element
"""
function setup_dropdowns(dims_dict_obs, selected_x, selected_art)
    dropdown_x_node = Observable(DOM.div("Click to load X variables"))
    
    # Setup X dropdown to update when data changes
    on(dims_dict_obs) do dims_dict
        vectors_only = filter(p -> length(last(p)) == 1, dims_dict)
        array_names = string.(keys(vectors_only)) |> sort!
        if isempty(array_names)
            array_names = [""]
        end
        dropdown_x_node[] = create_x_dropdown("Select X", array_names, selected_x)
    end
    notify(dims_dict_obs)
    
    dropdown_y_node = create_y_dropdown("Select Y after you selected X")
    dropdown_art_node = create_art_dropdown(selected_art)
    
    return (; x_node=dropdown_x_node, y_node=dropdown_y_node, art_node=dropdown_art_node)
end

"""
    create_x_dropdown(prompt_text, array_names, selected_x)

Create a dropdown menu for X variable selection.

# Arguments
- `prompt_text::String`: Placeholder text for the dropdown
- `array_names::Vector{String}`: Available variable names
- `selected_x::Observable`: Observable to update when selection changes

# Returns
DOM.select element with onchange handler bound to selected_x
"""
function create_x_dropdown(prompt_text::String, array_names::Vector{String}, selected_x::Observable)
    return DOM.select(
        DOM.option(prompt_text, value="", selected=true, disabled=true), # Placeholder
        [DOM.option(name, value=name) for name in array_names]...;
        onchange = js"event => $(selected_x).notify(event.target.value)"
    )
end

"""
    create_y_dropdown(prompt_text)

Create an initially disabled dropdown menu for Y variable selection.

The actual options will be populated dynamically by setup_x_callback()
when the user selects an X variable.

# Arguments
- `prompt_text::String`: Placeholder text for the dropdown

# Returns
Observable containing a disabled DOM.select element
"""
function create_y_dropdown(prompt_text::String)
    return Observable(
        DOM.select(DOM.option(prompt_text, value="", selected=true, disabled=true); 
        disabled=true
        )
    )
end

"""
    create_art_dropdown(selected_art)

Create a dropdown menu for plot type selection.

# Arguments
- `selected_art::Observable`: Observable to update when selection changes

# Returns
Observable containing DOM.select element with plot type options
"""
function create_art_dropdown(selected_art::Observable)
    current_art = selected_art[]
    art_options = [
        DOM.option("Lines", value="Lines", selected=(current_art == "Lines")),
        DOM.option("Scatter", value="Scatter", selected=(current_art == "Scatter")),
        DOM.option("BarPlot", value="BarPlot", selected=(current_art == "BarPlot"))
    ]
    return Observable(
        DOM.select(art_options...;
            onchange = js"event => $(selected_art).notify(event.target.value)"
        )
    )
end

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
    plot_observable = Observable{Any}(DOM.div("Pane 3"))
    table_observable = Observable{Any}(DOM.div("Pane 2"))
    current_plot_x = Observable{Union{Nothing, String}}(nothing)
    current_plot_y = Observable{Union{Nothing, String}}(nothing)
    
    return (; plot=plot_observable, table=table_observable, 
              current_x=current_plot_x, current_y=current_plot_y)
end

# ============================================================================
# 4. UI COMPONENT CREATION
# ============================================================================

"""
    create_control_panel_ui(dropdowns, show_legend, trigger_update, xlabel_text, ylabel_text, title_text)

Create UI elements for the control panel (data source and format controls).

Returns a NamedTuple with:
- `x_source`: X variable selection UI
- `y_source`: Y variable selection UI
- `plot_kind`: Plot type selection UI
- `legend_control`: Legend visibility checkbox UI
- `xlabel_input`: X-axis label text field
- `ylabel_input`: Y-axis label text field
- `title_input`: Plot title text field
"""
function create_control_panel_ui(dropdowns, show_legend, trigger_update, 
                                  xlabel_text, ylabel_text, title_text)
    x_source = DOM.div(
        "Select X:", 
        DOM.div(dropdowns.x_node; onclick=js"() => $(trigger_update).notify(true)");
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    y_source = DOM.div(
        "Select Y:", dropdowns.y_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    plot_kind = DOM.div(
        "Plot art:", dropdowns.art_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
    legend_checkbox = DOM.input(type="checkbox", checked=show_legend[];
        onchange = js"event => $(show_legend).notify(event.target.checked)"
    )
    legend_control = DOM.div(
        legend_checkbox, " Show Legend";
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
    )
    
    # Text input fields for plot labels
    xlabel_input = DOM.div(
        DOM.label("X-Axis:", style=Styles("min-width" => "60px")),
        DOM.input(type="text", value=xlabel_text, readonly=true,
                  style=Styles("flex" => "1", "padding" => "2px 5px"));
        style=Styles("display" => "flex", "align-items" => "center", 
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    ylabel_input = DOM.div(
        DOM.label("Y-Axis:", style=Styles("min-width" => "60px")),
        DOM.input(type="text", value=ylabel_text, readonly=true,
                  style=Styles("flex" => "1", "padding" => "2px 5px"));
        style=Styles("display" => "flex", "align-items" => "center",
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    title_input = DOM.div(
        DOM.label("Title:", style=Styles("min-width" => "60px")),
        DOM.input(type="text", value=title_text, readonly=true,
                  style=Styles("flex" => "1", "padding" => "2px 5px"));
        style=Styles("display" => "flex", "align-items" => "center",
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    return (; x_source, y_source, plot_kind, legend_control,
              xlabel_input, ylabel_input, title_input)
end

"""
    create_tab_content(control_panel)

Organize control panel elements into tabbed interface.

# Arguments
- `control_panel`: NamedTuple with x_source, y_source, plot_kind, legend_control

# Returns
Tabbed component DOM element with Source, Format, and Save tabs
"""
function create_tab_content(control_panel)
    t1_source_content = DOM.div(control_panel.x_source, control_panel.y_source)
    t2_format_content = DOM.div(
        control_panel.plot_kind, 
        control_panel.legend_control,
        control_panel.xlabel_input,
        control_panel.ylabel_input,
        control_panel.title_input
    )
    t3_save_content = DOM.div("Saving results will go here")
    
    tab_configs = [
        (name="Source", content=t1_source_content),
        (name="Format", content=t2_format_content),
        (name="Save", content=t3_save_content)
    ]
    
    return create_tabs_component(tab_configs)
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
function create_data_table(x::String, y::String)
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
    assemble_layout(pane1_content, help_visibility, plot_observable, table_observable)

Assemble the final application layout with all panes and grids.

# Arguments
- `pane1_content`: Tabbed control panel content
- `help_visibility`: Observable controlling help section visibility
- `plot_observable`: Observable containing plot display
- `table_observable`: Observable containing table display

# Returns
Complete DOM structure for the application
"""
function assemble_layout(pane1_content, help_visibility, plot_observable, table_observable)
    # Split pane1 vertically: tabs on top, help on bottom
    pane1_split = DOM.div(
        DOM.div(pane1_content, style=Styles("flex" => "1", "overflow" => "auto")),
        help_section(help_visibility);
        style=Styles("display" => "flex", "flex-direction" => "column", "height" => "100%")
    )
    
    pane1 = Card(pane1_split; style=Styles("background-color" => :whitesmoke, "padding" => "5px"))
    pane2 = Card(table_observable; style=Styles("background-color" => :silver, "padding" => "5px"))
    pane3 = Card(plot_observable; style=Styles("background-color" => :lightgray, "padding" => "5px"))
    
    top_row = Grid(pane1, pane3; columns="350px 810px", gap="5px")
    container = Grid(top_row, pane2; rows="610px auto", gap="5px")
    
    return DOM.div(container, style=Styles("padding" => "5px"))
end
