# src/code_generation.jl

function generate_data_preview(var_name::String)
    try
        val = getfield(Main, Symbol(var_name))
        preview = sprint((io, x) -> show(IOContext(io, :limit => true), MIME"text/plain"(), x), val)
        # Prefix each line of preview with "# "
        lines = split(preview, '\n')
        return join(map(l -> "# " * l, lines), "\n")
    catch e
        return "# Preview for $var_name not available"
    end
end

function generate_xy_arrays_code(state::CasualPlotsState)
    x_name = state.data_selection.selected_x[]
    y_name = state.data_selection.selected_y[]
    
    code = """

function cp_load_data(; $(x_name), $(y_name))
    # Assuming $(x_name) and $(y_name) are available in the executing environment
"""
    code *= generate_data_preview(x_name) * "\n"
    code *= generate_data_preview(y_name) * "\n"
    
    code *= """
    x_data = $(x_name)
    y_data = $(y_name)

    if y_data isa AbstractVector
        y_data = reshape(y_data, :, 1)
    end
"""
    
    range_from = state.data_selection.range_from[]
    range_to = state.data_selection.range_to[]
    
    if !isnothing(range_from) || !isnothing(range_to)
        code *= """
    # Apply range slicing
    from_idx = $(isnothing(range_from) ? "firstindex(x_data)" : range_from)
    to_idx = $(isnothing(range_to) ? "lastindex(x_data)" : range_to)
    
    x_first = firstindex(x_data)
    x_last = lastindex(x_data)
    from_idx = clamp(from_idx, x_first, x_last)
    to_idx = clamp(to_idx, x_first, x_last)
    
    x_data = x_data[from_idx:to_idx]
    
    y_first = firstindex(y_data, 1)
    pos_from = from_idx - x_first + y_first
    pos_to = to_idx - x_first + y_first
    y_data = y_data[pos_from:pos_to, :]
"""
    end
    
    code *= """
    return (; x_data, y_data, x_name="$(x_name)", y_name="$(y_name)")
end
"""
    return code
end

function generate_dataframe_code(state::CasualPlotsState)
    df_name = state.data_selection.selected_dataframe[]
    cols = state.data_selection.selected_columns[]
    cols_repr = repr(cols)
    
    code = """

"""
    if df_name == "__opened_file__"
        code *= "function cp_load_data()\n"
        filepath = state.file_opening.opened_file_path[]
        if endswith(lowercase(filepath), ".csv") || endswith(lowercase(filepath), ".tsv")
            opts = collect_csv_options(state)
            kwargs_str = join(["$k=$(repr(v))" for (k,v) in pairs(opts)], ", ")
            code *= "    using CSV\n"
            code *= "    df = CSV.read($(repr(filepath)), DataFrame; $kwargs_str)\n"
            
            skip_after_header = state.file_opening.skip_after_header[]
            skip_empty_rows = state.file_opening.skip_empty_rows[]
            if skip_after_header > 0 || skip_empty_rows
                code *= "    CasualPlots.skip_rows!(df, $skip_after_header, $skip_empty_rows)\n"
            end
        elseif endswith(lowercase(filepath), ".xlsx")
            sheet = state.file_opening.sheet_name[]
            code *= "    using XLSX\n"
            
            (; kwargs, skip_subheaders, skip_empty_rows) = collect_xlsx_options(state)
            kwargs_str = join(["$k=$(repr(v))" for (k,v) in pairs(kwargs)], ", ")
            code *= "    df = CasualPlots.readtable_xlsx($(repr(filepath)), $(repr(sheet)); infer_eltypes=true, stop_in_empty_row=false, $kwargs_str)\n"
            if skip_subheaders > 0 || skip_empty_rows
                code *= "    CasualPlots.skip_rows!(df, $skip_subheaders, $skip_empty_rows)\n"
            end
        end
    else
        code *= "function cp_load_data(; $df_name)\n"
        code *= "    # Assuming $df_name is available in the executing environment\n"
        code *= generate_data_preview(df_name) * "\n"
        code *= "    df = $df_name\n"
    end
    
    code *= "    df_selected = select(df, $cols_repr)\n"
    
    range_from = state.data_selection.range_from[]
    range_to = state.data_selection.range_to[]
    
    if !isnothing(range_from) || !isnothing(range_to)
        code *= "    from_idx = $(isnothing(range_from) ? 1 : range_from)\n"
        code *= "    to_idx = $(isnothing(range_to) ? "nrow(df_selected)" : range_to)\n"
        code *= "    df_selected = df_selected[from_idx:to_idx, :]\n"
    end
    
    code *= "    CasualPlots.normalize_numeric_columns!(df_selected, $cols_repr)\n"
    
    x_name = cols[1]
    y_names = length(cols) > 2 ? (df_name == "__opened_file__" ? state.file_opening.opened_file_name[] : df_name) : cols[2]
    
    code *= "    return (; df=df_selected, x_name=$(repr(x_name)), y_name=$(repr(y_names)))\n"
    code *= "end\n"
    return code
