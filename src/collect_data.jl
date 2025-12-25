"""
    _collect_variables_from_main(predicate)

Internal helper function to iterate over variables in `Main` and collect those satisfying `predicate`.
Handles `UndefVarError` quietly and warns on other errors.
"""
function _collect_variables_from_main(predicate::Function)
    collected_names = Symbol[]
    @static if VERSION ≥ v"1.12"
        nms = names(Main; imported=true, usings=true)
    else 
        nms = names(Main; imported=true)
    end

    for name in nms
        name == :ans && continue
        try
            var = getfield(Main, name)
            if predicate(var)
                push!(collected_names, name)
            end
        catch e
            if isa(e, UndefVarError)
                continue
            else
                @warn "`Main.$name` causes an error." exception=e
            end
        end
    end
    return collected_names
end

"""
    is_main_numeric_iterable(var)

Check if `var` is an array or iterable with `Real` or `Unitful.Quantity` elements.
"""
function is_main_numeric_iterable(var)
    allowed_types = Any[Real]
    if isdefined(Main, :Unitful)
        push!(allowed_types, Main.Unitful.Quantity)
    end

    if !(var isa Real) &&
       (isa(var, AbstractArray) || hasmethod(iterate, (typeof(var),)))
        return any(T -> eltype(var) <: T, allowed_types)
    end
    return false
end

collect_arrays_from_main() = _collect_variables_from_main(is_main_numeric_iterable)


"""
    is_main_dataframe(var)

Check if `var` is a `DataFrame` (from `Main`).
"""
function is_main_dataframe(var)
    if !isdefined(Main, :DataFrame)
        return false
    end
    DataFrame_type = getfield(Main, :DataFrame)
    return isa(var, DataFrame_type)
end

collect_dataframes_from_main() = _collect_variables_from_main(is_main_dataframe)

"""
    get_dims_of_arrays()

Collects arrays from `Main` using `collect_arrays_from_main()` and determines their dimensions.

Returns a dictionary where keys are the variable names (as `Symbol`) and the values are tuples 
representing the dimensions of the arrays. Iterables without a `size` method are ignored.
"""
function get_dims_of_arrays()
    array_names = collect_arrays_from_main()
    dims_dict = Dict{Symbol, Tuple}()

    for name in array_names
        try
            var = getfield(Main, name)
            if hasmethod(size, (typeof(var),))
                dims = size(var)
                dims_dict[name] = dims
            end
        catch e
            # Ignore errors if `getfield` fails for some reason, though it shouldn't for names from `collect_arrays_from_main`.
            @warn "Could not get dimensions for variable `$(name)`" exception=e
        end
    end
    return dims_dict
end

"""
    extract_x_candidates(dims_dict)

Filter dimensions dictionary for 1-dimensional arrays (vectors) to be used as X candidates.

# Returns
Sorted vector of strings representing variable names.
"""
function extract_x_candidates(dims_dict)
    vectors_only = filter(p -> length(last(p)) == 1, dims_dict)
    return string.(keys(vectors_only)) |> sort!
end

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

"""
    get_dataframe_columns(df_name::String)

Returns the column names of a DataFrame variable from Main module.

# Arguments
- `df_name::String`: Name of the DataFrame variable in Main

# Returns
Vector of column names (as Strings) in the order they appear in the DataFrame.
Returns empty vector if DataFrame doesn't exist or has no columns.
"""
function get_dataframe_columns(df_name::AbstractString)
    try
        df = getfield(Main, Symbol(df_name))
        if isdefined(Main, :DataFrame) && isa(df, getfield(Main, :DataFrame))
            return names(df)
        end
    catch e
        @warn "Could not get columns for DataFrame `$(df_name)`" exception=e
    end
    return String[]
end
