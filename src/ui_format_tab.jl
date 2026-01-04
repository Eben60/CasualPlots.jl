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
    create_theme_dropdown(selected_theme)

Create the dropdown for selecting Makie themes.

# Arguments
- `selected_theme`: Observable tracking the selected theme

# Returns
Observable containing the dropdown DOM element
"""
function create_theme_dropdown(selected_theme)
    return Observable(create_dropdown(SUPPORTED_THEMES, selected_theme))
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
    create_group_by_dropdown(selected_group_by, selected_plottype)

Create a reactive dropdown for selecting how groups are visually differentiated.
The "Geometry" option is disabled when BarPlot is selected.

# Arguments
- `selected_group_by`: Observable tracking the selected group style
- `selected_plottype`: Observable tracking the selected plot type (to disable Geometry for BarPlot)

# Returns
Observable containing the dropdown DOM element that updates reactively
"""
function create_group_by_dropdown(selected_group_by, selected_plottype)
    # Create a reactive dropdown that updates when plottype changes
    dropdown_node = map(selected_plottype) do plottype
        is_barplot = plottype == "BarPlot"
        
        # Build options with disabled attribute for Geometry when BarPlot
        options = map(GROUP_BY_OPTIONS) do opt
            if opt == "Geometry" && is_barplot
                DOM.option(opt; value=opt, disabled=true)
            else
                DOM.option(opt; value=opt)
            end
        end
        
        DOM.select(
            options...;
            class="dropdown",
            onchange=js"event => window.CasualPlots.updateObservableValue(event, $(selected_group_by))"
        )
    end
    
    return dropdown_node
end

"""
    create_group_by_selector(group_by_node)

Create group-by selection UI.

# Arguments
- `group_by_node`: The dropdown node for group-by selection

# Returns
DOM.div containing group-by dropdown with label
"""
function create_group_by_selector(group_by_node)
    DOM.div(
        "Show group by:", group_by_node;
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
    create_axis_limits_section(format)

Create the axis limits section with two rows (X and Y).
Each row has: "X from:" [input] "to:" [input] "rev.:" [checkbox]

# Arguments
- `format`: The plotting.format NamedTuple containing axis limit and reversal observables

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
            placeholder="",
            onchange=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(x_min), $(x_max), 'min')",
            onblur=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(x_min), $(x_max), 'min')",
            onkeydown=js"event => window.CasualPlots.handleAxisLimitEnterKey(event, $(x_min), $(x_max), 'min')",
        ),
        DOM.label("to:"; class="axis-limits-label-small"),
        DOM.input(
            type="number",
            step="any",
            id="axis-x-max-input",
            class="axis-limits-input",
            placeholder="",
            onchange=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(x_max), $(x_min), 'max')",
            onblur=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(x_max), $(x_min), 'max')",
            onkeydown=js"event => window.CasualPlots.handleAxisLimitEnterKey(event, $(x_max), $(x_min), 'max')",
        ),
        DOM.label("rev.:"; class="axis-limits-label-small"),
        DOM.input(
            type="checkbox",
            id="axis-x-reversed-checkbox",
            checked=xreversed,
            onchange=js"event => window.CasualPlots.updateObservableChecked(event, $(xreversed))",
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
            placeholder="",
            onchange=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(y_min), $(y_max), 'min')",
            onblur=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(y_min), $(y_max), 'min')",
            onkeydown=js"event => window.CasualPlots.handleAxisLimitEnterKey(event, $(y_min), $(y_max), 'min')",
        ),
        DOM.label("to:"; class="axis-limits-label-small"),
        DOM.input(
            type="number",
            step="any",
            id="axis-y-max-input",
            class="axis-limits-input",
            placeholder="",
            onchange=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(y_max), $(y_min), 'max')",
            onblur=js"event => window.CasualPlots.updateAxisLimitObservable(event, $(y_max), $(y_min), 'max')",
            onkeydown=js"event => window.CasualPlots.handleAxisLimitEnterKey(event, $(y_max), $(y_min), 'max')",
        ),
        DOM.label("rev.:"; class="axis-limits-label-small"),
        DOM.input(
            type="checkbox",
            id="axis-y-reversed-checkbox",
            checked=yreversed,
            onchange=js"event => window.CasualPlots.updateObservableChecked(event, $(yreversed))",
            class="axis-limits-checkbox",
        );
        class="axis-limits-row"
    )
    
    DOM.div(x_row, y_row; class="axis-limits-section")
end
