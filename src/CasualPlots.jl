"""
    Package CasualPlots v$(pkgversion(CasualPlots))

This package provides GUI for easy plots creation. Currently WIP.

Package local path: $(pathof(CasualPlots))
"""
module CasualPlots

using Bonito, Observables, AlgebraOfGraphics, WGLMakie, DataFrames
using Bonito.DOM

include("electron.jl")

include("collect_data.jl")
include("create_demo_data.jl")

include("plotting.jl")
include("tabs_component.jl")
include("setup_callbacks.jl")
include("label_update_callbacks.jl")

include("app_helpers.jl")
include("app.jl")

export casualplots_app
export cp_figure, cp_figure_ax
export Ele

end
