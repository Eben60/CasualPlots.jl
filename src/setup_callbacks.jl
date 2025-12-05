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
                    show_legend[] = fig.fig_params.updated_show_legend
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
                
                # Apply current custom labels to the new axis (preserve user customizations)
                ax = fig.axis
                if !isempty(xlabel_text[])
                    ax.xlabel = xlabel_text[]
                end
                if !isempty(ylabel_text[])
                    ax.ylabel = ylabel_text[]
                end
                if !isempty(title_text[])
                    ax.title = title_text[]
                end
                
                # Force plot refresh to show the updated labels
                plot_observable[] = plot_observable[]
                show(IOBuffer(), MIME"text/html"(), fig)
                plot_observable[] = plot_observable[]
            end
        end
        # Note: Table is NOT updated - it's source-dependent only
    end
end

"""
    update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)

Helper function to update DataFrame plot with selected columns and format settings.
Handles the common plotting logic used by both plot trigger and format callbacks.

# Arguments
- `state`: Application state NamedTuple
- `outputs`: Output observables NamedTuple
- `df_name`: Name of the DataFrame
- `cols`: Selected column names
- `reset_legend_title`: If true, resets legend title to empty string (for new plots)
- `update_table`: If true, updates the table observable (only for new plot data)
"""
function update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)
    (; plot_format, plot_handles) = state
    (; selected_plottype, show_legend) = plot_format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = plot_handles
    plot_observable = outputs.plot
    table_observable = outputs.table
    
    try
        # Get DataFrame from Main
        df = getfield(Main, Symbol(df_name))
        
        # Validate that all requested columns exist in the DataFrame
        available_columns = names(df)
        valid_cols = filter(col -> col in available_columns, cols)
        
        # If we don't have at least 2 valid columns after filtering, abort
        if length(valid_cols) < 2
            plot_observable[] = DOM.div("Error: Selected columns not found in DataFrame $(df_name). Available columns: $(join(available_columns, ", "))")
            return false
        end
        
        # Use select to get selected columns
        df_selected = select(df, valid_cols)
        
        # First column is X, rest are Y
        xcol_name = valid_cols[1]
        # Use DataFrame name as y_name when multiple Y columns
        y_names = length(valid_cols) > 2 ? df_name : valid_cols[2]
        
        # Reset legend title if requested (for new plots)
        if reset_legend_title
            state.block_format_update[] = true
            legend_title_text[] = ""
        end
        
        plottype = selected_plottype[] |> Symbol |> eval
        # Use xcol=1 since df_selected has X as first column
        legend_setting = reset_legend_title ? nothing : show_legend[]
        fig = create_plot(df_selected; xcol=1, x_name=xcol_name, y_name=y_names,
                         plot_format=(; plottype=plottype, show_legend=legend_setting, legend_title=legend_title_text[]))
        
        if !isnothing(fig)
            plot_observable[] = fig.fig
            current_figure[] = fig.fig
            current_axis[] = fig.axis
            
            if reset_legend_title
                # New plot: Initialize text fields with default values
                xlabel_text[] = fig.fig_params.x_name
                ylabel_text[] = fig.fig_params.y_name
                title_text[] = fig.fig_params.title
                show_legend[] = fig.fig_params.updated_show_legend
            else
                # Format change: Apply current custom labels to new axis (preserve user customizations)
                ax = fig.axis
                if !isempty(xlabel_text[])
                    ax.xlabel = xlabel_text[]
                end
                if !isempty(ylabel_text[])
                    ax.ylabel = ylabel_text[]
                end
                if !isempty(title_text[])
                    ax.title = title_text[]
                end
                # Force plot refresh to show the updated labels
                plot_observable[] = plot_observable[]
                show(IOBuffer(), MIME"text/html"(), fig)
                plot_observable[] = plot_observable[]
            end
        end
        
        if reset_legend_title
            state.block_format_update[] = false
        end
        
        # Update table if requested (only for new plot data)
        if update_table
            table_observable[] = DOM.div(Bonito.Table(df_selected), style=Styles("overflow" => "auto", "height" => "100%"))
        end
        
        return true  # Success
    catch e
        @warn "Error creating/updating DataFrame plot" exception=e
        plot_observable[] = DOM.div("Error creating plot: $(e)")
        return false  # Failure
    end
end

"""
    setup_dataframe_callbacks(state, outputs, plot_trigger)

Set up callbacks for DataFrame source mode.

Handles:
- Source type changes (clears selections when switching modes)
- DataFrame selection (clears column selections)
- Plot button click (triggers plot update when columns are selected)
"""
function setup_dataframe_callbacks(state, outputs, plot_trigger)
    (; source_type, selected_dataframe, selected_columns, plot_format, plot_handles) = state
    (; selected_plottype, show_legend) = plot_format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = plot_handles
    plot_observable = outputs.plot
    table_observable = outputs.table
    
    # When source type changes, clear plot and selections
    on(source_type) do st
        # Clear array mode selections when switching to DataFrame
        if st == "DataFrame"
            state.selected_x[] = nothing
            state.selected_y[] = nothing
        # Clear DataFrame mode selections when switching to arrays
        else
            selected_dataframe[] = nothing
            selected_columns[] = String[]
        end
        
        # Clear plot and table
        plot_observable[] = DOM.div("Plot Pane")
        table_observable[] = DOM.div("Table Pane")
        xlabel_text[] = ""
        ylabel_text[] = ""
        title_text[] = ""
        current_figure[] = nothing
        current_axis[] = nothing
    end
    
    # When DataFrame selection changes, clear column selections
    on(selected_dataframe) do df_name
        selected_columns[] = String[]
        plot_observable[] = DOM.div("Plot Pane")
        table_observable[] = DOM.div("Table Pane")
    end
    
    # When Plot button is clicked, create plot if valid selection
    on(plot_trigger) do _
        # Skip if not in DataFrame mode
        if source_type[] != "DataFrame"
            return
        end
        
        cols = selected_columns[]
        df_name = selected_dataframe[]
        if isnothing(df_name) || df_name == "" || length(cols) < 2
            # Need at least 2 columns (X and Y)
            plot_observable[] = DOM.div("Select at least 2 columns (first = X, others = Y)")
            table_observable[] = DOM.div("Table Pane")
            return
        end
        
        # Use helper function with reset_legend_title=true and update_table=true for new plots
        update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=true, update_table=true)
    end
    
    # Listen to format changes (plot type, legend) and replot with current DataFrame selection
    onany(selected_plottype, show_legend, legend_title_text) do plottype_str, legend_bool, leg_title
        if state.block_format_update[]
            return
        end
        
        # Only replot if in DataFrame mode with valid selections
        if source_type[] != "DataFrame"
            return
        end
        
        cols = selected_columns[]
        df_name = selected_dataframe[]
        
        # Need valid DataFrame and column selections to replot
        if isnothing(df_name) || df_name == "" || length(cols) < 2
            return
        end
        
        # Use helper function with reset_legend_title=false and update_table=false for format changes
        update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)
    end
end


