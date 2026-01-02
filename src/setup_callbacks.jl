"""
    setup_x_callback(dims_dict_obs, selected_x, selected_y, dropdown_y_node, plot_observable, table_observable)

Set up the listener for changes to the X-variable selection.
When `selected_x` updates:
1. Clears the current `selected_y`.
2. Resets the plot and table views.
3. Updates the Y-variable dropdown (`dropdown_y_node`) to show only variables congruent with the new X selection (based on `dims_dict_obs`).
"""
function setup_x_callback(state, dropdown_y_node, outputs)
    (; dims_dict_obs, selected_x, selected_y) = state.data_selection
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
    
    (; selected_x, selected_y) = state.data_selection
    (; format, handles) = state.plotting
    (; selected_plottype, show_legend) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = handles
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
            state.misc.block_format_update[] = true
            
            try
                # Reset legend title and format changed flags for new plot
                legend_title_text[] = ""
                reset_format_defaults!(state.misc.format_is_default)

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
                state.misc.block_format_update[] = false
            end
            
            # Create/update table (source-related only)
            table_observable[] = create_data_table(x, y)
        else
            # Clear everything
            current_plot_x[] = nothing
            current_plot_y[] = nothing
            plot_observable[] = DOM.div("Plot Pane")
            table_observable[] = DOM.div("Table Pane")
            # Clear text fields, references, and format changed flags
            reset_format_defaults!(state.misc.format_is_default)
            xlabel_text[] = ""
            ylabel_text[] = ""
            title_text[] = ""
            current_figure[] = nothing
            current_axis[] = nothing
        end
    end
end

