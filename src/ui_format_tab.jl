"""
    create_plot_kind_selector(dropdowns)

Create plot type selection UI.

# Arguments
- `dropdowns`: NamedTuple containing dropdown nodes

# Returns
DOM.div containing plot type dropdown
"""
function create_plot_kind_selector(dropdowns)
    DOM.div(
        "Plot type:", dropdowns.plottype_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
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
        onchange = js"event => $(show_legend).notify(event.target.checked)"
    )
    
    # Legend title input
    legend_title_style = map(show_legend) do show
        return Styles(
            "width" => "100px", 
            "padding" => "2px 5px", 
            "margin-left" => "10px",
            "display" => show ? "block" : "none"
        )
    end

    legend_title_input = DOM.input(
        type="text", 
        value=legend_title_text,
        placeholder="Legend Title",
        onkeydown=js"""
            event => {
                if (event.key === 'Enter') {
                    event.preventDefault();
                    $(legend_title_text).notify(event.target.value);
                }
            }
        """,
        style=legend_title_style
    )

    DOM.div(
        legend_checkbox, " Show Legend", legend_title_input;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
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
        DOM.label(label_text, style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=label_observable,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter') {
                        event.preventDefault();
                        $(label_observable).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center", 
                     "gap" => "5px", "margin-bottom" => "5px")
    )
end
