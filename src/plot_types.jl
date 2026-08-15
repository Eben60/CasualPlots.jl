# src/plot_types.jl

"""
    AbstractPlotConfig

Base abstract type for all plot configurations. Defines the core interface for
generating AlgebraOfGraphics layers and UI attributes.
"""
abstract type AbstractPlotConfig end

"""
    SinglePlotConfig <: AbstractPlotConfig

Abstract type for single layer plots (e.g., Scatter, Lines, BarPlot). Subtypes 
must implement the `visual_type` and `group_config` fields. Provides generic
implementations for mapping and visual parameter extraction.
"""
abstract type SinglePlotConfig <: AbstractPlotConfig end

"""
    AbstractPlotAttribute

Base abstract type for dynamic plot attributes that generate UI controls in the
format tab (e.g., dropdowns for grouping, directions, modes).
"""
abstract type AbstractPlotAttribute end

"""
    EnumAttribute <: AbstractPlotAttribute

Defines a categorical UI control (dropdown or radio) for a plot attribute.
Includes declarative routing fields (`visual_map` and `mapping_map`) that dictate
how the selected value is injected into the AlgebraOfGraphics pipeline.
"""
@kwdef struct EnumAttribute <: AbstractPlotAttribute
    name::Symbol
    label::String
    options::Vector{String}
    default::String
    reset_policy::String  # "never" | "source" | "range"
    layout::Symbol = :block

    # Routing: where does this attribute's value go?
    visual_map::Union{Nothing, Pair{Symbol, Dict{String, Any}}} = nothing
    mapping_map::Union{Nothing, Dict{String, Symbol}} = nothing
    requires_group::Bool = false  # if true, mapping_map only applies when group_by ≠ "None"
end

"""
    GroupByAttribute <: AbstractPlotAttribute

Specialized attribute for defining the primary grouping variable (e.g., Color, Marker).
"""
struct GroupByAttribute <: AbstractPlotAttribute
    name::Symbol
    label::String
    options::Vector{String}
    default::String
    reset_policy::String  # "never" | "source" | "range"
    layout::Symbol        # :block | :inline
end

# Constructor with default layout=:block
GroupByAttribute(name, label, options, default, reset_policy; layout=:block) =
    GroupByAttribute(name, label, options, default, reset_policy, layout)


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

supports_grouping(config::SinglePlotConfig, group_type::String) =
    haskey(config.group_config.mapping_kws, group_type)

function get_group_by_attribute(config::SinglePlotConfig)
    options = config.group_config.mapping_kws |> keys |> collect
    pushfirst!(options, "None")
    default_opt = "Color" in options ? "Color" : "None"
    return GroupByAttribute(:group_by, "Show group by:", options, default_opt, "never")
end

function _group_by_is_none(config::SinglePlotConfig, format)
    group_by = get(format, :group_by, "None")
    return group_by == "None" || !haskey(config.group_config.mapping_kws, group_by)
end

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

function get_attributes(config::SinglePlotConfig)
    return AbstractPlotAttribute[get_group_by_attribute(config)]
end


get_visual_type(config::SinglePlotConfig) = config.visual_type
get_visual_type_code(config::SinglePlotConfig) = split(string(get_visual_type(config)), ".")[end]
function get_visual_params(config::SinglePlotConfig, format)
    result = Dict{Symbol, Any}()
    for attr in get_attributes(config)
        if attr isa EnumAttribute && attr.visual_map !== nothing
            kwarg_name, value_dict = attr.visual_map
            val = get(format, attr.name, attr.default)
            result[kwarg_name] = value_dict[val]
        end
    end
    return NamedTuple(result)
end

function get_visual_params_code(config::SinglePlotConfig, format)
    parts = String[]
    for attr in get_attributes(config)
        if attr isa EnumAttribute && attr.visual_map !== nothing
            kwarg_name, value_dict = attr.visual_map
            val = get(format, attr.name, attr.default)
            push!(parts, "$kwarg_name = $(repr(value_dict[val]))")
        end
    end
    return isempty(parts) ? "" : "; " * join(parts, ", ")
end

