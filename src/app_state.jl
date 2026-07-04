"""
    initialize_app_state()

Initialize all Observable state variables for the application.

Returns a `CasualPlotsState` struct with nested categories:
- `file_opening`: Opened file DataFrame and reading options
- `file_saving`: Save path and status observables
- `dialogs`: Modal dialog visibility and type
- `data_selection`: Source type, array/DataFrame selection
- `plotting`: Format and handles sub-tuples
- `misc`: Trigger, last_update, block_format_update
"""
function initialize_app_state()
    state = CasualPlotsState(
        data_selection = DataSelection(
            dims_dict_obs = Observable(get_dims_of_arrays()),
            dataframes_dict_obs = Observable(collect_dataframes_from_main()),
        ),
        misc = Misc(
            last_update = Ref(time()),
        ),
    )

    # Setup auto-refresh callback
    on(state.misc.trigger_update) do val
        current_time = time()
        if current_time - state.misc.last_update[] > 30
            state.data_selection.dims_dict_obs[] = get_dims_of_arrays()
            state.data_selection.dataframes_dict_obs[] = collect_dataframes_from_main()
            state.misc.last_update[] = current_time
        end
    end

    return state
end

"""
    reset_format_defaults!(format_is_default::DefaultDict{Symbol, Bool})

Reset format_is_default dict to all-default state, EXCEPT for options
that should never be reset (listed in `RESET_FORMAT_OPTION["never"]`).
"""
reset_format_defaults!(format_is_default) = filter!(p -> p.first in RESET_FORMAT_OPTION["never"], format_is_default)

"""
    reset_semipersistent_format_options!(state)

Reset semipersistent format options (axis limits and reversal) to their default values.
Called when:
- A new data source is selected
- (Re-)Plot button is clicked

This resets the axis limits to `nothing` (auto) and reversal to `false`,
and marks them as default in format_is_default.
"""
function reset_semipersistent_format_options!(state)
    format = state.plotting.format
    format_is_default = state.misc.format_is_default
    
    # Reset axis limits to nothing (auto)
    format.x_min[] = nothing
    format.x_max[] = nothing
    format.y_min[] = nothing
    format.y_max[] = nothing
    
    # Reset reversal to false
    format.xreversed[] = false
    format.yreversed[] = false
    
    # Mark as default in format_is_default dict
    for key in RESET_FORMAT_OPTION["range"]
        format_is_default[key] = true
    end
end

"""
    apply_custom_formatting!(fig, ax, state)

Apply user-customized format options to the plot after creation.
Only applies options where `format_is_default[key] == false`, meaning the user
has explicitly changed them from their default values.

This allows user customizations to persist across plot rebuilds.
"""
function apply_custom_formatting!(fig, ax, state)
    isnothing(fig) && return
    isnothing(ax) && return
    
    format_is_default = state.misc.format_is_default
    handles = state.plotting.handles
    
    # Map from format_is_default keys to the corresponding observable and update_plot_format! keyword
    format_map = (;
        title = handles.title_text,
        xlabel = handles.xlabel_text,
        ylabel = handles.ylabel_text,
        legend_title = handles.legend_title_text,
    )
    
    for (key, obs) in pairs(format_map)
        if !format_is_default[key]
            update_plot_format!(fig, ax; (key => obs[],)...)
        end
    end
end

"""
    initialize_output_observables()

Create observables for plot and table output display.

Returns an `Outputs` struct with:
- `plot`: Observable for plot display
- `table`: Observable for table display
- `current_x`, `current_y`: Observables tracking currently plotted data
"""
function initialize_output_observables()
    return OutputObservables()
end







