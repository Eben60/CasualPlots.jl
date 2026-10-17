# CasualPlots.jl

`CasualPlots.jl` is a GUI-based plotting application for Julia. It is positioned in the middle ground between purely script-based plotting and standalone GUI plotting tools. 

The package is intended for experimental scientists, engineers, and casual Julia users who require fast visual exploration of 2D data without having to memorize syntax for common plot customizations.

**What it is not**: In no way is the intention to compete with any “serious” tools in terms of feature scope – not with standalone behemoths like commercial [Origin](https://www.originlab.com/) or free [Veusz](https://veusz.github.io/), nor with Julia graphic packages like [Makie.jl](https://github.com/MakieOrg/Makie.jl) or [Plots.jl](https://github.com/juliaplots/plots.jl).

The main feature of `CasualPlots.jl` is the combination of a GUI for data visualization, both as table and plot, with direct access to the variables in the Julia REPL session. Once you create and format a plot, CasualPlots can generate a standalone Julia script that reproduces the exact visualization. You can then polish that script to produce a publication-ready figure or integrate the code directly into a data processing pipeline.


## Features

- **Data Sources**:
  - Julia `Main` workspace variables (1D Vectors, Matrices, and DataFrames). [Unitful](https://github.com/JuliaPhysics/Unitful.jl) data are welcome
  - External files on disk in CSV/TSV and XLSX format.
- **Plot Types**:   
  - Common 2D plot types: Scatter, Lines, Line+Symbol, and BarPlot (supporting vertical or horizontal orientation, and dodged or stacked modes).
  - Dataset grouping by color or geometry (marker shape or line style).
- **Data Table Representation**: Displays the active dataset in a scrollable table. 
- **Script Generation**: Generates standalone Julia scripts replicating plots configured in the GUI using `AlgebraOfGraphics` and `Makie`.
- **Saving Plots**: Exports static figures directly from the GUI as PNG, SVG, or PDF. 

## Software Stack

- **GUI**: [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl) and [BonitoWidgets.jl](https://github.com/SimonDanisch/BonitoWidgets.jl).
- **Plotting Pipeline**: [AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl) and [Makie.jl](https://github.com/MakieOrg/Makie.jl) (`WGLMakie.jl` for interactive display and `CairoMakie.jl` for file export).

## How To Use

### Installation

`CasualPlots.jl` is a registered package. It requires Julia v1.10 or higher.

!!! note
    Because the package pulls in roughly 300 transitive dependencies, avoid installing it into your default global environment to prevent potential version conflicts.

```julia-repl
# Not recommended:

(@v1.13) pkg> add CasualPlots
```

Instead, it is better to install it directly into your project environment/workspace. Alternatively, install it into a shared environment and load it anywhere using [ShareAdd.jl](https://github.com/Eben60/ShareAdd.jl):

```julia-repl
julia> using ShareAdd

julia> @usingany CasualPlots
```

`@usingany` loads the package from any shared environment if found. If not, it first prompts to install it into a shared environment of your choice.

### Launching the GUI

`CasualPlots.jl` creates a Bonito GUI application that can display in a standalone [Electron.jl](https://github.com/JuliaGizmos/Electron.jl) window, a web browser, or the VS Code plot pane.

#### Default Display (which may be plot pane or browser)

```julia-repl
julia> using CasualPlots

julia> app = casualplots_app()

julia> display(app)

julia> close(app)  # close the app when finished
```

#### Serving to a Web Browser

```julia-repl
julia> app = casualplots_app()

julia> server = Bonito.Server(app, "127.0.0.1", 8000)
Server:
  isrunning: true
  listen_url: http://localhost:8000
  online_url: http://localhost:8000
  http routes: 1
    / => App
  websocket routes: 0
```

Open a browser and navigate to `http://localhost:8000` (or the fallback port shown in the terminal message if port 8000 is occupied).

#### Standalone Electron Window

```julia-repl
julia> app = casualplots_app()

julia> Ele.serve_app(app)
```

The author prefers Electron when using the package.

See usage/testing examples in the scripts in the `src/scripts` folder of the package.

### Accessing Data and Plotting

!!! note
    **"TTFP**: even on a fast computer, there may be a noticeable delay, colloquially known to Julia users as the "Time To First Plot" (TTFP). Please be patient on the first use. Subsequent replotting is fast.

#### REPL Variables

Variables (`Vector`, `Matrix`, `DataFrame`) in `Main` are detected automatically. DataFrames are expected to follow the ["wide" format](https://aog.makie.org/stable/examples/data-manipulations/wide-data#Long-vs-Wide-Data-Formats).

In the **Source** tab:

-  For **X, Y Arrays** source, first, select an **X** variable. Only 1D arrays (vectors) of numeric or `Unitful` values are shown.
  - The **Y** dropdown then shows variables whose first dimension matches X's length. Click **(Re-)Plot** to create the plot.
- For **File/DataFrame/Matrix**, select one from the dropdown, then pick your columns. The first selected column becomes the X-values. Click **(Re-)Plot**.
- You can select a data range.

The selected data is also displayed in the table view.

#### External Files (CSV and XLSX)

Supported disk formats are **CSV/TSV**, and **XLSX** (Excel).
*These features use package extensions, so you must import the `CSV` and/or `XLSX` packages before starting the GUI.*

The GUI provides just a small subset of the file reading options available in the respective packages. If you have a file with some fancy formatting, you might need to load it into a `DataFrame` manually in the REPL; the data will then be available as a standard variable.

In the **Open** tab:

- Optionally configure reading options (header row, delimiter, decimal separator, etc.).
- Click **Open File** to select your file.
  - For **Excel** files with multiple tables, the first worksheet will be opened initially. You can select a different sheet from the dropdown.
- The data is displayed in the table. You can adjust reading options and click **Reload**  to re-parse the file.
- Once loaded, the file data appears under `"opened file"` in the **Source** tab's **File/DataFrame/Matrix** dropdown.

#### Data Table Column Coloring

Column headers in the table view indicate data types:
- 🟩 **Green**: Numeric data (`Float64`, `Int64`).
- 🟦 **Blue**: `Unitful` quantities (e.g., `10.5u"m"`).
- 🟨 **Yellow**: Other types (e.g. `String`).

#### Data Cleansing and Normalization

Before plotting, the application automatically cleanses and normalizes selected data:

- **Non-numeric values**: If a column contains fewer than 10% non-numeric values, `CasualPlots` replaces them with `missing` (displaying a warning modal) so the remaining valid data can be plotted. If non-numeric values exceed 10%, the column is left as-is: an X-axis column is treated as categorical, while a Y-axis column may result in a downstream plotting error.
- **Unitful quantities**:
  - **Within a column**: Compatible units (e.g., `m` and `cm`) are converted to a single common unit. Incompatible physical dimensions (e.g., `m` and `m^2`) or a mix of units and plain numbers raise an error.
  - **Across multiple Y columns**: If multiple Y columns have compatible units, they are unified to a single common unit on the Y-axis. If multiple Y columns have incompatible physical dimensions (e.g., plotting voltage and current on the same axis), `CasualPlots` displays a warning and strips the units so the values can still be plotted together.

### REPL Access to the Live Plot

The active plot's `Makie.Figure` and `Axis` objects are exported directly to the `Main` REPL environment as `cp_figure` and `cp_figure_ax`. You can inspect or modify them from the REPL; changes update the interactive GUI display immediately:

```julia-repl
# Directly modify the axis in the REPL; changes reflect in the GUI immediately
julia> hidespines!(cp_figure_ax, :r, :t)
```

### Saving Plots and Generating Scripts

In the **Save** tab:

- **Saving Plots**: Specify a file path (or click **Select File...**) with a `.png`, `.svg`, or `.pdf` extension, then click **Save Plot**. If the destination file already exists, a confirmation prompt prevents accidental overwriting.
- **Generating Scripts**: Click **Create Script** to generate a standalone Julia script (`.jl`) that recreates the plot.
