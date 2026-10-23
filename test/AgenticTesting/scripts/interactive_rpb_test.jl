# interactive_rpb_test.jl
#
# Interactive runner for the RPB refactoring and reactive Data Table.
# Launches with a visible Electron window and prompts at key steps.

using Pkg

initial_env = Base.active_project()
target_env = normpath(joinpath(@__DIR__, ".."))
target_project = normpath(joinpath(target_env, "Project.toml"))
already_target = initial_env !== nothing && normpath(initial_env) == target_project

try
    already_target || Pkg.activate(target_env)
    using AgenticTesting
    using CasualPlots
    using CSV
    using XLSX
    using DataFrames

    println("================================================================")
    println("Interactive RPB Refactoring Explorer")
    println("================================================================")

    CasualPlots.apply_theme!(nothing, CasualPlots.DEFAULT_THEME)
    for (k, v) in pairs(CasualPlots.variable_examples())
        Core.eval(Main, :($k = $v))
    end

    local_app = casualplots_app()
    Core.eval(Main, :(app = $local_app))

    local_app.state.data_selection.dims_dict_obs[] = Base.invokelatest(CasualPlots.get_dims_of_arrays)
    local_app.state.data_selection.dataframes_dict_obs[] = Base.invokelatest(CasualPlots.collect_dataframes_from_main)

    println("Launching visible Electron window...")
    CasualPlots.Ele.serve_app(local_app; frame=true)

    println("Waiting for Bonito WebSocket session...")
    session = wait_for_session(local_app; timeout=15)
    local_app.state.misc.last_update[] = 0.0

    println("\nReady for interactive testing. Type commands in the REPL or inspect the window.")
    println("You can run test groups directly:")
    println("  test_group_a_table_decoupling(session, local_app)")
    println("  test_group_b_hot_patching(session, local_app)")
    println("  test_group_c_structural_continuity(session, local_app)")
    println("  test_group_d_file_import_continuity(session, local_app)")
    println("  test_group_e_format_cache_isolation(session, local_app)")
finally
    already_target || (initial_env !== nothing ? Pkg.activate(initial_env) : Pkg.activate())
end

