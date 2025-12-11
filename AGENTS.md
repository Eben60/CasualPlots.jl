# CasualPlots.jl - AI Agent Technical Reference

## Package Overview
**CasualPlots.jl** is a GUI-based plotting application for Julia which is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications. Target users are experimental scientists and engineers needing quick visualization without memorizing syntax. Aims to cover 60-80% of common 2D plotting needs (Scatter/Line/BarPlot, basic formatting).

## Core Architecture

### Coding Conventions

* Unless technically required, do not supply argument types to functions. In the docstring however, specify the type the function is expected to process properly. Technical need may be in case of a function with multiple methods. If specifying type, do not overspecify, e.g. `foo(x::Real)` should be used instead of `foo(x::Float64)` if `foo` would process any real type just as well. Example:

```
"""
    foo(x::Real)

Squaring the x
"""
function foo(x)
    return x^2
end
```

* Always start `NamedTuple`s with a semicolon. Always use semicolon before kwargs in function calls.Example:
```
# Good
state = (; x = 1, y = 2)
foo(a, b; kwarg1 = 1, kwarg2 = 2)
```

* If a Tuple, function arguments or other comma-separated lists span several lines, put a comma after the last item, too. Example:
```
items = (
    item1,
    item2,
    item3,  # trailing comma
)
```

