"""
    Package CasualPlots v$(pkgversion(CasualPlots))

This package provides GUI for easy plots creation. Currently WIP.

Package local path: $(pathof(CasualPlots))
"""
module CasualPlots

using Bonito, Observables, AlgebraOfGraphics, WGLMakie, CairoMakie, DataFrames, Dates
# using Bonito.DOM

include("electron.jl")
const GLOBAL_CSS = read(joinpath(@__DIR__, "css_styles.css"), String)

include("FileDialogWorkAround.jl")
using .FileDialogWorkAround
using .FileDialogWorkAround: posixpathstring

include("collect_data.jl")
include("create_demo_data.jl")

include("plotting.jl")
include("ui_tabs_component.jl")
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
include("get_and_preprocess_data.jl")
include("app_helpers.jl")
include("app.jl")
include("extensions.jl")

export casualplots_app
export cp_figure, cp_figure_ax
export Ele

end
