using CasualPlots
using Test
using SafeTestsets

# @safetestset "Data Transformations" include("data_transformations_test.jl")
@safetestset "Demo Data Functions" include("demo_data_test.jl")
@safetestset "Data Collection" include("collect_data_test.jl")
@safetestset "Plotting Utilities" include("plotting_utils_test.jl")
@safetestset "File Extensions (CSV/XLSX)" include("extensions_test.jl")
@safetestset "Data Normalization" include("normalization_test.jl")
@safetestset "Save Plot Validation" include("save_plot_test.jl")
@safetestset "File Reading Options" include("file_reading_options_test.jl")

# New Struct and State Tests
@safetestset "State Structs" include("app_types_test.jl")
@safetestset "App State Management" include("app_state_test.jl")
@safetestset "Code Generation" include("code_generation_test.jl")
@safetestset "Code Generation E2E" include("code_generation_e2e_test.jl")
@safetestset "Unitful Integration" include("unitful_integration_test.jl")