using Pkg

initial_env = Base.active_project()
target_env = normpath(joinpath(@__DIR__, ".."))
target_project = normpath(joinpath(target_env, "Project.toml"))
already_target = initial_env !== nothing && normpath(initial_env) == target_project

try
    already_target || Pkg.activate(target_env)
    using AgenticTesting, CasualPlots
    using CSV, XLSX
    Core.eval(Main, :(CasualPlots.@populate()))

    with_screenshot_env(; nofancy=true) do
        println("=== Running all screenshot generators ===")

        run_screenshot_generator(generate_non_linear_discharge_screenshot; makescript=false)
        
        println("=== Screenshot generated successfully ===")
    end
finally
    already_target || (initial_env !== nothing ? Pkg.activate(initial_env) : Pkg.activate())
end