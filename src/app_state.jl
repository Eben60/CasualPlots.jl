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
    range_from = Observable{Union{Nothing, Int}}(nothing)
    range_to = Observable{Union{Nothing, Int}}(nothing)
    # Data bounds - track the actual first/last indices of current data source
    data_bounds_from = Observable{Union{Nothing, Int}}(nothing)
    data_bounds_to = Observable{Union{Nothing, Int}}(nothing)
    
    data_selection = (; 
        source_type, dims_dict_obs, dataframes_dict_obs,
        selected_dataframe, selected_columns, selected_x, selected_y,
        range_from, range_to, data_bounds_from, data_bounds_to
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
    
    misc = (; trigger_update, last_update, block_format_update)

    return (; file_opening, file_saving, dialogs, data_selection, plotting, misc)
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







