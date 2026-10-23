# run_rpb_agentic_tests.jl
#
# Autonomous test runner for the RPB refactoring and reactive Data Table.
# Runs all test groups sequentially in Electron and logs detailed results.

using Pkg

initial_env = Base.active_project()
target_env = normpath(joinpath(@__DIR__, ".."))
target_project = normpath(joinpath(target_env, "Project.toml"))
already_target = initial_env !== nothing && normpath(initial_env) == target_project

results = Tuple{Bool, String}[]

try
    already_target || Pkg.activate(target_env)
    using AgenticTesting
    using AgenticTesting: wait_for_session,
                          test_group_a_table_decoupling,
                          test_group_b_hot_patching,
                          test_group_c_structural_continuity,
                          test_group_d_file_import_continuity,
                          test_group_e_format_cache_isolation
    using CasualPlots
    using CSV
    using XLSX
    using DataFrames
    using Dates

    println("================================================================")
    println("Starting Autonomous RPB Refactoring Agentic Test Suite")
    println("Timestamp: $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))")
    println("================================================================")

    # 1. Initialize environment & data
    CasualPlots.apply_theme!(nothing, CasualPlots.DEFAULT_THEME)
    for (k, v) in pairs(CasualPlots.variable_examples())
        Core.eval(Main, :($k = $v))
    end

    local_app = casualplots_app()
    Core.eval(Main, :(app = $local_app))

    local_app.state.data_selection.dims_dict_obs[] = Base.invokelatest(CasualPlots.get_dims_of_arrays)
    local_app.state.data_selection.dataframes_dict_obs[] = Base.invokelatest(CasualPlots.collect_dataframes_from_main)

    println("Launching Electron window...")
    CasualPlots.Ele.serve_app(local_app; frame=false)

    println("Waiting for Bonito WebSocket session...")
    session = wait_for_session(local_app; timeout=15)
    local_app.state.misc.last_update[] = 0.0

    try
        # Run Test Groups
        test_group_a_table_decoupling(session, local_app; results=results)
        test_group_b_hot_patching(session, local_app; results=results)
        test_group_c_structural_continuity(session, local_app; results=results)
        test_group_d_file_import_continuity(session, local_app; results=results)
        test_group_e_format_cache_isolation(session, local_app; results=results)
    finally
        println("\nCleaning up app and Electron session...")
        try
            close(local_app)
        catch e
            @warn "Error closing app: $e"
        end
        try
            CasualPlots.Ele.close_display(strict=true)
        catch e
            @warn "Error closing Electron display: $e"
        end
    end

    # Write summary report
    report_dir = normpath(joinpath(@__DIR__, "..", "screenshots", "reports"))
    mkpath(report_dir)
    report_file = joinpath(report_dir, "report_rpb_refactoring.md")

    total_tests = length(results)
    passed_tests = count(r -> r[1], results)
    failed_tests = total_tests - passed_tests

    open(report_file, "w") do io
        println(io, "# Agentic Test Report: (Re-)Plot Button Refactoring & Reactive Table")
        println(io, "\n*Run Date: $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))*\n")
        println(io, "## Summary")
        println(io, "- **Total Checks**: $total_tests")
        println(io, "- **Passed**: $passed_tests")
        println(io, "- **Failed**: $failed_tests")
        println(io, "- **Overall Status**: $(failed_tests == 0 ? "✅ **ALL TESTS PASSED**" : "❌ **FAILURES DETECTED**")\n")
        println(io, "## Detailed Test Results\n")
        println(io, "| Step ID | Status | Details |")
        println(io, "| :--- | :---: | :--- |")
        for (pass, msg) in results
            # Extract step_id and status message
            # format from log_result is already logged to results.md
            status_icon = pass ? "✅ PASS" : "❌ FAIL"
            println(io, "| - | $status_icon | $msg |")
        end
    end

    println("\n================================================================")
    println("Test Suite Completed: $passed_tests / $total_tests passed ($(failed_tests) failures)")
    println("Detailed report saved to: $report_file")
    println("================================================================")

finally
    already_target || (initial_env !== nothing ? Pkg.activate(initial_env) : Pkg.activate())
end

