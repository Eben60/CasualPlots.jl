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
    allowed_types = (Real, Unitful.Quantity{<:Real})

    if !(var isa Real) &&
       (isa(var, AbstractArray) || hasmethod(iterate, (typeof(var),)))
        return any(T -> eltype(var) <: T, allowed_types)
    end
    return false
end

collect_arrays_from_main() = _collect_variables_from_main(is_main_numeric_iterable)

is_vector_like(dims::Tuple) = length(dims) == 1 || (length(dims) == 2 && dims[2] == 1)

function is_main_dataframe_or_matrix(var)
    isa(var, AbstractDataFrame) && return true
    if isa(var, AbstractMatrix)
        hasmethod(size, (typeof(var),)) || return false
        return !is_vector_like(size(var))
    end
    return false
end

collect_dataframes_from_main() = _collect_variables_from_main(is_main_dataframe_or_matrix)

"""
    get_source_as_dataframe(source_name::AbstractString, opened_file_df=nothing) -> Union{AbstractDataFrame, Nothing}

Helper to retrieve a DataFrame from Main, or coerce a Matrix into a DataFrame.
"""
function get_source_as_dataframe(source_name, opened_file_df=nothing)
    if source_name == "__opened_file__" && !isnothing(opened_file_df)
        return opened_file_df
    end
    var = getfield(Main, Symbol(source_name))
    if isa(var, AbstractDataFrame)
        return var
    elseif isa(var, AbstractMatrix)
        col_names = [Symbol("$(source_name)_$i") for i in 1:size(var, 2)]
        return DataFrame(var, col_names)
    end
    return nothing
end

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
        var = getfield(Main, name)
        if hasmethod(size, (typeof(var),))
            ndims(var) > 2 && continue # skip high-dimensional arrays
            dims = size(var)
            dims_dict[name] = dims
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
    vectors_only = filter(p -> is_vector_like(last(p)), dims_dict)
    return string.(keys(vectors_only)) |> sort!
end

function get_congruent_y_names(x, dims_dict::Dict)
    new_y_opts_strings = String[]
    if !(isnothing(x) || x == "")
        x_sym = Symbol(x)
        if haskey(dims_dict, x_sym)
            x_dims = dims_dict[x_sym]
            vec_length = prod(x_dims)
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
    df = get_source_as_dataframe(df_name)
    isnothing(df) ? String[] : names(df)
end

"""
    get_dataframe_bounds(df_name::AbstractString, opened_file_df=nothing)

Get the row index bounds (1, nrow) for a DataFrame.
DataFrames are always 1-indexed, so returns (1, nrow(df)).

# Arguments
- `df_name::AbstractString`: Name of the DataFrame variable in Main, or "__opened_file__"
- `opened_file_df`: Optional DataFrame from opened file (when df_name == "__opened_file__")

# Returns
Tuple of (1, num_rows) or (nothing, nothing) on error.
"""
function get_dataframe_bounds(df_name::AbstractString, opened_file_df=nothing)
    df = get_source_as_dataframe(df_name, opened_file_df)
    isnothing(df) ? (nothing, nothing) : (1, nrow(df))
end
