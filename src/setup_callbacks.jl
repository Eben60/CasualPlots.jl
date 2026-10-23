"""
    get_current_axis_limits(state::CasualPlotsState) -> NamedTuple

Get the current axis limits from state for use in plot_format.
Returns a NamedTuple with `x_min`, `x_max`, `y_min`, `y_max`, `xreversed`, `yreversed`.
"""
function get_current_axis_limits(state)
    format = state.plotting.format
    return (;
        x_min = format.x_min[],
        x_max = format.x_max[],
        y_min = format.y_min[],
        y_max = format.y_max[],
        xreversed = format.xreversed[],
        yreversed = format.yreversed[],
        xlog = format.xlog[],
        ylog = format.ylog[],
    )
end

"""
    do_replot(
        state::CasualPlotsState,
        outputs::OutputObservables;
        data::NamedTuple,
        plot_format::NamedTuple,
        is_new_data::Bool=false,
        reset_semipersistent::Bool=false,
    ) -> Union{NamedTuple, Nothing}

Unified function for plotting and replotting, regardless of data source or update reason.

# Arguments
- `state::CasualPlotsState`: Application state struct `CasualPlotsState`.
- `outputs::OutputObservables`: Output observables struct `OutputObservables`.

# Keyword Arguments
- `data::NamedTuple`: Data specification containing `(; df, x_name, y_name)`.
- `plot_format::NamedTuple`: Format options (e.g., `plottype`, `show_legend`, dynamic attributes, and axis limits).
- `is_new_data::Bool`: If `true`, initializes text fields from plot defaults and resets format defaults. Defaults to `false`.
- `reset_semipersistent::Bool`: If `true`, resets semipersistent format options (such as axis limits) to defaults. Defaults to `false`.

# Returns
- `NamedTuple`: The plot result `(; fig, axis, fig_params)` if successful.
- `Nothing`: If plot creation failed or returned `nothing`.
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

        # Create the plot
        # data always has (; df, x_name, y_name)
        dfw = data.df
        x_name = data.x_name
        y_name = data.y_name
        
        ys = names(dfw)[2:end]
        n_cols = length(ys)
        
        # Handle show_legend logic
        format_show_legend = plot_format.show_legend
        updated_show_legend = isnothing(format_show_legend) ? (n_cols > 1) : format_show_legend
        plot_format = merge(plot_format, (; show_legend=updated_show_legend))
        
        df_long = stack(dfw, ys; variable_name=:group, value_name=:y)
        
        x_col = names(dfw)[1] |> Symbol
        mappings = (; x_col, y_col=:y, group_col=:group)
        
        raw_size = state.plotting.handles.plot_size[]
        sz_tuple = (Int(raw_size[1]), Int(raw_size[2]))
        
        fig = create_plot_df_long(df_long, x_name, y_name, plot_format; mappings, plot_size=sz_tuple)
        
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
        else
            # Not new data (e.g. format change). Update text fields that are still at their default values
            if state.misc.format_is_default[:xlabel]
                xlabel_text[] = fig.fig_params.x_name
            end
            if state.misc.format_is_default[:ylabel]
                ylabel_text[] = fig.fig_params.y_name
            end
            if state.misc.format_is_default[:title]
                title_text[] = fig.fig_params.title
            end
            if state.misc.format_is_default[:show_legend]
                show_legend[] = fig.fig_params.updated_show_legend
            end
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
    apply_theme!(theme_name::String)

Apply the specified Makie theme globally.

# Theme Types:
- `"Makie default"` - Resets to the default Makie theme
- `"AoG default"` - Sets the AlgebraOfGraphics theme using `set_aog_theme!()`
- `"theme_*"` - Uses the corresponding Makie theme function (e.g., `theme_dark()`)
"""
function apply_theme!(state, theme_name)
    if theme_name == "Makie default"
        # Reset to Makie's default theme - use empty theme or merge
        set_theme!()
    elseif theme_name == "AoG default"
        set_aog_theme!()
    elseif startswith(theme_name, "theme_")
        # Evaluate and call the theme function (e.g., theme_dark())
        theme_fn = theme_name |> Symbol |> eval
        set_theme!(theme_fn())
    else
        msg = "Unknown theme: $theme_name"
        @warn msg
        show_modal!(state, msg; type=:warning)
    end
end

