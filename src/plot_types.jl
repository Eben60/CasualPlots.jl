# src/plot_types.jl

abstract type AbstractPlotConfig end

# --- Data Structures ---

"""
Configuration for how a plot type handles grouping
"""
struct GroupConfig
    mapping_kws::Dict{String, Symbol}
end

GroupConfig(pairs::Pair...) = GroupConfig(Dict(pairs...))

# --- Interfaces ---

"""
    build_layer(config::AbstractPlotConfig, format::NamedTuple, group_col, legend_title)
Returns the fully configured AoG layer (mapping * visual) for this plot type.
"""
function build_layer end

"""
    build_layer_code(config::AbstractPlotConfig, format::NamedTuple, group_col_str, legend_title_str)
Returns the string representation of the AoG layer (mapping * visual) for code generation.
"""
function build_layer_code end

"""
    supports_grouping(config::AbstractPlotConfig, group_type::String)
Returns true if the plot type supports the specified grouping type (e.g. "Geometry" or "Color").
"""
function supports_grouping end

# --- Implementations ---

# 1. Simple Plot (Scatter, Lines, etc.)
struct SimplePlot <: AbstractPlotConfig
    visual_type::Type
    group_config::GroupConfig
end

function build_layer(config::SimplePlot, format, group_col, legend_title)
    group_by = get(format, :group_by, "Color")
    kw = config.group_config.mapping_kws[group_by]
    grp_map = NamedTuple{(kw,)}((group_col => legend_title,))
    return mapping(; grp_map...) * visual(config.visual_type)
end

function build_layer_code(config::SimplePlot, format, group_col_str, legend_title_str)
    group_by = get(format, :group_by, "Color")
    kw = config.group_config.mapping_kws[group_by]
    return "mapping(; $kw = $group_col_str => $legend_title_str) * visual($(config.visual_type))"
end

function supports_grouping(config::SimplePlot, group_type::String)
    return haskey(config.group_config.mapping_kws, group_type)
end

# 2. Bar Plot
struct BarPlotConfig <: AbstractPlotConfig 
    group_config::GroupConfig
end

function build_layer(config::BarPlotConfig, format, group_col, legend_title)
    dir_val = get(format, :bar_direction, "Vertical") == "Horizontal" ? :x : :y
    group_by = get(format, :group_by, "Color")
    
    if group_by == "Geometry"
        return mapping() * visual(BarPlot; direction = dir_val)
    end
    
    bar_mode = get(format, :bar_mode, "Dodged")
    
    grp_map = if bar_mode == "Stacked"
        (; color = group_col => legend_title, stack = group_col => legend_title)
    else
        (; color = group_col => legend_title, dodge = group_col => legend_title)
    end
    
    return mapping(; grp_map...) * visual(BarPlot; direction = dir_val)
end

function build_layer_code(config::BarPlotConfig, format, group_col_str, legend_title_str)
    dir_val = get(format, :bar_direction, "Vertical") == "Horizontal" ? :x : :y
    group_by = get(format, :group_by, "Color")
    
    if group_by == "Geometry"
        return "mapping() * visual(BarPlot; direction = $(repr(dir_val)))"
    end
    
    bar_mode = get(format, :bar_mode, "Dodged")
    
    grp_map_str = if bar_mode == "Stacked"
        "color = $group_col_str => $legend_title_str, stack = $group_col_str => $legend_title_str"
    else
        "color = $group_col_str => $legend_title_str, dodge = $group_col_str => $legend_title_str"
    end
    
    return "mapping(; $grp_map_str) * visual(BarPlot; direction = $(repr(dir_val)))"
end

function supports_grouping(config::BarPlotConfig, group_type::String)
    return haskey(config.group_config.mapping_kws, group_type)
end

# 3. Compound Plot (Line+Symbol, etc.)
struct CompoundPlot <: AbstractPlotConfig
    configs::Vector{AbstractPlotConfig}
end

function build_layer(config::CompoundPlot, format, group_col, legend_title)
    layers = [build_layer(c, format, group_col, legend_title) for c in config.configs]
    return mapreduce(identity, +, layers)
end

function build_layer_code(config::CompoundPlot, format, group_col_str, legend_title_str)
    codes = [build_layer_code(c, format, group_col_str, legend_title_str) for c in config.configs]
    return join(["(" * c * ")" for c in codes], " + ")
end

function supports_grouping(config::CompoundPlot, group_type::String)
    return any(c -> supports_grouping(c, group_type), config.configs)
end

# --- Plot Types Registry ---

const PLOT_TYPES = OrderedDict{String, AbstractPlotConfig}(
    "Scatter" => SimplePlot(Scatter, GroupConfig("Color" => :color, "Geometry" => :marker)),
    "Lines" => SimplePlot(Lines, GroupConfig("Color" => :color, "Geometry" => :linestyle)),
    "Line+Symbol" => CompoundPlot([
        SimplePlot(Lines, GroupConfig("Color" => :color, "Geometry" => :linestyle)),
        SimplePlot(Scatter, GroupConfig("Color" => :color, "Geometry" => :marker))
    ]),
    "BarPlot" => BarPlotConfig(GroupConfig("Color" => :color)),
    "Line+Bar" => CompoundPlot([
        SimplePlot(Lines, GroupConfig("Color" => :color, "Geometry" => :linestyle)),
        BarPlotConfig(GroupConfig("Color" => :color))
    ])
)
