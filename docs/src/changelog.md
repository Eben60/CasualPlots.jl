# Changelog

### [0.9.1]

_WIP_

**Added**
- Auto-select the first sheet by default when opening XLSX files.
- Visual loading indicator in the Plot pane during heavy operations (e.g., initial JIT compilation).

**Changed/Internal**
- Centralized REPL logging into `show_modal!` to automatically mirror GUI popups to the REPL.
- Various minor behavior fixes


### [0.9.0]

_2026-08-16_

**Added**
- `Line+Symbol` composite plot type support.

**Changed**
- Improved the Data Table view with reliable scrolling and cleaner number formatting.

**Internal**
- Complete overhaul of the plot type architecture. Adding new plot types or composite layers is now modular and straightforward.

### [0.8.0]

_2026-08-11_

- Migration to use [`BonitoWidgets.jl`](https://github.com/SimonDanisch/BonitoWidgets.jl).
- Floating and resizable Plot and Table panes.
    - Pane controls for minimize, restore, and maximize actions.


### [0.7.0]

_2026-07-26_

- Added vertical and horizontal BarPlots with support for **Dodged** and **Stacked** grouping modes.

### [0.6.0]

_2026-07-13_

- Standalone Julia script generation reflecting active GUI state using [`AlgebraOfGraphics.jl`](https://github.com/MakieOrg/AlgebraOfGraphics.jl) and [`CairoMakie.jl`](https://github.com/MakieOrg/Makie.jl).
- Color-coded table column headers indicating data types (green=numeric, blue=[`Unitful.jl`](https://github.com/PainterQubits/Unitful.jl), yellow=other).
- Support for mixed compatible units within a single column and cross-column unit unification.
- Introduced [`CasualPlotApp`](@ref) wrapper type to provide REPL read-access to application state.

### [0.5.0]

_2026-01-04_

- Added theme selection (Default, AoG, Dark, Light, Minimal, ggplot2, etc.).
- Option to differentiate dataset series by Color or Geometry (linestyle / marker).

### [0.4.0]

_2026-01-04_

- Editable numerical fields for `X min`, `X max`, `Y min`, and `Y max`.
- Options to reverse X and Y axis orientation.
- Two-way synchronization between canvas pan/zoom interactions and axis limit text fields.

### [0.3.0]

_2025-12-26_

- Introduced granular format options tracking (`RESET_FORMAT_OPTION`) to preserve user customizations across replots.
- Initial precompilation workload setup to reduce display latency.

### [0.2.0]

_2025-12-25_

- Configurable file reading options (header row, subheaders, skip empty rows, delimiter, decimal separator).

### [0.1.0]

_2025-12-25_

- Core [`Bonito.jl`](https://github.com/SimonDanisch/Bonito.jl) GUI application for 2D plotting in Julia.
- Support for 1D vectors, matrices, and DataFrames in the `Main` workspace.
- Package extensions for reading [`CSV.jl`](https://github.com/JuliaData/CSV.jl) and [`XLSX.jl`](https://github.com/felipenoris/XLSX.jl) files.
- Basic Line and Scatter plotting powered by [`AlgebraOfGraphics.jl`](https://github.com/MakieOrg/AlgebraOfGraphics.jl) and [`WGLMakie.jl`](https://github.com/MakieOrg/Makie.jl).