"""
    setup_theme_callback(state, outputs)

Set up callback for theme changes. When the theme selection changes:
1. Applies the new theme globally
2. Triggers replot with current data (if any plot exists)

Note: This callback does NOT check for block_format_update since theme changes
are considered independent from other format changes.
"""
function setup_theme_callback(state, outputs)
    (; selected_theme, selected_plottype, show_legend) = state.plotting.format
    (; legend_title_text, current_figure) = state.plotting.handles
    (; source_type, selected_x, selected_y, selected_dataframe, selected_columns,
       range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
    current_plot_x = outputs.current_x
    current_plot_y = outputs.current_y
    
    on(selected_theme) do theme_name
        # Apply the new theme globally
        apply_theme!(state, theme_name)
        
        # Mark as non-default if different from DEFAULT_THEME
        if theme_name != DEFAULT_THEME
            state.misc.format_is_default[:theme] = false
        end
        
        # If no plot exists, nothing more to do
        isnothing(current_figure[]) && return
        
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
        
        replot_from_cache!(state, outputs)
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
        try
        # println("selected x: $x")
        selected_y[] = nothing

        dims_dict = dims_dict_obs[]
        new_y_opts_strings = get_congruent_y_names(x, dims_dict)
        
        if isempty(new_y_opts_strings)
            dropdown_y_node[] = create_dropdown([], nothing; placeholder="No congruent Y-arrays for this X", disabled=true, id="dropdown-y")
        else
            # println("trying to set Y menu to $new_y_opts_strings")
            dropdown_y_node[] = create_dropdown(new_y_opts_strings, selected_y; placeholder="Select Y", id="dropdown-y")
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
        catch e
            bt = catch_backtrace()
            show_modal!(state, "Error in X selection: " * sprint(showerror, e); type=:error, exception=(e, bt))
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
        try
        is_valid = !isnothing(y) && y != "" && !isnothing(x) && x != ""
        
        if is_valid
            # Store current data for format callbacks
            current_plot_x[] = x
            current_plot_y[] = y
            state.misc.source_signature[] = capture_signature(:array, x, y)
            # Note: actual plotting is now triggered by plot_trigger (via (Re-)Plot button)
        else
            # Clear everything except table (handled by refresh_table!)
            current_plot_x[] = nothing
            current_plot_y[] = nothing
            state.misc.source_signature[] = nothing
            state.misc.cached_cleaned_df[] = nothing
            state.misc.cached_cols[] = String[]
            state.misc.cached_xcol_name[] = nothing
            state.misc.cached_y_names[] = nothing
            plot_observable[] = DOM.div("Plot Pane")
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
        catch e
            bt = catch_backtrace()
            show_modal!(state, "Error in source selection: " * sprint(showerror, e); type=:error, exception=(e, bt))
        end
    end
end

"""
    show_loading_indicator(outputs::Outputs) -> Nothing

Displays a loading message with a time tag in the Plot pane and yields to the Bonito server.
"""
function show_loading_indicator(outputs)
    time_tag = Dates.format(Dates.now(), "HH:MM:SS")
    outputs.plot[] = DOM.div(
        "[$time_tag] Your Plot is being processed. Please be patient...", 
        style="display: flex; justify-content: center; align-items: center; height: 100%; font-size: 1.2rem; color: var(--text-color, #333);"
    )
    sleep(0.02)
    return nothing
end

"""
    acquire_source(state; override_cols=nothing) -> Union{NamedTuple, Nothing}

Fetch fresh data source from Main or opened file based on active selection.
Returns `(; df, display_name, valid_cols, is_array_mode)`.
Throws `DataContinuityError` if variables are missing or invalid.
"""
function acquire_source(state; override_cols=nothing)
    source_type = state.data_selection.source_type[]
    is_array_mode = source_type == "X, Y Arrays"

    if is_array_mode
        x = state.data_selection.selected_x[]
        y = state.data_selection.selected_y[]
        if isnothing(x) || isempty(x) || isnothing(y) || isempty(y)
            return nothing
        end

        if !isdefined(Main, Symbol(x))
            throw(DataContinuityError("Variable \"$x\" is no longer defined in Main."))
        end
        if !isdefined(Main, Symbol(y))
            throw(DataContinuityError("Variable \"$y\" is no longer defined in Main."))
        end

        x_data = getfield(Main, Symbol(x))
        y_data = getfield(Main, Symbol(y))

        if !(x_data isa AbstractArray) || !(y_data isa AbstractArray)
            throw(DataContinuityError("X or Y variable is not an array."))
        end

        if y_data isa AbstractVector
            y_data = reshape(y_data, :, 1)
        end

        n_cols = size(y_data, 2)
        ys = n_cols == 1 ? [String(y)] : ["$(y)_$n" for n in 1:n_cols]
        valid_cols = vcat(String(x), ys)
        df = DataFrame()
        df[!, String(x)] = x_data
        for i in 1:n_cols
            df[!, ys[i]] = y_data[:, i]
        end
        display_name = "$(y) vs $(x)"
        return (; df=df, display_name=display_name, valid_cols=valid_cols, is_array_mode=true)
    else
        cols = isnothing(override_cols) ? state.data_selection.selected_columns[] : override_cols
        df_name = state.data_selection.selected_dataframe[]
        if isnothing(df_name) || isempty(df_name) || length(cols) < 2
            return nothing
        end

        if df_name == "__opened_file__"
            df = state.file_opening.opened_file_df[]
            display_name = state.file_opening.opened_file_name[]
            if isnothing(df)
                throw(DataContinuityError("No file has been opened. Use the Open tab to load a file."))
            end
        else
            if !isdefined(Main, Symbol(df_name))
                throw(DataContinuityError("Variable \"$df_name\" is no longer defined in Main."))
            end
            df = get_source_as_dataframe(df_name, state.file_opening.opened_file_df[])
            if isnothing(df)
                throw(DataContinuityError("Variable \"$df_name\" is neither a DataFrame nor a Matrix."))
            end
            display_name = df_name
        end

        available_columns = names(df)
        valid_cols = filter(col -> col in available_columns, cols)

        if length(valid_cols) < 2
            throw(DataContinuityError("Selected columns not found in DataFrame $(display_name). Available columns: $(join(available_columns, ", "))"))
        end

        return (; df=df, display_name=display_name, valid_cols=valid_cols, is_array_mode=false)
    end
end

"""
    prepare_plot_data!(state, acquire; range_from=nothing, range_to=nothing) -> NamedTuple

Applies row slicing, cleansing (`clean_plot_data!`), categorical detection, and caches the cleaned data.
Returns `(; df_selected, xcol_name, y_names)`.
"""
function prepare_plot_data!(state, acquire; range_from=nothing, range_to=nothing)
    (; df, display_name, valid_cols, is_array_mode) = acquire
    cache = state.misc

    # Slicing
    df_selected = select(df, valid_cols)
    n_rows = nrow(df_selected)
    from_idx = isnothing(range_from) ? 1 : clamp(range_from, 1, max(1, n_rows))
    to_idx = isnothing(range_to) ? n_rows : clamp(range_to, 1, max(1, n_rows))
    df_selected = df_selected[from_idx:to_idx, :]

    # Clean data for plotting
    df_selected = clean_plot_data!(df_selected, valid_cols, state)

    # First column is X, rest are Y
    xcol_name = valid_cols[1]
    if is_array_mode
        y_names = state.data_selection.selected_y[]
    else
        y_names = length(valid_cols) > 2 ? display_name : valid_cols[2]
    end

    # Check for categorical data to disable numeric-only UI controls
    T_x = nonmissingtype(eltype(df_selected[!, xcol_name]))
    x_is_cat = !(T_x <: Union{Real, Unitful.Quantity})
    state.plotting.format.x_is_categorical[] = x_is_cat

    if length(valid_cols) > 1
        T_y = nonmissingtype(eltype(df_selected[!, valid_cols[2]]))
        y_is_cat = !(T_y <: Union{Real, Unitful.Quantity})
    else
        y_is_cat = false
    end
    state.plotting.format.y_is_categorical[] = y_is_cat

    # Update cache
    cache.cached_cleaned_df[] = df_selected
    cache.cached_cols[] = copy(valid_cols)
    cache.cached_xcol_name[] = xcol_name
    cache.cached_y_names[] = y_names

    return (; df_selected=df_selected, xcol_name=xcol_name, y_names=y_names)
end

"""
    replot_from_cache!(state, outputs; is_new_data=false, reset_semipersistent=false, catch_errors=true) -> Bool

Re-renders the plot using previously cached and cleaned plot data.
Used by format, theme, axis-limit, and label callbacks without re-reading the source or active selection.
"""
function replot_from_cache!(state, outputs; is_new_data=false, reset_semipersistent=false, catch_errors=true)
    cache = state.misc
    df_selected = cache.cached_cleaned_df[]
    xcol_name = cache.cached_xcol_name[]
    y_names = cache.cached_y_names[]

    if isnothing(df_selected) || isnothing(xcol_name) || isnothing(y_names)
        return false
    end

    function _do_cached_replot()
        selected_plottype = state.plotting.format.selected_plottype[]
        show_legend = state.plotting.format.show_legend
        legend_title_text = state.plotting.handles.legend_title_text

        dynamic_vals = Dict(k => v[] for (k, v) in state.plotting.format.dynamic_attributes)
        base_format = merge((;
            plottype = selected_plottype,
            show_legend = is_new_data ? nothing : show_legend[],
            legend_title = is_new_data ? "" : legend_title_text[],
        ), NamedTuple(dynamic_vals))
        plot_format = if is_new_data || reset_semipersistent
            base_format
        else
            merge(get_current_axis_limits(state), base_format)
        end

        do_replot(
            state,
            outputs;
            data = (; df = df_selected, x_name = xcol_name, y_name = y_names),
            plot_format = plot_format,
            is_new_data = is_new_data,
            reset_semipersistent = reset_semipersistent,
        )
        return true
    end

    if !catch_errors
        return _do_cached_replot()
    end

    try
        return _do_cached_replot()
    catch e
        bt = catch_backtrace()
        show_modal!(state, "Error updating plot: $e"; type=:error, exception=(e, bt))
        outputs.plot[] = DOM.div("")
        return false
    end
end

"""
    finish_rpb!(state, outputs, acquire, fresh_sig; is_new_source=false, adopt_baseline=false) -> Nothing

Finalize the (Re-)Plot Button pipeline:
1. Update bounds and range fields if full range.
2. Prepare and clean data.
3. Call `do_replot` with reset_semipersistent=true.
4. Refresh Table.
5. Update last_plotted observables and baseline signature if requested.
"""
function finish_rpb!(state, outputs, acquire, fresh_sig; is_new_source=false, adopt_baseline=false)
    sel = selection_from_state(state)
    if sel.full_range
        state.data_selection.data_bounds_from[] = fresh_sig.first_index
        state.data_selection.data_bounds_to[] = fresh_sig.last_index
        state.data_selection.range_from[] = fresh_sig.first_index
        state.data_selection.range_to[] = fresh_sig.last_index
    end

    if fresh_sig.kind == :table && fresh_sig.is_matrix && sel.all_columns
        if state.data_selection.selected_columns[] != fresh_sig.colnames
            state.data_selection.selected_columns[] = copy(fresh_sig.colnames)
        end
    end

    range_from = state.data_selection.range_from[]
    range_to = state.data_selection.range_to[]

    prepare_plot_data!(state, acquire; range_from=range_from, range_to=range_to)

    replot_from_cache!(state, outputs; is_new_data=is_new_source, reset_semipersistent=true, catch_errors=false)

    refresh_table!(state, outputs)

    if acquire.is_array_mode
        state.misc.last_plotted_x[] = state.data_selection.selected_x[]
        state.misc.last_plotted_y[] = state.data_selection.selected_y[]
    else
        state.misc.last_plotted_dataframe[] = state.data_selection.selected_dataframe[]
    end

    if adopt_baseline
        state.misc.source_signature[] = fresh_sig
    end
    return nothing
end

"""
    refresh_candidates!(state) -> Nothing

Force refresh array dimensions and DataFrame candidate lists from Main without 30s throttling.
"""
function refresh_candidates!(state)
    state.misc.last_update[] = 0.0
    state.data_selection.dims_dict_obs[] = get_dims_of_arrays()
    state.data_selection.dataframes_dict_obs[] = collect_dataframes_from_main()
    state.misc.last_update[] = time()
    return nothing
end

"""
    reset_selection!(state, outputs; reset_dataframe=false) -> Nothing

Reset data selections and views after a continuity error or "Select data anew".
"""
function reset_selection!(state, outputs; reset_dataframe=false)
    source_type = state.data_selection.source_type[]
    if source_type == "X, Y Arrays"
        state.data_selection.selected_x[] = nothing
        state.data_selection.selected_y[] = nothing
        state.misc.last_plotted_x[] = nothing
        state.misc.last_plotted_y[] = nothing
    else
        state.data_selection.selected_columns[] = String[]
        state.misc.last_plotted_dataframe[] = nothing
        if reset_dataframe
            state.data_selection.selected_dataframe[] = nothing
        else
            df_name = state.data_selection.selected_dataframe[]
            if !isnothing(df_name) && !isempty(df_name)
                try
                    opened_df = state.file_opening.opened_file_df[]
                    (first_idx, last_idx) = get_dataframe_bounds(df_name, opened_df)
                    state.data_selection.data_bounds_from[] = first_idx
                    state.data_selection.data_bounds_to[] = last_idx
                    state.data_selection.range_from[] = first_idx
                    state.data_selection.range_to[] = last_idx
                    state.misc.source_signature[] = capture_signature(:table, df_name, opened_df)
                catch
                    state.data_selection.selected_dataframe[] = nothing
                    state.misc.source_signature[] = nothing
                end
            end
            state.misc.source_refresh[] += 1
        end
    end

    outputs.plot[] = DOM.div("Plot Pane")
    if source_type == "X, Y Arrays" || reset_dataframe || isnothing(state.data_selection.selected_dataframe[])
        outputs.table[] = DOM.div("Table Pane")
        outputs.table_title[] = "Data Table (No source selected)"
        state.misc.source_signature[] = nothing
    else
        refresh_table!(state, outputs)
    end

    state.plotting.handles.current_figure[] = nothing
    state.plotting.handles.current_axis[] = nothing
    clear_axis_limits(state)

    state.misc.cached_cleaned_df[] = nothing
    state.misc.cached_cols[] = String[]
    state.misc.cached_xcol_name[] = nothing
    state.misc.cached_y_names[] = nothing

    refresh_candidates!(state)
    return nothing
end

"""
    run_rpb!(state, outputs) -> Nothing

Unified (Re-)Plot Button execution pipeline.
Reads fresh data from Main / opened file, validates continuity, handles 2-button warnings or error dialogs,
and updates both Plot and Table.
"""
function run_rpb!(state, outputs)
    source_type = state.data_selection.source_type[]
    if source_type == "X, Y Arrays"
        x = state.data_selection.selected_x[]
        y = state.data_selection.selected_y[]
        if isnothing(x) || isempty(x) || isnothing(y) || isempty(y)
            return nothing
        end
    else
        df_name = state.data_selection.selected_dataframe[]
        cols = state.data_selection.selected_columns[]
        if isnothing(df_name) || isempty(df_name) || length(cols) < 2
            return nothing
        end
    end

    show_loading_indicator(outputs)

    try
        fresh_sig = capture_signature(state)
        baseline = state.misc.source_signature[]
        sel = selection_from_state(state)
        cont = check_continuity(baseline, fresh_sig, sel)

        if cont.status == :fatal
            throw(DataContinuityError(cont.reason))
        end

        override_cols = (fresh_sig.kind == :table && fresh_sig.is_matrix && sel.all_columns) ? fresh_sig.colnames : nothing
        acquire = acquire_source(state; override_cols=override_cols)
        if isnothing(acquire)
            return nothing
        end

        is_new_source = if acquire.is_array_mode
            (state.data_selection.selected_x[] != state.misc.last_plotted_x[] || state.data_selection.selected_y[] != state.misc.last_plotted_y[])
        else
            (state.data_selection.selected_dataframe[] != state.misc.last_plotted_dataframe[])
        end

        if cont.status == :resumable
            show_modal!(
                state,
                join(cont.changes, "\n");
                type = :warning,
                primary_label = "Continue",
                secondary_label = "Select data anew",
                on_primary = () -> begin
                    finish_rpb!(state, outputs, acquire, fresh_sig; is_new_source = is_new_source, adopt_baseline = true)
                    state.misc.source_refresh[] += 1
                end,
                on_secondary = () -> begin
                    reset_selection!(state, outputs)
                end,
            )
            return nothing
        else # :identical
            finish_rpb!(state, outputs, acquire, fresh_sig; is_new_source = is_new_source, adopt_baseline = (baseline === nothing))
            return nothing
        end
    catch e
        bt = catch_backtrace()
        msg = e isa DataContinuityError ? e.msg : "Error generating plot: " * sprint(showerror, e)
        show_modal!(state, msg; type=:error, exception=(e, bt))
        reset_selection!(state, outputs)
        outputs.plot[] = DOM.div("")
        outputs.table[] = DOM.div("")
        outputs.table_title[] = "Data Table (Error)"
    end
    return nothing
end

"""
    setup_format_change_callbacks(state, outputs)

Handle format changes for X,Y Array mode: plottype, show_legend, legend_title_text.
All changes trigger a full replot using the unified do_replot function.
"""
function setup_format_change_callbacks(state, outputs)
    (; selected_plottype, show_legend, dynamic_attributes) = state.plotting.format
    (; legend_title_text) = state.plotting.handles
    (; range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
    
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
        
        # Mark as non-default if different from DEFAULT_PLOT_TYPE
        plottype_sym = Symbol(plottype_str)
        if plottype_sym != DEFAULT_PLOT_TYPE
            state.misc.format_is_default[:plottype] = false
        end
        
        # Validate dynamic attributes against new plot type
        config = get_plot_config(plottype_str)
        for attr in get_attributes(config)
            current_val = dynamic_attributes[attr.name][]
            if current_val ∉ attr.options
                fallback = attr.name == :group_by ? "None" : attr.default
                dynamic_attributes[attr.name][] = fallback
            end
        end
        
        replot_from_cache!(state, outputs)
    end
    
    # === Legend Visibility Change Handler ===
    on(show_legend) do legend_bool
        state.misc.block_format_update[] && return
        
        # Mark as non-default
        state.misc.format_is_default[:show_legend] = false
        
        replot_from_cache!(state, outputs)
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
        
        replot_from_cache!(state, outputs)
    end
    
    # === Dynamic Attributes Change Handlers ===
    for (attr_name, obs) in dynamic_attributes
        on(obs) do val
            state.misc.block_format_update[] && return
            
            state.misc.format_is_default[attr_name] = false
            
            replot_from_cache!(state, outputs)
        end
    end
end



"""
    update_unified_plot!(state, outputs; is_new_data=false, update_table=false, range_from=nothing, range_to=nothing, reset_semipersistent=false)

Legacy / test compatibility wrapper around the split plot pipeline.
"""
function update_unified_plot!(
    state,
    outputs;
    is_new_data=false,
    update_table=false,
    range_from=nothing,
    range_to=nothing,
    reset_semipersistent=false,
)
    if !isnothing(range_from) && !isnothing(range_to) && range_from > range_to
        show_modal!(state, "Range Error: 'Range from' must be less than or equal to 'Range to'"; type=:warning)
        return false
    end

    try
        acquire = acquire_source(state)
        if isnothing(acquire)
            return false
        end

        from_val = isnothing(range_from) ? state.data_selection.range_from[] : range_from
        to_val = isnothing(range_to) ? state.data_selection.range_to[] : range_to

        prepare_plot_data!(state, acquire; range_from=from_val, range_to=to_val)
        replot_from_cache!(state, outputs; is_new_data=is_new_data, reset_semipersistent=reset_semipersistent)

        if update_table
            refresh_table!(state, outputs)
        end
        return true
    catch e
        bt = catch_backtrace()
        msg = "Error creating/updating plot: $e"
        show_modal!(state, msg; type=:error, exception=(e, bt))
        outputs.plot[] = DOM.div("")
        return false
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
function setup_dataframe_callbacks(state, outputs, plot_trigger=nothing)
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
        
        # Clear plot, table, cache, and range bounds
        plot_observable[] = DOM.div("Plot Pane")
        outputs.table_title[] = "Data Table (No source selected)"
        table_observable[] = DOM.div("Table Pane")
        state.misc.source_signature[] = nothing
        state.misc.cached_cleaned_df[] = nothing
        state.misc.cached_cols[] = String[]
        state.misc.cached_xcol_name[] = nothing
        state.misc.cached_y_names[] = nothing
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
        try
        selected_columns[] = String[]
        plot_observable[] = DOM.div("Plot Pane")
        current_figure[] = nothing
        current_axis[] = nothing
        state.misc.cached_cleaned_df[] = nothing
        state.misc.cached_cols[] = String[]
        state.misc.cached_xcol_name[] = nothing
        state.misc.cached_y_names[] = nothing
        clear_axis_limits(state)
        
        # Set data bounds and baseline signature for the DataFrame
        if !isnothing(df_name) && df_name != ""
            (first_idx, last_idx) = get_dataframe_bounds(df_name, opened_file_df[])
            data_bounds_from[] = first_idx
            data_bounds_to[] = last_idx
            range_from[] = first_idx
            range_to[] = last_idx
            state.misc.source_signature[] = capture_signature(:table, df_name, opened_file_df[])
        else
            data_bounds_from[] = nothing
            data_bounds_to[] = nothing
            range_from[] = nothing
            range_to[] = nothing
            state.misc.source_signature[] = nothing
        end
        catch e
            bt = catch_backtrace()
            show_modal!(state, "Error in DataFrame selection: " * sprint(showerror, e); type=:error, exception=(e, bt))
        end
    end
end

"""
    setup_range_ui_sync(session, state)

Set up callbacks to sync range input field values and bounds with the UI,
and attach event listeners to the range inputs (since BonitoWidgets.Tabs
replaces inline event handlers during its initialization sequence).
"""
function setup_range_ui_sync(session, state)
    (; range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection

    # Workaround: manually attach JS event listeners since BonitoWidgets strips
    # inline onchange/onkeydown handlers during its Tabs initialization sequence.
    Bonito.evaljs(session, js"""
        let attempts = 0;
        const interval = setInterval(() => {
            const fromInput = document.getElementById('range-from-input');
            const toInput = document.getElementById('range-to-input');
            if (fromInput && toInput) {
                clearInterval(interval);

                const cb_from = e => window.CasualPlots.updateIntObservable(e, $(range_from));
                const kb_from = e => window.CasualPlots.handleIntEnterKey(e, $(range_from));
                fromInput.addEventListener('change', cb_from);
                fromInput.addEventListener('keydown', kb_from);

                const cb_to = e => window.CasualPlots.updateIntObservable(e, $(range_to));
                const kb_to = e => window.CasualPlots.handleIntEnterKey(e, $(range_to));
                toInput.addEventListener('change', cb_to);
                toInput.addEventListener('keydown', kb_to);
            } else if (attempts > 50) {
                clearInterval(interval);
            }
            attempts++;
        }, 100);
    """)

    onany(data_bounds_from, data_bounds_to) do from_val, to_val
        from_js = isnothing(from_val) ? nothing : from_val
        to_js = isnothing(to_val) ? nothing : to_val
        Bonito.evaljs(session, js"""
            requestAnimationFrame(() => {
                window.CasualPlots.setRangeInputValues($from_js, $to_js);
            });
        """)
    end

    # Also sync the DOM input values whenever range_from or range_to changes in Julia
    # (e.g., when reset to full bounds even if data_bounds_from/to did not change)
    onany(range_from, range_to) do r_from, r_to
        r_from_js = isnothing(r_from) ? "" : string(r_from)
        r_to_js = isnothing(r_to) ? "" : string(r_to)
        Bonito.evaljs(session, js"""
            requestAnimationFrame(() => {
                const fromInput = document.getElementById('range-from-input');
                const toInput = document.getElementById('range-to-input');
                if (fromInput && fromInput.value !== $r_from_js) {
                    fromInput.value = $r_from_js;
                }
                if (toInput && toInput.value !== $r_to_js) {
                    toInput.value = $r_to_js;
                }
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
    
    # Reset log scales
    format.xlog[] = false
    format.ylog[] = false
    
    # Mark all as default
    for key in RESET_FORMAT_OPTION["range"]
        format_is_default[key] = true
    end
end

"""
    setup_axis_limits_callbacks(state, outputs)

Set up callbacks for axis limit and reversal changes.
Changes are applied immediately without needing a Replot button.
"""
function setup_axis_limits_callbacks(state, outputs)
    (; x_min, x_max, y_min, y_max, xreversed, yreversed, selected_plottype, show_legend, dynamic_attributes) = state.plotting.format
    (; current_axis, current_figure, legend_title_text) = state.plotting.handles
    (; source_type, selected_x, selected_y, selected_dataframe, selected_columns,
       range_from, range_to, data_bounds_from, data_bounds_to) = state.data_selection
    format_is_default = state.misc.format_is_default
    
    # Helper to get current plot format
    function get_current_plot_format()
        dynamic_vals = Dict(k => v[] for (k, v) in dynamic_attributes)
        base_format = (;
            plottype = selected_plottype[],
            show_legend = show_legend[],
            legend_title = legend_title_text[],
            x_min = x_min[],
            x_max = x_max[],
            y_min = y_min[],
            y_max = y_max[],
            xreversed = xreversed[],
            yreversed = yreversed[],
            xlog = state.plotting.format.xlog[],
            ylog = state.plotting.format.ylog[],
        )
        return merge(base_format, NamedTuple(dynamic_vals))
    end
    
    # Helper to trigger replot
    function trigger_axis_replot()
        state.misc.block_format_update[] && return
        replot_from_cache!(state, outputs)
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
    
    # === Log Scale Change Handlers ===
    on(state.plotting.format.xlog) do val
        state.misc.block_format_update[] && return
        isnothing(current_axis[]) && return
        
        format_is_default[:xlog] = !val
        trigger_axis_replot()
    end
    
    on(state.plotting.format.ylog) do val
        state.misc.block_format_update[] && return
        isnothing(current_axis[]) && return
        
        format_is_default[:ylog] = !val
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
    (; x_min_default, x_max_default, y_min_default, y_max_default, x_min, x_max, y_min, y_max, xreversed, yreversed) = state.plotting.format
    (; current_axis) = state.plotting.handles
    
    # Workaround: manually attach JS event listeners to prevent REPL timeout spam 
    # since BonitoWidgets strips them during its initialization sequence.
    Bonito.evaljs(session, js"""
        let attempts = 0;
        const interval = setInterval(() => {
            const xmin = document.getElementById('axis-x-min-input');
            const xmax = document.getElementById('axis-x-max-input');
            const ymin = document.getElementById('axis-y-min-input');
            const ymax = document.getElementById('axis-y-max-input');
            const xrev = document.getElementById('axis-x-reversed-checkbox');
            const yrev = document.getElementById('axis-y-reversed-checkbox');
            
            if (xmin && xmax && ymin && ymax && xrev && yrev) {
                clearInterval(interval);
                
                const cb_xmin = e => window.CasualPlots.updateAxisLimitObservable(e, $(x_min), $(x_max), 'min');
                const kb_xmin = e => window.CasualPlots.handleAxisLimitEnterKey(e, $(x_min), $(x_max), 'min');
                xmin.addEventListener('change', cb_xmin);
                xmin.addEventListener('blur', cb_xmin);
                xmin.addEventListener('keydown', kb_xmin);
                
                const cb_xmax = e => window.CasualPlots.updateAxisLimitObservable(e, $(x_max), $(x_min), 'max');
                const kb_xmax = e => window.CasualPlots.handleAxisLimitEnterKey(e, $(x_max), $(x_min), 'max');
                xmax.addEventListener('change', cb_xmax);
                xmax.addEventListener('blur', cb_xmax);
                xmax.addEventListener('keydown', kb_xmax);
                
                const cb_ymin = e => window.CasualPlots.updateAxisLimitObservable(e, $(y_min), $(y_max), 'min');
                const kb_ymin = e => window.CasualPlots.handleAxisLimitEnterKey(e, $(y_min), $(y_max), 'min');
                ymin.addEventListener('change', cb_ymin);
                ymin.addEventListener('blur', cb_ymin);
                ymin.addEventListener('keydown', kb_ymin);
                
                const cb_ymax = e => window.CasualPlots.updateAxisLimitObservable(e, $(y_max), $(y_min), 'max');
                const kb_ymax = e => window.CasualPlots.handleAxisLimitEnterKey(e, $(y_max), $(y_min), 'max');
                ymax.addEventListener('change', cb_ymax);
                ymax.addEventListener('blur', cb_ymax);
                ymax.addEventListener('keydown', kb_ymax);
                
                const cb_xrev = e => window.CasualPlots.updateObservableChecked(e, $(xreversed));
                xrev.addEventListener('change', cb_xrev);
                
                const cb_yrev = e => window.CasualPlots.updateObservableChecked(e, $(yreversed));
                yrev.addEventListener('change', cb_yrev);
                
                const xlog_chk = document.getElementById('axis-x-log-checkbox');
                if (xlog_chk) {
                    const cb_xlog = e => window.CasualPlots.updateObservableChecked(e, $(state.plotting.format.xlog));
                    xlog_chk.addEventListener('change', cb_xlog);
                }
                
                const ylog_chk = document.getElementById('axis-y-log-checkbox');
                if (ylog_chk) {
                    const cb_ylog = e => window.CasualPlots.updateObservableChecked(e, $(state.plotting.format.ylog));
                    ylog_chk.addEventListener('change', cb_ylog);
                }
                
            } else if (attempts > 50) {
                clearInterval(interval);
            }
            attempts++;
        }, 100);
    """)
    
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

"""
    setup_plot_resize_callback(state)

Sets up a callback to resize the Makie Figure when the plot_size observable updates.
"""
function setup_plot_resize_callback(state)
    on(state.plotting.handles.plot_size) do sz
        if sz[1] > 0 && sz[2] > 0
            fig = state.plotting.handles.current_figure[]
            if !isnothing(fig)
                Makie.resize!(fig, Int(sz[1]), Int(sz[2]))
            end
        end
    end
end

"""
    refresh_table!(state, outputs) -> Nothing

Refresh the Table view according to the active data selection and row range.
Does not perform any plotting.
"""
function refresh_table!(state, outputs)
    try
        source_type = state.data_selection.source_type[]
        range_from = state.data_selection.range_from[]
        range_to = state.data_selection.range_to[]

        if source_type == "X, Y Arrays"
            x = state.data_selection.selected_x[]
            y = state.data_selection.selected_y[]

            if isnothing(x) || isempty(x)
                outputs.table[] = DOM.div("Table Pane")
                outputs.table_title[] = "Data Table (No source selected)"
                return nothing
            end

            if !isdefined(Main, Symbol(x))
                outputs.table[] = DOM.div("Table Pane")
                outputs.table_title[] = "Data Table (No source selected)"
                return nothing
            end

            res = create_data_table(x, y; range_from=range_from, range_to=range_to)
            outputs.table[] = res.table
            outputs.table_title[] = "SOURCE: " * res.info_text
        else
            df_name = state.data_selection.selected_dataframe[]
            opened_file_df = state.file_opening.opened_file_df[]
            cols = state.data_selection.selected_columns[]

            if isnothing(df_name) || isempty(df_name)
                outputs.table[] = DOM.div("Table Pane")
                outputs.table_title[] = "Data Table (No source selected)"
                return nothing
            end

            local df
            local display_name
            if df_name == "__opened_file__"
                df = opened_file_df
                display_name = state.file_opening.opened_file_name[]
                if isempty(display_name)
                    display_name = "opened file"
                end
            else
                if !isdefined(Main, Symbol(df_name))
                    outputs.table[] = DOM.div("Table Pane")
                    outputs.table_title[] = "Data Table (No source selected)"
                    return nothing
                end
                df = get_source_as_dataframe(df_name, opened_file_df)
                display_name = df_name
            end

            if isnothing(df)
                outputs.table[] = DOM.div("Table Pane")
                outputs.table_title[] = "Data Table (No source selected)"
                return nothing
            end

            selected_cols = isnothing(cols) ? String[] : cols
            res = create_dataframe_table(df, selected_cols; range_from=range_from, range_to=range_to, display_name=display_name)
            outputs.table[] = res.table
            outputs.table_title[] = "SOURCE: " * res.info_text
        end
    catch e
        bt = catch_backtrace()
        show_modal!(state, "Error refreshing table: " * sprint(showerror, e); type=:error, exception=(e, bt))
        outputs.table[] = DOM.div("")
    end
    return nothing
end

"""
    setup_table_refresh_callback(state, outputs)

Register reactive listeners to immediately refresh the data table on selection and range changes.
"""
function setup_table_refresh_callback(state, outputs)
    (; source_type, selected_x, selected_y, selected_dataframe, selected_columns,
       range_from, range_to) = state.data_selection

    onany(
        source_type,
        selected_x,
        selected_y,
        selected_dataframe,
        selected_columns,
        range_from,
        range_to,
    ) do _...
        refresh_table!(state, outputs)
    end
    return nothing
end
