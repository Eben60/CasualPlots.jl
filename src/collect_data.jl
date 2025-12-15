"""
    collect_arrays_from_main()

Collects names of variables from the `Main` module that are arrays or other iterable data structures 
with elements of type `Real` or `Unitful.Quantity` (if `Unitful` is loaded).
    
It iterates through all names in `Main`. For each name, it checks if the corresponding variable is an 
`AbstractArray` or an iterable, and if its elements are `Real` or `Unitful.Quantity`.

Returns a vector of Symbol.
"""
function collect_arrays_from_main()
    data_names = Symbol[]
    
    # Define the types to check for
    allowed_types = Any[Real]
    if isdefined(Main, :Unitful)
        push!(allowed_types, Main.Unitful.Quantity)
    end

    for name in names(Main; imported=true,  usings=true) # this limits package compat to Julia v1.11 !
        name == :ans && continue
        var = getfield(Main, name)

        # Check if it's an array or a generic iterable     
        if  !(var isa Real) &&   # some special numbers like NaN are iterables, they are excluded here
            (isa(var, AbstractArray) || hasmethod(iterate, (typeof(var),)))
            # Check if the element type is a subtype of any of the allowed types
            if any(T -> eltype(var) <: T, allowed_types) 
                push!(data_names, name)
            end
        end
    end
    return data_names
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
    collect_dataframes_from_main()

Collects names of DataFrame variables from the `Main` module.

Iterates through all names in `Main` and checks if the corresponding variable is a DataFrame.

Returns a vector of Symbol representing DataFrame variable names.
"""
function collect_dataframes_from_main()
    df_names = Symbol[]
    
    # Check if DataFrames is loaded
    if !isdefined(Main, :DataFrame)
        return df_names
    end
    
    DataFrame_type = getfield(Main, :DataFrame)
    
    for name in names(Main; imported=true, usings=true)
        name == :ans && continue
        try
            var = getfield(Main, name)
            if isa(var, DataFrame_type)
                push!(df_names, name)
            end
        catch e
            # Ignore errors from getfield
        end
    end
    return df_names
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
