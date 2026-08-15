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
    return Observable(create_dropdown(
        supported_plot_types, selected_plottype; 
        id="dropdown-plottype",
        onchange=js"event => { window.CasualPlots.updateObservableValue(event, $(selected_plottype)); }"
    ))
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
    create_theme_dropdown(selected_theme)

Create the dropdown for selecting Makie themes.

# Arguments
- `selected_theme`: Observable tracking the selected theme

# Returns
Observable containing the dropdown DOM element
"""
function create_theme_dropdown(selected_theme)
    return Observable(create_dropdown(SUPPORTED_THEMES, selected_theme; id="dropdown-theme"))
end

"""
    create_theme_selector(theme_node)

Create theme selection UI.

# Arguments
- `theme_node`: The dropdown node for theme selection

# Returns
DOM.div containing theme dropdown
"""
function create_theme_selector(theme_node)
    DOM.div(
        "Theme:", theme_node;
        class="flex-row align-center gap-1 mb-1"
    )
end

"""
    render_attribute(attr::Union{EnumAttribute, GroupByAttribute}, obs::Observable)

Create a generic dropdown for a dynamic attribute.
"""
function render_attribute(attr::Union{EnumAttribute, GroupByAttribute}, obs::Observable)
    dropdown_node = Observable(create_dropdown(attr.options, obs; id="dropdown-$(attr.name)"))
    
    return DOM.div(
        attr.label, dropdown_node;
        class="flex-row align-center gap-1 mb-1"
    )
end

"""
    create_dynamic_attributes_section(selected_plottype, dynamic_attributes)

Create a reactive UI section that renders dynamic attribute controls based on the selected plot type.
"""
function create_dynamic_attributes_section(selected_plottype, dynamic_attributes)
    return map(selected_plottype) do pt
        config = PLOT_TYPES[pt]
        attrs = get_attributes(config)
        
        nodes = []
        
        for attr in attrs
            push!(nodes, (attr.name, attr.layout, render_attribute(attr, dynamic_attributes[attr.name])))
        end
        
        if isempty(nodes)
            return DOM.div(style="display: none;")
        end
        
        # Sort nodes according to ATTRIBUTE_DISPLAY_ORDER
        sort!(nodes, by = x -> begin
            idx = findfirst(==(x[1]), ATTRIBUTE_DISPLAY_ORDER)
            idx === nothing ? error("Attribute $(x[1]) is missing from ATTRIBUTE_DISPLAY_ORDER!") : idx
        end)
        
        # Group inline elements
        final_nodes = []
        inline_group = []
        
        for (_, layout, node) in nodes
            if layout == :inline
                push!(inline_group, node)
            else
                if !isempty(inline_group)
                    push!(final_nodes, DOM.div(inline_group...; class="flex-row gap-2 mb-1 flex-wrap"))
                    empty!(inline_group)
                end
                push!(final_nodes, node)
            end
        end
        if !isempty(inline_group)
            push!(final_nodes, DOM.div(inline_group...; class="flex-row gap-2 mb-1 flex-wrap"))
        end
        
        DOM.div(final_nodes...; class="flex-col")
    end
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
    legend_checkbox = DOM.input(type="checkbox", id="chk-show-legend", checked=show_legend;
        onchange = js"event => window.CasualPlots.updateObservableChecked(event, $(show_legend))"
    )
    
    # Legend title input visibility
    # Static styles moved to CSS classes, dynamic visibility kept here
    legend_visibility = map(show_legend) do show
        return Styles("display" => show ? "block" : "none")
    end

    legend_title_input = DOM.input(
        type="text", 
        id="input-legend-title",
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
            id="input-$(label_name)",
            value=label_observable,
            onkeydown=js"event => window.CasualPlots.handleEnterKey(event, $(label_observable))",
            onblur=js"event => window.CasualPlots.handleTextInputBlur(event, $(label_observable))",
            class="input-small flex-1"
        );
        class="flex-row align-center gap-1 mb-1"
    )
end

"""
    create_axis_limits_section(format)

Create the axis limits section with two rows (X and Y).
Each row has: "X from:" [input] "to:" [input] "rev.:" [checkbox]

# Arguments
- `format`: The `PlotFormat` struct containing axis limit and reversal observables

# Returns
DOM.div containing the complete axis limits section
"""
function create_axis_limits_section(format)
    (; x_min, x_max, y_min, y_max, xreversed, yreversed) = format
    
    # X axis row
    x_row = DOM.div(
        DOM.label("X from:"; class="axis-limits-label"),
        DOM.input(
            type="number",
            step="any",
            id="axis-x-min-input",
            class="axis-limits-input",
            placeholder=""
        ),
        DOM.label("to:"; class="axis-limits-label-small"),
        DOM.input(
            type="number",
            step="any",
            id="axis-x-max-input",
            class="axis-limits-input",
            placeholder=""
        ),
        DOM.label("rev.:"; class="axis-limits-label-small"),
        DOM.input(
            type="checkbox",
            id="axis-x-reversed-checkbox",
            checked=xreversed,
            class="axis-limits-checkbox",
        );
        class="axis-limits-row"
    )
    
    # Y axis row
    y_row = DOM.div(
        DOM.label("Y from:"; class="axis-limits-label"),
        DOM.input(
            type="number",
            step="any",
            id="axis-y-min-input",
            class="axis-limits-input",
            placeholder=""
        ),
        DOM.label("to:"; class="axis-limits-label-small"),
        DOM.input(
            type="number",
            step="any",
            id="axis-y-max-input",
            class="axis-limits-input",
            placeholder=""
        ),
        DOM.label("rev.:"; class="axis-limits-label-small"),
        DOM.input(
            type="checkbox",
            id="axis-y-reversed-checkbox",
            checked=yreversed,
            class="axis-limits-checkbox",
        );
        class="axis-limits-row"
    )
    
    DOM.div(x_row, y_row; class="axis-limits-section")
end
