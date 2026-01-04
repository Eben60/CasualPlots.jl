"""
    do_replot(state, outputs; data, plot_format, is_new_data=false)

Unified function for plotting and replotting, regardless of data source or update reason.

# Arguments
- `state`: Application state NamedTuple
- `outputs`: Output observables NamedTuple
- `data`: NamedTuple with either:
  - `(; x_name, y_name, range_from=nothing, range_to=nothing)` for array mode (fetches from Main)
  - `(; df, x_name, y_name)` for DataFrame mode (uses provided DataFrame)
- `plot_format`: NamedTuple with format options `(; plottype, show_legend, legend_title)`
- `is_new_data`: If true, initializes text fields from plot defaults and resets format_is_default

# Returns
- The FigureResult if successful, nothing otherwise
"""
function do_replot(state, outputs; data, plot_format, is_new_data=false, reset_semipersistent=false)
    (; current_figure, current_axis, xlabel_text, ylabel_text, title_text, legend_title_text) = state.plotting.handles
    (; show_legend) = state.plotting.format
    plot_observable = outputs.plot
    
    state.misc.block_format_update[] = true
    try
        # Reset semipersistent options if requested (e.g. via Replot button) or if new data
        if is_new_data || reset_semipersistent
            reset_semipersistent_format_options!(state)
        end

        # Create the plot based on data type
        local fig
        if haskey(data, :df)
            # DataFrame mode
            fig = create_plot(data.df; xcol=1, x_name=data.x_name, y_name=data.y_name,
                             plot_format=plot_format)
        else
            # Array mode - fetch from Main, with optional range
            range_from = get(data, :range_from, nothing)
            range_to = get(data, :range_to, nothing)
            fig = check_data_create_plot(data.x_name, data.y_name; 
                                        plot_format=plot_format, 
                                        range_from=range_from, 
                                        range_to=range_to)
        end
        
        if isnothing(fig)
            return nothing
        end
        
        current_figure[] = fig.fig
        current_axis[] = fig.axis
        
        if is_new_data
            # New data: initialize text fields with defaults from the plot
            xlabel_text[] = fig.fig_params.x_name
            ylabel_text[] = fig.fig_params.y_name
            title_text[] = fig.fig_params.title
            show_legend[] = fig.fig_params.updated_show_legend
            # Reset legend title for new data
            legend_title_text[] = ""
            # Reset format flags (preserves persistent ones like plottype)
            reset_format_defaults!(state.misc.format_is_default)
        end
        
        # Update defaults for semipersistent options if they were reset
        if is_new_data || reset_semipersistent
             # Extract and store axis limits defaults from the newly created plot
             update_axis_limits_from_axis(state, fig.axis; set_defaults=true)
        end
        
        # Publish the figure
        plot_observable[] = fig.fig
        
        # Apply custom formatting for non-default options
        apply_custom_formatting!(fig.fig, fig.axis, state)
        
        return fig
    finally
        state.misc.block_format_update[] = false
    end
end


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
            try
                x_data = getfield(Main, Symbol(x))
                first_idx = firstindex(x_data)
                last_idx = lastindex(x_data)
                data_bounds_from[] = first_idx
                data_bounds_to[] = last_idx
                range_from[] = first_idx
                range_to[] = last_idx
            catch
                data_bounds_from[] = nothing
                data_bounds_to[] = nothing
                range_from[] = nothing
                range_to[] = nothing
            end
        else
            data_bounds_from[] = nothing
            data_bounds_to[] = nothing
            range_from[] = nothing
            range_to[] = nothing
        end
    end
end

"""
    setup_source_callback(state, outputs)

Handle data source changes (X or Y selection updates).
This callback NO LONGER auto-plots on Y selection - plotting is now triggered
by the (Re-)Plot button via plot_trigger.

It only:
- Updates `current_plot_x` and `current_plot_y` for tracking
- Clears plot/table and state when selection is invalid
"""
function setup_source_callback(state, outputs)
    (; selected_x, selected_y) = state.data_selection
    (; xlabel_text, ylabel_text, title_text, current_figure, current_axis) = state.plotting.handles
    (; last_plotted_x, last_plotted_y) = state.misc
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
            # Note: actual plotting is now triggered by plot_trigger (via (Re-)Plot button)
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
            # Clear last plotted source
            last_plotted_x[] = nothing
            last_plotted_y[] = nothing
            # Clear axis limits
            clear_axis_limits(state)
        end
    end
