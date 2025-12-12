module ReadXLSX_Ext

using CasualPlots
using XLSX
using DataFrames

import CasualPlots: open_xlsx, readtable_xlsx, sheetnames_xlsx

"""
    open_xlsx(filepath; kwargs...) -> XLSXFile

Wrapper around `XLSX.openxlsx` (or `XLSX.readxlsx` for read-only access).

# Arguments
- `filepath`: Path to the XLSX file
- `kwargs...`: Additional keyword arguments passed to `XLSX.openxlsx`

# Returns
- `XLSXFile`: The opened XLSX file object
"""
function open_xlsx(filepath; kwargs...)
    return XLSX.openxlsx(filepath; kwargs...)
end

"""
    readtable_xlsx(filepath, sheet; kwargs...) -> DataFrame

Wrapper around `XLSX.readtable` that reads an Excel sheet into a DataFrame.

# Arguments
- `filepath`: Path to the XLSX file
- `sheet`: Sheet name or index to read
- `kwargs...`: Additional keyword arguments passed to `XLSX.readtable`

# Returns
- `DataFrame`: The parsed data from the specified sheet
"""
function readtable_xlsx(filepath, sheet; kwargs...)
    return XLSX.readtable(filepath, sheet; kwargs...) |> DataFrame
end

"""
    sheetnames_xlsx(filepath) -> Vector{String}

Get the list of sheet names from an XLSX file.

# Arguments
- `filepath`: Path to the XLSX file

# Returns
- `Vector{String}`: Names of all sheets in the file
"""
function sheetnames_xlsx(filepath)
    return XLSX.sheetnames(XLSX.readxlsx(filepath))
end

end # module
