using Pkg
Pkg.activate(".")
using CasualPlots

state = CasualPlots.CasualPlotsState()
# simulate X, Y arrays
Main.eval(:(x = 1:100))
Main.eval(:(y = rand(100)))

state.data_selection.source_type[] = "X, Y Arrays"
state.data_selection.selected_x[] = "x"
state.data_selection.selected_y[] = "y"

code = CasualPlots.generate_julia_code(state)
println("=== Generated Code for Arrays ===")
println(code)
Meta.parse("begin\n" * code * "\nend")

# simulate DataFrame from Main
using DataFrames
Main.eval(:(test_df = DataFrame(A=1:10, B=rand(10))))
state.data_selection.source_type[] = "DataFrame"
state.data_selection.selected_dataframe[] = "test_df"
state.data_selection.selected_columns[] = ["A", "B"]

code_df = CasualPlots.generate_julia_code(state)
println("=== Generated Code for DataFrame (Main) ===")
println(code_df)
Meta.parse("begin\n" * code_df * "\nend")

println("Verification successful!")
