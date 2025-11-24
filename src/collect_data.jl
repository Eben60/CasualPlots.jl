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
    disallowed_types = [Irrational, DataType]
    if isdefined(Main, :Unitful)
        push!(allowed_types, Main.Unitful.Quantity)
    end

    for name in names(Main; imported=true,  usings=true)
        name == :ans && continue
        try
            var = getfield(Main, name)

            # Check if it's an array or a generic iterable
            
            if  !(var isa Real) &&   # some special numbers like NaN are iterables, they are excluded here
                (isa(var, AbstractArray) || hasmethod(iterate, (typeof(var),)))
                # Check if the element type is a subtype of any of the allowed types
                if any(T -> eltype(var) <: T, allowed_types) && !any(T -> eltype(var) <: T, disallowed_types) 
                    push!(data_names, name)
                end
            end
        catch e
            # TODO
            # Ignore errors from getfield or eltype
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
