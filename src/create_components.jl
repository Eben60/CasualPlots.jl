

function create_x_dropdown(prompt_text::String, array_names::Vector{String}, selected_x::Observable)
    return DOM.select(
        DOM.option(prompt_text, value="", selected=true, disabled=true), # Placeholder
        [DOM.option(name, value=name) for name in array_names]...;
        onchange = js"event => $(selected_x).notify(event.target.value)"
    )
end

function create_y_dropdown(prompt_text::String)
    return Observable(
        DOM.select(DOM.option(prompt_text, value="", selected=true, disabled=true); 
        disabled=true
        )
    )
end

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

function create_data_table(x::String, y::String)
    """Extract table creation logic for reuse"""
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

# Permanent separator line and help section container
help_section(help_visibility) = DOM.div(
    DOM.div(style=Styles("border-top" => "1px solid #ccc")),  # Permanent separator line
    mouse_helptext(help_visibility);  # Conditionally visible help text
    style=Styles("flex-shrink" => "0")
)