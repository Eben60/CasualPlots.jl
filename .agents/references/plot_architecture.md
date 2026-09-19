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

## Plotting Implementation (`plotting.jl`)

All plotting uses **AlgebraOfGraphics exclusively** (no direct Makie `Figure`/`Axis` calls in plotting logic).

**Key Functions:**
- `do_replot(state, outputs; data, plot_format, is_new_data)`: **Unified entry point** for all plotting
  - `data`: Either `(; x_name, y_name)` for arrays or `(; df, x_name, y_name)` for DataFrames
  - `plot_format`: `(; plottype, show_legend, legend_title)` + axis limits + all registered `dynamic_attributes` unpacked (e.g. `group_by`, `bar_direction`, `bar_mode`).
  - `is_new_data`: If true, initializes text fields from plot defaults
- `check_data_create_plot(x_name, y_name; plot_format)`: Fetch from Main, delegate to create_plot
- `create_plot(x_data::AbstractVector, y_data, ...)`: Arrays -> DataFrame -> AoG pipeline
- `create_plot(df::AbstractDataFrame; xcol=1, ...)`: DataFrame -> long format -> AoG
- `create_plot_df_long(df, ...)`: Core AoG plotting logic
- `update_plot_format!(fig, axis; title, xlabel, ylabel)`: Update axis labels without replot
- `apply_custom_formatting!(fig, ax, state)`: Re-apply non-default format options after replot

**AlgebraOfGraphics Pattern:**
```julia
# Group differentiation based on dynamically generated layer code:
plot_config = PLOT_TYPES[plottype]
layer_code = build_layer(plot_config, plot_format, group_col, legend_title)
plt = AlgebraOfGraphics.data(df) * mapping(x_col => x_name, y_col => y_name) * layer_code
fg = draw(plt; figure=(; size=(800, 600)), legend=(show=show_legend,), axis=(; title))
fig = fg.figure
axis = fg.grid[1, 1].axis  # Extract Axis from FigureGrid
```

**Exports to Main:**
```julia
global cp_figure = fig      # Figure object
global cp_figure_ax = axis  # Axis object for fine-tuning (for manual REPL usage, do not use in app logic)
```
