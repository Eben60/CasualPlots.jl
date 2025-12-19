"""
    initialize_app_state()

Initialize all Observable state variables for the application.

Returns a NamedTuple with:
- `dims_dict_obs`: Observable tracking available arrays
- `trigger_update`: Observable for triggering data refresh
- `selected_x`, `selected_y`: Observables for selected variables
- `selected_plottype`: Observable for plot type
- `show_legend`: Observable for legend visibility
- `last_update`: Ref for tracking last data refresh time
"""
function initialize_app_state()
    last_update = Ref(time())
    dims_dict_obs = Observable(get_dims_of_arrays())
    trigger_update = Observable(true)
    
    # Setup auto-refresh callback
    on(trigger_update) do val
        current_time = time()
        if current_time - last_update[] > 30
            dims_dict_obs[] = get_dims_of_arrays()
            dataframes_dict_obs[] = collect_dataframes_from_main()
            last_update[] = current_time
        end
    end
    
    # Array source observables
    selected_x = Observable{Union{Nothing, String}}(nothing)
    selected_y = Observable{Union{Nothing, String}}(nothing)
    selected_plottype = Observable("Scatter")
    show_legend = Observable(true)
    
    # DataFrame source observables
    source_type = Observable("X, Y Arrays")  # Default to array mode
    dataframes_dict_obs = Observable(collect_dataframes_from_main())
    selected_dataframe = Observable{Union{Nothing, String}}(nothing)
    selected_columns = Observable{Vector{String}}(String[])
    
    # Opened file DataFrame (from Open tab)
    opened_file_df = Observable{Union{Nothing, DataFrame}}(nothing)
    opened_file_name = Observable("")  # Display name (filename without path/suffix)
    
    # Text field observables for plot labels
    xlabel_text = Observable("")
    ylabel_text = Observable("")
    title_text = Observable("")
    legend_title_text = Observable("")
    
    # Store figure and axis for direct label manipulation
    current_figure = Observable{Union{Nothing, Figure}}(nothing)
    current_axis = Observable{Union{Nothing, Axis}}(nothing)
    
    plot_format = (; selected_plottype, show_legend)
    plot_handles = (; xlabel_text, ylabel_text, title_text, legend_title_text, current_figure, current_axis)
    
    block_format_update = Observable(false)

    # Save functionality observables
    save_file_path = Observable("")  # Persists across plots
    save_status_message = Observable("")
    save_status_type = Observable(:none)  # :none, :success, :warning, :error
    show_overwrite_confirm = Observable(false)
    
    # Modal dialog observables
    show_modal = Observable(false)  # Controls modal visibility
    modal_type = Observable(:none)  # :success, :error, :warning, :confirm

    return (; dims_dict_obs, trigger_update, selected_x, selected_y, last_update,
              plot_format, plot_handles, block_format_update,
              source_type, dataframes_dict_obs, selected_dataframe, selected_columns,
              opened_file_df, opened_file_name,
              save_file_path, save_status_message, save_status_type, show_overwrite_confirm,
              show_modal, modal_type)
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







