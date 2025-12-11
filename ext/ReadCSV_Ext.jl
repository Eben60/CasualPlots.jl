module ReadCSV_Ext

using CasualPlots
using CSV
using DataFrames

import CasualPlots: read_csv

"""
    read_csv(source; kwargs...) -> DataFrame

Wrapper around `CSV.read` that reads a CSV file into a DataFrame.

# Arguments
- `source`: Path to the CSV file or any source accepted by `CSV.read`
- `kwargs...`: Additional keyword arguments passed to `CSV.read`

# Returns
- `DataFrame`: The parsed data
"""
function CasualPlots.read_csv(source; kwargs...)
    return CSV.read(source, DataFrame; kwargs...)
end

end # module
