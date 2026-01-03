# Reactive State Architecture

## State Structure
The application uses a `NamedTuple` called `state` with nested categories:

```julia
state = (;
    file_opening = (;
        opened_file_df::Observable{Union{Nothing, DataFrame}},
        opened_file_name::Observable{String},
        opened_file_path::Observable{String},  # Full path for reload
        header_row::Observable{Int},          # 0 = no headers
        skip_after_header::Observable{Int},   # Rows to skip after header
        skip_empty_rows::Observable{Bool},
        delimiter::Observable{String},        # Auto, Comma, Tab, etc.
        decimal_separator::Observable{String}
    ),
    file_saving = (;
        save_file_path::Observable{String},
        save_status_message::Observable{String},
        save_status_type::Observable{Symbol},  # :none, :success, :warning, :error
        show_overwrite_confirm::Observable{Bool}
    ),
    dialogs = (;
        show_modal::Observable{Bool},
        modal_type::Observable{Symbol}         # :none, :success, :warning, :confirm
    ),
    data_selection = (;
        source_type::Observable{String},       # "X, Y Arrays" or "DataFrame"
        dims_dict_obs::Observable{Dict},
        dataframes_dict_obs::Observable{Vector},
        selected_dataframe::Observable{Union{String, Nothing}},
        selected_columns::Observable{Vector{String}},
        selected_x::Observable{Union{String, Nothing}},
        selected_y::Observable{Union{String, Nothing}},
        range_from::Observable{Union{Nothing, Int}},     # User-selected range start
        range_to::Observable{Union{Nothing, Int}},       # User-selected range end
        data_bounds_from::Observable{Union{Nothing, Int}},  # Data's first index (auto-set)
        data_bounds_to::Observable{Union{Nothing, Int}}     # Data's last index (auto-set)
    ),
    plotting = (;
        format = (;
            selected_plottype::Observable{String},
            show_legend::Observable{Bool},
            # Axis limits (nothing = auto)
            x_min::Observable{Union{Nothing, Float64}},
            x_max::Observable{Union{Nothing, Float64}},
            y_min::Observable{Union{Nothing, Float64}},
            y_max::Observable{Union{Nothing, Float64}},
            # Axis limit defaults (for reset and placeholder display)
            x_min_default::Observable{Union{Nothing, Float64}},
            x_max_default::Observable{Union{Nothing, Float64}},
            y_min_default::Observable{Union{Nothing, Float64}},
            y_max_default::Observable{Union{Nothing, Float64}},
            # Axis reversal
            xreversed::Observable{Bool},
            yreversed::Observable{Bool}
        ),
        handles = (;
            xlabel_text::Observable{String},
            ylabel_text::Observable{String},
            title_text::Observable{String},
            legend_title_text::Observable{String},
            current_figure::Observable{Union{Figure, Nothing}},
            current_axis::Observable{Union{Axis, Nothing}}
        )
    ),
    misc = (;
        trigger_update::Observable{Bool},
        last_update::Ref{Float64},
        block_format_update::Observable{Bool},  # Race condition prevention
        format_is_default::DefaultDict{Symbol, Bool},  # Track user-customized format options
        last_plotted_x::Observable{Union{Nothing, String}},  # Data source tracking (Array)
        last_plotted_y::Observable{Union{Nothing, String}},  # Data source tracking (Array)
        last_plotted_dataframe::Observable{Union{Nothing, String}}  # Data source tracking (DataFrame)
    )
)
```

## Output Observables
Separate `outputs` NamedTuple for UI display:
```julia
outputs = (
    plot::Observable{Any},           # DOM element for plot pane
    table::Observable{Any},          # DOM element for table pane
    current_x::Observable{Any},      # Currently plotted X data
    current_y::Observable{Any}       # Currently plotted Y data
)
```
