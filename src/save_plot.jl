# Save plot functionality using CairoMakie

"""Supported file extensions for plot saving via CairoMakie"""
const SUPPORTED_SAVE_FORMATS = ["png", "svg", "pdf"]


"""
    validate_save_path(path::AbstractString) -> NamedTuple

Validate that the save path has a supported file extension.
Returns `(; valid::Bool, error_message::String, path::String)`.
The returned path will have its extension converted to lowercase if necessary.
"""
function validate_save_path(path::AbstractString)
    path = strip(path)
    
    if isempty(path)
        return (; valid=false, error_message="Please specify a file path", path="")
    end
    
    base_name, orig_ext = splitext(path)
    ext = lowercase(orig_ext)
    
    if isempty(ext)
        return (; valid=false, error_message="File must have an extension (.png, .svg, or .pdf)", path)
    end

    clean_ext = lstrip(ext, '.') 
    if clean_ext ∉ SUPPORTED_SAVE_FORMATS
        return (; valid=false, error_message="Unsupported format '$(orig_ext)'. Use .png, .svg, or .pdf", path)
    end
    
    normalized_path = base_name * ext
    if orig_ext != ext
        @warn "Makie (FileIO) requires lowercase extensions. The file will be saved as $(basename(normalized_path)) instead."
    end
    
    return (; valid=true, error_message="", path=normalized_path)
end

"""
    save_current_plot(path::AbstractString, figure::Figure) -> (success::Bool, message::String)

Save the figure to the specified path using CairoMakie.
Temporarily activates CairoMakie backend, saves the figure, then reactivates WGLMakie.

# Arguments
- `path::AbstractString`: Absolute path to save the file to
- `figure::Figure`: The Makie Figure object to save

# Returns
Tuple of (success::Bool, message::String) indicating result and any error message.
"""
function save_current_plot(path::AbstractString, figure::Figure)
    # Validate path first
    val = validate_save_path(path)
    if !val.valid
        @warn "Save validation failed: $(val.error_message)"
        return (false, val.error_message)
    end
    
    path = val.path
    
    # Ensure directory exists
    dir = dirname(path)
    if !isempty(dir) && !isdir(dir)
        try
            mkpath(dir)
        catch e
            err_msg = "Cannot create directory: $(e)"
            @warn err_msg
            return (false, err_msg)
        end
    end
    
    # Switch to CairoMakie for file saving
    CairoMakie.activate!()
    try
        # Use CairoMakie.save explicitly to avoid FileIO routing issues
        CairoMakie.save(String(path), figure)
        msg = "Plot saved to $(basename(path))"
        @info msg
        return (true, msg)
    catch e
        err_msg = "Error saving plot: $(e)"
        @warn err_msg
        return (false, err_msg)
    finally
        # Always switch back to WGLMakie for display
        WGLMakie.activate!()
    end
end
