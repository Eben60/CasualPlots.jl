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
function create_control_panel_ui(dropdowns, state)
    (; trigger_update, plot_format, plot_handles) = state
    (; show_legend) = plot_format
    (; xlabel_text, ylabel_text, title_text) = plot_handles
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
        "Plot type:", dropdowns.plottype_node;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
    )
    
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
        value=state.plot_handles.legend_title_text,
        placeholder="Legend Title",
        onkeydown=js"""
            event => {
                if (event.key === 'Enter' || event.key === 'Tab') {
                    event.preventDefault();
                    $(state.plot_handles.legend_title_text).notify(event.target.value);
                }
            }
        """,
        style=legend_title_style
    )

    legend_control = DOM.div(
        legend_checkbox, " Show Legend", legend_title_input;
        style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
    )
    
    # Text input fields for plot labels - editable with Enter/Tab support
    xlabel_input = DOM.div(
        DOM.label("X-Axis:", style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=xlabel_text,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter' || event.key === 'Tab') {
                        event.preventDefault();
                        $(xlabel_text).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center", 
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    ylabel_input = DOM.div(
        DOM.label("Y-Axis:", style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=ylabel_text,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter' || event.key === 'Tab') {
                        event.preventDefault();
                        $(ylabel_text).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center",
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    title_input = DOM.div(
        DOM.label("Title:", style=Styles("min-width" => "60px")),
        DOM.input(
            type="text", 
            value=title_text,
            onkeydown=js"""
                event => {
                    if (event.key === 'Enter' || event.key === 'Tab') {
                        event.preventDefault();
                        $(title_text).notify(event.target.value);
                    }
                }
            """,
            style=Styles("flex" => "1", "padding" => "2px 5px")
        );
        style=Styles("display" => "flex", "align-items" => "center",
                     "gap" => "5px", "margin-bottom" => "5px")
    )
    
    return (; x_source, y_source, plot_kind, legend_control,
              xlabel_input, ylabel_input, title_input)
end
