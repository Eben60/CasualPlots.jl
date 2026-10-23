"""
    DataContinuityError <: Exception

Exception raised when reloaded data structure violates continuity rules
(e.g., deleted selected columns, mismatched dimensions, or out-of-bound ranges).
"""
struct DataContinuityError <: Exception
    msg::String
end

function Base.showerror(io::IO, err::DataContinuityError)
    print(io, err.msg)
    return nothing
end

"""
    SourceSignature

Snapshot of the structure of a plot data source (bounds, column names, column types).
"""
struct SourceSignature
    kind::Symbol               # :array or :table
    source::String             # source identifier
    first_index::Int           # row firstindex of X (or 1 for table)
    last_index::Int            # row lastindex of X (or nrow for table)
    colnames::Vector{String}   # column names
    coltypes::Vector{Type}     # column types
    is_matrix::Bool            # whether source/Y is a matrix
    y_first_index::Int         # row firstindex of Y (equal to first_index for table)
    y_last_index::Int          # row lastindex of Y (equal to last_index for table)
end

function SourceSignature(
    kind::Symbol,
    source::AbstractString,
    first_index::Integer,
    last_index::Integer,
    colnames::AbstractVector{<:AbstractString},
    coltypes::AbstractVector,
    is_matrix::Bool=false,
    y_first_index::Integer=first_index,
    y_last_index::Integer=last_index,
)
    return SourceSignature(
        kind,
        String(source),
        Int(first_index),
        Int(last_index),
        String.(colnames),
        Type[t for t in coltypes],
        is_matrix,
        Int(y_first_index),
        Int(y_last_index),
    )
end

function Base.:(==)(a::SourceSignature, b::SourceSignature)
    return a.kind == b.kind &&
        a.source == b.source &&
        a.first_index == b.first_index &&
        a.last_index == b.last_index &&
        a.colnames == b.colnames &&
        a.coltypes == b.coltypes &&
        a.is_matrix == b.is_matrix &&
        a.y_first_index == b.y_first_index &&
        a.y_last_index == b.y_last_index
end

"""
    capture_signature(kind::Symbol, args...; kwargs...) -> SourceSignature
    capture_signature(state) -> SourceSignature

Capture a structural snapshot of the specified data source.
Throws `DataContinuityError` if variables are missing or of an unsuitable kind.
"""
function capture_signature end

function capture_signature(kind::Symbol, x_name::AbstractString, y_name::AbstractString)
    if kind != :array
        throw(DataContinuityError("Expected :array kind, got :$kind."))
    end
    if isempty(x_name)
        throw(DataContinuityError("No X variable specified."))
    end
    if isempty(y_name)
        throw(DataContinuityError("No Y variable specified."))
    end
    if !isdefined(Main, Symbol(x_name))
        throw(DataContinuityError("Variable \"$x_name\" is no longer defined in Main."))
    end
    if !isdefined(Main, Symbol(y_name))
        throw(DataContinuityError("Variable \"$y_name\" is no longer defined in Main."))
    end

    x_var = getfield(Main, Symbol(x_name))
    y_var = getfield(Main, Symbol(y_name))

    if !(x_var isa AbstractArray) || !is_main_numeric_iterable(x_var)
        throw(DataContinuityError("Variable \"$x_name\" is not a numeric array."))
    end
    if !(y_var isa AbstractArray) || !is_main_numeric_iterable(y_var)
        throw(DataContinuityError("Variable \"$y_name\" is not a numeric array."))
    end
    if ndims(x_var) > 2 || (ndims(x_var) == 2 && size(x_var, 2) != 1)
        throw(DataContinuityError("Variable \"$x_name\" is not a 1D vector."))
    end
    if ndims(y_var) > 2
        throw(DataContinuityError("Variable \"$y_name\" has more than 2 dimensions."))
    end

    x_first = firstindex(x_var, 1)
    x_last = lastindex(x_var, 1)
    y_first = firstindex(y_var, 1)
    y_last = lastindex(y_var, 1)
    is_matrix = ndims(y_var) == 2 && size(y_var, 2) > 1

    if !is_matrix
        colnames = String[String(x_name), String(y_name)]
        coltypes = Type[eltype(x_var), eltype(y_var)]
    else
        n_cols = size(y_var, 2)
        ys = ["$(y_name)_$n" for n in 1:n_cols]
        colnames = vcat(String(x_name), ys)
        coltypes = vcat(Type[eltype(x_var)], Type[eltype(y_var) for _ in 1:n_cols])
    end

    source_id = "$(y_name) vs $(x_name)"
    return SourceSignature(
        :array,
        source_id,
        x_first,
        x_last,
        colnames,
        coltypes,
        is_matrix,
        y_first,
        y_last,
    )
end

