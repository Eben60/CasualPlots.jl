module FileDialogWorkAround

using NativeFileDialog, Dates, FilePathsBase

# https://discourse.julialang.org/t/better-handling-of-pathnames/36792/33
function posixpathstring(inp)
    inp |> string |> isempty && return ""
    return inp |> Path |> _posixpath |> string
end
_posixpath(path::WindowsPath) = PosixPath((path.drive, path.segments...))
_posixpath(path) = path

function os_spec_path(path)
    Sys.iswindows() && return path |> WindowsPath |> string
    return posixpathstring(path)
end

"Returns OS version on Mac, or v0 if other OS"
function macos_version()
    Sys.isapple() || return v"0"
    try
        osversion = read(`sw_vers -productVersion`, String) # this works both on old MacOS and MacOs 15
        return VersionNumber(osversion)
    catch
        osversion = read(`sw_vers --productVersion`, String) # this is the official way to get the version on MacOS 15, but it doesn't work on old MacOS
        return VersionNumber(osversion)
    end
end

const BUGGY_MACOS = macos_version() >= v"15"

function pick_file(path=""; filterlist="")
    path = path |> os_spec_path
    BUGGY_MACOS || return NativeFileDialog.pick_file(path; filterlist) |> posixpathstring
    return pick_workaround(path, :pickfile; filterlist) |> posixpathstring
end
export pick_file

function pick_multi_file(path=""; filterlist="")
    path = path |> os_spec_path
    BUGGY_MACOS || return NativeFileDialog.pick_multi_file(path; filterlist) |> posixpathstring
    return pick_workaround(path, :multifile; filterlist) |> posixpathstring
end
export pick_multi_file

function pick_folder(path="")
    path = path |> os_spec_path
    BUGGY_MACOS || return NativeFileDialog.pick_folder(path) |> posixpathstring
    return pick_workaround(path, :pickfolder) |> posixpathstring
end
export pick_folder

function save_file(path=""; filterlist="")
    isempty(filterlist) || @warn "Filtering by extension is not supported by this hack on MacOS 15+ . filterlist `$filterlist` therefore ignored on all OSes for consistency."
    filterlist="" # Mac workaround 
    path = path |> os_spec_path
    BUGGY_MACOS || return NativeFileDialog.save_file(path; filterlist) |> posixpathstring
    return pick_workaround(path, :savefile; filterlist) |> posixpathstring
end
export save_file

function check_if_log_noise(s, starttime)
    s == "" && return nothing
    format = DateFormat("yyyy-mm-dd HH:MM:SS.sss")

    lognoise = length(s) >= 23 && (ss = s[1:23]; true) &&
        !isnothing(tryparse(DateTime, ss, format)) &&
        starttime <= DateTime(ss, format) <= now() && 
        occursin("osascript", s) &&
        occursin("IMKClient", s)

    lognoise || @warn "OS information, possibly irrelevant: $s"

    return nothing
end

"""
    extension_to_uti(ext)

Convert a file extension to its corresponding UTI (Uniform Type Identifier).
AppleScript's `choose file of type` requires UTIs, not plain extensions.
"""
function extension_to_uti(ext::AbstractString)
    ext = lowercase(ext)
    # Common UTI mappings for file extensions
    uti_map = Dict(
        "csv" => "public.comma-separated-values-text",
        "tsv" => "public.tab-separated-values-text",
        "xlsx" => "org.openxmlformats.spreadsheetml.sheet",
        "xls" => "com.microsoft.excel.xls",
        "txt" => "public.plain-text",
        "json" => "public.json",
        "xml" => "public.xml",
        "pdf" => "com.adobe.pdf",
        "png" => "public.png",
        "jpg" => "public.jpeg",
        "jpeg" => "public.jpeg",
    )
    # Return mapped UTI or fallback to "public.<ext>" format
    return get(uti_map, ext, "public.$ext")
end

function pick_workaround(path, picktype; filterlist="")
    path = string(path)
    if picktype == :pickfile
        script_trunk = """POSIX path of (choose file with prompt "Pick a file:" """
    elseif picktype == :savefile
        script_trunk = """POSIX path of (choose file name with prompt "Save the document as:" """
        isempty(filterlist) || @warn "Filtering by extension is not supported by this hack on MacOS 15+ . filterlist `$filterlist` will be ignored"
        filterlist = ""
    elseif picktype == :multifile
        script_trunk = """(choose file with prompt "Pick a file:" with multiple selections allowed """
    elseif picktype == :pickfolder
        script_trunk = """POSIX path of (choose folder with prompt "Pick a folder:" """
    else
        error("Key $picktype not supported")
    end

    startswith(filterlist, ".") && (filterlist = filterlist[2:end])
    filterlist = filterlist |> lowercase

    stderr_buffer = IOBuffer()

    if isempty(filterlist)
        filterdef = filtercall = ""
    else
        startswith(filterlist, ".") && (filterlist = filterlist[2:end])
        filterlist = filterlist |> lowercase
        # Convert comma-separated extensions to UTIs (Uniform Type Identifiers)
        # AppleScript's "of type" requires UTIs, not plain extensions
        extensions = split(filterlist, ",")
        utis = [extension_to_uti(strip(ext)) for ext in extensions]
        applescript_list = "{" * join(["\"$(uti)\"" for uti in utis], ", ") * "}"
        filterdef = """set filetype to $applescript_list\n"""
        filtercall = "of type filetype"
    end

    if isempty(path)
        pathdef = pathcall = ""
    else
        pathdef = """set strPath to "$path"\n"""
        pathcall = "default location strPath"
    end

    script = """$(filterdef)$(pathdef)$(script_trunk) $filtercall $pathcall)"""
    cmd = `osascript -e $script`
    flpath = ""
    warn_noise = ""
    starttime = now()
    try
        flpath = readchomp(pipeline(cmd; stderr=stderr_buffer));
        warn_noise = take!(stderr_buffer) |> String;
    catch
        flpath = ""
        warn_noise = ""
    end
    check_if_log_noise(warn_noise, starttime)
    picktype == :multifile || return flpath
    return parse_multifiles(flpath)
end

function parse_multifiles(p)
    p1 = replace(p, ", alias " => "\nalias ")
    als = split(p1, "\n")
    for (i, al) in pairs(als)
        startswith(al, "alias ") || error("cannot parse $al")
        als[i] = al[7:end]
    end
    return alias2posix.(als)
end

function alias2posix(fl)
    script = """POSIX path of "$fl" """ 
    cmd = `osascript -e $(script)`
    return readchomp(cmd)
end

end # module FileDialogWorkAround
