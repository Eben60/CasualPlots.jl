function get_congruent_y_names(x, dims_dict::Dict)
    new_y_opts_strings = String[]
    if !(isnothing(x) || x == "")
        x_sym = Symbol(x)
        if haskey(dims_dict, x_sym)
            x_dims = dims_dict[x_sym]
            vec_length = x_dims[1] 
            for (key, dims) in dims_dict
                if key != x_sym && !isempty(dims) && dims[1] == vec_length
                    push!(new_y_opts_strings, string(key))
                end
            end
        end
    end
    return new_y_opts_strings |> sort!
end