"""
    setup_format_change_callbacks(state, outputs)

Handle format changes for X,Y Array mode: plottype, show_legend, legend_title_text.
All changes trigger a full replot, then apply custom formatting for non-default options.
"""
function setup_format_change_callbacks(state, outputs)
    (; selected_plottype, show_legend) = state.plotting.format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = state.plotting.handles
    current_plot_x = outputs.current_x
    current_plot_y = outputs.current_y
    plot_observable = outputs.plot
    
    # Helper function to replot with current format settings
    function do_replot()
        x = current_plot_x[]
        y = current_plot_y[]
        
        # Only replot if we have valid data
        isnothing(x) && return
        isnothing(y) && return
        
        state.misc.block_format_update[] = true
        try
            plottype = selected_plottype[] |> Symbol |> eval
            fig = check_data_create_plot(x, y; plot_format = (;
                plottype = plottype,
                show_legend = show_legend[],
                legend_title = legend_title_text[],
            ))
            
            if !isnothing(fig)
                current_figure[] = fig.fig
                current_axis[] = fig.axis
                plot_observable[] = fig.fig
                
                # Apply custom formatting for non-default options
                apply_custom_formatting!(fig.fig, fig.axis, state)
            end
        finally
            state.misc.block_format_update[] = false
        end
    end
    
    # === Plot Type Change Handler ===
    on(selected_plottype) do plottype_str
        state.misc.block_format_update[] && return
        
        # Mark as non-default if different from DEFAULT_PLOT_TYPE
        plottype_sym = Symbol(plottype_str)
        if plottype_sym != DEFAULT_PLOT_TYPE
            state.misc.format_is_default[:plottype] = false
        end
        
        do_replot()
    end
    
    # === Legend Visibility Change Handler ===
    on(show_legend) do legend_bool
        state.misc.block_format_update[] && return
        
        # Mark as non-default (actual default depends on data, so any user change marks it)
        state.misc.format_is_default[:show_legend] = false
        
        do_replot()
    end
    
    # === Legend Title Change Handler ===
    on(legend_title_text) do leg_title
        state.misc.block_format_update[] && return
        
        # Mark as non-default if not empty
        if !isempty(leg_title)
            state.misc.format_is_default[:legend_title] = false
        end
        
        # Skip replot if legend is not shown - title is saved for when legend becomes visible
        show_legend[] || return
        
        do_replot()
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
- `reset_legend_title`: If true, resets legend title and format flags (for new plots)
- `update_table`: If true, updates the table observable (only for new plot data)
"""
    function update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)
    (; format, handles) = state.plotting
    (; show_modal, modal_type) = state.dialogs
    (; selected_plottype, show_legend) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = handles
    plot_observable = outputs.plot
    table_observable = outputs.table
    
    try
        # Get DataFrame - either from Main or from opened file
        local df
        local display_name  # Name used for table info and plot title
        
        if df_name == "__opened_file__"
            # Use DataFrame loaded from file (already has strings normalized)
            df = state.file_opening.opened_file_df[]
            display_name = state.file_opening.opened_file_name[]
            if isnothing(df)
                plot_observable[] = DOM.div("Error: No file has been opened. Use the Open tab to load a file.")
                return false
            end
        else
            # Get DataFrame from Main module
            df = getfield(Main, Symbol(df_name))
            display_name = df_name
        end
        
        # Validate that all requested columns exist in the DataFrame
        available_columns = names(df)
        valid_cols = filter(col -> col in available_columns, cols)
        
        # If we don't have at least 2 valid columns after filtering, abort
        if length(valid_cols) < 2
            plot_observable[] = DOM.div("Error: Selected columns not found in DataFrame $(display_name). Available columns: $(join(available_columns, ", "))")
            return false
        end
        
        # Use select to get selected columns
        df_selected = select(df, valid_cols)
        
        # Normalize numeric columns for plotting and track any columns with data issues
        df_selected, dirty_cols = normalize_numeric_columns!(df_selected, valid_cols)
        
        # Show warning if any columns had non-numeric values converted to missing
        if !isempty(dirty_cols)
            warning_msg = "Converted non-numeric values to missing in column(s): $(join(dirty_cols, ", "))"
            @warn warning_msg
            # Show popup warning
            state.file_saving.save_status_message[] = warning_msg
            state.file_saving.save_status_type[] = :warning
            modal_type[] = :warning
            show_modal[] = true
        end
        
        # First column is X, rest are Y
        xcol_name = valid_cols[1]
        # Use display name as y_name when multiple Y columns
        y_names = length(valid_cols) > 2 ? display_name : valid_cols[2]
        
        # Reset legend title and format flags if requested (for new plots)
        if reset_legend_title
            legend_title_text[] = ""
            reset_format_defaults!(state.misc.format_is_default)
        end
        
        # Block label callbacks during plot recreation
        state.misc.block_format_update[] = true
        
        plottype = selected_plottype[] |> Symbol |> eval
        
        # Create plot with current format settings
        fig = create_plot(df_selected; xcol=1, x_name=xcol_name, y_name=y_names,
                         plot_format=(; 
                             plottype=plottype, 
                             show_legend=show_legend[], 
                             legend_title=legend_title_text[],
                         ))
        
        if !isnothing(fig)
            current_figure[] = fig.fig
            current_axis[] = fig.axis
            
            if reset_legend_title
                # New plot: initialize text fields with defaults from the plot
                xlabel_text[] = fig.fig_params.x_name
                ylabel_text[] = fig.fig_params.y_name
                title_text[] = fig.fig_params.title
                show_legend[] = fig.fig_params.updated_show_legend
            end
            
            # Publish the figure
            plot_observable[] = fig.fig
            
            # Apply custom formatting for non-default options
            apply_custom_formatting!(fig.fig, fig.axis, state)
        end
        
        state.misc.block_format_update[] = false
        
        # Update table if requested (only for new plot data)
        if update_table
            table_observable[] = create_table_with_info(Bonito.Table(df_selected), display_name)
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
    (; source_type, selected_dataframe, selected_columns, selected_x, selected_y) = state.data_selection
    (; format, handles) = state.plotting
    (; selected_plottype, show_legend) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = handles
    plot_observable = outputs.plot
    table_observable = outputs.table
    
    # When source type changes, clear plot and selections
    on(source_type) do st
        # Clear array mode selections when switching to DataFrame
        if st == "DataFrame"
            selected_x[] = nothing
            selected_y[] = nothing
        # Clear DataFrame mode selections when switching to arrays
        else
            selected_dataframe[] = nothing
            selected_columns[] = String[]
        end
        
        # Clear plot and table
        plot_observable[] = DOM.div("Plot Pane")
        table_observable[] = DOM.div("Table Pane")
        # Clear format changed flags and text fields
        reset_format_defaults!(state.misc.format_is_default)
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
    
    # === Plot Type Change Handler for DataFrame mode ===
    on(selected_plottype) do plottype_str
        state.misc.block_format_update[] && return
        source_type[] != "DataFrame" && return
        
        cols = selected_columns[]
        df_name = selected_dataframe[]
        (isnothing(df_name) || df_name == "" || length(cols) < 2) && return
        
        # Mark as non-default if different from DEFAULT_PLOT_TYPE
        plottype_sym = Symbol(plottype_str)
        if plottype_sym != DEFAULT_PLOT_TYPE
            state.misc.format_is_default[:plottype] = false
        end
        
        update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)
    end

    # === Legend Visibility Change Handler for DataFrame mode ===
    on(show_legend) do legend_bool
        state.misc.block_format_update[] && return
        source_type[] != "DataFrame" && return
        
        cols = selected_columns[]
        df_name = selected_dataframe[]
        (isnothing(df_name) || df_name == "" || length(cols) < 2) && return
        
        # Mark as non-default
        state.misc.format_is_default[:show_legend] = false
        
        update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)
    end

    # === Legend Title Change Handler for DataFrame mode ===
    on(legend_title_text) do leg_title
        state.misc.block_format_update[] && return
        source_type[] != "DataFrame" && return
        
        cols = selected_columns[]
        df_name = selected_dataframe[]
        (isnothing(df_name) || df_name == "" || length(cols) < 2) && return
        
        # Mark as non-default if not empty
        if !isempty(leg_title)
            state.misc.format_is_default[:legend_title] = false
        end
        
        # Skip replot if legend is not shown - title is saved for when legend becomes visible
        show_legend[] || return
        
        update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false)
    end
end

