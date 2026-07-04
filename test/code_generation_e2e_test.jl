using CasualPlots
using Test
using DataFrames
using CairoMakie


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
        code = CasualPlots.generate_julia_code(state).code
        
        png_path = joinpath(dir, "plot1.png")
        svg_path = joinpath(dir, "plot1.svg")
        
        # Evaluate the function definitions in a clean, anonymous module
        test_mod = Module(:E2EArraysMod)
        include_string(test_mod, code)

        # Explicitly execute the functions and save the plot
        data = Core.eval(test_mod, :(cp_load_data(; _casualplots_e2e_test_x=Main._casualplots_e2e_test_x, _casualplots_e2e_test_y=Main._casualplots_e2e_test_y)))
        fg = Core.eval(test_mod, :(cp_create_plot($data)))
        
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
        code = CasualPlots.generate_julia_code(state).code
        
        png_path = joinpath(dir, "plot2.png")
        
        # Evaluate the function definitions in a clean, anonymous module
        test_mod = Module(:E2EDataFrameMod)
        include_string(test_mod, code)

        # Explicitly execute the functions and save the plot
        data = Core.eval(test_mod, :(cp_load_data(; _casualplots_e2e_df=Main._casualplots_e2e_df)))
        fg = Core.eval(test_mod, :(cp_create_plot($data)))
        
        CairoMakie.activate!()
        CairoMakie.save(png_path, fg.figure)

        @test isfile(png_path)
        @test filesize(png_path) > 1000
    end
end

@testset "E2E Script File Execution" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "DataFrame"
    state.data_selection.selected_dataframe[] = "_casualplots_e2e_df"
    state.data_selection.selected_columns[] = ["a", "b"]
    state.plotting.handles.title_text[] = "My E2E Integration Title"
    
    mktempdir() do dir
        script_path = joinpath(dir, "my_test_script.jl")
        
        # 1. Generate and save the script using the full pipeline
        CasualPlots.generate_julia_code(state; file=script_path)
        @test isfile(script_path)
        
        # 2. Read, uncomment execution lines, and rewrite
        script_content = read(script_path, String)
        
        # Uncomment the data loading and plotting
        script_content = replace(script_content, r"^# (data = .*cp_create_plot.*)$"m => s"\1"; count=1)
        # Uncomment CairoMakie usage
        script_content = replace(script_content, r"^# (using CairoMakie)$"m => s"\1")
        script_content = replace(script_content, r"^# (CairoMakie\.activate!\(\))$"m => s"\1")
        # Uncomment SVG saving
        script_content = replace(script_content, r"^# (CairoMakie\.save\(.*\.svg\".*)$"m => s"\1")
        
        write(script_path, script_content)
        
        # 3. Execute in an isolated module
        cd(dir) do
            test_mod = Module(:ScriptFileTestingMod)
            Core.eval(test_mod, :(const _casualplots_e2e_df = Main._casualplots_e2e_df))
            Base.include(test_mod, script_path)
        end
        
        # 4. Verify the SVG was generated
        svg_file = joinpath(dir, "a-vs-b.svg")
        @test isfile(svg_file)
        @test filesize(svg_file) > 1000
        
        # Check script contents for the title string (CairoMakie converts text to paths in SVGs, so we can't grep the SVG)
        @test occursin("My E2E Integration Title", script_content)
    end
end

# Clean up Main scope data
@eval Main begin
    _casualplots_e2e_test_x = nothing
    _casualplots_e2e_test_y = nothing
    _casualplots_e2e_df = nothing
end
