# ==========================================
# State Component Types
# ==========================================

"""
    FileOpening

State observables for the File Open tab.
Controls the loaded DataFrame from disk, file paths, sheet selections, and parsing options (delimiter, headers, etc.).
"""
@kwdef struct FileOpening
    opened_file_df::Observable{Union{Nothing, DataFrame}} = Observable{Union{Nothing, DataFrame}}(nothing)
    opened_file_name::Observable{String} = Observable("")
    opened_file_path::Observable{String} = Observable("")
    sheet_name::Observable{String} = Observable("")  # XLSX sheet name (empty for CSV)
    header_row::Observable{Int} = Observable(1)
    skip_after_header::Observable{Int} = Observable(0)
    skip_empty_rows::Observable{Bool} = Observable(true)
    delimiter::Observable{String} = Observable("Auto")
    decimal_separator::Observable{String} = Observable("Dot")
end

"""
    FileSaving

State observables for the File Save tab.
Controls the output path, save status messages, and overwrite confirmation dialogs.
"""
@kwdef struct FileSaving
    save_file_path::Observable{String} = Observable("")
    save_status_message::Observable{String} = Observable("")
    save_status_type::Observable{Symbol} = Observable(:none)
    show_overwrite_confirm::Observable{Bool} = Observable(false)
end

"""
    Dialogs

State observables for application-wide modal dialogs (errors, warnings, etc.).
"""
@kwdef struct Dialogs
    show_modal::Observable{Bool} = Observable(false)
    modal_type::Observable{Symbol} = Observable(:none)
end

"""
    DataSelection

State observables for data source selection (X, Y Arrays vs DataFrame).
Stores available datasets, selected column names, and row range boundaries.
"""
@kwdef struct DataSelection
    source_type::Observable{String} = Observable("X, Y Arrays")
    dims_dict_obs::Observable{Dict} = Observable(Dict())
    dataframes_dict_obs::Observable{Vector} = Observable([])
    selected_dataframe::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    selected_columns::Observable{Vector{String}} = Observable{Vector{String}}(String[])
    selected_x::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    selected_y::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    range_from::Observable{Union{Nothing, Int}} = Observable{Union{Nothing, Int}}(nothing)
    range_to::Observable{Union{Nothing, Int}} = Observable{Union{Nothing, Int}}(nothing)
    data_bounds_from::Observable{Union{Nothing, Int}} = Observable{Union{Nothing, Int}}(nothing)
    data_bounds_to::Observable{Union{Nothing, Int}} = Observable{Union{Nothing, Int}}(nothing)
end

"""
    PlotFormat

State observables for plot formatting.
Controls the selected plot type, theme, legend visibility, axis limits, log scales, and dynamic plot attributes (like `group_by` or `bar_mode`).
"""
@kwdef struct PlotFormat
    selected_plottype::Observable{String} = Observable("Scatter")
    selected_theme::Observable{String} = Observable(DEFAULT_THEME)
    dynamic_attributes::Dict{Symbol, Observable{Any}} = Dict{Symbol, Observable{Any}}()
    show_legend::Observable{Bool} = Observable(true)
    x_min::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    x_max::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    y_min::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    y_max::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    x_min_default::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    x_max_default::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    y_min_default::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    y_max_default::Observable{Union{Nothing, Float64}} = Observable{Union{Nothing, Float64}}(nothing)
    xreversed::Observable{Bool} = Observable(false)
    yreversed::Observable{Bool} = Observable(false)
    xlog::Observable{Bool} = Observable(false)
    ylog::Observable{Bool} = Observable(false)
    x_is_categorical::Observable{Bool} = Observable(false)
    y_is_categorical::Observable{Bool} = Observable(false)
end

"""
    PlotHandles

State observables that hold the active plot's figure, axis, and dimension handles.
Also stores user-defined or default text labels for the axes and titles.
"""
@kwdef struct PlotHandles
    xlabel_text::Observable{String} = Observable("")
    ylabel_text::Observable{String} = Observable("")
    title_text::Observable{String} = Observable("")
    legend_title_text::Observable{String} = Observable("")
    current_figure::Observable{Union{Nothing, Figure}} = Observable{Union{Nothing, Figure}}(nothing)
    current_axis::Observable{Union{Nothing, Axis}} = Observable{Union{Nothing, Axis}}(nothing)
    plot_size::Observable{Any} = Observable{Any}((810, 610))
end

"""
    Plotting

Nested state category combining plot formatting options (`PlotFormat`) and active figure/axis handles (`PlotHandles`).
"""
@kwdef struct Plotting
    format::PlotFormat = PlotFormat()
    handles::PlotHandles = PlotHandles()
end

"""
    Misc

Miscellaneous state and caching references.
Includes anti-bounce update tracking (`last_update`), formatting block flags (`block_format_update`), and cached dataframes to avoid redundant recomputations.
"""
@kwdef struct Misc
    trigger_update::Observable{Bool} = Observable(true)
    last_update::Ref{Float64} = Ref(0.0)
    block_format_update::Observable{Bool} = Observable(false)
    format_is_default::DefaultDict{Symbol, Bool} = DefaultDict{Symbol, Bool}(true)
    last_plotted_x::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    last_plotted_y::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    last_plotted_dataframe::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    cached_cleaned_df::Ref{Union{Nothing, DataFrame}} = Ref{Union{Nothing, DataFrame}}(nothing)
    cached_xcol_name::Ref{Union{Nothing, String}} = Ref{Union{Nothing, String}}(nothing)
    cached_y_names::Ref{Any} = Ref{Any}(nothing)
    cached_cols::Ref{Vector{String}} = Ref{Vector{String}}(String[])
end

# ==========================================
# Top-Level State Type
# ==========================================

"""
    CasualPlotsState

The top-level reactive state struct for the `CasualPlots` application.
This struct orchestrates all UI observables, separated into logical categories:
- `file_opening`: Disk I/O parsing and loaded file paths.
- `file_saving`: Output paths and save status.
- `dialogs`: Error/Warning modal visibility.
- `data_selection`: Array/DataFrame choices and active column selections.
- `plotting`: Plot type, formatting options, and Makie figure/axis handles.
- `misc`: Internal update flags and cached data.

To inspect this state in the REPL:
```julia
app = casualplots_app()
propertynames(app.state)
```
"""
@kwdef struct CasualPlotsState
    file_opening::FileOpening = FileOpening()
    file_saving::FileSaving = FileSaving()
    dialogs::Dialogs = Dialogs()
    data_selection::DataSelection = DataSelection()
    plotting::Plotting = Plotting()
    misc::Misc = Misc()
end

# ==========================================
# Outputs Type
# ==========================================

@kwdef struct OutputObservables
    plot::Observable{Any} = Observable{Any}(DOM.div("Plot Pane"))
    table::Observable{Any} = Observable{Any}(DOM.div("Table Pane"))
    table_title::Observable{String} = Observable{String}("Data Table (No source selected)")
    current_x::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
    current_y::Observable{Union{Nothing, String}} = Observable{Union{Nothing, String}}(nothing)
end
