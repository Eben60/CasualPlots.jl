# CasualPlots.jl - AI Agent Technical Reference

## Package Overview
**CasualPlots.jl** is a GUI-based plotting application for Julia which is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications. Target users are experimental scientists and engineers needing quick visualization without memorizing syntax. Aims to cover 60-80% of common 2D plotting needs (Scatter/Line/BarPlot, basic formatting).

## Core Architecture

### JavaScript Conventions
*   **External Logic**: All non-trivial JavaScript logic must be placed in `src/javascripts.js` and namespaced under `window.CasualPlots`.
*   **Inline Minimization**: Inline JS in Julia files (`js"..."`) should be restricted to simple calls to these external functions or mandatory one-liners.
*   **Loading**: The `javascripts.js` file is read and injected as a script tag in the main application layout (`app.jl`).

### Technology Stack
*   **[Bonito.jl](https://github.com/SimonDanisch/Bonito.jl)**: Web-based reactive GUI framework
*   **[BonitoWidgets.jl](https://github.com/SimonDanisch/BonitoWidgets.jl)**: Advanced layout system (Workspace, Panels, Tabs, FloatingWindow)
*   **[WGLMakie](https://github.com/MakieOrg/Makie.jl)**: WebGL-based plotting backend
*   **[AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl)**: Declarative plot specification (all plots built using AoG)
*   **[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)**: Data handling
*   **[Observables.jl](https://github.com/JuliaGizmos/Observables.jl)**: Reactive state management
*   **[Electron.jl](https://github.com/davidanthoff/Electron.jl)**: Window hosting 
*   **[CSV.jl](https://github.com/JuliaData/CSV.jl)** / **[XLSX.jl](https://github.com/felipenoris/XLSX.jl)**: File I/O via Package Extensions

### Error Handling & Logging
*   **User-Facing Errors/Warnings**: Any errors and warnings in code run from the GUI (e.g., callbacks, file reading, script generation) must call `show_modal!` to inform the user, rather than silently failing or exclusively logging to the REPL. Caught GUI errors also save their backtrace automatically, which can be viewed in the REPL using `CasualPlots.last_error()`.
*   **Error Propagation Rule**: Low-level functions (like data fetchers) should not catch expected errors. Instead, errors should naturally propagate up to the outermost reactive boundaries (e.g., `on(...)` blocks in `setup_callbacks.jl`), which must catch them and call `show_modal!`. When an error is caught in a plot/table callback, the respective panes should be blanked (`outputs.plot[] = DOM.div("")`).
*   **"Skippable" Errors Exception**: An exception to the propagation rule is for "skippable" errors during bulk iteration, which need not be presented to user. 

### File Structure (src/)

```
CasualPlots.jl                  # Main module, exports casualplots_app()
struct_CasualPlotApp.jl         # Wrapper struct to expose reactive state and avoid memory leaks
app.jl                          # Main app entry point (casualplots_app function)
app_state.jl                    # Application state initialization (Observables)
app_types.jl                    # Type definitions used across the application
constants.jl                    # Application-wide constants
css_styles.css                  # Global CSS styles for all UI components
javascripts.js                  # Global JavaScript functions (namespaced window.CasualPlots)

# Core Logic
plot_types.jl                   # Declarative plot type configuration system (SinglePlotConfig, CompoundPlot, EnumAttribute)
plotting.jl                     # Plot generation using AlgebraOfGraphics
setup_callbacks.jl              # Core reactive callbacks (do_replot, source, format, DataFrame)
label_update_callbacks.jl       # Label text field callbacks
dropdowns_setup.jl              # Dropdown menu creation (X, Y, DataFrame)
code_generation.jl              # Automatic Julia code generation from GUI state
integrations_unitful.jl         # Unitful.jl support for plotting quantities with units

# UI Components (gui_*.jl)
gui_tabs.jl                     # Tab component + create_tab_content wiring
gui_layout.jl                   # assemble_layout - Workspace grid construction, FloatingWindows with maximize/restore/resize
gui_table.jl                    # Table display with info header and dynamic column type coloring
gui_help_section.jl             # Mouse controls help text
gui_source_tab.jl               # Source selection UI (Array/DataFrame modes)
gui_format_tab.jl               # Format controls UI (plot type, legend, labels)
gui_open_tab.jl                 # File open tab UI
gui_save_tab.jl                 # Save tab UI
gui_modal_dialog.jl             # Modal dialog component

# Control Panel
create_control_panel_ui.jl      # Control panel UI construction (static layout w/ CSS toggling)

# Data Handling
collect_data.jl                 # Data collection from Main module
preprocess_dataframes.jl        # Data frame normalization and validation
load_from_file.jl               # File reading logic (CSV/XLSX) and loading callbacks
options_file_reading.jl         # Options processing for file reading
create_demo_data.jl             # Demo data generation

# Save/Export
save_plot.jl                    # Plot saving functionality (CairoMakie backend)

# Other
electron.jl                     # Electron window integration (show kwarg for hidden windows)
FileDialogWorkAround.jl         # Cross-platform file dialog utilities
extensions.jl                   # Package extensions loader
precompile.jl                   # PrecompileTools workload for reducing TTFP
public.julia                    # Public API declarations

scripts/                        # Example/demo scripts
../ext/                         # Package Extensions (ReadCSV_Ext.jl, ReadXLSX_Ext.jl)
../test/AgenticTesting/         # Workspace sub-project containing GUI testing utilities
```

### Reactive State Architecture

The application uses a reactive `state` struct (`CasualPlotsState`) with `Observables.jl` for all UI state management.
To provide REPL read-access, the `Bonito.App` and the `state` are bundled in a `CasualPlotApp` struct returned by `casualplots_app()`.
See [Reactive State Architecture](AGENTS_more_info/specific_issues/reactive_state_architecture.md) for the full state structure and output observables documentation.

**Window Management & Layout**: The Plot and Table panes are implemented as `BonitoWidgets.FloatingWindow`s. Custom JavaScript in `gui_layout.jl` injects window controls (Minimize, Restore, Maximize) and handles cross-window visibility toggling (e.g., maximizing the Plot pane hides the Table pane and Grid, while restoring resets the layout). A `ResizeObserver` monitors the Plot pane's dimensions and notifies a `plot_size` observable, which triggers an in-place `Makie.resize!` of the figure without a full replot.

### Developer Diagrams

Diagrams are in the linked files:

- [High-Level User Flow](AGENTS_more_info/Mermaid/high-level_user_flow.md)
- [Callback Execution Sequence](AGENTS_more_info/Mermaid/callback_execution_sequence.md)
- [State Transition Map](AGENTS_more_info/Mermaid/state_transition_map.md)


### Critical Implementation Patterns

See [Callback & Formatting Flow](AGENTS_more_info/specific_issues/callback_and_formatting_flow.md) for the full source selection pipeline (X,Y, DataFrame, File Import), format persistence strategy (`RESET_FORMAT_OPTION`), and legend behavior.

See [Data Cleansing](AGENTS_more_info/specific_issues/data_cleansing.md) for `clean_plot_data!`, Unitful unification, and numeric normalization.

### Plot Types & Plotting Implementation

See [Plot Architecture](AGENTS_more_info/specific_issues/plot_architecture.md) for the declarative `SinglePlotConfig`/`CompoundPlot` system, `EnumAttribute` routing, the `do_replot` unified entry point, and the AoG pipeline pattern.

### Known Issues 
   
- currently none

### Road-map

#### Deliberately Limited Feature Set

- Only support for the most common 2‑D plot types (`Scatter`, `Lines`, `BarPlot`, and maybe a few others) is planned

#### Planned Enhancements (as of v0.10.0)

- More plot format options, e.g. palettes
- Support for multiple independent data sources in a diagram
    - Dual-Y or dual-X axes with different scales
- Optional regression‑fit integration
- Extensive Documenter.jl based documentation

### Development Workflows & Testing

- Review the **Testing Guidelines** Knowledge Item (KI) before running or modifying tests.
- Manual testing via `src/scripts/casualplots_test.jl`

See [Development Workflows](AGENTS_more_info/specific_issues/development_workflows.md) for UI modification guides, adding observables, debugging patterns, interactive agentic testing workflow, and SafeTestsets conventions.

See [Agentic Screenshots](AGENTS_more_info/specific_issues/agentic_screenshots.md) for instructions on automating UI screenshots seamlessly through Electron without UI clutter.

### Precompilation

See [Precompilation](AGENTS_more_info/specific_issues/precompilation.md) for details on PrecompileTools workload, Electron hidden window feature, and known limitations.


### Exports
```julia
export casualplots_app      # Main app launcher
export CasualPlotApp        # Wrapper around Bonito.App containing reactive state
export cp_figure            # Global Figure object
export cp_figure_ax         # Global Axis object  
export Ele                  # Displaying Bonito `app` in Electron window 
```

## UI Screenshots

For annotated screenshots of the GUI in action, refer to the **[Tutorial (WIP)](docs/src/tutorial.md)**, which covers:

- **Data Selection** — X,Y Arrays mode and DataFrame mode (§2a, §2b)
- **File Import** — Open tab with CSV/XLSX options (§2c)
- **Plot Formatting** — Lines/Scatter plots, BarPlot (Dodged & Stacked), Axis Limits (§3)
- **Window Management** — Maximized Plot Pane (§4)
- **Data Table** — Column header color coding by type (§5)
- **Export & Script Generation** — Save tab (§6)

## Development Status
**Status**: Work In Progress (WIP) - Core functionality operational, ongoing refinement and feature additions.

## Agent Housekeeping Rules
- Whenever the Agent notes that a new commit has been made, they should ask the user whether to update `AGENTS.md` and `docs/src/changelog.md`.
