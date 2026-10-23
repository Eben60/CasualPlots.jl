# Plot Types Architecture & Plotting Implementation

Extracted from `AGENTS.md`.

## Plot Types Architecture (`plot_types.jl`)

The application uses an object-oriented, declarative configuration system for defining plot types and their UI controls.

- **`SinglePlotConfig`**: Abstract base type for all single-layer plots (e.g. `SimplePlot`, `BarPlotConfig`). Subtypes must provide a `visual_type` (e.g. `Makie.Scatter`) and a `group_config`.
- **`CompoundPlot`**: Configuration for layered plots combining multiple child `AbstractPlotConfig`s (e.g., `Line+Symbol`). It automatically aggregates and merges UI attributes from all its children, and generates composite AlgebraOfGraphics layers using the `+` operator.
- **Declarative Attribute Routing**: Plot configurations declare their UI controls by returning vectors of `AbstractPlotAttribute`.
  - `EnumAttribute`s specify `visual_map` or `mapping_map` (and `requires_group`) to declare exactly how their UI values map into the `visual()` or `mapping()` layers of the AoG pipeline.
  - A generic fallback automatically iterates over these attributes to assemble the final plot parameters, drastically reducing the need for plot-specific overrides.
- **Silent Grouping**: When `group_by == "None"` but multiple data columns are selected, the pipeline automatically injects a neutral `group` mapping. This ensures distinct lines remain separated (no zigzag loops) without altering their visual aesthetics.

### Adding a New Plot Type

1. Define a new `SinglePlotConfig` or `CompoundPlot` subtype in `plot_types.jl`
2. Register it in `PLOT_TYPES` dict in `app.jl`
3. Declare its `AbstractPlotAttribute` controls - the generic fallback handles the rest
4. No changes needed in `plotting.jl`

---

## Plotting Implementation (`plotting.jl` & `setup_callbacks.jl`)

All plotting uses **AlgebraOfGraphics exclusively** (no direct Makie `Figure`/`Axis` calls in plotting logic).

**Key Functions:**
- `run_rpb!(state, outputs)`: Unified **(Re-)Plot** button pipeline — validates structural continuity (`check_continuity`), fetches fresh source data (`acquire_source`), cleanses and caches it (`prepare_plot_data!`), triggers `replot_from_cache!`, and refreshes the Table (`refresh_table!`).
- `replot_from_cache!(state, outputs; is_new_data, reset_semipersistent)`: Re-renders the plot from `state.misc.cached_cleaned_df[]` (used by both `finish_rpb!` and all format/theme/limit callbacks without re-reading the data source).
- `do_replot(state, outputs; data, plot_format, is_new_data, reset_semipersistent)`: **Unified core entry point** for rendering the plot
  - Shows visual loading indicator in `outputs.plot[]` during processing (`show_loading_indicator` in `run_rpb!`).
  - `data`: Always `(; df, x_name, y_name)` where `df` is the cleaned wide `DataFrame`.
  - `plot_format`: `(; plottype, show_legend, legend_title)` + axis limits & scales (`x_min`, `x_max`, `y_min`, `y_max`, `xreversed`, `yreversed`, `xlog`, `ylog`) + all registered `dynamic_attributes` unpacked (e.g. `group_by`, `bar_direction`, `bar_mode`).
  - `is_new_data`: If true, initializes text fields from plot defaults and resets source-scoped format flags.
  - `reset_semipersistent`: If true (on **(Re-)Plot**), resets axis limits, reversal, and log scale options to data defaults.
- `create_plot_df_long(df, ...)`: Core AoG plotting logic
- `update_plot_format!(fig, axis; title, xlabel, ylabel)`: Update axis labels in-place without replot
- `apply_custom_formatting!(fig, ax, state)`: Re-apply non-default format options after replot

**AlgebraOfGraphics Pattern:**
```julia
# Group differentiation based on dynamically generated layer code:
plot_config = PLOT_TYPES[plottype]
layer_code = build_layer(plot_config, plot_format, group_col, legend_title)
plt = AlgebraOfGraphics.data(df) * mapping(x_col => x_name, y_col => y_name) * layer_code
fg = draw(plt; 
    figure=(; size=(800, 600)), 
    legend=(show=show_legend,), 
    axis=(; title, xlabel, ylabel, limits=(xlimits, ylimits),
            xreversed, yreversed,
            xscale = xlog ? log10 : identity, 
            yscale = ylog ? log10 : identity))
fig = fg.figure
axis = fg.grid[1, 1].axis  # Extract Axis from FigureGrid
```

**Exports & Error Inspection:**
```julia
global cp_figure = fig      # Figure object
global cp_figure_ax = axis  # Axis object for fine-tuning (for manual REPL usage, do not use in app logic)
global cp_file_df = df      # DataFrame object from opened file (CSV/XLSX)

CasualPlots.last_error()    # View full backtrace of the most recent error caught in GUI callbacks
```
