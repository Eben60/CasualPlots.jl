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

function setup_source_callback(selected_x, selected_y, selected_art, show_legend,
                                current_plot_x, current_plot_y,
                                plot_observable, table_observable)
    """Handle data source changes (X/Y selection)"""
    
    onany(selected_x, selected_y) do x, y
        is_valid = !isnothing(y) && y != "" && !isnothing(x) && x != ""
        
        if is_valid
            # Store current data for format callbacks
            current_plot_x[] = x
            current_plot_y[] = y
            
            # Create plot with current format settings
            art = selected_art[] |> Symbol |> eval
            fig = check_data_create_plot(x, y; plot_format = (;art=art, show_legend=show_legend[]))
            if fig isa Figure
                plot_observable[] = fig
            end
            
            # Create/update table (source-related only)
            table_observable[] = create_data_table(x, y)
        else
            # Clear everything
            current_plot_x[] = nothing
            current_plot_y[] = nothing
            plot_observable[] = DOM.div("Pane 3")
            table_observable[] = DOM.div("Pane 2")
        end
    end
end

function setup_format_callback(selected_art, show_legend, current_plot_x, current_plot_y,
                                 plot_observable)
    """Handle format changes (plot art, legend) - replot with new settings"""
    
    onany(selected_art, show_legend) do art_str, legend_bool
        x = current_plot_x[]
        y = current_plot_y[]
        
        # Only replot if we have valid data
        if !isnothing(x) && !isnothing(y)
            art = art_str |> Symbol |> eval
            fig = check_data_create_plot(x, y; plot_format = (; art=art, show_legend=legend_bool))
            if fig isa Figure
                plot_observable[] = fig
            end
        end
        # Note: Table is NOT updated - it's source-dependent only
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
        show_legend = Observable(true)
        
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

        # Observables to track currently plotted data
        current_plot_x = Observable{Union{Nothing, String}}(nothing)
        current_plot_y = Observable{Union{Nothing, String}}(nothing)

        # Setup callbacks with separated concerns
        setup_x_callback(dims_dict_obs, selected_x, selected_y, dropdown_y_node, plot_observable, table_observable)
        setup_source_callback(selected_x, selected_y, selected_art, show_legend,
                              current_plot_x, current_plot_y,
                              plot_observable, table_observable)
        setup_format_callback(selected_art, show_legend, current_plot_x, current_plot_y,
                              plot_observable)

        # Create three rows with horizontal layout for the dropdowns
        x_source = DOM.div(
            "Select X:", 
            DOM.div(dropdown_x_node; onclick=js"() => $(trigger_update).notify($(trigger_update[]) + 1)");
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
        )
        y_source = DOM.div(
            "Select Y:", dropdown_y_node;
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
        )
        plot_kind = DOM.div(
            "Plot art:", dropdown_art_node;
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px", "margin-bottom" => "5px")
        )
        
        legend_checkbox = DOM.input(type="checkbox", checked=show_legend[];
            onchange = js"event => $(show_legend).notify(event.target.checked)"
        )
        legend_ckgbox_container = DOM.div(
            legend_checkbox, " Show Legend";
            style=Styles("display" => "flex", "align-items" => "center", "gap" => "5px")
        )
        
        # Organize controls into tabs
        t1_source_content = DOM.div(x_source, y_source)
        t2_format_content = DOM.div(plot_kind, legend_ckgbox_container)
        t3_save_content = DOM.div("Saving results will go here")
        
        tab_configs = [
            (name="Source", content=t1_source_content),
            (name="Format", content=t2_format_content),
            (name="Save", content=t3_save_content)
        ]
        
        pane1_content = create_tabs_component(tab_configs)
        
        # Observable to track if a plot is displayed
        has_plot = Observable(false)
        
        # Update has_plot when plot_observable changes
        on(plot_observable) do plot_content
            has_plot[] = plot_content isa Figure
        end
        
        # Create help section for mouse controls with reactive visibility
        help_visibility = map(has_plot) do show_help
            show_help ? "visible" : "hidden"
        end
        

        
        # Split pane1 vertically: tabs on top, help on bottom
        pane1_split = DOM.div(
            DOM.div(pane1_content, style=Styles("flex" => "1", "overflow" => "auto")),
            help_section(help_visibility);
            style=Styles("display" => "flex", "flex-direction" => "column", "height" => "100%")
        )
        
        pane1 = Card(pane1_split; style=Styles("background-color" => :whitesmoke, "padding" => "5px")) # Menus
        pane2 = Card(table_observable; style=Styles("background-color" => :silver, "padding" => "5px")) # Table
        pane3 = Card(plot_observable; style=Styles("background-color" => :lightgray, "padding" => "5px")) # Plot

        top_row = Grid(pane1, pane3; columns="350px 810px", gap="5px")
        container = Grid(top_row, pane2; rows="610px auto", gap="5px")
        
        return DOM.div(container, style=Styles("padding" => "5px"))
    end
    
    return app
end

export three_panes_app