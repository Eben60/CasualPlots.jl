# CasualPlots.jl - AI Agent Technical Reference

## Agents Behavior

- **Always clarify first** if a user's request is unclear, before starting the actual action.
- **Do not** interpret a question or a review request as an implicit request for action. Example of proper dialogue:
    - *Human*: Is XY a good idea?
    - *Agent*: Yes, XY is good because of A, B, and C. Should I implement it for you?
    - *Human*: Yes, please
- **Do not** update this file unless explicitely requested.
- Abbreviation "aqogo" means "Ask questions, if you have any, otherwise go on"

## Package Overview
**CasualPlots.jl** is a GUI-based plotting application for Julia which is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications. Target users are experimental scientists and engineers needing quick visualization without memorizing syntax. Aims to cover 60-80% of common 2D plotting needs (Scatter/Line/BarPlot, basic formatting).

## Core Architecture

### Coding Conventions

*   **Function Signatures**: Unless technically required (e.g., for multiple dispatch), do not supply argument types in the function definition. If specifying types, do not overspecify (e.g., use `Real` instead of `Float64` if appropriate).
*   **Docstrings**: Specify the expected types in the docstring signature. You may also explicitly show the return type. Skip detailed explanations if the function is self-explanatory.

Example:
```
"""
    foo(x::Real) --> Real

Squaring the x
"""
function foo(x)
    return x^2
end
```

*   **Syntax**:
    *   Always start `NamedTuple`s with a semicolon.
    *   Always use a semicolon before keyword arguments in function calls.

Example:
```
# Good
state = (; x = 1, y = 2)
foo(a, b; kwarg1 = 1, kwarg2 = 2)
```

*   **Formatting**: If a Tuple, function argument list, or other comma-separated list spans multiple lines, always add a trailing comma after the last item.

Example:
```
items = (
    item1,
    item2,
    item3,  # trailing comma
)
```

### JavaScript Conventions
*   **External Logic**: All non-trivial JavaScript logic must be placed in `src/javascripts.js` and namespaced under `window.CasualPlots`.
*   **Inline Minimization**: Inline JS in Julia files (`js"..."`) should be restricted to simple calls to these external functions or mandatory one-liners.
*   **Loading**: The `javascripts.js` file is read and injected as a script tag in the main application layout (`app.jl`).