function get_mapping_params(config::SinglePlotConfig, format, group_col, legend_title)
    result = Dict{Symbol, Any}()
    
    if !_group_by_is_none(config, format)
        group_by = get(format, :group_by, "None")
        kw = config.group_config.mapping_kws[group_by]
        result[kw] = group_col => legend_title
    else
        # Silent grouping (avoids lines zigzagging across groups)
        result[:group] = group_col => legend_title
    end
    
    for attr in get_attributes(config)
        if attr isa EnumAttribute && attr.mapping_map !== nothing
            if !attr.requires_group || !_group_by_is_none(config, format)
                val = get(format, attr.name, attr.default)
                kwarg = attr.mapping_map[val]
                result[kwarg] = group_col => legend_title
            end
        end
    end
    
    return NamedTuple(result)
end

function get_mapping_params_code(config::SinglePlotConfig, format, group_col_str, legend_title_str)
    parts = String[]
    
    if !_group_by_is_none(config, format)
        group_by = get(format, :group_by, "None")
        kw = config.group_config.mapping_kws[group_by]
        push!(parts, "$kw = $group_col_str => $legend_title_str")
    else
        push!(parts, "group = $group_col_str => $legend_title_str")
    end
    
    for attr in get_attributes(config)
        if attr isa EnumAttribute && attr.mapping_map !== nothing
            if !attr.requires_group || !_group_by_is_none(config, format)
                val = get(format, attr.name, attr.default)
                kwarg = attr.mapping_map[val]
                push!(parts, "$kwarg = $group_col_str => $legend_title_str")
            end
        end
    end
    
    return isempty(parts) ? "" : "; " * join(parts, ", ")
end

function build_layer(config::SinglePlotConfig, format, group_col, legend_title)
    map_kws = get_mapping_params(config, format, group_col, legend_title)
    vis_kws = get_visual_params(config, format)
    vis_type = get_visual_type(config)
    
    return mapping(; map_kws...) * visual(vis_type; vis_kws...)
end

function build_layer_code(config::SinglePlotConfig, format, group_col_str, legend_title_str)
    map_code = get_mapping_params_code(config, format, group_col_str, legend_title_str)
    vis_code = get_visual_params_code(config, format)
    vis_type_code = get_visual_type_code(config)
    
    return "mapping($map_code) * visual($vis_type_code$vis_code)"
end


# --- Implementations ---

# 1. Simple Plot (Scatter, Lines, etc.)
"""
    SimplePlot <: SinglePlotConfig

Configuration for basic plot types like Scatter and Lines that only require
standard grouping (color, marker, linestyle) without custom mapping logic.
"""
struct SimplePlot <: SinglePlotConfig
    visual_type::Type
    group_config::GroupConfig
end



# 2. Bar Plot
"""
    BarPlotConfig <: SinglePlotConfig

Configuration for BarPlots. Includes specialized attributes for bar direction
(horizontal vs vertical) and bar mode (stacked vs dodged).
"""
@kwdef struct BarPlotConfig <: SinglePlotConfig 
    visual_type::Type = BarPlot
    group_config::GroupConfig
end



function get_attributes(config::BarPlotConfig)
    return AbstractPlotAttribute[
        get_group_by_attribute(config),
        EnumAttribute(
            name = :bar_direction,
            label = "Direction:",
            options = ["Vertical", "Horizontal"],
            default = "Vertical",
            reset_policy = "never",
            layout = :inline,
            visual_map = :direction => Dict("Horizontal" => :x, "Vertical" => :y)
        ),
        EnumAttribute(
            name = :bar_mode,
            label = "Mode:",
            options = ["Dodged", "Stacked"],
            default = "Dodged",
            reset_policy = "never",
            layout = :inline,
            mapping_map = Dict("Stacked" => :stack, "Dodged" => :dodge),
            requires_group = false
        )
    ]
end

# 3. Compound Plot (Line+Symbol, etc.)
"""
    CompoundPlot <: AbstractPlotConfig

Configuration for combining multiple `AbstractPlotConfig`s into a single 
composite plot (e.g., Line + Scatter). Collects attributes dynamically from
its child configurations.
"""
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
    group_by_options = String["None"]
    for child in config.configs
        if supports_group_by(child)
            append!(group_by_options, child.group_config.mapping_kws |> keys |> collect)
        end
    end
    unique!(group_by_options)
    
    if length(group_by_options) > 1 # if it's not just "None"
        default_opt = "Color" in group_by_options ? "Color" : "None"
        push!(attrs, GroupByAttribute(:group_by, "Show group by:", group_by_options, default_opt, "never"))
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


