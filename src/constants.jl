# Constants for CasualPlots module

const REQUIRES_FULL_REPLOT = (; # TODO update and actually use it
    plottype = true, 
    show_legend = true,
    legend_title = true,
    title = false,
    xlabel = false,
    ylabel = false,
)

const DEFAULT_PLOT_TYPE = :Scatter

const SUPPORTED_THEMES = [
    "Makie default",
    "AoG default",
    "theme_black",
    "theme_dark",
    "theme_ggplot2",
    "theme_latexfonts",
    "theme_light",
    "theme_minimal",
]

const DEFAULT_THEME = "Makie default"

const GLOBAL_CSS = read(joinpath(@__DIR__, "css_styles.css"), String)

const AXES_LIMITS_OPTIONS = [:x_min, :x_max, :y_min, :y_max, :xreversed, :yreversed]
const PLOT_LABELS_OPTIONS= [:title, :xlabel, :ylabel, ]
const PLOT_LEGEND_OPTIONS = [:show_legend, :legend_title]

"merge to a Set"
m2s(args...) = vcat(args...) |> Set

"""
    RESET_FORMAT_OPTION::Dict{String, Set{Symbol}}

Maps reset trigger names to the set of format options that should be reset.

**Triggers:**
- `"never"` - Options that persist across all changes (e.g., `:plottype`)
- `"source"` - Options reset when data source changes (labels, legend, axis limits)
- `"range"` - Options reset when range/(Re-)Plot is clicked (axis limits)

**Result:**
```
"never"  => Set([:plottype])
"range"  => Set([:x_min, :x_max, :y_min, :y_max, :xreversed, :yreversed])
"source" => Set([:x_min, :x_max, :y_min, :y_max, :xreversed, :yreversed, 
                 :title, :xlabel, :ylabel, :show_legend, :legend_title])
```
"""
const RESET_FORMAT_OPTION = let
    rfo = Dict(
        ["never"] => m2s([:plottype, :theme]),
        ["source", "range"] => m2s(AXES_LIMITS_OPTIONS),
        ["source"] => m2s(PLOT_LABELS_OPTIONS, PLOT_LEGEND_OPTIONS),
    )
    rfo_keys = union(keys(rfo)...)
    d = Dict{String, Set{Symbol}}()

    for key in rfo_keys
        d[key] = union([v for (k, v) in rfo if key in k]...)
    end
    d
end
