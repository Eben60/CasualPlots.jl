# CasualPlots

[![Build Status](https://github.com/Eben60/CasualPlots.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Eben60/CasualPlots.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Eben60/CasualPlots.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Eben60/CasualPlots.jl)

**This package is a work in progress. It is already functional to an extent, but still in its early stages.**

## Aims

`CasualPlots.jl` aims to provide a graphical user interface (GUI) to simplify the creation of plots in Julia. The tool is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications.

The tool is intended to be started from a Julia command line, providing access to the variables defined in the script's environment.

The intended user is someone who wants an easy way to create common plot types without memorizing dozens or hundreds of options.

## What It Does (now, or in future)

`CasualPlots` provides a GUI window where you can quickly visualize your data. You can select data from your `Main` namespace, or from disk, and the plot will be displayed along with a table view of your data. You can customize some common attributes like plot title, and switch between different plot types. You can simply save it as a `PNG` or `SVG` file directly from the GUI, or you can manually customize the `Makie.Figure` object that `CasualPlots` exports to your workspace.


It uses [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl), [AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl), and [WGLMakie.jl](https://github.com/MakieOrg/Makie.jl) under the hood.

As of v0.0.4, you can test it in an [Electron.jl](https://github.com/JuliaGizmos/Electron.jl) window or in a browser using the scripts in the `src/scripts/` folder.
