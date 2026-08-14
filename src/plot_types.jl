# src/plot_types.jl

abstract type AbstractPlotConfig end
abstract type AbstractPlotAttribute end

struct EnumAttribute <: AbstractPlotAttribute
    name::Symbol
    label::String
    options::Vector{String}
    default::String
    reset_policy::String  # "never" | "source" | "range"
    layout::Symbol        # :block | :inline

    # Constructor with default layout=:block
    function EnumAttribute(name, label, options, default, reset_policy; layout=:block)
        new(name, label, options, default, reset_policy, layout)
    end
end


struct GroupByAttribute <: AbstractPlotAttribute
    name::Symbol
    label::String
    options::Vector{String}
    default::String
    reset_policy::String  # "never" | "source" | "range"
    layout::Symbol        # :block | :inline

    function GroupByAttribute(name, label, options, default, reset_policy; layout=:block)
        new(name, label, options, default, reset_policy, layout)
    end
end

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

"""
    supports_group_by(config::AbstractPlotConfig)
Returns true if the plot type supports the group_by dropdown at all.
Defaults to true for most plot types.
"""
supports_group_by(config::AbstractPlotConfig) = true

"""
    get_attributes(config::AbstractPlotConfig)
Returns a vector of AbstractPlotAttribute defining the dynamic configuration schema for the plot type.
Defaults to empty vector.
"""
get_attributes(config::AbstractPlotConfig) = AbstractPlotAttribute[]


# --- Implementations ---

# 1. Simple Plot (Scatter, Lines, etc.)
struct SimplePlot <: AbstractPlotConfig
    visual_type::Type
    group_config::GroupConfig
end

function get_attributes(config::SimplePlot)
    options = String[]
    if supports_group_by(config)
        append!(options, config.group_config.mapping_kws |> keys |> collect)
    end
    if isempty(options)
        return AbstractPlotAttribute[]
    else
        return AbstractPlotAttribute[
            GroupByAttribute(:group_by, "Show group by:", options, "Color", "never")
        ]
    end
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

function get_attributes(config::BarPlotConfig)
    return AbstractPlotAttribute[
        GroupByAttribute(:group_by, "Show group by:", ["Color"], "Color", "never"),
        EnumAttribute(:bar_direction, "Direction:", ["Vertical", "Horizontal"], "Vertical", "never"; layout=:inline),
        EnumAttribute(:bar_mode, "Mode:", ["Dodged", "Stacked"], "Dodged", "never"; layout=:inline)
    ]
end

# 3. Compound Plot (Line+Symbol, etc.)
struct CompoundPlot <: AbstractPlotConfig
    configs::Vector{AbstractPlotConfig}
    extra_attributes::Vector{AbstractPlotAttribute}
end
CompoundPlot(configs) = CompoundPlot(configs, AbstractPlotAttribute[])

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

function get_attributes(config::CompoundPlot)
    attrs = AbstractPlotAttribute[]
    
    # Collect group_by options dynamically from children
    group_by_options = String[]
    for child in config.configs
        if supports_group_by(child)
            append!(group_by_options, child.group_config.mapping_kws |> keys |> collect)
        end
    end
    unique!(group_by_options)
    
    if !isempty(group_by_options)
        push!(attrs, GroupByAttribute(:group_by, "Show group by:", group_by_options, "Color", "never"))
    end
    
    for child in config.configs
        for attr in get_attributes(child)
            if attr.name != :group_by && !any(x -> x.name == attr.name, attrs)
                push!(attrs, attr)
            end
        end
    end
    for attr in config.extra_attributes
        if !any(x -> x.name == attr.name, attrs)
            push!(attrs, attr)
        end
    end
    return attrs
end

supports_group_by(config::CompoundPlot) = any(supports_group_by, config.configs)