### Technology Stack
*   **[Bonito.jl](https://github.com/SimonDanisch/Bonito.jl)**: Web-based reactive GUI framework
*   **[WGLMakie](https://github.com/MakieOrg/Makie.jl)**: WebGL-based plotting backend
*   **[AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl)**: Declarative plot specification (all plots built using AoG)
*   **[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)**: Data handling
*   **[Observables.jl](https://github.com/JuliaGizmos/Observables.jl)**: Reactive state management
*   **[Electron.jl](https://github.com/davidanthoff/Electron.jl)**: Window hosting 

### File Structure (src/)
```
CasualPlots.jl                  # Main module, exports casualplots_app()
app.jl                          # Main app entry point (casualplots_app function)
app_helpers.jl                  # Helper functions for app assembly
collect_data.jl                 # Data collection from Main module
create_demo_data.jl             # Demo data generation
dropdowns_setup.jl              # Dropdown menu initialization
create_control_panel_ui.jl      # Control panel UI construction
create_control_panel_ui_helpers.jl  # UI component helpers
tabs_component.jl               # Tab-based UI organization
setup_callbacks.jl              # Core reactive callbacks (source, format, DataFrame)
label_update_callbacks.jl       # Label text field callbacks
plotting.jl                     # Plot generation using AlgebraOfGraphics
electron.jl                     # Electron window integration
create_save_ui.jl               # Save tab UI construction
modal_dialog.jl                 # Modal dialog component
save_plot.jl                    # Plot saving functionality (CairoMakie backend)
scripts/                        # Example/demo scripts
```

### Reactive State Architecture

#### State Structure
The application uses a `NamedTuple` called `state` containing all reactive `Observable` objects:

```julia
state = (
    selected_x::Observable{Union{String,Nothing}},
    selected_y::Observable{Union{String,Nothing}},
    plot_format = (
        selected_plottype::Observable{String},
        show_legend::Observable{Bool}
    ),
    plot_handles = (
        xlabel_text::Observable{String},
        ylabel_text::Observable{String},
        title_text::Observable{String},
        legend_title_text::Observable{String},
        current_figure::Observable{Union{Figure,Nothing}},
        current_axis::Observable{Union{Axis,Nothing}}
    ),
    block_format_update::Observable{Bool},  # Race condition prevention
    # DataFrame mode
    selected_df::Observable{Union{String,Nothing}},
    selected_cols::Observable{Vector{String}},
    # Save functionality
    save_file_path::Observable{String},           # Persists across plots
    save_status_message::Observable{String},
    save_status_type::Observable{Symbol},         # :none, :success, :warning, :error
    show_overwrite_confirm::Observable{Bool},     # Kept for backward compat / specific path flows
    # Modal Dialog
    show_modal::Observable{Bool},
    modal_type::Observable{Symbol}                # :none, :success, :warning, :confirm
)
```

#### Output Observables
Separate `outputs` NamedTuple for UI display:
```julia
outputs = (
    plot::Observable{Any},           # DOM element for plot pane
    table::Observable{Any},          # DOM element for table pane
    current_x::Observable{Any},      # Currently plotted X data
    current_y::Observable{Any}       # Currently plotted Y data
)
```

### Developer Diagrams

Diagrams are in the linked files:

- [High-Level User Flow](AGENTS_more_info/Mermaid/high-level_user_flow.md)
- [Callback Execution Sequence](AGENTS_more_info/Mermaid/callback_execution_sequence.md)
- [State Transition Map](AGENTS_more_info/Mermaid/state_transition_map.md)


### Critical Implementation Patterns

#### 1. Source Selection & Plotting Flow
Both **X,Y Source** and **DataFrame Source** modes follow a similar two-step selection process, but differ in how plotting is triggered.

**A. X,Y Source Selection:**
1.  **Step 1: X Selection** (`setup_x_callback`)
    - User selects X variable.
    - Triggers population of congruent Y-variable options.
    - Clears current Y selection.
2.  **Step 2: Y Selection** (`setup_source_callback`)
    - User selects Y variable.
    - **Immediately triggers plotting**:
        - Fetches data from `Main`.
        - Generates plot with **default labels**.
        - Updates `current_plot_x`, `current_plot_y`.
        - Updates table view.
        - Blocks format callback to prevent race conditions (`state.block_format_update[] = true`).
    - *On invalid selection*: Clears plot, table, and state.

**B. DataFrame Source Selection:**
1.  **Step 1: DataFrame Selection**
    - User selects a DataFrame.
    - Triggers population of column checkboxes.
    - Clears current column selection.
2.  **Step 2: Column Selection & Plotting** (`setup_dataframe_callbacks`)
    - User selects columns (checkboxes).
    - **Plotting is triggered manually**: User must click "(Re-)Plot" button.
    - `plot_trigger` observable fires:
        - Validates selection (at least 2 columns).
        - Calls `update_dataframe_plot` helper.
        - Generates plot with **default labels** (resets legend title).
        - Updates table view.

#### 2. Formatting & Updates
Formatting changes (Plot Type, Legend, Labels) are handled differently to preserve user customizations and optimize performance. Both X,Y and DataFrame modes have separate format callback implementations that follow identical patterns.

**A. Format Callback Logic:**
- **Triggered by**: `selected_plottype`, `show_legend`, `legend_title_text`.
- **Implementations**:
    - X,Y Mode: `setup_format_callback` (uses `check_data_create_plot`)
    - DataFrame Mode: Format callback within `setup_dataframe_callbacks` (uses `update_dataframe_plot` helper)
- **Shared Behavior**:
    - Replots using **currently stored data** (no new data fetch).
    - **Preserves user labels**: Applies text from `xlabel_text`, `ylabel_text`, etc., to the new plot, overriding defaults.
    - **Does NOT update table**: Table update is skipped as data hasn't changed.
    - **Race Condition Prevention**: Returns early if `block_format_update[]` is true.

**B. Label Persistence Strategy:**
To ensure user edits to labels aren't lost during formatting updates:
1.  **Source Update**: Generates plot with *default* labels from data, then updates the text input fields.
2.  **Format Update**: Reads values *from* the text input fields and applies them to the new plot, ensuring manual edits persist.

#### 3. Legend Behavior
- **Default Visibility**: `show_legend` defaults to `true` only if `n_cols > 1`.
- **State Management**:
    - **New Plot**: Legend title is reset to empty.
    - **Format Change**: Legend title and visibility persist.
- **User Override**: Checkbox allows manual toggle, persisting through format updates.

### Plotting Implementation (plotting.jl)

All plotting uses **AlgebraOfGraphics exclusively** (no direct Makie `Figure`/`Axis` calls in plotting logic).

**Key Functions:**
- `check_data_create_plot(x_name, y_name; plot_format)`: Fetch from Main, delegate to create_plot
- `create_plot(x_data::AbstractVector, y_data, ...)`: Arrays → DataFrame → AoG pipeline
- `create_plot(df::AbstractDataFrame; xcol=1, ...)`: DataFrame → long format → AoG
- `create_plot_df_long(df, ...)`: Core AoG plotting logic

**AlgebraOfGraphics Pattern:**
```julia
plt = data(df) * mapping(x_col => x_name, y_col => y_name; color=group_col => legend_title) * visual(plottype)
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
   
1. **Label Persistence** : Plot title/labels by user not always successful, often multiple "Enters" combined with text changes necessary.
   - Tried Solution: Logics implemented in `force_plot_refresh` improves situation, but not 100%

### Road-map

#### Deliberately Limited Feature Set

- Only support for the most common 2‑D plot types (`Scatter`, `Lines`, `BarPlot`) is planned

#### Planned Enhancements (as of v0.0.3)

- Importing data from external files  
- Exporting plots to image/PDF formats  
- Optional regression‑fit overlays  
- Automatic Julia code generation from GUI actions  
- Additional formatting options (e.g., axis limits, themes)  
- Support for multiple independent data sources


### Development Workflows

#### Adding a New Plot Type:
1. Add to `supported_plot_types` in `app.jl`
2. Ensure the type evaluates to a valid AoG visual (e.g., `Scatter`, `Lines`)
3. No changes needed in `plotting.jl` (uses generic `visual(plottype)`)

#### Modifying UI Components:
1. **Control panel**: Edit `create_control_panel_ui.jl` and helpers
2. **Tabs**: Modify `tabs_component.jl`
3. **Layout**: Adjust `assemble_layout` in `app_helpers.jl`

#### Adding New Observables:
1. Initialize in `initialize_app_state()` (app_helpers.jl)
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
- Test suite WIP in early stage, currently (as of v0.0.5) only "easy" tests for non-GUI-functions 


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
**Status**: Early Work In Progress (WIP) - Core functionality operational, ongoing refinement and feature additions.

