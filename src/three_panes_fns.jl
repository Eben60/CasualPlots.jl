

function create_x_dropdown(prompt_text::String, array_names::Vector{String}, selected_x::Observable)
    return DOM.select(
        DOM.option(prompt_text, value="", selected=true, disabled=true), # Placeholder
        [DOM.option(name, value=name) for name in array_names]...;
        onchange = js"event => $(selected_x).notify(event.target.value)"
    )
end

function create_y_dropdown(prompt_text::String)
    return Observable{Hyperscript.Node}(
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
    return Observable{Hyperscript.Node}(
        DOM.select(art_options...;
            onchange = js"event => $(selected_art).notify(event.target.value)"
        )
    )
end

function get_congruent_y_names(x, dims_dict::Dict)
    new_y_opts_strings = String[]
    if !(isnothing(x) || x == "")
        x_sym = Symbol(x)
        if haskey(dims_dict, x_sym)
            x_dims = dims_dict[x_sym]
            vec_length = x_dims[1] 
            for (key, dims) in dims_dict
                if key != x_sym && !isempty(dims) && dims[1] == vec_length
                    push!(new_y_opts_strings, string(key))
                end
            end
        end
    end
    return new_y_opts_strings |> sort!
end

export get_congruent_y_names

function setup_x_callback(dims_dict_obs::Observable, selected_x::Observable, selected_y::Observable, dropdown_y_node::Observable, plot_observable::Observable, table_observable::Observable)
    Observables.on(selected_x) do x
        # println("selected x: $x")
        selected_y[] = nothing
        plot_observable[] = DOM.div("Pane 3")
        table_observable[] = DOM.div("Pane 2")

        dims_dict = dims_dict_obs[]
        new_y_opts_strings = get_congruent_y_names(x, dims_dict)
        
        if isempty(new_y_opts_strings)
            dropdown_y_node[] = DOM.select(DOM.option("No congruent Y-arrays for this X", value="", selected=true, disabled=true); disabled=true)
        else
            # println("trying to set Y menu to $new_y_opts_strings")
            new_options = [
                DOM.option("Select Y", value="", selected=true, disabled=true),
                [DOM.option(name, value=name) for name in new_y_opts_strings]...
            ]
            dropdown_y_node[] = DOM.select(new_options...; disabled=false, onchange = js"event => $(selected_y).notify(event.target.value)")
        end
    end
end

function setup_y_and_art_callback(selected_x, selected_y, selected_art, plot_observable, table_observable)
    # This callback handles plotting and table display
    onany(selected_y, selected_art) do y, art_str
        x = selected_x[]
        is_y_selected = !isnothing(y) && y != ""

        if is_y_selected && !isnothing(x) && x != ""
            art = art_str |> Symbol |> eval
            fig = check_data_create_plot(x, y; art=art)
            if fig isa Figure
                plot_observable[] = fig
            end

            # Create and display table
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
            
            table_observable[] = DOM.div(Bonito.Table(df), style=Styles("overflow" => "auto", "height" => "100%"))

        else
            plot_observable[] = DOM.div("Pane 3")
            table_observable[] = DOM.div("Pane 2") # Reset table
        end
    end
end

function three_panes_app()
    app = App() do session
        last_update = Ref(time()) # Store last update time

        dims_dict_obs = Observable(get_dims_of_arrays())
        trigger_update = Observable(0)

        on(trigger_update) do val
            if val > 0
                current_time = time()
                if current_time - last_update[] > 30
                    # println("Refreshing variable list.")
                    dims_dict_obs[] = get_dims_of_arrays()
                    last_update[] = current_time
                end
            end
        end

        selected_x = Observable{Union{Nothing, String}}(nothing)
        selected_y = Observable{Union{Nothing, String}}(nothing)
        selected_art = Observable("Scatter")
        
        dropdown_x_node = Observable{Hyperscript.Node}(DOM.div("Click to load X variables"))
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

        plot_observable = Observable{Any}(DOM.div("Pane 3"))
        table_observable = Observable{Any}(DOM.div("Pane 2"))

        setup_x_callback(dims_dict_obs, selected_x, selected_y, dropdown_y_node, plot_observable, table_observable)
        setup_y_and_art_callback(selected_x, selected_y, selected_art, plot_observable, table_observable)

        # Create three rows with horizontal layout for the dropdowns
        x_row = DOM.div(
            "Select X:", 
            DOM.div(dropdown_x_node; onclick=js"() => $(trigger_update).notify($(trigger_update[]) + 1)");
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
        )
        y_row = DOM.div(
            "Select Y:", dropdown_y_node;
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
        )
        art_row = DOM.div(
            "Plot art:", dropdown_art_node;
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
        )
        
        pane1 = Card(DOM.div(x_row, y_row, art_row); style=Styles("background-color" => :whitesmoke, "padding" => "5px")) # Menus
        pane2 = Card(table_observable; style=Styles("background-color" => :silver, "padding" => "5px")) # Table
        pane3 = Card(plot_observable; style=Styles("background-color" => :lightgray, "padding" => "5px")) # Plot

        top_row = Grid(pane1, pane3; columns="350px 810px", gap="5px")
        container = Grid(top_row, pane2; rows="610px auto", gap="5px")
        
        return DOM.div(container, style=Styles("padding" => "5px"))
    end
    
    return app
end

export three_panes_app