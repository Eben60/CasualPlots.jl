
"""
    normalize_strings!(df)

Normalize string columns for compatibility with Bonito.Table display.

Converts:
- AbstractString (e.g., InlineString from CSV.jl) → String
- Any columns: replaces InlineString values with String equivalents

Modifies the DataFrame in-place and returns it.
"""
function normalize_strings!(df)
    for col in names(df)
        col_eltype = eltype(df[!, col])
        base_type = nonmissingtype(col_eltype)
        
        if base_type <: AbstractString
            # Convert to String (handles InlineString from CSV.jl)
            df[!, col] = [ismissing(v) ? missing : String(v) for v in df[!, col]]
            
        elseif base_type === Any
            # Check for InlineStrings in Any columns and convert to String
            df[!, col] = [
                ismissing(v) ? missing : 
                (v isa AbstractString ? String(v) : v) 
                for v in df[!, col]
            ]
        end
    end
    return df
end

"""
    normalize_numeric_columns!(df, cols)

Normalize numeric columns for plotting compatibility.

For each specified column:
- AbstractString and Dates.AbstractTime → unchanged
- Concrete numeric types (Float64, Int, etc.) and Bool → unchanged
- Abstract Integer subtypes → Int (preserving missing)
- Abstract Real subtypes → Float64 (preserving missing)
- Any/unknown types:
  - If >90% of non-missing values are numeric → Float64 (non-numeric become missing)
  - Otherwise → unchanged

# Arguments
- `df`: DataFrame to normalize
- `cols`: Vector of column names to normalize

# Returns
`(df, dirty_cols)` - the modified DataFrame and a vector of column names where 
non-numeric values were converted to missing.
"""
function normalize_numeric_columns!(df, cols)
    dirty_cols = String[]
    
    for col in cols
        col ∉ names(df) && continue
        
        col_eltype = eltype(df[!, col])
        base_type = nonmissingtype(col_eltype)
        has_missing = col_eltype !== base_type
        
        if base_type <: AbstractString || base_type <: Dates.AbstractTime
            # Leave as is
            continue
        
        elseif base_type <: Real && isconcretetype(base_type)
            continue
            
        elseif base_type <: Integer 
            # Convert Integer subtypes to Int
            if has_missing
                df[!, col] = [ismissing(v) ? missing : Int(v) for v in df[!, col]]
            else
                df[!, col] = Int.(df[!, col])
            end
            
        elseif base_type <: Real
            # Convert Real subtypes to Float64
            if has_missing
                df[!, col] = [ismissing(v) ? missing : Float64(v) for v in df[!, col]]
            else
                df[!, col] = Float64.(df[!, col])
            end
            
        else
            # Any or unknown type - analyze content
            values = df[!, col]
            non_missing = filter(!ismissing, values)
            
            if isempty(non_missing)
                # All missing - leave as is
                continue
            end
            
            # Count numeric values
            n_numeric = count(v -> v isa Number, non_missing)
            numeric_ratio = n_numeric / length(non_missing)
            
            if numeric_ratio > 0.9
                # >90% numeric: convert to Float64, others become missing
                original_missing_count = count(ismissing, values)
                new_values = [ismissing(v) ? missing : (v isa Number ? Float64(v) : missing) for v in values]
                new_missing_count = count(ismissing, new_values)
                
                df[!, col] = new_values
                
                # Track if we converted non-numeric to missing
                if new_missing_count > original_missing_count
                    push!(dirty_cols, col)
                end
            end
            # If not mostly numeric, leave as is (will likely cause plot error, but user should fix data)
        end
    end
    return (df, dirty_cols)
end

"""
    skip_rows!(df, skip_firstrows::UInt, skip_empty_rows::Bool) -> DataFrame

Mutate DataFrame by removing rows:
1. Delete the first `skip_firstrows` rows (if > 0)
2. Delete all rows where every element is missing (if `skip_empty_rows` is true)

If any rows were deleted and a column's original eltype was not a concrete type 
(or Union{Missing, ConcreteType}), re-collect the column values to potentially narrow the type.

Returns the mutated DataFrame.
"""
function skip_rows!(df, skip_firstrows, skip_empty_rows)
    # Store original eltypes to check if re-collection is needed
    original_eltypes = Dict(col => eltype(df[!, col]) for col in names(df))
    
    mutated = false
    
    # Step 1: Delete first skip_firstrows rows if > 0
    if skip_firstrows > 0 && nrow(df) >= skip_firstrows
        deleteat!(df, 1:skip_firstrows)
        mutated = true
    end
    
    # Step 2: Delete rows where all elements are missing
    if skip_empty_rows
        all_missing_rows = findall(row -> all(ismissing, row), eachrow(df))
        if !isempty(all_missing_rows)
            deleteat!(df, all_missing_rows)
            mutated = true
        end
    end
    
    # Step 3: Re-collect columns if df was mutated and original eltype was not concrete
    if mutated
        for col in names(df)
            orig_eltype = original_eltypes[col]
            base_type = nonmissingtype(orig_eltype)
            # Re-collect if original type was NOT concrete (e.g., Any, complex unions)
            if !isconcretetype(base_type)
                df[!, col] = collect(df[!, col])
            end
        end
    end
    
    return df
end