end

"""
    setup_array_plot_trigger_callback(state, outputs, plot_trigger)

Handle (Re-)Plot button click for X,Y Array mode.
This is triggered when the user clicks the (Re-)Plot button with valid X,Y selection.
"""
function setup_array_plot_trigger_callback(state, outputs, plot_trigger)
    (; selected_x, selected_y, source_type, range_from, range_to,
       data_bounds_from, data_bounds_to) = state.data_selection
    (; selected_plottype, show_legend) = state.plotting.format
    (; legend_title_text) = state.plotting.handles
    (; last_plotted_x, last_plotted_y) = state.misc
    table_observable = outputs.table
    
    on(plot_trigger) do _
        # Skip if not in Array mode
        source_type[] != "X, Y Arrays" && return
        
        x = selected_x[]
        y = selected_y[]
        is_valid = !isnothing(y) && y != "" && !isnothing(x) && x != ""
        !is_valid && return
        
        # Get range values (use bounds as defaults)
        from_val = range_from[]
        to_val = range_to[]
        if isnothing(from_val)
            from_val = data_bounds_from[]
        end
        if isnothing(to_val)
            to_val = data_bounds_to[]
        end
        
        # Detect if this is a NEW data source (X or Y changed)
        is_new_source = (x != last_plotted_x[] || y != last_plotted_y[])
        
        plottype = selected_plottype[] |> Symbol |> eval
        do_replot(state, outputs;
            data = (; x_name = x, y_name = y, range_from = from_val, range_to = to_val),
            plot_format = (; 
                plottype = plottype, 
                show_legend = is_new_source ? nothing : show_legend[],
                legend_title = is_new_source ? "" : legend_title_text[],
            ),
            is_new_data = is_new_source,
            reset_semipersistent = true, # Requirement 16: Reset on (Re-)Plot
        )
        
        # Update last plotted source
        last_plotted_x[] = x
        last_plotted_y[] = y
        
        # Create/update table with range
        table_observable[] = create_data_table(x, y; range_from=from_val, range_to=to_val)
    end
end

"""
    setup_format_change_callbacks(state, outputs)

Handle format changes for X,Y Array mode: plottype, show_legend, legend_title_text.
All changes trigger a full replot using the unified do_replot function.
"""
function setup_format_change_callbacks(state, outputs)
    (; selected_plottype, show_legend) = state.plotting.format
    (; legend_title_text) = state.plotting.handles
    (; range_from, range_to, data_bounds_from, data_bounds_to, source_type) = state.data_selection
    current_plot_x = outputs.current_x
    current_plot_y = outputs.current_y
    
    # Helper to get current range values
    function get_range_values()
        from_val = range_from[]
        to_val = range_to[]
        if isnothing(from_val)
            from_val = data_bounds_from[]
        end
        if isnothing(to_val)
            to_val = data_bounds_to[]
        end
        return (from_val, to_val)
    end
    
    # === Plot Type Change Handler ===
    on(selected_plottype) do plottype_str
        state.misc.block_format_update[] && return
        source_type[] != "X, Y Arrays" && return
        
        x = current_plot_x[]
        y = current_plot_y[]
        (isnothing(x) || isnothing(y)) && return
        
        # Mark as non-default if different from DEFAULT_PLOT_TYPE
        plottype_sym = Symbol(plottype_str)
        if plottype_sym != DEFAULT_PLOT_TYPE
            state.misc.format_is_default[:plottype] = false
        end
        
        from_val, to_val = get_range_values()
        
        do_replot(state, outputs;
            data = (; x_name = x, y_name = y, range_from = from_val, range_to = to_val),
            plot_format = (; 
                plottype = plottype_sym |> eval,
                show_legend = show_legend[],
                legend_title = legend_title_text[],
            ),
        )
    end
    
    # === Legend Visibility Change Handler ===
    on(show_legend) do legend_bool
        state.misc.block_format_update[] && return
        source_type[] != "X, Y Arrays" && return
        
        x = current_plot_x[]
        y = current_plot_y[]
        (isnothing(x) || isnothing(y)) && return
        
        # Mark as non-default
        state.misc.format_is_default[:show_legend] = false
        
        from_val, to_val = get_range_values()
        
        do_replot(state, outputs;
            data = (; x_name = x, y_name = y, range_from = from_val, range_to = to_val),
            plot_format = (; 
                plottype = selected_plottype[] |> Symbol |> eval,
                show_legend = legend_bool,
                legend_title = legend_title_text[],
            ),
        )
    end
    
    # === Legend Title Change Handler ===
    on(legend_title_text) do leg_title
        state.misc.block_format_update[] && return
        source_type[] != "X, Y Arrays" && return
        
        x = current_plot_x[]
        y = current_plot_y[]
        (isnothing(x) || isnothing(y)) && return
        
        # Mark as non-default if not empty
        if !isempty(leg_title)
            state.misc.format_is_default[:legend_title] = false
        end
        
        # Skip replot if legend is not shown - title is saved for when legend becomes visible
        show_legend[] || return
        
        from_val, to_val = get_range_values()
        
        do_replot(state, outputs;
            data = (; x_name = x, y_name = y, range_from = from_val, range_to = to_val),
            plot_format = (; 
                plottype = selected_plottype[] |> Symbol |> eval,
                show_legend = show_legend[],
                legend_title = leg_title,
            ),
        )
    end
