"""
    Package CasualPlots v$(pkgversion(CasualPlots))

This package provides GUI for easy plots creation. Currently WIP.

Package local path: $(pathof(CasualPlots))
"""
module CasualPlots

using Bonito, Observables, AlgebraOfGraphics, WGLMakie, CairoMakie, DataFrames, Dates
# using Bonito.DOM

include("electron.jl")

include("FileDialogWorkAround.jl")
using .FileDialogWorkAround
using .FileDialogWorkAround: posixpathstring

include("collect_data.jl")
include("create_demo_data.jl")

include("plotting.jl")
include("tabs_component.jl")
include("setup_callbacks.jl")
include("label_update_callbacks.jl")

include("dropdowns_setup.jl")
include("create_control_panel_ui_helpers.jl")
include("create_control_panel_ui.jl")
include("save_plot.jl")
include("modal_dialog.jl")
include("create_save_ui.jl")
include("get_and_preprocess_data.jl")
include("app_helpers.jl")
include("app.jl")
include("extensions.jl")

export casualplots_app
export cp_figure, cp_figure_ax
export Ele

end
