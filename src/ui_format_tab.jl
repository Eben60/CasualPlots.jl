"""
    create_plottype_dropdown(supported_plot_types, selected_plottype)

Create the dropdown for selecting plot types.

# Arguments
- `supported_plot_types`: List of supported plot type strings
- `selected_plottype`: Observable tracking the selected plot type

# Returns
Observable containing the dropdown DOM element
"""
function create_plottype_dropdown(supported_plot_types, selected_plottype)
    # create_dropdown is available from dropdowns_setup.jl (module scope)
    return Observable(create_dropdown(supported_plot_types, selected_plottype))
end

"""
    create_plot_kind_selector(plottype_node)

Create plot type selection UI.

# Arguments
- `plottype_node`: The dropdown node for plot type selection

# Returns
DOM.div containing plot type dropdown
"""
function create_plot_kind_selector(plottype_node)
    DOM.div(
        "Plot type:", plottype_node;
        class="flex-row align-center gap-1 mb-1"
    )
end

"""
    create_legend_control(show_legend, legend_title_text)

Create legend visibility checkbox and title input UI.

# Arguments
- `show_legend::Observable{Bool}`: Observable tracking legend visibility
- `legend_title_text::Observable{String}`: Observable tracking legend title text

# Returns
DOM.div containing legend checkbox and title input
"""
function create_legend_control(show_legend, legend_title_text)
    legend_checkbox = DOM.input(type="checkbox", checked=show_legend;
        onchange = js"event => window.CasualPlots.updateObservableChecked(event, $(show_legend))"
    )
    
    # Legend title input visibility
    # Static styles moved to CSS classes, dynamic visibility kept here
    legend_visibility = map(show_legend) do show
        return Styles("display" => show ? "block" : "none")
    end

    legend_title_input = DOM.input(
        type="text", 
        value=legend_title_text,
        placeholder="Legend Title",
        onkeydown=js"event => window.CasualPlots.handleEnterKey(event, $(legend_title_text))",
        onblur=js"event => window.CasualPlots.handleTextInputBlur(event, $(legend_title_text))",
        style=legend_visibility,
        class="input-small w-100px ml-2"
    )

    DOM.div(
        legend_checkbox, " Show Legend", legend_title_input;
        class="flex-row align-center gap-1"
    )
end

"""
    create_label_input(label_text, label_name, label_observable)

Create a text input field for plot labels (xlabel, ylabel, or title).

# Arguments
- `label_text::String`: Display label for the input field
- `label_name::String`: Name/identifier for the label
- `label_observable::Observable{String}`: Observable tracking the label text

# Returns
DOM.div containing labeled text input field
"""
function create_label_input(label_text, label_name, label_observable)
    DOM.div(
        DOM.label(label_text; class="label-fixed"),
        DOM.input(
            type="text", 
            value=label_observable,
            onkeydown=js"event => window.CasualPlots.handleEnterKey(event, $(label_observable))",
            onblur=js"event => window.CasualPlots.handleTextInputBlur(event, $(label_observable))",
            class="input-small flex-1"
        );
        class="flex-row align-center gap-1 mb-1"
    )
end

"""
    create_axis_limits_row(x_min, x_max, y_min, y_max)

Create a row with axis limits input fields (X min, X max, Y min, Y max).

# Arguments
- `x_min::Observable{Union{Nothing,Float64}}`: Observable for X axis minimum
- `x_max::Observable{Union{Nothing,Float64}}`: Observable for X axis maximum  
- `y_min::Observable{Union{Nothing,Float64}}`: Observable for Y axis minimum
- `y_max::Observable{Union{Nothing,Float64}}`: Observable for Y axis maximum

# Returns
DOM.div containing axis limits inputs in a 4-column layout
"""
function create_axis_limits_row(x_min, x_max, y_min, y_max)
    # Caption row
    caption_row = DOM.div(
        DOM.div("X min"; class="axis-limits-caption"),
        DOM.div("X max"; class="axis-limits-caption"),
        DOM.div("Y min"; class="axis-limits-caption"),
        DOM.div("Y max"; class="axis-limits-caption");
        class="axis-limits-row"
    )
    
    # Create input fields
    x_min_input = DOM.input(
        type="number",
        step="any",
        id="axis-x-min-input",
        class="axis-limits-input",
        placeholder="",
        onchange=js"event => window.CasualPlots.updateFloatObservable(event, $(x_min))",
        onkeydown=js"event => window.CasualPlots.handleFloatEnterKey(event, $(x_min))"
    )
    
    x_max_input = DOM.input(
        type="number",
        step="any",
        id="axis-x-max-input",
        class="axis-limits-input",
        placeholder="",
        onchange=js"event => window.CasualPlots.updateFloatObservable(event, $(x_max))",
        onkeydown=js"event => window.CasualPlots.handleFloatEnterKey(event, $(x_max))"
    )
    
    y_min_input = DOM.input(
        type="number",
        step="any",
        id="axis-y-min-input",
        class="axis-limits-input",
        placeholder="",
        onchange=js"event => window.CasualPlots.updateFloatObservable(event, $(y_min))",
        onkeydown=js"event => window.CasualPlots.handleFloatEnterKey(event, $(y_min))"
    )
    
    y_max_input = DOM.input(
        type="number",
        step="any",
        id="axis-y-max-input",
        class="axis-limits-input",
        placeholder="",
        onchange=js"event => window.CasualPlots.updateFloatObservable(event, $(y_max))",
        onkeydown=js"event => window.CasualPlots.handleFloatEnterKey(event, $(y_max))"
    )
    
    # Input row
    input_row = DOM.div(
        x_min_input,
        x_max_input,
        y_min_input,
        y_max_input;
        class="axis-limits-row"
    )
    
    DOM.div(caption_row, input_row; class="axis-limits-section")
end

