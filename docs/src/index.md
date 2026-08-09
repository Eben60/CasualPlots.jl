# CasualPlots.jl

`CasualPlots.jl` is a GUI-based plotting application for Julia. It is positioned in the middle ground between purely script-based plotting and standalone GUI plotting tools. 

The package is intended for experimental scientists, engineers, and casual Julia users who require fast visual exploration of 2D data without having to memorize syntax for common plot customizations.

## Core Features

- **Interactive GUI**: Interactive layout built with [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl) and [BonitoWidgets.jl](https://github.com/SimonDanisch/BonitoWidgets.jl), containing floating and resizable Plot and Table panes.
- **AlgebraOfGraphics Engine**: Plotting pipeline built on top of [AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl) and [WGLMakie.jl](https://github.com/MakieOrg/Makie.jl).
- **Multiple Data Sources**:
  - Julia `Main` workspace variables (1D Vectors, Matrices, and DataFrames).
  - External files on disk (CSV/TSV and XLSX/Excel) via package extensions.
- **Synchronized Data Table**: Tabular view of plotted data with column header colors reflecting data types:
  - Green for numeric types.
  - Blue for `Unitful` quantity types.
  - Yellow for string, categorical, or other non-numeric types.
- **Automatic Data Cleansing**:
  - Non-numeric parsing in string/mixed columns (<10% invalid elements converted to `missing`).
  - Unitful quantity unification across compatible units in a single column or across multiple Y columns.
- **REPL Accessibility**: Exported `cp_figure` (`Makie.Figure`) and `cp_figure_ax` (`Makie.Axis`) objects allow direct manipulation from the REPL.
- **Script Generation**: Generates clean, standalone Julia scripts replicating GUI configuration and plot commands using `AlgebraOfGraphics` and `CairoMakie`.

## Installation

CasualPlots is registered in the general Julia package registry. Requires Julia 1.10 or higher.

To avoid version conflicts due to dependencies, installing into a project environment or using [ShareAdd.jl](https://github.com/Eben60/ShareAdd.jl) is recommended:

```julia
using ShareAdd
@usingany CasualPlots
```

Or install directly into an active project environment:

```julia
using Pkg
Pkg.add("CasualPlots")
```

## Accessing the GUI

After loading the package:

```julia
using CasualPlots

app = casualplots_app()
```

### Standalone Electron Window (Recommended)

To launch the GUI in a standalone window using [Electron.jl](https://github.com/JuliaGizmos/Electron.jl):

```julia
Ele.serve_app(app)
```

### Local Web Browser

To serve the application to a browser:

```julia
server = Bonito.Server(app, "127.0.0.1", 8000)
```

Navigate to `http://localhost:8000` in your web browser.

### REPL and VSCode Display

To render in the default Julia display (such as the VSCode Plot Pane or inline browser):

```julia
display(app)
```

To close the application session when finished:

```julia
close(app)
```

## Documentation Sections

- [Tutorial](tutorial.md): Step-by-step walkthrough of dataset selection, formatting, table interaction, file opening, and script generation.
- [API Reference](api.md): Autodoc reference for exported and public functions and types.
- [Script Generation](script_generation.md): Explanation of automatic Julia code generation with example scripts.
- [Changelog](changelog.md): Release notes across package versions.
