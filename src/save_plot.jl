# Save plot functionality using CairoMakie

"""Supported file extensions for plot saving via CairoMakie"""
const SUPPORTED_SAVE_FORMATS = ["png", "svg", "pdf"]

"""
    get_file_extension(path::AbstractString) -> String

Extract lowercase file extension from path (without dot).
Returns empty string if no extension found.
"""
function get_file_extension(path::AbstractString)
    path = strip(path)
    isempty(path) && return ""
    
    basename_str = basename(path)
    dot_idx = findlast('.', basename_str)
    isnothing(dot_idx) && return ""
    dot_idx == length(basename_str) && return ""
    
    return lowercase(basename_str[dot_idx+1:end])
end

"""
    validate_save_path(path::AbstractString) -> (valid::Bool, error_message::String)

Validate that the save path has a supported file extension.
Returns a tuple of (is_valid, error_message).
"""
function validate_save_path(path::AbstractString)
    path = strip(path)
    
    if isempty(path)
        return (false, "Please specify a file path")
    end
    
    ext = get_file_extension(path)
    
    if isempty(ext)
        return (false, "File must have an extension (.png, .svg, or .pdf)")
    end
    
    if ext ∉ SUPPORTED_SAVE_FORMATS
        return (false, "Unsupported format '.$ext'. Use .png, .svg, or .pdf")
    end
    
    return (true, "")
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
    (valid, err_msg) = validate_save_path(path)
    if !valid
        @warn "Save validation failed: $err_msg"
        return (false, err_msg)
    end
    
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
