using PrecompileTools

@setup_workload begin
    using DataFrames
    using WGLMakie
    using AlgebraOfGraphics
    using Bonito

    # TEMPORARY bisect switch for the Julia 1.14 precompile stall (set env var before `precompile`):
    #   0 = DataFrame preprocessing only (default on Julia >= 1.14: Electron workload stalls there)
    #   1 = + Electron application start/close (no Bonito, no app)
    #   2 = + casualplots_app() + Ele.serve_app + cleanup
    #   3 = + plot loop (full workload, default on Julia < 1.14)
    # NB: `v"1.14.0-"` sorts below every 1.14 prerelease, whereas `VERSION < v"1.14"` is true for 1.14.0-alphaN.
    pc_stage = parse(Int, get(ENV, "CASUALPLOTS_PC_STAGE", VERSION < v"1.14.0-" ? "3" : "0"))

    @compile_workload begin
        # ===========================
        # DataFrame preprocessing
        # ===========================

        dirty_df = DataFrame(
            x = 1:10,
            y1 = collect(1.0:10.0),
            y2 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            str_col = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
            mixed = Any[1, 2.0, "3", 4, 5.0, 6, 7, 8, 9, 10]
        )

        normalize_strings!(dirty_df)
        numeric_cols = ["y1", "y2", "mixed"]
        normalize_numeric_columns!(dirty_df, numeric_cols)

        skip_df = DataFrame(x = 1:5, y = [missing, 2.0, missing, 4.0, 5.0])
        skip_rows!(skip_df, UInt(1), true)

        # ===========================
        # Electron window approach
        # ===========================

        plot_df = DataFrame(x = 1:5, y = [1.0, 4.0, 9.0, 16.0, 25.0])

        if pc_stage ≥ 1 && VERSION ≥ v"1.12" && !(Sys.islinux() && get(ENV, "CI", "false") == "true")
            @info "CasualPlots precompile workload: stage $pc_stage"
            local app = nothing
            try
                if pc_stage == 1
                    Ele.get_electron_app()
                else
                    app = casualplots_app()

                    # Serve app in Electron window (show=true for testing, change to false later)
                    Ele.serve_app(app; show=false)

                    sleep(0.5)
                end

                if pc_stage ≥ 3
                    WGLMakie.activate!()

                    # Phase 2/3: Updated to use new unified `create_plot_df_long` pipeline
                    ys = names(plot_df)[2:end]
                    df_long = stack(plot_df, ys; variable_name=:group, value_name=:y)
                    mappings = (; x_col=:x, y_col=:y, group_col=:group)

                    for plottype in ["Lines", "Scatter", "BarPlot"]
                        plot_format = (;
                            plottype=plottype, show_legend=false, legend_title="", group_by="Color",
                            x_min=nothing, x_max=nothing, y_min=nothing, y_max=nothing,
                            xreversed=false, yreversed=false, xlog=false, ylog=false,
                        )
                        CasualPlots.create_plot_df_long(df_long, "x", "y", plot_format; mappings)
                    end
                end
            catch e
                @error "Precompile workload error on Julia $VERSION" exception=(e, catch_backtrace())
                rethrow(e)
            finally
                # Cleanup
                global cp_figure = nothing
                global cp_figure_ax = nothing
                global cp_file_df = nothing

                sleep(0.3)
                # TEMPORARY diagnostics (1.14 stall): identify the lingering `pipe[N]` handle
                local eproc = try Ele.ELECTRON_APP[].proc catch; nothing end
                try !isnothing(app) && close(app) catch end
                try Ele.close_display(; strict=true) catch end

                function pc_hinfo(io)
                    try
                        "$(typeof(io)) $(Base._fd(io)) isopen=$(isopen(io))"
                    catch err
                        "$(typeof(io)) fd=n/a ($(typeof(err))) isopen=$(try isopen(io) catch; "?" end)"
                    end
                end
                function pc_report(tag)
                    lines = String[]
                    if !isnothing(eproc)
                        push!(lines, "proc.in:  " * pc_hinfo(eproc.in))
                        push!(lines, "proc.out: " * pc_hinfo(eproc.out))
                        push!(lines, "proc.err: " * pc_hinfo(eproc.err))
                    end
                    for h in collect(keys(Base.uvhandles))
                        occursin("Pipe", string(typeof(h))) && push!(lines, "uvhandles: " * pc_hinfo(h))
                    end
                    msg = "PCDIAG $tag\n    " * join(lines, "\n    ")
                    @info msg
                end
                pc_report("after close_display")
                if !isnothing(eproc)
                    try
                        close(eproc.in)
                    catch err
                        @info "PCDIAG close(proc.in) failed" exception=(err, catch_backtrace())
                    end
                    pc_report("after close(proc.in)")

                    t0 = time()
                    while process_running(eproc) && time() - t0 < 5
                        sleep(0.1)
                    end
                    @info "PCDIAG electron process state" running=process_running(eproc) exited=process_exited(eproc) exitcode=eproc.exitcode waited_s=round(time() - t0; digits=2)
                    yield()
                    pc_report("after process wait")
                end
            end
        end

        # ===========================
        # Final cleanup
        # ===========================

        for _ in 1:3
            GC.gc()
            yield()
            sleep(0.1)
        end
        GC.gc(true)
        yield()
    end
end