end



"""
    update_dataframe_plot(state, outputs, df_name, cols; is_new_data=false, update_table=false, range_from=nothing, range_to=nothing)

Helper function to update DataFrame plot with selected columns and format settings.
Handles data preparation (fetching, validation, normalization) then delegates to do_replot.

# Arguments
- `state`: Application state NamedTuple
- `outputs`: Output observables NamedTuple
- `df_name`: Name of the DataFrame
- `cols`: Selected column names
- `is_new_data`: If true, initializes text fields from plot defaults (for new plots)
- `update_table`: If true, updates the table observable (only for new plot data)
- `range_from`: Starting row index (1-based, uses 1 if nothing)
- `range_to`: Ending row index (uses nrow if nothing)
"""
function update_dataframe_plot(state, outputs, df_name, cols; 
                               is_new_data=false, update_table=false,
                               range_from::Union{Nothing,Int}=nothing, 
                               range_to::Union{Nothing,Int}=nothing,
                               reset_semipersistent::Bool=false)
    (; show_modal, modal_type) = state.dialogs
    (; selected_plottype, show_legend) = state.plotting.format
    (; legend_title_text) = state.plotting.handles
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
        
        plottype = selected_plottype[] |> Symbol |> eval
        
        # Use unified replot function
        do_replot(state, outputs;
            data = (; df = df_selected, x_name = xcol_name, y_name = y_names),
            plot_format = (;
                plottype = plottype,
                show_legend = is_new_data ? nothing : show_legend[],
                legend_title = is_new_data ? "" : legend_title_text[],
            ),
            is_new_data = is_new_data,
            reset_semipersistent = reset_semipersistent,
        )
        
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
- DataFrame selection (clears column selections, sets data bounds)
- Plot button click (triggers plot update when columns are selected)
"""
function setup_dataframe_callbacks(state, outputs, plot_trigger)
    (; source_type, selected_dataframe, selected_columns, selected_x, selected_y,
       range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
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
            state.misc.last_plotted_x[] = nothing
            state.misc.last_plotted_y[] = nothing
        # Clear DataFrame mode selections when switching to arrays
        else
            selected_dataframe[] = nothing
            selected_columns[] = String[]
            state.misc.last_plotted_dataframe[] = nothing
        end
        
        # Clear plot, table, and range bounds
        plot_observable[] = DOM.div("Plot Pane")
        table_observable[] = DOM.div("Table Pane")
        # Clear format changed flags and text fields
        reset_format_defaults!(state.misc.format_is_default)
        xlabel_text[] = ""
        ylabel_text[] = ""
        title_text[] = ""
        current_figure[] = nothing
        current_axis[] = nothing
        # Clear range bounds
        data_bounds_from[] = nothing
        data_bounds_to[] = nothing
        range_from[] = nothing
        range_to[] = nothing
        # Clear axis limits
        clear_axis_limits(state)
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
        
        # Get range values (use bounds as defaults)
        from_val = range_from[]
        to_val = range_to[]
        if isnothing(from_val)
            from_val = data_bounds_from[]
        end
        if isnothing(to_val)
            to_val = data_bounds_to[]
        end
        
        # Detect if this is a NEW data source (DataFrame changed)
        is_new_source = (df_name != state.misc.last_plotted_dataframe[])
        
        update_dataframe_plot(state, outputs, df_name, cols; 
                              is_new_data=is_new_source, update_table=true,
                              range_from=from_val, range_to=to_val,
                              reset_semipersistent=true) # Requirement 16: Reset on (Re-)Plot
        
        # Update last plotted source
        state.misc.last_plotted_dataframe[] = df_name
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
        
        update_dataframe_plot(state, outputs, df_name, cols; is_new_data=false, update_table=false)
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
        
        update_dataframe_plot(state, outputs, df_name, cols; is_new_data=false, update_table=false)
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
        
        update_dataframe_plot(state, outputs, df_name, cols; is_new_data=false, update_table=false)
    end
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

# ============================================================
# Axis Limits Callbacks
# ============================================================

"""
    extract_axis_limits(axis) -> NamedTuple

