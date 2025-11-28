"""
    setup_x_callback(dims_dict_obs, selected_x, selected_y, dropdown_y_node, plot_observable, table_observable)

Set up the listener for changes to the X-variable selection.
When `selected_x` updates:
1. Clears the current `selected_y`.
2. Resets the plot and table views.
3. Updates the Y-variable dropdown (`dropdown_y_node`) to show only variables congruent with the new X selection (based on `dims_dict_obs`).
"""
function setup_x_callback(state, dropdown_y_node, outputs)
    (; dims_dict_obs, selected_x, selected_y) = state
    on(selected_x) do x
        # println("selected x: $x")
        selected_y[] = nothing

        dims_dict = dims_dict_obs[]
        new_y_opts_strings = get_congruent_y_names(x, dims_dict)
        
        if isempty(new_y_opts_strings)
            dropdown_y_node[] = create_dropdown([], nothing; placeholder="No congruent Y-arrays for this X", disabled=true)
        else
            # println("trying to set Y menu to $new_y_opts_strings")
            dropdown_y_node[] = create_dropdown(new_y_opts_strings, selected_y; placeholder="Select Y")
        end
    end
end

"""
    setup_source_callback(selected_x, selected_y, selected_plottype, show_legend, current_plot_x, current_plot_y, plot_observable, table_observable, xlabel_text, ylabel_text, title_text, current_figure, current_axis)

Handle data source changes (X or Y selection updates).
- If valid X and Y are selected:
    - Updates `current_plot_x` and `current_plot_y`.
    - Generates a new plot using `check_data_create_plot`.
    - Updates `plot_observable` with the new figure.
    - Updates `table_observable` with the new data table.
    - Initializes label text fields (`xlabel_text`, `ylabel_text`, `title_text`) from the plot parameters.
    - Stores the figure and axis references.
- If selection is invalid/incomplete:
    - Clears the plot and table views.
    - Resets internal state and text fields.
"""
function setup_source_callback(state, outputs)
    
    (; selected_x, selected_y, plot_format, plot_handles) = state
    (; selected_plottype, show_legend) = plot_format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = plot_handles
    current_plot_x = outputs.current_x
    current_plot_y = outputs.current_y
    plot_observable = outputs.plot
    table_observable = outputs.table
    
    onany(selected_x, selected_y) do x, y
        is_valid = !isnothing(y) && y != "" && !isnothing(x) && x != ""
        
        if is_valid
            # Store current data for format callbacks
            current_plot_x[] = x
            current_plot_y[] = y
            
            # Block format callback to prevent double plotting and ensure atomic update
            state.block_format_update[] = true
            
            try
                # Reset legend title for new plot
                legend_title_text[] = ""

                plottype = selected_plottype[] |> Symbol |> eval
                fig = check_data_create_plot(x, y; plot_format = (;plottype=plottype, show_legend=nothing, legend_title=legend_title_text[]))
                
                if !isnothing(fig)
                    plot_observable[] = fig.fig
                    current_figure[] = fig.fig  # Store figure reference
                    current_axis[] = fig.axis    # Store axis reference
                    
                    # Initialize text fields with default values
                    xlabel_text[] = fig.fig_params.x_name
                    ylabel_text[] = fig.fig_params.y_name
                    title_text[] = fig.fig_params.title
                    show_legend[] = fig.fig_params.effective_show_legend
                end
            finally
                state.block_format_update[] = false
            end
            
            # Create/update table (source-related only)
            table_observable[] = create_data_table(x, y)
        else
            # Clear everything
            current_plot_x[] = nothing
            current_plot_y[] = nothing
            plot_observable[] = DOM.div("Plot Pane")
            table_observable[] = DOM.div("Table Pane")
            # Clear text fields and references
            xlabel_text[] = ""
            ylabel_text[] = ""
            title_text[] = ""
            current_figure[] = nothing
            current_axis[] = nothing
        end
    end
end

"""
    setup_format_callback(selected_plottype, show_legend, current_plot_x, current_plot_y, plot_observable, xlabel_text, ylabel_text, title_text, current_axis)

Handle format changes (e.g., plot type `selected_plottype`, `show_legend` toggle).
Triggers a replot using the currently stored data (`current_plot_x`, `current_plot_y`) with the new format settings.
Updates the `plot_observable` and text fields, but does *not* regenerate the data table.
"""
function setup_format_callback(state, outputs)
    (; selected_plottype, show_legend) = state.plot_format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = state.plot_handles
    current_plot_x = outputs.current_x
    current_plot_y = outputs.current_y
    plot_observable = outputs.plot

    onany(selected_plottype, show_legend, legend_title_text) do plottype_str, legend_bool, leg_title
        if state.block_format_update[]
            return
        end

        x = current_plot_x[]
        y = current_plot_y[]
        
        # Only replot if we have valid data
        if !isnothing(x) && !isnothing(y)
            plottype = plottype_str |> Symbol |> eval
            fig = check_data_create_plot(x, y; plot_format = (; plottype=plottype, show_legend=legend_bool, legend_title=leg_title))
            if !isnothing(fig)
                plot_observable[] = fig.fig
                current_figure[] = fig.fig # Update figure reference
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
