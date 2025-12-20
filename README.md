# CasualPlots

[![Build Status](https://github.com/Eben60/CasualPlots.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Eben60/CasualPlots.jl/actions/workflows/CI.yml?query=branch%3Amain)

**This package is a work in progress.**

## Aims

`CasualPlots.jl` aims to provide a graphical user interface (GUI) to simplify the creation of plots in Julia. The tool is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications.

The tool is intended to be started from a Julia command line, providing access to the variables defined in the script's environment.

The expected user is someone who wants an easy way to create common plot types without memorizing dozens or hundreds of options.

## What It Does

`CasualPlots` provides a GUI window where you can quickly visualize your data. You can select data from your `Main` namespace, or from disk, and the plot will be displayed along with a table view of your data. You can customize some common attributes like plot title, and switch between different plot types. You can simply save it as a `PNG`, `SVG`, or `PDF` file directly from the GUI, or you can manually customize the exported `Makie.Figure` object.

## How It Does It

It uses [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl), [AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl), and [WGLMakie.jl](https://github.com/MakieOrg/Makie.jl) under the hood.

## How To Use

Note: it currently needs Julia v1.12 or higher. The package is registered. Keep in mind, the package has a heavy dependency footprint (pulling in around 300 transitive dependencies), so, to avoid potential version conflicts, you might want to avoid installing it into your "main/default" environment like this:

```
(@v1.12) pkg> add CasualPlots
```

Instead better install it in directly your project environment(s). Alternatively you can install it into a shared environment and make it available from everywhere with the help of [ShareAdd.jl](https://github.com/Eben60/ShareAdd.jl) package:

```
julia> using ShareAdd

julia> @usingany CasualPlots
```

`@usingany` would import a package from any shared environment if available, otherwise first install it into a shared env of your choice.

The package creates a Bonito GUI app, which can be opened in an [Electron.jl](https://github.com/JuliaGizmos/Electron.jl) window, in a browser, or in a plot pane of VSCode. If you need to read data from CSV and/or "excel" files, you need to import `CSV` and/or `XLSX` packages, as these are implemented as extensions.

Examples:

### Default display, which may be plot pane or browser

```
julia> using CasualPlots

julia> using CSV, XLSX # optionally

julia> app = casualplots_app()

julia> display(app)

julia> close(app) # you may close the app when you no longer need it
```

### Serving to browser

```
julia> app = casualplots_app()

julia> server = Bonito.Server(app, "127.0.0.1", 8000)
┌ Warning: Port in use, using different port. New port: 8001
└ @ Bonito.HTTPServer ~/.julia/packages/Bonito/18mTs/src/HTTPServer/implementation.jl:346
Server:
  isrunning: true
  listen_url: http://localhost:8001
  online_url: http://localhost:8001
  http routes: 1
    / => App
  websocket routes: 0
```

After starting the server, go to browser and navigate to `http://localhost:8000` or `http://127.0.0.1:8000`. You get a message in the Terminal if the port 8000 is busy and other port is used.

### Opening a Standalone Electron Window

```
julia> app = casualplots_app()

julia> Ele.serve_app(app)
```

The author sees Electron as the preferred usage way.

See usage/testing examples in the scripts in the folder `src/scripts` of the package.

### Accessing Created Plot

The plot (the `Makie.Figure` object, to be exact) is exported as `cp_figure`, whereas its `Axis` object exported as `cp_figure_ax`. Both objects will be accessible in REPL as soon as the plot is displayed. You a free to modify them in any way possible in `Makie`:

```
# the change will be immediately reflected in the currently displayed plot
julia> hidespines!(cp_figure_ax, :r, :t)
```

## Current State

In short, it is WIP. Particularly, if you see this README, the package is far from being finished, as it is intended, among other things, to create a Documenter.jl based documentation. However, the main goals are already implemented and the package is usable.

- [✅] A GUI with panes for user interactions, plot display, and source data display.
- [✅] Data sources: variables defined in the Main module (vectors, matrices, dataframes).
- [✅] Data sources: CSV and XLSX files.
    - [🚧] Support for CSV/XLSX file reading options (kwargs) planned.
- [✅] Plotting: Lines and Scatter plots.
    - [🚧] More plot formatting options.
- [✅] Saving plot to a file.
- [✅] Exporting the Figure object.
- [❌] Saving the Figure object to `JLD2` file.
- [❌] Precompile to reduce TTFP.
- [❌] Documenter.jl based documentation.
- [❌] Automatic generation of Julia code corresponding to the user’s actions.
- [❌] Applying a least-squares fit from the GUI.

## Screenshots

- [Open File Tab](AGENTS_more_info/ScreenShots/open_file_tab.png)
- [X, Y Source Selection, Scatter Plot](AGENTS_more_info/ScreenShots/xy_source_selection.png)
- [DataFrame Source Selection](AGENTS_more_info/ScreenShots/dataframe_source_selection.png)
- [Format Tab, Lines Plot](AGENTS_more_info/ScreenShots/format_tab.png)
- [Save Tab](AGENTS_more_info/ScreenShots/save_tab.png)
