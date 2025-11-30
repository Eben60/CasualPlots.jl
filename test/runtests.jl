using CasualPlots
using Test
using SafeTestsets

@safetestset "Data Transformations" include("data_transformations_test.jl")
@safetestset "Demo Data Functions" include("demo_data_test.jl")
@safetestset "Data Collection" include("collect_data_test.jl")
@safetestset "Plotting Utilities" include("plotting_utils_test.jl")