Extract current axis limits from a Makie axis.
Returns (; x_min, x_max, y_min, y_max) with Float64 values.
"""
function extract_axis_limits(axis)
    isnothing(axis) && return (; x_min=nothing, x_max=nothing, y_min=nothing, y_max=nothing)
    
    # Get the finallimits from the axis
    limits = axis.finallimits[]
    
    x_min = Float64(limits.origin[1])
    x_max = Float64(limits.origin[1] + limits.widths[1])
    y_min = Float64(limits.origin[2])
    y_max = Float64(limits.origin[2] + limits.widths[2])
    
    return (; x_min, x_max, y_min, y_max)
end

"""
    is_limit_at_default(current, default, range_span) -> Bool

Check if a limit value is approximately at its default using relative tolerance.
Formula: |current - default| / |range_span| < 5e-4
"""
function is_limit_at_default(current, default, range_span)
    (isnothing(current) || isnothing(default)) && return isnothing(current) == isnothing(default)
    (range_span == 0 || isnan(range_span)) && return false
    
    relative_error = abs(current - default) / abs(range_span)
    return relative_error < 5e-4
end

"""
    update_axis_limits_from_axis(state, axis; set_defaults=false)

Extract limits from Makie axis and update state observables.
If set_defaults=true, also updates the default limit observables.
"""
function update_axis_limits_from_axis(state, axis; set_defaults=false)
    isnothing(axis) && return
    
    limits = extract_axis_limits(axis)
    format = state.plotting.format
    format_is_default = state.misc.format_is_default
    
    if set_defaults
        # Store as defaults AND update current (for new plot)
        format.x_min_default[] = limits.x_min
        format.x_max_default[] = limits.x_max
        format.y_min_default[] = limits.y_min
        format.y_max_default[] = limits.y_max
        
        # Current values stay at nothing (auto) for new plot
        format.x_min[] = nothing
        format.x_max[] = nothing
        format.y_min[] = nothing
        format.y_max[] = nothing
        
        # Mark as default
        for key in (:x_min, :x_max, :y_min, :y_max)
            format_is_default[key] = true
        end
    else
        # Pan/zoom update - check if returning to defaults
        x_range = limits.x_max - limits.x_min
        y_range = limits.y_max - limits.y_min
        
        # Check each limit for default state
        if is_limit_at_default(limits.x_min, format.x_min_default[], x_range)
            format.x_min[] = nothing
            format_is_default[:x_min] = true
        else
            format.x_min[] = limits.x_min
            format_is_default[:x_min] = false
        end
        
        if is_limit_at_default(limits.x_max, format.x_max_default[], x_range)
            format.x_max[] = nothing
            format_is_default[:x_max] = true
        else
            format.x_max[] = limits.x_max
            format_is_default[:x_max] = false
        end
        
        if is_limit_at_default(limits.y_min, format.y_min_default[], y_range)
            format.y_min[] = nothing
            format_is_default[:y_min] = true
        else
            format.y_min[] = limits.y_min
            format_is_default[:y_min] = false
        end
        
        if is_limit_at_default(limits.y_max, format.y_max_default[], y_range)
            format.y_max[] = nothing
            format_is_default[:y_max] = true
        else
            format.y_max[] = limits.y_max
            format_is_default[:y_max] = false
        end
    end
end

"""
    clear_axis_limits(state)

