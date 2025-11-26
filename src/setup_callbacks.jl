function setup_x_callback(dims_dict_obs::Observable, selected_x::Observable, selected_y::Observable, dropdown_y_node::Observable, plot_observable::Observable, table_observable::Observable)
    on(selected_x) do x
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
                                plot_observable, table_observable,
                                xlabel_text, ylabel_text, title_text,
                                current_figure, current_axis)
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
            if !isnothing(fig)
                plot_observable[] = fig.fig
                current_figure[] = fig.fig  # Store figure reference
                current_axis[] = fig.axis    # Store axis reference
                
                # Initialize text fields with default values
                xlabel_text[] = fig.fig_params.x_name
                ylabel_text[] = fig.fig_params.y_name
                title_text[] = fig.fig_params.title
            end
            
            # Create/update table (source-related only)
            table_observable[] = create_data_table(x, y)
        else
            # Clear everything
            current_plot_x[] = nothing
            current_plot_y[] = nothing
            plot_observable[] = DOM.div("Pane 3")
            table_observable[] = DOM.div("Pane 2")
            # Clear text fields and references
            xlabel_text[] = ""
            ylabel_text[] = ""
            title_text[] = ""
            current_figure[] = nothing
            current_axis[] = nothing
        end
    end
end

function setup_format_callback(selected_art, show_legend, current_plot_x, current_plot_y,
                                 plot_observable,
                                 xlabel_text, ylabel_text, title_text,
                                 current_axis)
    """Handle format changes (plot art, legend) - replot with new settings"""
    
    onany(selected_art, show_legend) do art_str, legend_bool
        x = current_plot_x[]
        y = current_plot_y[]
        
        # Only replot if we have valid data
        if !isnothing(x) && !isnothing(y)
            art = art_str |> Symbol |> eval
            fig = check_data_create_plot(x, y; plot_format = (; art=art, show_legend=legend_bool))
            if !isnothing(fig)
                plot_observable[] = fig.fig
                current_axis[] = fig.axis  # Update axis reference
                # Update text fields with updated plot metadata
                xlabel_text[] = fig.fig_params.x_name
                ylabel_text[] = fig.fig_params.y_name
                title_text[] = fig.fig_params.title
            end
        end
        # Note: Table is NOT updated - it's source-dependent only
    end
end
