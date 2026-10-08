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

        run_screenshot_generator(generate_dataframe_source_screenshot)
        run_screenshot_generator(generate_xy_source_screenshot)
        run_screenshot_generator(generate_open_tab_screenshot)
        run_screenshot_generator(generate_format_tab_barplot_dodged_screenshot)
        run_screenshot_generator(generate_format_tab_barplot_stacked_screenshot)
        run_screenshot_generator(generate_format_tab_limits_screenshot)
        run_screenshot_generator(generate_format_tab_lines_screenshot)
        run_screenshot_generator(generate_plot_pane_maximized_screenshot)
        run_screenshot_generator(generate_save_tab_script_screenshot)
        run_screenshot_generator(generate_table_view_screenshot)
        run_screenshot_generator(generate_line_symbol_plot_screenshot)
        run_screenshot_generator(generate_Scatter_by_geometry_screenshot)
        
        println("=== All screenshots generated successfully ===")
    end
finally
    already_target || (initial_env !== nothing ? Pkg.activate(initial_env) : Pkg.activate())
end