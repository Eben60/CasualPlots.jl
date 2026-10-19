using CasualPlots
using Test
using SafeTestsets

@safetestset "Aqua.jl" include("src/aqua_test.jl")
@safetestset "Demo Data Functions" include("src/demo_data_test.jl")
@safetestset "Data Collection" include("src/collect_data_test.jl")
@safetestset "Plotting Utilities" include("src/plotting_utils_test.jl")
@safetestset "File Extensions (CSV/XLSX)" include("src/extensions_test.jl")
@safetestset "Data Normalization" include("src/normalization_test.jl")
@safetestset "Save Plot Validation" include("src/save_plot_test.jl")
@safetestset "File Reading Options" include("src/options_file_reading_test.jl")

# New Struct and State Tests
@safetestset "State Structs" include("src/app_types_test.jl")
@safetestset "App State Management" include("src/app_state_test.jl")
@safetestset "Code Generation" include("src/code_generation_test.jl")
@safetestset "Code Generation E2E" include("src/code_generation_e2e_test.jl")
@safetestset "Unitful Integration" include("src/integrations_unitful_test.jl")
@safetestset "Categorical Detection" include("src/categorical_detection_test.jl")