function capture_signature(kind::Symbol, source_name::AbstractString, opened_file_df=nothing)
    if kind != :table
        throw(DataContinuityError("Expected :table kind, got :$kind."))
    end
    if isempty(source_name)
        throw(DataContinuityError("No table or DataFrame source specified."))
    end

    if source_name == "__opened_file__"
        if isnothing(opened_file_df) || !(opened_file_df isa AbstractDataFrame)
            throw(DataContinuityError("Opened file DataFrame is not available."))
        end
        first_idx = 1
        last_idx = nrow(opened_file_df)
        colnames = String.(names(opened_file_df))
        coltypes = Type[eltype(opened_file_df[!, col]) for col in colnames]
        return SourceSignature(
            :table,
            String(source_name),
            first_idx,
            last_idx,
            colnames,
            coltypes,
            false,
            first_idx,
            last_idx,
        )
    end

    if !isdefined(Main, Symbol(source_name))
        throw(DataContinuityError("Variable \"$source_name\" is no longer defined in Main."))
    end

    var = getfield(Main, Symbol(source_name))
    if var isa AbstractDataFrame
        first_idx = 1
        last_idx = nrow(var)
        colnames = String.(names(var))
        coltypes = Type[eltype(var[!, col]) for col in colnames]
        return SourceSignature(
            :table,
            String(source_name),
            first_idx,
            last_idx,
            colnames,
            coltypes,
            false,
            first_idx,
            last_idx,
        )
    elseif var isa AbstractMatrix
        if is_vector_like(size(var))
            throw(DataContinuityError("Variable \"$source_name\" is a 1D array, not a table or matrix."))
        end
        first_idx = firstindex(var, 1)
        last_idx = lastindex(var, 1)
        n_cols = size(var, 2)
        colnames = ["$(source_name)_$i" for i in 1:n_cols]
        coltypes = Type[eltype(var) for _ in 1:n_cols]
        return SourceSignature(
            :table,
            String(source_name),
            first_idx,
            last_idx,
            colnames,
            coltypes,
            true,
            first_idx,
            last_idx,
        )
    else
        throw(DataContinuityError("Variable \"$source_name\" is neither a DataFrame nor a Matrix."))
    end
end

function capture_signature(state)
    source_type = state.data_selection.source_type[]
    if source_type == "X, Y Arrays"
        x = state.data_selection.selected_x[]
        y = state.data_selection.selected_y[]
        return capture_signature(:array, isnothing(x) ? "" : x, isnothing(y) ? "" : y)
    elseif source_type == "DataFrame"
        df_name = state.data_selection.selected_dataframe[]
        opened_file_df = state.file_opening.opened_file_df[]
        return capture_signature(:table, isnothing(df_name) ? "" : df_name, opened_file_df)
    else
        throw(DataContinuityError("Unknown source type: \"$source_type\"."))
    end
end

"""
    selection_from_state(state) -> NamedTuple

Extract the active data selection and row bounds from `state`.
"""
function selection_from_state(state)
    is_array_mode = state.data_selection.source_type[] == "X, Y Arrays"
    range_from = state.data_selection.range_from[]
    range_to = state.data_selection.range_to[]
    bounds_min = state.data_selection.data_bounds_from[]
    bounds_max = state.data_selection.data_bounds_to[]

    is_from_full = isnothing(range_from) || (!isnothing(bounds_min) && range_from == bounds_min)
    is_to_full = isnothing(range_to) || (!isnothing(bounds_max) && range_to == bounds_max)
    full_range = is_from_full && is_to_full

    if is_array_mode
        x = state.data_selection.selected_x[]
        y = state.data_selection.selected_y[]
        selected_cols = String[
            isnothing(x) ? "" : String(x),
            isnothing(y) ? "" : String(y),
        ]
        all_cols = true
    else
        cols = state.data_selection.selected_columns[]
        selected_cols = isnothing(cols) ? String[] : String.(cols)
        df_name = state.data_selection.selected_dataframe[]
        avail = if !isnothing(state.misc.source_signature[])
            state.misc.source_signature[].colnames
        elseif !isnothing(df_name) && !isempty(df_name)
            if df_name == "__opened_file__"
                opened = state.file_opening.opened_file_df[]
                isnothing(opened) ? String[] : names(opened)
            else
                get_dataframe_columns(df_name)
            end
        else
            String[]
        end
        all_cols = !isempty(selected_cols) && !isempty(avail) && length(selected_cols) == length(avail)
    end

    return (;
        selected_columns = selected_cols,
        range_from = range_from,
        range_to = range_to,
        full_range = full_range,
        all_columns = all_cols,
    )
end