Clear all axis limit values and defaults, and reset reversal checkboxes.
Called when plot is cleared.
"""
function clear_axis_limits(state)
    format = state.plotting.format
    format_is_default = state.misc.format_is_default
    
    # Clear current values
    format.x_min[] = nothing
    format.x_max[] = nothing
    format.y_min[] = nothing
    format.y_max[] = nothing
    
    # Clear defaults
    format.x_min_default[] = nothing
    format.x_max_default[] = nothing
    format.y_min_default[] = nothing
    format.y_max_default[] = nothing
    
    # Reset reversal
    format.xreversed[] = false
    format.yreversed[] = false
    
    # Mark all as default
    for key in SEMIPERSISTENT_FORMAT_OPTIONS
        format_is_default[key] = true
    end
end

"""
    setup_axis_limits_callbacks(state, outputs)

Set up callbacks for axis limit and reversal changes.
Changes are applied immediately without needing a Replot button.
"""
function setup_axis_limits_callbacks(state, outputs)
    (; x_min, x_max, y_min, y_max, xreversed, yreversed, selected_plottype, show_legend) = state.plotting.format
    (; current_axis, current_figure, legend_title_text) = state.plotting.handles
    (; source_type, selected_x, selected_y, selected_dataframe, selected_columns,
       range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
    format_is_default = state.misc.format_is_default
    
    # Helper to get current plot format
    function get_current_plot_format()
        return (;
            plottype = selected_plottype[] |> Symbol |> eval,
            show_legend = show_legend[],
            legend_title = legend_title_text[],
            x_min = x_min[],
            x_max = x_max[],
            y_min = y_min[],
            y_max = y_max[],
            xreversed = xreversed[],
            yreversed = yreversed[],
        )
    end
    
    # Helper to trigger replot
    function trigger_axis_replot()
        state.misc.block_format_update[] && return
        
        if source_type[] == "X, Y Arrays"
            x = outputs.current_x[]
            y = outputs.current_y[]
            (isnothing(x) || isnothing(y)) && return
            
            from_val = isnothing(range_from[]) ? data_bounds_from[] : range_from[]
            to_val = isnothing(range_to[]) ? data_bounds_to[] : range_to[]
            
            do_replot(state, outputs;
                data = (; x_name = x, y_name = y, range_from = from_val, range_to = to_val),
                plot_format = get_current_plot_format(),
            )
        elseif source_type[] == "DataFrame"
            df_name = selected_dataframe[]
            cols = selected_columns[]
            (isnothing(df_name) || df_name == "" || length(cols) < 2) && return
            
            update_dataframe_plot(state, outputs, df_name, cols; is_new_data=false, update_table=false)
        end
    end
    
    # === Axis Limit Change Handlers ===
    for (limit_obs, limit_key) in [(x_min, :x_min), (x_max, :x_max), (y_min, :y_min), (y_max, :y_max)]
        on(limit_obs) do val
            state.misc.block_format_update[] && return
            isnothing(current_axis[]) && return
            
            # Mark as non-default if value is set
            if !isnothing(val)
                format_is_default[limit_key] = false
            end
            
            trigger_axis_replot()
        end
    end
    
    # === Axis Reversal Change Handlers ===
    on(xreversed) do val
        state.misc.block_format_update[] && return
        isnothing(current_axis[]) && return
        
        # Mark as non-default if reversed
        format_is_default[:xreversed] = !val
        
        trigger_axis_replot()
    end
    
    on(yreversed) do val
        state.misc.block_format_update[] && return
        isnothing(current_axis[]) && return
        
        # Mark as non-default if reversed
        format_is_default[:yreversed] = !val
        
        trigger_axis_replot()
    end
end

"""
    setup_axis_limits_ui_sync(session, state)

