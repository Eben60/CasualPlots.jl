# src/unitful_integration.jl

"""
    unify_units!(df, cols, state)

Checks the specified columns `cols` in `df` for `Unitful` quantities.
If multiple Y-columns are Unitful:
1. If they have compatible physical dimensions, it unifies them to the largest metric unit used (or largest overall unit).
2. If they have incompatible dimensions, it issues a warning and strips the units to prevent AlgebraOfGraphics from crashing.
"""
function unify_units!(df, cols, state=nothing)
    # Return early if we don't have multiple columns to unify
    if length(cols) < 2
        return df
    end
    
    # 1. Find all columns that have Unitful quantities
    unitful_cols = String[]
    for col in cols
        idx = findfirst(!ismissing, df[!, col])
        if !isnothing(idx) && df[idx, col] isa Unitful.Quantity
            push!(unitful_cols, col)
        end
    end
    
    if length(unitful_cols) < 2
        return df # Nothing to unify
    end
    
    # Extract the units for each column
    col_units = Dict{String, Any}()
    ordered_units = Any[]
    for col in unitful_cols
        idx = findfirst(!ismissing, df[!, col])
        unit = Unitful.unit(df[idx, col])
        col_units[col] = unit
        push!(ordered_units, unit)
    end
    
    unique_units = unique(ordered_units)
    
    if length(unique_units) == 1
        return df # All units are identical, nothing to do
    end
    
    # 2. Check if all units have the same dimension
    first_dim = Unitful.dimension(unique_units[1])
    dimensions_match = all(u -> Unitful.dimension(u) == first_dim, unique_units)
    
    if !dimensions_match
        # 3. Units are not compatible. Issue warning and plot with stripped units.
        warning_msg = "Incompatible physical dimensions detected among Y columns: $(join(unitful_cols, ", ")). Stripping units to plot."
        @warn warning_msg
        
        if !isnothing(state)
            state.file_saving.save_status_message[] = warning_msg
            state.file_saving.save_status_type[] = :warning
            state.dialogs.modal_type[] = :warning
            state.dialogs.show_modal[] = true
        end
        
        # Strip units for all unitful columns
        for col in unitful_cols
            df[!, col] = map(v -> ismissing(v) ? missing : (v isa Unitful.Quantity ? Unitful.ustrip(v) : v), df[!, col])
        end
        return df
    end
    
    # 4. Units are compatible. Find the "largest" unit to unify them.
    # Helper to check if a unit is "metric" by seeing if its factor relative to SI is a clean power of 10.
    function is_metric(u)
        val = Unitful.ustrip(Unitful.upreferred(1.0*u))
        isapprox(log10(val), round(log10(val)), atol=1e-10)
    end
    
    metric_units = filter(is_metric, unique_units)
    
    # Select the target unit based on which has the largest conversion factor (i.e. the "largest" unit)
    target_unit = if !isempty(metric_units)
        # Largest metric unit
        argmax(u -> Unitful.ustrip(Unitful.upreferred(1.0*u)), metric_units)
    else
        # Largest overall unit if no metric units exist
        argmax(u -> Unitful.ustrip(Unitful.upreferred(1.0*u)), unique_units)
    end
    
    # 5. Convert all unitful columns to the target unit
    for col in unitful_cols
        u = col_units[col]
        if u != target_unit
            df[!, col] = map(v -> ismissing(v) ? missing : Unitful.uconvert(target_unit, v), df[!, col])
        end
    end
    
    return df
end

"""
    check_internal_unit_compatibility!(df, cols)

Checks each individual column in `cols` for internal dimensional consistency.
If a single column contains a mix of incompatible units (e.g., `m` and `m^2`), or a mix of unitless numbers and unitful quantities, it throws an ArgumentError.
"""
function check_internal_unit_compatibility!(df, cols)
    for col in cols
        first_dim = nothing
        has_quantity = false
        
        for v in df[!, col]
            if !ismissing(v) && v isa Number
                is_q = v isa Unitful.Quantity
                if first_dim === nothing
                    first_dim = is_q ? Unitful.dimension(v) : Unitful.NoDims
                    has_quantity = is_q
                else
                    dim = is_q ? Unitful.dimension(v) : Unitful.NoDims
                    # If we encounter a quantity, or we have already encountered a quantity, we must enforce dimension matching
                    if is_q || has_quantity
                        if dim != first_dim
                            throw(ArgumentError("Column '$col' contains mixed incompatible data (e.g., a mix of incompatible units, or units and plain numbers). Please ensure the column has consistent physical dimensions."))
                        end
                    end
                end
            end
        end
    end
end