end

function generate_plot_function(state::CasualPlotsState)
    format = state.plotting.format
    handles = state.plotting.handles
    
    plottype = format.selected_plottype[]
    theme = format.selected_theme[]
    group_by = format.selected_group_by[]
    show_legend = format.show_legend[]
    
    title = handles.title_text[]
    xlabel = handles.xlabel_text[]
    ylabel = handles.ylabel_text[]
    legend_title = handles.legend_title_text[]
    
    x_min = format.x_min[]
    x_max = format.x_max[]
    y_min = format.y_min[]
    y_max = format.y_max[]
    xreversed = format.xreversed[]
    yreversed = format.yreversed[]
    
    source_type = state.data_selection.source_type[]
    
    code = """

function cp_create_plot(data)
    WGLMakie.activate!() # Or CairoMakie.activate!() for static output
"""

    if theme != "AoG default" && theme != "Makie default"
        code *= "    set_theme!($(theme)())\n"
    end
    
    if source_type == "X, Y Arrays"
        code *= """
    (; x_data, y_data, x_name, y_name) = data
    n_cols = size(y_data, 2)
    ys = ["y_name_\$n" for n in 1:n_cols]
    nms = vcat("x", ys)
    m = hcat(x_data, y_data)
    df_w = DataFrame(m, nms)
    df = stack(df_w, ys; variable_name=:group, value_name=:y)
    
    x_col = :x
    y_col = :y
    group_col = :group
"""
    else
        code *= """
    (; df, x_name, y_name) = data
    ys = names(df)[2:end]
    x_col = Symbol(names(df)[1])
    y_col = :y
    group_col = :group
    df = stack(df, ys; variable_name=:group, value_name=:y)
"""
    end
    
    # Generate labels fallback
    code *= """
    final_x_name = $(xlabel == "" ? "x_name" : repr(xlabel))
    final_y_name = $(ylabel == "" ? "y_name" : repr(ylabel))
    title = $(title == "" ? "\"$(plottype) Plot of \$final_y_name vs \$final_x_name\"" : repr(title))
"""

    # Group Mapping
    if group_by == "Geometry" && plottype != "BarPlot"
        if plottype == "Lines"
            code *= "    group_mapping = (; linestyle = group_col => $(repr(legend_title)))\n"
        else
            code *= "    group_mapping = (; marker = group_col => $(repr(legend_title)))\n"
        end
    else
        code *= "    group_mapping = (; color = group_col => $(repr(legend_title)))\n"
    end
    
    # Plotting code
    code *= """
    plt = AlgebraOfGraphics.data(df) * mapping(x_col => final_x_name, y_col => final_y_name; group_mapping...) * visual($(plottype))
    
    limits = ($(repr(x_min)), $(repr(x_max)), $(repr(y_min)), $(repr(y_max)))
    
    fg = draw(plt; 
        figure=(; size=(800, 600)), 
        legend=(show=$(show_legend),), 
        axis=(; title, limits, xreversed=$(xreversed), yreversed=$(yreversed))
    )
    
    return fg
end
"""
    return code
end