Set up callback to sync axis limit placeholders and values to the UI.
When defaults change, updates placeholder text.
When current_axis is set (new plot), syncs defaults as placeholders.
"""
function setup_axis_limits_ui_sync(session, state)
    (; x_min_default, x_max_default, y_min_default, y_max_default) = state.plotting.format
    (; current_axis) = state.plotting.handles
    
    # Sync placeholders when defaults change (new plot created)
    onany(x_min_default, x_max_default, y_min_default, y_max_default) do xmin, xmax, ymin, ymax
        Bonito.evaljs(session, js"""
            requestAnimationFrame(() => {
                window.CasualPlots.setAxisLimitPlaceholders($xmin, $xmax, $ymin, $ymax);
            });
        """)
    end
    
    # Clear inputs when axis is cleared
    on(current_axis) do axis
        if isnothing(axis)
            Bonito.evaljs(session, js"""
                requestAnimationFrame(() => {
                    window.CasualPlots.clearAxisLimitInputs();
                });
            """)
        end
    end
    
    # Sync input field values when current limits change programmatically
    # (e.g., when reset to nothing via reset_semipersistent_format_options!)
    (; x_min, x_max, y_min, y_max) = state.plotting.format
    onany(x_min, x_max, y_min, y_max) do xmin_val, xmax_val, ymin_val, ymax_val
        Bonito.evaljs(session, js"""
            requestAnimationFrame(() => {
                window.CasualPlots.setAxisLimitInputValues($xmin_val, $xmax_val, $ymin_val, $ymax_val);
            });
        """)
    end
end

"""
    setup_axis_pan_zoom_sync(session, state)

Set up callback to sync axis limits from Makie when user pans/zooms.
Listens to axis.finallimits changes and updates observables.
Uses Observables.throttle to limit update frequency during rapid pan/zoom.
"""
function setup_axis_pan_zoom_sync(session, state)
    current_axis_ref = Ref{Union{Nothing, Any}}(nothing)
    finallimits_listener = Ref{Union{Nothing, Any}}(nothing)
    throttled_limits_ref = Ref{Union{Nothing, Any}}(nothing)
    
    on(state.plotting.handles.current_axis) do axis
        # Clean up previous listener
        if !isnothing(finallimits_listener[]) && !isnothing(throttled_limits_ref[])
            try
                Observables.off(throttled_limits_ref[], finallimits_listener[])
            catch
                # Ignore errors during cleanup
            end
        end
        
        current_axis_ref[] = axis
        
        if !isnothing(axis)
            # Create throttled observable for finallimits (100ms delay to handle rapid zoom/pan)
            # Note: Observables.throttle returns a new observable that only updates at most once per interval
            throttled_limits = Observables.throttle(0.1, axis.finallimits)
            throttled_limits_ref[] = throttled_limits
            
            # Set up listener on throttled finallimits
            finallimits_listener[] = on(throttled_limits) do limits
                # Skip if block_format_update is set (we're in a replot)
                state.misc.block_format_update[] && return
                
                # Block format callbacks during pan/zoom observable updates
                # to prevent cascade that would recreate the plot
                state.misc.block_format_update[] = true
                try
                    # Update state from axis (this handles default detection)
                    update_axis_limits_from_axis(state, axis; set_defaults=false)
                    
                    # Sync to UI - for current values (empty string if at default/nothing)
                    format = state.plotting.format
                    xmin_val = format.x_min[]
                    xmax_val = format.x_max[]
                    ymin_val = format.y_min[]
                    ymax_val = format.y_max[]
                    
                    Bonito.evaljs(session, js"""
                        requestAnimationFrame(() => {
                            window.CasualPlots.setAxisLimitInputValues($xmin_val, $xmax_val, $ymin_val, $ymax_val);
                        });
                    """)
                finally
                    state.misc.block_format_update[] = false
                end
            end
        else
            finallimits_listener[] = nothing
            throttled_limits_ref[] = nothing
        end
    end
end

