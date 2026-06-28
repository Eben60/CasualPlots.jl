using CasualPlots
using Test
using DataFrames
using CairoMakie

@testset "Code Generation End-to-End Execution" begin
    # Inject test data into Main scope since Arrays mode code expects it there
    @eval Main _casualplots_e2e_test_x = collect(1.0:10.0)
    @eval Main _casualplots_e2e_test_y = sqrt.(Main._casualplots_e2e_test_x)
    @eval Main import DataFrames: DataFrame
    @eval Main _casualplots_e2e_df = Main.DataFrame(a=Main._casualplots_e2e_test_x, b=Main._casualplots_e2e_test_y)

    @testset "Arrays + Lines" begin
        state = CasualPlots.initialize_app_state()
        state.data_selection.source_type[] = "X, Y Arrays"
        state.data_selection.selected_x[] = "_casualplots_e2e_test_x"
        state.data_selection.selected_y[] = "_casualplots_e2e_test_y"
        state.plotting.handles.title_text[] = "My E2E Plot Title"
        state.plotting.format.selected_plottype[] = "Lines"

        mktempdir() do dir
            code = CasualPlots.generate_julia_code(state)
            
            png_path = joinpath(dir, "plot1.png")
            svg_path = joinpath(dir, "plot1.svg")
            
            # Evaluate the function definitions in a clean, anonymous module
            test_mod = Module(:E2EArraysMod)
            include_string(test_mod, code)

            # Explicitly execute the functions and save the plot
            data = Base.invokelatest(test_mod.cp_load_data; _casualplots_e2e_test_x=Main._casualplots_e2e_test_x, _casualplots_e2e_test_y=Main._casualplots_e2e_test_y)
            fg = Base.invokelatest(test_mod.cp_create_plot, data)
            
            CairoMakie.activate!()
            CairoMakie.save(png_path, fg.figure)
            CairoMakie.save(svg_path, fg.figure)

            # 1. Verify PNG
            @test isfile(png_path)
            @test filesize(png_path) > 1000 # Should be substantial
            
            png_bytes = read(png_path, 4)
            @test png_bytes == UInt8[0x89, 0x50, 0x4e, 0x47] # PNG magic bytes

            # 2. Verify SVG
            @test isfile(svg_path)
            @test filesize(svg_path) > 1000
            
            svg_content = read(svg_path, String)
            @test startswith(svg_content, "<?xml") || startswith(svg_content, "<svg")
        end
    end

    @testset "DataFrame + Custom Limits" begin
        state = CasualPlots.initialize_app_state()
        state.data_selection.source_type[] = "DataFrame"
        state.data_selection.selected_dataframe[] = "_casualplots_e2e_df"
        state.data_selection.selected_columns[] = ["a", "b"]
        state.plotting.format.selected_plottype[] = "Scatter"
        state.plotting.format.x_min[] = 2.0
        state.plotting.format.x_max[] = 8.0

        mktempdir() do dir
            code = CasualPlots.generate_julia_code(state)
            
            png_path = joinpath(dir, "plot2.png")
            
            # Evaluate the function definitions in a clean, anonymous module
            test_mod = Module(:E2EDataFrameMod)
            include_string(test_mod, code)

            # Explicitly execute the functions and save the plot
            data = Base.invokelatest(test_mod.cp_load_data; _casualplots_e2e_df=Main._casualplots_e2e_df)
            fg = Base.invokelatest(test_mod.cp_create_plot, data)
            
            CairoMakie.activate!()
            CairoMakie.save(png_path, fg.figure)

            @test isfile(png_path)
            @test filesize(png_path) > 1000
        end
    end

    # Clean up Main scope data
    @eval Main begin
        _casualplots_e2e_test_x = nothing
        _casualplots_e2e_test_y = nothing
        _casualplots_e2e_df = nothing
    end
end
