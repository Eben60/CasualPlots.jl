"""
    Package CasualPlots v$(pkgversion(CasualPlots))

CasualPlots aims to provide a graphical user interface (GUI) to simplify the creation of plots in Julia. 
The tool is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications.

Package local path: $(pathof(CasualPlots))

Usage example:
```julia-repl
julia> using CasualPlots
julia> app = casualplots_app()
julia> Ele.serve_app(app) # Open GUI in Electron window
```
"""
module CasualPlots

using Bonito, Observables, AlgebraOfGraphics, WGLMakie, CairoMakie, DataFrames, Dates
using DataStructures: DefaultDict

include("electron.jl")
include("constants.jl")

include("FileDialogWorkAround.jl")
using .FileDialogWorkAround
using .FileDialogWorkAround: posixpathstring

include("collect_data.jl")
include("create_demo_data.jl")

include("plotting.jl")
include("ui_tabs.jl")
include("setup_callbacks.jl")
include("label_update_callbacks.jl")

include("dropdowns_setup.jl")
include("ui_source_tab.jl")
include("ui_format_tab.jl")
include("ui_open_tab.jl")
include("create_control_panel_ui.jl")
include("save_plot.jl")
include("ui_modal_dialog.jl")
include("ui_save_tab.jl")
include("file_reading_options.jl")
include("preprocess_dataframes.jl")
include("read_from_file.jl")
include("ui_help_section.jl")
include("ui_table.jl")
include("ui_layout.jl")
include("app_state.jl")
include("app.jl")
include("extensions.jl")
include("precompile.jl")

export casualplots_app
export cp_figure, cp_figure_ax
export Ele

end
