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

using Bonito, BonitoWidgets, Observables, AlgebraOfGraphics, WGLMakie, CairoMakie, DataFrames, Dates
using Unitful
using DataStructures: DefaultDict

include("electron.jl")
include("constants.jl")

include("FileDialogWorkAround.jl")
using .FileDialogWorkAround
using .FileDialogWorkAround: posixpathstring

include("collect_data.jl")
include("create_demo_data.jl")

include("plotting.jl")
include("gui_tabs.jl")
include("setup_callbacks.jl")
include("label_update_callbacks.jl")

include("dropdowns_setup.jl")
include("gui_source_tab.jl")
include("gui_format_tab.jl")
include("gui_open_tab.jl")
include("create_control_panel_ui.jl")
include("save_plot.jl")
include("gui_modal_dialog.jl")
include("gui_save_tab.jl")
include("options_file_reading.jl")
include("integrations_unitful.jl")
include("preprocess_dataframes.jl")
include("load_from_file.jl")
include("gui_help_section.jl")
include("gui_table.jl")
include("gui_layout.jl")
include("app_types.jl")
include("struct_CasualPlotApp.jl")
include("app_state.jl")
include("app.jl")
include("code_generation.jl")
include("extensions.jl")

include("precompile.jl")

export casualplots_app
export CasualPlotApp
export cp_figure, cp_figure_ax
export Ele

@static VERSION ≥ v"1.11" && include("public.julia") # define public functions

end
