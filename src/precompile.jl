using PrecompileTools

@setup_workload begin
    using DataFrames
    using WGLMakie
    using AlgebraOfGraphics
    using Bonito

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

        if VERSION ≥ v"1.12" && !(Sys.islinux() && get(ENV, "CI", "false") == "true")
            try
                app = casualplots_app()

                # Serve app in Electron window (show=true for testing, change to false later)
                Ele.serve_app(app; show=false)

                sleep(0.5)

                WGLMakie.activate!()

                for plottype in [Lines, Scatter, BarPlot]
                    plot_format = (; plottype=plottype, show_legend=false, legend_title="")
                    create_plot(plot_df; xcol=1, x_name="x", y_name="y", plot_format)
                end

                # Cleanup
                global cp_figure = nothing
                global cp_figure_ax = nothing

                sleep(0.3)
                try close(app) catch end
                try Ele.close_display(; strict=true) catch end
            catch e
                @debug "Electron precompilation skipped" exception=e
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
