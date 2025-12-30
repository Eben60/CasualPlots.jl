"""
    setup_x_callback(dims_dict_obs, selected_x, selected_y, dropdown_y_node, plot_observable, table_observable)

Set up the listener for changes to the X-variable selection.
When `selected_x` updates:
1. Clears the current `selected_y`.
2. Resets the plot and table views.
3. Updates the Y-variable dropdown (`dropdown_y_node`) to show only variables congruent with the new X selection (based on `dims_dict_obs`).
4. Sets data bounds from the X array's firstindex/lastindex.
"""
function setup_x_callback(state, dropdown_y_node, outputs)
    (; dims_dict_obs, selected_x, selected_y, data_bounds_from, data_bounds_to, 
       range_from, range_to) = state.data_selection
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
        
        # Set data bounds from X array
        if !isnothing(x) && x != ""
            (first_idx, last_idx) = get_array_bounds(x)
            data_bounds_from[] = first_idx
            data_bounds_to[] = last_idx
            range_from[] = first_idx
            range_to[] = last_idx
        else
            data_bounds_from[] = nothing
            data_bounds_to[] = nothing
            range_from[] = nothing
            range_to[] = nothing
        end
    end
end

"""
    setup_source_callback(selected_x, selected_y, selected_plottype, show_legend, current_plot_x, current_plot_y, plot_observable, table_observable, xlabel_text, ylabel_text, title_text, current_figure, current_axis)

Handle data source changes (X or Y selection updates).
- If valid X and Y are selected:
    - Updates `current_plot_x` and `current_plot_y`.
    - Auto-plots with full range (range values are already set from X selection).
- If selection is invalid/incomplete:
    - Clears the plot and table views.
    - Resets internal state and text fields.
"""
function setup_source_callback(state, outputs)
    
    (; selected_x, selected_y, range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
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
            
            # Get range values (use bounds as defaults)
            from_val = range_from[]
            to_val = range_to[]
            if isnothing(from_val)
                from_val = data_bounds_from[]
            end
            if isnothing(to_val)
                to_val = data_bounds_to[]
            end
            
            # Block format callback to prevent double plotting and ensure atomic update
            state.misc.block_format_update[] = true
            
            try
                # Reset legend title for new plot
                legend_title_text[] = ""

                plottype = selected_plottype[] |> Symbol |> eval
                fig = check_data_create_plot(x, y; 
                    plot_format = (;plottype=plottype, show_legend=nothing, legend_title=legend_title_text[]),
                    range_from=from_val, range_to=to_val)
                
                if !isnothing(fig)
                    plot_observable[] = fig.fig
                    current_figure[] = fig.fig  # Store figure reference
                    current_axis[] = fig.axis    # Store axis reference
                    
                    # Initialize axis limits from the new plot (set_defaults=true for new plot)
                    update_axis_limits_from_axis(state, fig.axis; set_defaults=true)
                    
                    # Initialize text fields with default values
                    xlabel_text[] = fig.fig_params.x_name
                    ylabel_text[] = fig.fig_params.y_name
                    title_text[] = fig.fig_params.title
                    show_legend[] = fig.fig_params.updated_show_legend
                end
            finally
                state.misc.block_format_update[] = false
            end
            
            # Create/update table with range
            table_observable[] = create_data_table(x, y; range_from=from_val, range_to=to_val)
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
            clear_axis_limits(state)
        end
    end
end

"""
    setup_replot_callback(state, outputs)

Handle the Replot button click from the Format tab.
Triggers a replot using the currently stored data with the new format settings (plot type, legend, labels, title, axis limits).
Updates the `plot_observable` but does *not* regenerate the data table or reload data.
This is explicitly triggered by the user clicking the Replot button.
"""
function setup_replot_callback(state, outputs)
    (; selected_plottype, show_legend, x_min, x_max, y_min, y_max) = state.plotting.format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = state.plotting.handles
    (; source_type, selected_dataframe, selected_columns, range_from, range_to) = state.data_selection
    (; replot_trigger) = state.misc
    current_plot_x = outputs.current_x
    current_plot_y = outputs.current_y
    plot_observable = outputs.plot

    on(replot_trigger) do _
        # Check which mode we're in and handle accordingly
        if source_type[] == "DataFrame"
            # DataFrame mode - use the helper function with axis limits
            cols = selected_columns[]
            df_name = selected_dataframe[]
            
            # Need valid DataFrame and column selections to replot
            if isnothing(df_name) || df_name == "" || length(cols) < 2
                return
            end
            
            # Use helper function with reset_legend_title=false and update_table=false for format changes
            # Axis limits are now passed through to update_dataframe_plot
            update_dataframe_plot(state, outputs, df_name, cols; 
                                  reset_legend_title=false, update_table=false,
                                  range_from=range_from[], range_to=range_to[],
                                  apply_limits=true)  # New flag to apply axis limits
        else
            # X,Y Arrays mode
            x = current_plot_x[]
            y = current_plot_y[]
            
            # Only replot if we have valid data
            if isnothing(x) || isnothing(y)
                return
            end
            
            # Capture current label values BEFORE creating new plot
            saved_xlabel = xlabel_text[]
            saved_ylabel = ylabel_text[]
            saved_title = title_text[]
            
            # Get current range values
            from_val = range_from[]
            to_val = range_to[]
            
            # Block label callbacks during plot recreation
            state.misc.block_format_update[] = true
            try
                plottype = selected_plottype[] |> Symbol |> eval
                # Pass all format settings including axis limits through plot_format
                # so they're baked into the plot during creation
                fig = check_data_create_plot(x, y; plot_format = (; 
                    plottype=plottype, 
                    show_legend=show_legend[], 
                    legend_title=legend_title_text[],
                    xlabel=saved_xlabel,
                    ylabel=saved_ylabel,
                    title=saved_title,
                    x_min=x_min[],  # Pass axis limits
                    x_max=x_max[],
                    y_min=y_min[],
                    y_max=y_max[]
                ), range_from=from_val, range_to=to_val)
                if !isnothing(fig)
                    current_figure[] = fig.fig
                    current_axis[] = fig.axis
                    
                    # Now publish the figure
                    plot_observable[] = fig.fig
                    # Force complete render
                    show(IOBuffer(), MIME"text/html"(), fig.fig)
                    plot_observable[] = plot_observable[]
                    # Axis limits are already applied during plot creation - no need for post-hoc application
                end
            finally
                state.misc.block_format_update[] = false
            end
            
            # UNBLOCKED Force Notify:
            # Update text observables AFTER unblocking.
            if !isempty(saved_xlabel)
                xlabel_text[] = ""
                xlabel_text[] = saved_xlabel
            end
            if !isempty(saved_ylabel)
                ylabel_text[] = ""
                ylabel_text[] = saved_ylabel
            end
            if !isempty(saved_title)
                title_text[] = ""
                title_text[] = saved_title
            end
        end
        # Note: Table is NOT updated - it's source-dependent only
    end
end

"""
    apply_axis_limits_from_state(state)

Apply axis limits from state observables to the current axis.
Called by setup_replot_callback when the Replot button is clicked.

Note: After applying limits via xlims!/ylims!, we must notify the tick observables
to force WGLMakie to refresh the grid lines and tick labels. This is a workaround
for a WGLMakie rendering issue where data points rescale correctly but axis
decorations remain stuck at their previous positions.
"""
function apply_axis_limits_from_state(state)
    (; x_min, x_max, y_min, y_max) = state.plotting.format
    (; current_axis) = state.plotting.handles
    
    axis = current_axis[]
    isnothing(axis) && return
    
    xmin_val = x_min[]
    xmax_val = x_max[]
    ymin_val = y_min[]
    ymax_val = y_max[]
    
    # Don't apply if min == max (user may be swapping)
    x_valid = !isnothing(xmin_val) && !isnothing(xmax_val) && xmin_val != xmax_val
    y_valid = !isnothing(ymin_val) && !isnothing(ymax_val) && ymin_val != ymax_val
    
    try
        if x_valid
            Makie.xlims!(axis, xmin_val, xmax_val)
        end
        if y_valid
            Makie.ylims!(axis, ymin_val, ymax_val)
        end
        
        # Workaround for WGLMakie: notify tick observables to force grid/tick refresh
        # Without this, data points rescale correctly but grid lines and tick labels
        # remain stuck at their previous positions
        if x_valid || y_valid
            notify(axis.xticks)
            notify(axis.yticks)
        end
    catch e
        @warn "Failed to apply axis limits" exception=e
    end
end

"""
    update_dataframe_plot(state, outputs, df_name, cols; reset_legend_title=false, update_table=false, range_from=nothing, range_to=nothing, apply_limits=false)

Helper function to update DataFrame plot with selected columns and format settings.
Handles the common plotting logic used by both plot trigger and format callbacks.

# Arguments
- `state`: Application state NamedTuple
- `outputs`: Output observables NamedTuple
- `df_name`: Name of the DataFrame
- `cols`: Selected column names
- `reset_legend_title`: If true, resets legend title to empty string (for new plots)
- `update_table`: If true, updates the table observable (only for new plot data)
- `range_from`: Starting row index (1-based for DataFrames)
- `range_to`: Ending row index
- `apply_limits`: If true, applies current axis limits from state (for Replot button)
"""
function update_dataframe_plot(state, outputs, df_name, cols; 
                               reset_legend_title=false, update_table=false,
                               range_from::Union{Nothing,Int}=nothing, 
                               range_to::Union{Nothing,Int}=nothing,
                               apply_limits::Bool=false)
    (; format, handles) = state.plotting
    (; show_modal, modal_type) = state.dialogs
    (; selected_plottype, show_legend) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = handles
    plot_observable = outputs.plot
    table_observable = outputs.table
    
    # Capture current label values BEFORE any updates (for format changes)
    saved_xlabel = xlabel_text[]
    saved_ylabel = ylabel_text[]
    saved_title = title_text[]
    
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
        
        # Apply range slicing if provided
        n_rows = nrow(df_selected)
        from_idx = isnothing(range_from) ? 1 : clamp(range_from, 1, n_rows)
        to_idx = isnothing(range_to) ? n_rows : clamp(range_to, 1, n_rows)
        
        # Ensure from <= to
        if from_idx > to_idx
            from_idx, to_idx = to_idx, from_idx
        end
        
        # Slice the DataFrame
        df_selected = df_selected[from_idx:to_idx, :]
        
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
        
        # Reset legend title if requested (for new plots)
        if reset_legend_title
            legend_title_text[] = ""
        end
        
        # Block label callbacks during plot recreation
        state.misc.block_format_update[] = true
        
        plottype = selected_plottype[] |> Symbol |> eval
        # Use xcol=1 since df_selected has X as first column
        legend_setting = reset_legend_title ? nothing : show_legend[]
        # For format changes, pass saved labels through plot_format
        xlabel_setting = reset_legend_title ? nothing : saved_xlabel
        ylabel_setting = reset_legend_title ? nothing : saved_ylabel
        title_setting = reset_legend_title ? nothing : saved_title
        
        # Build plot_format - include axis limits if apply_limits is true
        plot_format = if apply_limits
            (; x_min, x_max, y_min, y_max) = format
            (; 
                plottype=plottype, 
                show_legend=legend_setting, 
                legend_title=legend_title_text[],
                xlabel=xlabel_setting,
                ylabel=ylabel_setting,
                title=title_setting,
                x_min=x_min[],
                x_max=x_max[],
                y_min=y_min[],
                y_max=y_max[]
            )
        else
            (; 
                plottype=plottype, 
                show_legend=legend_setting, 
                legend_title=legend_title_text[],
                xlabel=xlabel_setting,
                ylabel=ylabel_setting,
                title=title_setting
            )
        end
        
        fig = create_plot(df_selected; xcol=1, x_name=xcol_name, y_name=y_names, plot_format)
        
        if !isnothing(fig)
            current_figure[] = fig.fig
            current_axis[] = fig.axis
            
            if reset_legend_title
                # New plot: initialize axis limits (set_defaults=true)
                update_axis_limits_from_axis(state, fig.axis; set_defaults=true)
                
                # New plot: publish figure first, then initialize text fields
                plot_observable[] = fig.fig
                xlabel_text[] = fig.fig_params.x_name
                ylabel_text[] = fig.fig_params.y_name
                title_text[] = fig.fig_params.title
                show_legend[] = fig.fig_params.updated_show_legend
            else
                # Format change: labels and title were already set via plot_format
                # Now publish the figure
                plot_observable[] = fig.fig
                # Force complete render
                show(IOBuffer(), MIME"text/html"(), fig.fig)
                plot_observable[] = plot_observable[]
            end
        end
        
        state.misc.block_format_update[] = false
        
        # UNBLOCKED Force Notify:
        # Update text observables AFTER unblocking.
        # This triggers the label update listener, which checks if the axis matches.
        # If the axis label was lost, the listener re-applies it and refreshes.
        if !reset_legend_title
             if !isempty(saved_xlabel)
                xlabel_text[] = "" # Force change
                xlabel_text[] = saved_xlabel # Trigger listener
            end
            if !isempty(saved_ylabel)
                ylabel_text[] = ""
                ylabel_text[] = saved_ylabel
            end
            if !isempty(saved_title)
                title_text[] = ""
                title_text[] = saved_title
            end
        end
        
        # Update table if requested (only for new plot data)
        if update_table
            # Build table info with range info
            if from_idx == 1 && to_idx == n_rows
                info_text = display_name
            else
                info_text = "$display_name [$(from_idx):$(to_idx)]"
            end
            
            # Add Index column to df_selected for display
            df_with_index = copy(df_selected)
            insertcols!(df_with_index, 1, :Index => from_idx:to_idx)
            
            table_observable[] = create_table_with_info(Bonito.Table(df_with_index), info_text)
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
    (; source_type, selected_dataframe, selected_columns, selected_x, selected_y,
       data_bounds_from, data_bounds_to, range_from, range_to) = state.data_selection
    (; format, handles) = state.plotting
    (; selected_plottype, show_legend) = format
    (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis) = handles
    (; opened_file_df) = state.file_opening
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
        
        # Clear plot, table, and bounds
        plot_observable[] = DOM.div("Plot Pane")
        table_observable[] = DOM.div("Table Pane")
        xlabel_text[] = ""
        ylabel_text[] = ""
        title_text[] = ""
        current_figure[] = nothing
        current_axis[] = nothing
        clear_axis_limits(state)
        data_bounds_from[] = nothing
        data_bounds_to[] = nothing
        range_from[] = nothing
        range_to[] = nothing
    end
    
    # When DataFrame selection changes, clear column selections and set bounds
    on(selected_dataframe) do df_name
        selected_columns[] = String[]
        plot_observable[] = DOM.div("Plot Pane")
        table_observable[] = DOM.div("Table Pane")
        
        # Set data bounds for the DataFrame
        if !isnothing(df_name) && df_name != ""
            (first_idx, last_idx) = get_dataframe_bounds(df_name, opened_file_df[])
            data_bounds_from[] = first_idx
            data_bounds_to[] = last_idx
            range_from[] = first_idx
            range_to[] = last_idx
        else
            data_bounds_from[] = nothing
            data_bounds_to[] = nothing
            range_from[] = nothing
            range_to[] = nothing
        end
    end
    
    # When Plot button is clicked, create plot if valid selection
    on(plot_trigger) do _
        if source_type[] == "DataFrame"
            # DataFrame mode
            cols = selected_columns[]
            df_name = selected_dataframe[]
            if isnothing(df_name) || df_name == "" || length(cols) < 2
                # Need at least 2 columns (X and Y)
                plot_observable[] = DOM.div("Select at least 2 columns (first = X, others = Y)")
                table_observable[] = DOM.div("Table Pane")
                return
            end
            
            # Validate and apply range
            from_val = range_from[]
            to_val = range_to[]
            bounds_from = data_bounds_from[]
            bounds_to = data_bounds_to[]
            
            # Fill in defaults for empty values
            if isnothing(from_val) && !isnothing(bounds_from)
                from_val = bounds_from
                range_from[] = from_val
            end
            if isnothing(to_val) && !isnothing(bounds_to)
                to_val = bounds_to
                range_to[] = to_val
            end
            
            # Validate from <= to (don't swap, just reject)
            if !isnothing(from_val) && !isnothing(to_val) && from_val > to_val
                plot_observable[] = DOM.div("Range Error: \"Range from\" must be less than or equal to \"Range to\"")
                return
            end
            
            # Use helper function with range values
            update_dataframe_plot(state, outputs, df_name, cols; 
                                  reset_legend_title=true, update_table=true,
                                  range_from=from_val, range_to=to_val)
        else
            # Array mode
            x = outputs.current_x[]
            y = outputs.current_y[]
            
            if isnothing(x) || x == "" || isnothing(y) || y == ""
                plot_observable[] = DOM.div("Select X and Y arrays to plot")
                return
            end
            
            # Get range values (already validated by JavaScript on input)
            from_val = range_from[]
            to_val = range_to[]
            bounds_from = data_bounds_from[]
            bounds_to = data_bounds_to[]
            
            # Fill in defaults for empty values
            if isnothing(from_val) && !isnothing(bounds_from)
                from_val = bounds_from
                range_from[] = from_val
            end
            if isnothing(to_val) && !isnothing(bounds_to)
                to_val = bounds_to
                range_to[] = to_val
            end
            
            # Validate from <= to (don't swap, just reject)
            if !isnothing(from_val) && !isnothing(to_val) && from_val > to_val
                plot_observable[] = DOM.div("Range Error: \"Range from\" must be less than or equal to \"Range to\"")
                return
            end
            
            # Block format callback to prevent double plotting
            state.misc.block_format_update[] = true
            
            try
                # Reset legend title for new plot
                legend_title_text[] = ""

                plottype = selected_plottype[] |> Symbol |> eval
                fig = check_data_create_plot(x, y; 
                    plot_format = (;plottype=plottype, show_legend=nothing, legend_title=legend_title_text[]),
                    range_from=from_val, range_to=to_val)
                
                if !isnothing(fig)
                    plot_observable[] = fig.fig
                    current_figure[] = fig.fig
                    current_axis[] = fig.axis
                    
                    # Initialize axis limits from the new plot (set_defaults=true for new plot)
                    update_axis_limits_from_axis(state, fig.axis; set_defaults=true)
                    
                    # Initialize text fields with default values
                    xlabel_text[] = fig.fig_params.x_name
                    ylabel_text[] = fig.fig_params.y_name
                    title_text[] = fig.fig_params.title
                    show_legend[] = fig.fig_params.updated_show_legend
                end
            finally
                state.misc.block_format_update[] = false
            end
            
            # Create/update table with range
            table_observable[] = create_data_table(x, y; range_from=from_val, range_to=to_val)
        end
    end
    
    # Note: Format changes (plot type, legend, labels) are now handled by setup_replot_callback
    # which is triggered by the Replot button in the Format tab
end

"""
    setup_range_ui_sync(session, state)

Set up a callback to sync range input field values with data bounds.
When data_bounds_from or data_bounds_to changes, updates the HTML input fields
with the new values. Uses requestAnimationFrame to ensure DOM is ready.
"""
function setup_range_ui_sync(session, state)
    (; data_bounds_from, data_bounds_to) = state.data_selection
    
    onany(data_bounds_from, data_bounds_to) do from_val, to_val
        # Update the input fields via JavaScript with a slight delay to ensure DOM is ready
        # Pass actual values (or nothing/null) - Bonito handles the conversion
        from_js = isnothing(from_val) ? nothing : from_val
        to_js = isnothing(to_val) ? nothing : to_val
        # Use requestAnimationFrame to ensure DOM updates are complete
        Bonito.evaljs(session, js"""
            requestAnimationFrame(() => {
                window.CasualPlots.setRangeInputValues($from_js, $to_js);
            });
        """)
    end
end

"""
    clear_axis_limits(state)

Clear all axis limit observables (current and defaults) to nothing.
Called when plot is cleared.
"""
function clear_axis_limits(state)
    (; x_min, x_max, y_min, y_max,
       x_min_default, x_max_default, y_min_default, y_max_default) = state.plotting.format
    x_min[] = nothing
    x_max[] = nothing
    y_min[] = nothing
    y_max[] = nothing
    x_min_default[] = nothing
    x_max_default[] = nothing
    y_min_default[] = nothing
    y_max_default[] = nothing
end

"""
    extract_axis_limits(axis)

Extract the current axis limits from a Makie Axis.
Returns a NamedTuple with (x_min, x_max, y_min, y_max) as Float64 values.
"""
function extract_axis_limits(axis)
    rect = axis.finallimits[]
    x_min = Float64(rect.origin[1])
    y_min = Float64(rect.origin[2])
    x_max = Float64(rect.origin[1] + rect.widths[1])
    y_max = Float64(rect.origin[2] + rect.widths[2])
    return (; x_min, x_max, y_min, y_max)
end

"""
    update_axis_limits_from_axis(state, axis; set_defaults=false)

Update the axis limit observables from the current axis state.
If set_defaults=true, also updates the default limit values (used for reset).
"""
function update_axis_limits_from_axis(state, axis; set_defaults=false)
    isnothing(axis) && return
    
    (; x_min, x_max, y_min, y_max, 
       x_min_default, x_max_default, y_min_default, y_max_default) = state.plotting.format
    
    limits = extract_axis_limits(axis)
    
    # Update current limits
    x_min[] = limits.x_min
    x_max[] = limits.x_max
    y_min[] = limits.y_min
    y_max[] = limits.y_max
    
    # Update defaults if requested (typically on plot creation)
    if set_defaults
        x_min_default[] = limits.x_min
        x_max_default[] = limits.x_max
        y_min_default[] = limits.y_min
        y_max_default[] = limits.y_max
    end
end

"""
    setup_axis_limits_sync(session, state)

Set up synchronization of axis limit input fields in the UI.
Updates the input values when the limit observables change.
Uses onany with all four limits to batch updates.
"""
function setup_axis_limits_sync(session, state)
    (; x_min, x_max, y_min, y_max) = state.plotting.format
    
    onany(x_min, x_max, y_min, y_max) do xmin, xmax, ymin, ymax
        # Convert nothing to null for JavaScript
        xmin_js = isnothing(xmin) ? nothing : xmin
        xmax_js = isnothing(xmax) ? nothing : xmax
        ymin_js = isnothing(ymin) ? nothing : ymin
        ymax_js = isnothing(ymax) ? nothing : ymax
        
        Bonito.evaljs(session, js"""
            requestAnimationFrame(() => {
                window.CasualPlots.setAxisLimitInputValues($xmin_js, $xmax_js, $ymin_js, $ymax_js);
            });
        """)
    end
end

"""
    setup_axis_finallimits_listener(state)

Set up a listener on the axis.finallimits observable to update limit observables
when the user zooms or pans. Uses Observables.throttle to limit update frequency.
"""
function setup_axis_finallimits_listener(state)
    (; current_axis) = state.plotting.handles
    (; x_min, x_max, y_min, y_max) = state.plotting.format
    (; block_format_update) = state.misc
    
    # Keep track of the current listener to clean it up when axis changes
    current_listener = Ref{Union{Nothing, Observables.ObserverFunction}}(nothing)
    
    on(current_axis) do axis
        # Clean up previous listener
        if !isnothing(current_listener[])
            Observables.off(current_listener[])
            current_listener[] = nothing
        end
        
        isnothing(axis) && return
        
        # Create throttled observable for finallimits (100ms delay to handle rapid zoom/pan)
        # Note: Observables.throttle returns a new observable that only updates at most once per interval
        throttled_limits = Observables.throttle(0.1, axis.finallimits)
        
        # Listen to throttled finallimits changes
        current_listener[] = on(throttled_limits) do rect
            # Don't update during format changes (when we're setting limits programmatically)
            block_format_update[] && return
            
            # Extract limits from Rect2
            new_x_min = Float64(rect.origin[1])
            new_y_min = Float64(rect.origin[2])
            new_x_max = Float64(rect.origin[1] + rect.widths[1])
            new_y_max = Float64(rect.origin[2] + rect.widths[2])
            
            # Update observables (this will trigger UI sync via setup_axis_limits_sync)
            x_min[] = new_x_min
            x_max[] = new_x_max
            y_min[] = new_y_min
            y_max[] = new_y_max
        end
    end
end

"""
    setup_axis_limits_input_callbacks(state)

Set up callbacks to handle user-entered axis limit observables.
Handles only the reset-to-default logic when a value is cleared (set to nothing).
The actual application of limits to the axis is done by setup_replot_callback when
the Replot button is clicked.
"""
function setup_axis_limits_input_callbacks(state)
    (; x_min, x_max, y_min, y_max,
       x_min_default, x_max_default, y_min_default, y_max_default) = state.plotting.format
    (; block_format_update) = state.misc
    
    # Watch for cleared X limits and reset to defaults
    onany(x_min, x_max) do xmin, xmax
        block_format_update[] && return
        
        # Reset to default if cleared
        if isnothing(xmin) && !isnothing(x_min_default[])
            x_min[] = x_min_default[]
        end
        if isnothing(xmax) && !isnothing(x_max_default[])
            x_max[] = x_max_default[]
        end
        # Note: Actual axis limit application is done via Replot button
    end
    
    # Watch for cleared Y limits and reset to defaults
    onany(y_min, y_max) do ymin, ymax
        block_format_update[] && return
        
        # Reset to default if cleared
        if isnothing(ymin) && !isnothing(y_min_default[])
            y_min[] = y_min_default[]
        end
        if isnothing(ymax) && !isnothing(y_max_default[])
            y_max[] = y_max_default[]
        end
        # Note: Actual axis limit application is done via Replot button
    end
end

