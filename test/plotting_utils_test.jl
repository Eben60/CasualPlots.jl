using CasualPlots
using Test
using DataFrames

using CasualPlots: var_to_string

# Test with simple symbol
@test var_to_string(:myvar) == "myvar"

# Test with qualified name (e.g., Main.myvar)
@test var_to_string(Symbol("Main.myvar")) == "myvar"
@test var_to_string(Symbol("Some.Module.var")) == "var"

# Test with string input
@test var_to_string("myvar") == "myvar"

# Note: select_cols is already tested in data_transformations_test.jl
