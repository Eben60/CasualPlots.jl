"""
    Package CasualPlots v$(pkgversion(CasualPlots))

This package provides GUI for easy plots creation. Currently WIP.

Package local path: $(pathof(CasualPlots))
"""
module CasualPlots

using Bonito, Observables, Hyperscript, AlgebraOfGraphics, WGLMakie, DataFrames
using Bonito.DOM



include("Ele.jl")


include("collect_data.jl")
include("create_data.jl")

include("plotting.jl")
include("tabs_component.jl")
include("three_panes_fns.jl")

export cp_figure, cp_figure_ax
export Ele

end