"""
    _generate_julia_code_string(state::CasualPlotsState) -> String

Internal function to generate executable Julia code as a String.
"""
function _generate_julia_code_string(state::CasualPlotsState)
    source_type = state.data_selection.source_type[]
    source_code = ""
    if source_type == "X, Y Arrays"
        source_code = generate_xy_arrays_code(state)
    elseif source_type == "DataFrame"
        source_code = generate_dataframe_code(state)
    end
    
    plot_code = generate_plot_function(state)
    
    uses_casualplots = occursin("CasualPlots.", source_code) || occursin("CasualPlots.", plot_code)
    
    code = """
# Auto-generated by CasualPlots.jl
using DataFrames
using WGLMakie
using AlgebraOfGraphics
"""
    if uses_casualplots
        code *= "using CasualPlots # for helper functions like skip_rows!\n"
    end
    
    code *= "# uncomment next line for high quality static output, esp. for saving:\n"
    code *= "# using CairoMakie\n"

    code *= source_code
    code *= plot_code
    
    code *= "\n# Execution \n"
    code *= "#\n"
    code *= "# uncomment and run the corresponding lines to generate, display, and/or save the plot\n"
    code *= "#\n"
    code *= "# # --- taking exactly the same data already existing in the Main --\n"
    code *= "#\n"
    
    if source_type == "X, Y Arrays"
        x_name = state.data_selection.selected_x[]
        y_name = state.data_selection.selected_y[]
        filename_base = "$(x_name)-vs-$(y_name)"
        code *= "# data = cp_load_data(; $(x_name), $(y_name)); fg = cp_create_plot(data);\n"
        code *= "#\n"
        code *= "# # --- or, specify your input data (here my_x, my_y) ---\n"
        code *= "#\n"
        code *= "# data = cp_load_data(; $(x_name)=my_x, $(y_name)=my_y); fg = cp_create_plot(data);\n"
    elseif source_type == "DataFrame" && state.data_selection.selected_dataframe[] != "__opened_file__"
        df_name = state.data_selection.selected_dataframe[]
        cols = state.data_selection.selected_columns[]
        x_col = !isempty(cols) ? cols[1] : "x"
        y_col = length(cols) > 1 ? cols[2] : "y"
        filename_base = "$(x_col)-vs-$(y_col)"
        code *= "# data = cp_load_data(; $(df_name)); fg = cp_create_plot(data);\n"
        code *= "#\n"
        code *= "# # --- or, specify your input data (here my_df) ---\n"
        code *= "#\n"
        code *= "# data = cp_load_data(; $(df_name)=my_df); fg = cp_create_plot(data);\n"
    else
        cols = state.data_selection.selected_columns[]
        x_col = !isempty(cols) ? cols[1] : "x"
        y_col = length(cols) > 1 ? cols[2] : "y"
        filename_base = "$(x_col)-vs-$(y_col)"
        code *= "# data = cp_load_data(); fg = cp_create_plot(data);\n"
    end
    
    code *= "# \n"
    code *= "# display(fg)\n"
    code *= "#\n"
    code *= "# # --- in case not already done:  ---\n"
    code *= "# using CairoMakie\n"
    code *= "# CairoMakie.activate!()\n"
    code *= "#\n"
    code *= "# CairoMakie.save(\"$(filename_base).svg\", fg) # saving as svg\n"
    code *= "# CairoMakie.save(\"$(filename_base).pdf\", fg) # saving as pdf\n"
    code *= "# CairoMakie.save(\"$(filename_base).png\", fg) # saving as png\n"
    code *= ";\n"
    return code
end

"""
    generate_julia_code(state::CasualPlotsState; file=nothing) -> Union{String, Nothing}

Generates executable Julia code to replicate the current CasualPlots state.
If `file` is provided, writes the code to the file (appending a ".jl" suffix if it has no suffix) and returns `nothing`.
Otherwise, returns the code as a `String`.
"""
function generate_julia_code(state::CasualPlotsState; file=nothing)
    code = _generate_julia_code_string(state)
    if isnothing(file)
        return code
    else
        if isempty(splitext(file)[2])
            file = file * ".jl"
        end
        write(file, code)
        return nothing
    end
end

"""
    generate_julia_code(app::CasualPlotApp; file=nothing) -> Union{String, Nothing}

Generates executable Julia code to replicate the current CasualPlots state.
Delegates to `generate_julia_code(app.state; file)`.
"""
generate_julia_code(app::CasualPlotApp; file=nothing) = generate_julia_code(app.state; file=file)