### Technology Stack
*   **[Bonito.jl](https://github.com/SimonDanisch/Bonito.jl)**: Web-based reactive GUI framework
*   **[WGLMakie](https://github.com/MakieOrg/Makie.jl)**: WebGL-based plotting backend
*   **[AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl)**: Declarative plot specification (all plots built using AoG)
*   **[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)**: Data handling
*   **[Observables.jl](https://github.com/JuliaGizmos/Observables.jl)**: Reactive state management
*   **[Electron.jl](https://github.com/davidanthoff/Electron.jl)**: Window hosting 
*   **[CSV.jl](https://github.com/JuliaData/CSV.jl)** / **[XLSX.jl](https://github.com/felipenoris/XLSX.jl)**: File I/O via Package Extensions

### File Structure (src/)

```
CasualPlots.jl                  # Main module, exports casualplots_app()
app.jl                          # Main app entry point (casualplots_app function)
app_state.jl                    # Application state initialization (Observables)
css_styles.css                  # Global CSS styles for all UI components
javascripts.js                  # Global JavaScript functions (namespaced window.CasualPlots)

# Core Logic
plotting.jl                     # Plot generation using AlgebraOfGraphics
setup_callbacks.jl              # Core reactive callbacks (do_replot, source, format, DataFrame)
label_update_callbacks.jl       # Label text field callbacks
dropdowns_setup.jl              # Dropdown menu creation (X, Y, DataFrame)

# UI Components (ui_*.jl)
ui_tabs.jl                      # Tab component + create_tab_content wiring
ui_layout.jl                    # assemble_layout - main pane grid construction
ui_table.jl                     # Table display with info header
ui_help_section.jl              # Mouse controls help text
ui_source_tab.jl                # Source selection UI (Array/DataFrame modes)
ui_format_tab.jl                # Format controls UI (plot type, legend, labels)
ui_open_tab.jl                  # File open tab UI
ui_save_tab.jl                  # Save tab UI
ui_modal_dialog.jl              # Modal dialog component

# Control Panel
create_control_panel_ui.jl      # Control panel UI construction

# Data Handling
collect_data.jl                 # Data collection from Main module
preprocess_dataframes.jl        # Data frame normalization and validation
read_from_file.jl               # File reading logic (CSV/XLSX) and loading callbacks
file_reading_options.jl         # Options processing for file reading
create_demo_data.jl             # Demo data generation

# Save/Export
save_plot.jl                    # Plot saving functionality (CairoMakie backend)

# Other
electron.jl                     # Electron window integration (show kwarg for hidden windows)
FileDialogWorkAround.jl         # Cross-platform file dialog utilities
extensions.jl                   # Package extensions loader
precompile.jl                   # PrecompileTools workload for reducing TTFP

scripts/                        # Example/demo scripts
../ext/                         # Package Extensions (ReadCSV_Ext.jl, ReadXLSX_Ext.jl)
```

### Reactive State Architecture

The application uses a reactive `state` NamedTuple with `Observables.jl` for all UI state management.
See [Reactive State Architecture](AGENTS_more_info/specific_issues/reactive_state_architecture.md) for the full state structure and output observables documentation.

### Developer Diagrams

Diagrams are in the linked files:

- [High-Level User Flow](AGENTS_more_info/Mermaid/high-level_user_flow.md)
- [Callback Execution Sequence](AGENTS_more_info/Mermaid/callback_execution_sequence.md)
- [State Transition Map](AGENTS_more_info/Mermaid/state_transition_map.md)


### Critical Implementation Patterns

#### 1. Source Selection & Plotting Flow
Both **X,Y Source**, **DataFrame Source**, and **Open File** modes feed into the plotting pipeline.

**A. X,Y Source Selection:**
1.  **Step 1: X Selection** (`setup_x_callback`)
    - User selects X variable.
    - Triggers population of congruent Y-variable options.
    - Clears current Y selection.
    - Sets `data_bounds_from`/`data_bounds_to` from the X array's first/last indices.
    - Initializes `range_from`/`range_to` to match bounds.
2.  **Step 2: Y Selection** (`setup_source_callback`)
    - User selects Y variable.
    - Updates `current_plot_x`, `current_plot_y` for tracking.
    - **Does NOT auto-plot** - waits for user to click "(Re-)Plot" button.
    - *On invalid selection*: Clears plot, table, and state.
3.  **Step 3: (Re-)Plot** (`setup_array_plot_trigger_callback`)
    - User clicks "(Re-)Plot" button.
    - Validates range values (uses bounds as defaults if empty).
    - Calls `do_replot` with range parameters.
    - Updates table view with range-filtered data.
    - Applies non-default formatting options via `apply_custom_formatting!`.

**B. DataFrame Source Selection (Main or Opened File):**
1.  **Step 1: DataFrame Selection**
    - User selects a DataFrame from `Main` OR selects "**opened file**" (if file loaded via Open tab).
    - If needed (opened file), strings are normalized (`normalize_strings!`) at load time.
    - Triggers population of column checkboxes.
    - Clears current column selection.
2.  **Step 2: Column Selection & Plotting** (`setup_dataframe_callbacks`)
    - User selects columns (checkboxes).
    - **Plotting is triggered manually**: User must click "(Re-)Plot" button.
    - `plot_trigger` observable fires:
        - Validates selection (at least 2 columns).
        - **Data Normalization**: Calls `normalize_numeric_columns!` to convert Abstract/Any types to Float64/Int. Warns if non-numeric values are lost (popup + log).
        - Calls `update_dataframe_plot` helper.
        - Generates plot with **default labels** (resets legend title).
        - Updates table view.

**C. File Import with Reading Options (Open Tab):**
The Open tab provides configurable file reading options before/after loading:
1.  **Reading Options** (configured via UI controls):
    - `header_row`: Row number containing headers (0 = no headers)
    - `skip_after_header`: Rows to skip after header (subheaders)
    - `skip_empty_rows`: Remove rows where all elements are missing
    - `delimiter`: CSV delimiter (Auto, Comma, Tab, Space, Semicolon, Pipe)
    - `decimal_separator`: Decimal/thousands separator format
2.  **File Loading**:
    - CSV/TSV: Options passed to `CSV.read()` via `collect_csv_options()`
    - XLSX: Options passed to `XLSX.readtable()` via `collect_xlsx_options()`
    - Both call `skip_rows!()` for post-load row processing
3.  **Reload Button**:
    - Enabled when a file is loaded (CSV) or sheet selected (XLSX)
    - Re-reads the same file (`opened_file_path`) with current options
    - Useful for adjusting options after seeing initial import results

#### 2. Formatting & Updates
Formatting changes (Plot Type, Legend, Labels) are handled differently to preserve user customizations and optimize performance. Both X,Y and DataFrame modes have separate format callback implementations that follow identical patterns.

**A. Format Callback Logic:**
- **Triggered by**: `selected_plottype`, `selected_theme`, `selected_group_by`, `show_legend`, `legend_title_text`, axis limit observables.
- **Implementations**:
    - X,Y Mode: `setup_format_change_callbacks` (triggers `do_replot`)
    - DataFrame Mode: Format callbacks within `setup_dataframe_callbacks` (triggers `update_dataframe_plot` → `do_replot`)
    - Theme: `setup_theme_callback` (applies theme globally, triggers replot)
    - Group By: `setup_group_by_callback` (triggers replot with new group mapping)
    - Axis Limits: `setup_axis_limits_callbacks` (triggers immediate replot with current limits)
- **Shared Behavior**:
    - **All format changes trigger full replot** using the unified `do_replot` function.
    - **Preserves user labels and axis limits**: `format_is_default` dict tracks which options are customized. After replot, `apply_custom_formatting!` re-applies non-default values.
    - **Axis limits preserved during format changes**: `get_current_axis_limits(state)` helper merges current limits into `plot_format`.
    - **Does NOT update table**: Table update is skipped as data hasn't changed.
    - **Race Condition Prevention**: Returns early if `block_format_update[]` is true.
    - **Legend title optimization**: Skip replot if legend is not visible (title is saved for when legend becomes visible).

**B. Format Persistence Strategy (`format_is_default` and `RESET_FORMAT_OPTION`):**
A `DefaultDict{Symbol, Bool}` tracks which format options are still at their default values.

**Reset behavior is defined in `constants.jl` via `RESET_FORMAT_OPTION` Dict:**
- `"never"` → Options that persist across all changes:
    - `:plottype`, `:theme`
- `"source"` → Options reset when data source changes:
    - `:title`, `:xlabel`, `:ylabel`, `:show_legend`, `:legend_title`
    - `:x_min`, `:x_max`, `:y_min`, `:y_max`, `:xreversed`, `:yreversed`
- `"range"` → Options reset when (Re-)Plot button is clicked:
    - `:x_min`, `:x_max`, `:y_min`, `:y_max`, `:xreversed`, `:yreversed`

**Data Source Tracking:**
- `last_plotted_x`, `last_plotted_y` - track last X and Y variable names (Array mode)
- `last_plotted_dataframe` - tracks last DataFrame name (DataFrame mode)

**Flow:**
1.  **New Data Source**: `is_new_data=true` → reset options in `RESET_FORMAT_OPTION["source"]`, initialize text fields from plot defaults.
2.  **(Re-)Plot Button**: `reset_semipersistent=true` → reset options in `RESET_FORMAT_OPTION["range"]` (axis limits).
3.  **Format Change**: Preserve all format customizations, axis limits passed via `get_current_axis_limits(state)`.
4.  **User Edit**: Mark corresponding flag as `false` (e.g., user changes title → `format_is_default[:title] = false`).
5.  **Replot**: After creating new plot, `apply_custom_formatting!` iterates over non-default options and re-applies them.

#### 3. Legend Behavior
- **Default Visibility**: `show_legend` defaults to `true` only if `n_cols > 1`.
- **State Management**:
    - **New Plot**: Legend title is reset to empty.
    - **Format Change**: Legend title and visibility persist.
- **User Override**: Checkbox allows manual toggle, persisting through format updates.

### Plotting Implementation (plotting.jl)

All plotting uses **AlgebraOfGraphics exclusively** (no direct Makie `Figure`/`Axis` calls in plotting logic).

**Key Functions:**
- `do_replot(state, outputs; data, plot_format, is_new_data)`: **Unified entry point** for all plotting
  - `data`: Either `(; x_name, y_name)` for arrays or `(; df, x_name, y_name)` for DataFrames
  - `plot_format`: `(; plottype, show_legend, legend_title, group_by)` + axis limits
  - `is_new_data`: If true, initializes text fields from plot defaults
- `check_data_create_plot(x_name, y_name; plot_format)`: Fetch from Main, delegate to create_plot
- `create_plot(x_data::AbstractVector, y_data, ...)`: Arrays → DataFrame → AoG pipeline
- `create_plot(df::AbstractDataFrame; xcol=1, ...)`: DataFrame → long format → AoG
- `create_plot_df_long(df, ...)`: Core AoG plotting logic
- `update_plot_format!(fig, axis; title, xlabel, ylabel)`: Update axis labels without replot
- `apply_custom_formatting!(fig, ax, state)`: Re-apply non-default format options after replot

**AlgebraOfGraphics Pattern:**
```julia
# Group differentiation based on group_by setting:
group_mapping = if group_by == "Geometry" && plottype != BarPlot
    plottype == Lines ? (; linestyle = group_col => legend_title) : (; marker = group_col => legend_title)
else
    (; color = group_col => legend_title)
end
plt = data(df) * mapping(x_col => x_name, y_col => y_name; group_mapping...) * visual(plottype)
fg = draw(plt; figure=(; size=(800, 600)), legend=(show=show_legend,), axis=(; title))
fig = fg.figure
axis = fg.grid[1, 1].axis  # Extract Axis from FigureGrid
```

**Exports to Main:**
```julia
global cp_figure = fig      # Figure object
global cp_figure_ax = axis  # Axis object for fine-tuning
```

### Known Issues 
   
- currently none

### Road-map

#### Deliberately Limited Feature Set

- Only support for the most common 2‑D plot types (`Scatter`, `Lines`, `BarPlot`) is planned

#### Planned Enhancements (as of v0.5.0)

- ~~Axis limits~~ ✓ Implemented (configurable min/max, reversal, pan/zoom sync)
- ~~Themes~~ ✓ Implemented (Makie default, AoG, theme_black/dark/ggplot2/light/minimal)
- ~~Group differentiation~~ ✓ Implemented (Color or Geometry; Geometry disabled for BarPlot)
- Support for multiple independent data sources
- Automatic Julia code generation from GUI actions
- Optional regression‑fit overlays  

### Development Workflows

#### Adding a New Plot Type:
1. Add to `supported_plot_types` in `app.jl`
2. Ensure the type evaluates to a valid AoG visual (e.g., `Scatter`, `Lines`)
3. No changes needed in `plotting.jl` (uses generic `visual(plottype)`)

#### Modifying UI Components:
1. **Control panel**: Edit `create_control_panel_ui.jl`
2. **Tabs**: Modify `ui_tabs.jl`
3. **Layout**: Adjust `assemble_layout` in `ui_layout.jl`
4. **Styles**: Edit `css_styles.css` (prefer CSS classes over inline styles)

#### Adding New Observables:
1. Initialize in `initialize_app_state()` (`app_state.jl`)
2. Add to state NamedTuple unpacking where needed
3. Connect to callbacks in relevant `setup_*_callback` function

#### Debugging Observable Updates:
- Use `on(obs) do val; @info "Observable changed" val; end` pattern
- Check `block_format_update[]` state to verify race prevention
- Verify callback execution order in REPL output

### Testing
- Manual testing via `src/scripts/casualplots_test.jl`
- Browser testing with Antigravity plugin (conversation history refs) via `src/scripts/casualplots_browser-test.jl`
- Test suite is using SafeTestsets.jl package. Each `@safetestset` is in an included file. It can contain one more level of `@testset` if necessary, but not more.
- Test suite WIP in early stage.
  - Tests for non-GUI-functions only yet

### Precompilation

See [Precompilation](AGENTS_more_info/specific_issues.md/precompilation.md) for details on PrecompileTools workload, Electron hidden window feature, and known limitations.


### Exports
```julia
export casualplots_app      # Main app launcher
export cp_figure            # Global Figure object
export cp_figure_ax         # Global Axis object  
export Ele                  # Displaying Bonito `app` in Electron window 
```

## UI Screenshots

### Data Source Selection
**DataFrame Selection:**
![DataFrame Source Selection](AGENTS_more_info/ScreenShots/DataFrame%20source%20selection%20tab.png)

**Array Selection:**
![Array Source Selection](AGENTS_more_info/ScreenShots/Source%20selection%20-%20arrays.png)

### Plotting Examples
**DataFrame Plotting:**
![DataFrame Plot Example](AGENTS_more_info/ScreenShots/DataFrame%20selected,%20checkboxes%20selected.png)

**Array Plotting:**
![Array Plot Example](AGENTS_more_info/ScreenShots/X,Y%20arrays%20selected,%20plot,%20table%20displayed.png)

### Plot Formatting
**Format Pane:**
![Format Pane](AGENTS_more_info/ScreenShots/Format%20pane%20for%20DataFrames%20source.png)

## Development Status
**Status**: Work In Progress (WIP) - Core functionality operational, ongoing refinement and feature additions.