"""
    check_continuity(old, new, selection) -> NamedTuple

Compare baseline signature `old` with fresh signature `new` for the given `selection`.

Returns `(; status, changes, reason)` where `status ∈ (:identical, :resumable, :fatal)`.
"""
function check_continuity(old, new, selection)
    if isnothing(old)
        return (; status = :identical, changes = String[], reason = "")
    end

    if old.kind != new.kind
        return (;
            status = :fatal,
            changes = String[],
            reason = "Source kind changed from :$(old.kind) to :$(new.kind).",
        )
    end

    if old.kind == :table && old.is_matrix != new.is_matrix
        return (;
            status = :fatal,
            changes = String[],
            reason = "Source kind changed between DataFrame and Matrix.",
        )
    end

    # Rule 1: XY length match
    if new.kind == :array
        x_len = new.last_index - new.first_index + 1
        y_rows = new.y_last_index - new.y_first_index + 1
        if x_len != y_rows
            return (;
                status = :fatal,
                changes = String[],
                reason = "Length of X ($x_len) does not match rows of Y ($y_rows).",
            )
        end
    end

    # Rule 2: Row range
    if !selection.full_range
        from = selection.range_from
        to = selection.range_to
        if !isnothing(from) && !isnothing(to)
            if from > to
                return (;
                    status = :fatal,
                    changes = String[],
                    reason = "'Range from' ($from) cannot be greater than 'Range to' ($to).",
                )
            end
            if from < new.first_index || to > new.last_index
                new_bounds = "$(new.first_index):$(new.last_index)"
                return (;
                    status = :fatal,
                    changes = String[],
                    reason = "Selected range $from:$to exceeds the new row bounds $new_bounds.",
                )
            end
        end
    end

    # Rule 3: Matrix / Y matrix column count
    if old.is_matrix
        if !selection.all_columns
            selected_cols = selection.selected_columns
            max_pos = 0
            for col in selected_cols
                idx = findfirst(==(col), old.colnames)
                if !isnothing(idx) && idx > max_pos
                    max_pos = idx
                end
            end
            new_cols = length(new.colnames)
            if new_cols < max_pos
                return (;
                    status = :fatal,
                    changes = String[],
                    reason = "New column count ($new_cols) is less than highest selected column position ($max_pos).",
                )
            end
        end
    end

    # Rule 4: DataFrame columns
    if old.kind == :table && !old.is_matrix
        for col in selection.selected_columns
            if !(col in new.colnames)
                return (;
                    status = :fatal,
                    changes = String[],
                    reason = "Selected column \"$col\" is no longer present in data.",
                )
            end
        end

        p = 0
        for col in selection.selected_columns
            idx = findfirst(==(col), old.colnames)
            if !isnothing(idx) && idx > p
                p = idx
            end
        end

        if p > 0
            if length(new.colnames) < p
                return (;
                    status = :fatal,
                    changes = String[],
                    reason = "Data has only $(length(new.colnames)) columns, but column at position $p was selected.",
                )
            end
            for i in 1:p
                if new.colnames[i] != old.colnames[i]
                    return (;
                        status = :fatal,
                        changes = String[],
                        reason = "Column $i name changed from \"$(old.colnames[i])\" to \"$(new.colnames[i])\".",
                    )
                end
                if new.coltypes[i] != old.coltypes[i]
                    return (;
                        status = :fatal,
                        changes = String[],
                        reason = "Column \"$(old.colnames[i])\" type changed from $(old.coltypes[i]) to $(new.coltypes[i]).",
                    )
                end
            end
        end
    end

    # Check for non-fatal structural changes
    changes = String[]

    old_rows = old.last_index - old.first_index + 1
    new_rows = new.last_index - new.first_index + 1
    if old_rows != new_rows
        push!(changes, "Row count changed from $(old_rows) to $(new_rows).")
    elseif old.first_index != new.first_index || old.last_index != new.last_index
        push!(changes, "Row index range changed from $(old.first_index):$(old.last_index) to $(new.first_index):$(new.last_index).")
    end

    if old.kind == :array
        old_y_cols = length(old.colnames) - 1
        new_y_cols = length(new.colnames) - 1
        if old_y_cols != new_y_cols
            push!(changes, "Y column count changed from $(old_y_cols) to $(new_y_cols).")
        end
    elseif old.is_matrix
        old_cols = length(old.colnames)
        new_cols = length(new.colnames)
        if old_cols != new_cols
            push!(changes, "Matrix column count changed from $(old_cols) to $(new_cols).")
        end
    elseif old.kind == :table
        if length(new.colnames) > length(old.colnames)
            added = new.colnames[(length(old.colnames) + 1):end]
            push!(changes, "Trailing columns added: $(join(added, ", ")).")
        elseif length(new.colnames) < length(old.colnames)
            removed = old.colnames[(length(new.colnames) + 1):end]
            push!(changes, "Trailing columns removed: $(join(removed, ", ")).")
        end
    end

    common_cols = min(length(old.colnames), length(new.colnames))
    for i in 1:common_cols
        if old.kind == :table && !old.is_matrix && old.colnames[i] != new.colnames[i]
            push!(changes, "Column $i name changed from \"$(old.colnames[i])\" to \"$(new.colnames[i])\".")
        end
        if old.coltypes[i] != new.coltypes[i]
            push!(changes, "Column \"$(new.colnames[i])\" type changed from $(old.coltypes[i]) to $(new.coltypes[i]).")
        end
    end

    if isempty(changes)
        return (; status = :identical, changes = String[], reason = "")
    else
        return (; status = :resumable, changes = changes, reason = "")
    end
end
