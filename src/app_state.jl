"""
    initialize_app_state()

Initialize all Observable state variables for the application.

Returns a NamedTuple with nested categories:
- `file_opening`: Opened file DataFrame and reading options
- `file_saving`: Save path and status observables
- `dialogs`: Modal dialog visibility and type
- `data_selection`: Source type, array/DataFrame selection
- `plotting`: Format and handles sub-tuples
- `misc`: Trigger, last_update, block_format_update
"""
function initialize_app_state()
    last_update = Ref(time())
    dims_dict_obs = Observable(get_dims_of_arrays())
    trigger_update = Observable(true)
    dataframes_dict_obs = Observable(collect_dataframes_from_main())
    
    # Setup auto-refresh callback
    on(trigger_update) do val
        current_time = time()
        if current_time - last_update[] > 30
            dims_dict_obs[] = get_dims_of_arrays()
            dataframes_dict_obs[] = collect_dataframes_from_main()
            last_update[] = current_time
        end
    end
    
    # --- File Opening ---
    opened_file_df = Observable{Union{Nothing, DataFrame}}(nothing)
    opened_file_name = Observable("")
    opened_file_path = Observable("")  # Full path of currently loaded file (for reload)
    header_row = Observable(1)
    skip_after_header = Observable(0)
    skip_empty_rows = Observable(true)
    delimiter = Observable("Auto")
    decimal_separator = Observable("Dot")
    
    file_opening = (; 
        opened_file_df, opened_file_name, opened_file_path,
        header_row, skip_after_header, skip_empty_rows, delimiter, decimal_separator
    )
    
    # --- File Saving ---
    save_file_path = Observable("")
    save_status_message = Observable("")
    save_status_type = Observable(:none)
    show_overwrite_confirm = Observable(false)
    
    file_saving = (; save_file_path, save_status_message, save_status_type, show_overwrite_confirm)
    
    # --- Dialogs ---
    show_modal = Observable(false)
    modal_type = Observable(:none)
    
    dialogs = (; show_modal, modal_type)
    
    # --- Data Selection ---
    source_type = Observable("X, Y Arrays")
    selected_dataframe = Observable{Union{Nothing, String}}(nothing)
    selected_columns = Observable{Vector{String}}(String[])
    selected_x = Observable{Union{Nothing, String}}(nothing)
    selected_y = Observable{Union{Nothing, String}}(nothing)
    
    data_selection = (; 
        source_type, dims_dict_obs, dataframes_dict_obs,
        selected_dataframe, selected_columns, selected_x, selected_y
    )
    
    # --- Plotting ---
    selected_plottype = Observable("Scatter")
    show_legend = Observable(true)
    plot_format = (; selected_plottype, show_legend)
    
    xlabel_text = Observable("")
    ylabel_text = Observable("")
    title_text = Observable("")
    legend_title_text = Observable("")
    current_figure = Observable{Union{Nothing, Figure}}(nothing)
    current_axis = Observable{Union{Nothing, Axis}}(nothing)
    plot_handles = (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis)
    
    plotting = (; format=plot_format, handles=plot_handles)
    
    # --- Misc ---
    block_format_update = Observable(false)
    
    # Track which format options have been explicitly changed by user
    # Keys: :title, :xlabel, :ylabel, :show_legend, :legend_title
    # Values: true if user has changed this option, false otherwise
    # Reset when new data source is selected. Used to preserve user customizations during plot rebuilds.
    format_is_default = DefaultDict{Symbol, Bool}(true)
    
    # Track last plotted data source to detect when a NEW source is selected
    # (vs just re-plotting same source with different columns)
    last_plotted_x = Observable{Union{Nothing, String}}(nothing)  # For Array mode (X variable)
    last_plotted_y = Observable{Union{Nothing, String}}(nothing)  # For Array mode (Y variable)
    last_plotted_dataframe = Observable{Union{Nothing, String}}(nothing)  # For DataFrame mode
    
    misc = (; trigger_update, last_update, block_format_update, format_is_default, last_plotted_x, last_plotted_y, last_plotted_dataframe)

    return (; file_opening, file_saving, dialogs, data_selection, plotting, misc)
end

"""
    reset_format_defaults!(format_is_default::DefaultDict{Symbol, Bool})

Reset format_is_default dict to all-default state, EXCEPT for options
listed in PERSISTENT_FORMAT_OPTION which should persist across data source changes.
"""
reset_format_defaults!(format_is_default) = filter!(p -> p.first in PERSISTENT_FORMAT_OPTION, format_is_default)

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

Returns a NamedTuple with:
- `plot`: Observable for plot display
- `table`: Observable for table display
- `current_x`, `current_y`: Observables tracking currently plotted data
"""
function initialize_output_observables()
    plot_observable = Observable{Any}(DOM.div("Plot Pane"))
    table_observable = Observable{Any}(DOM.div("Table Pane"))
    current_x = Observable{Union{Nothing, String}}(nothing)
    current_y = Observable{Union{Nothing, String}}(nothing)
    
    return (; plot=plot_observable, table=table_observable, 
              current_x, current_y)
end







