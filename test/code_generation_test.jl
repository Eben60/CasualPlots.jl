using CasualPlots
using Test

@testset "Code Generation String Verification - Arrays Mode" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "X, Y Arrays"
    state.data_selection.selected_x[] = "xx100"
    state.data_selection.selected_y[] = "yy100"
    
    code = CasualPlots.generate_julia_code(state)
    
    @test occursin("function cp_load_data(; xx100, yy100)", code)
    @test occursin("data = cp_load_data(; xx100, yy100)", code)
    @test occursin("cp_create_plot(data)", code)
    
    # Should not include CasualPlots import if not needed
    @test !occursin("using CasualPlots", code)
end

@testset "Code Generation String Verification - DataFrame Mode" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "DataFrame"
    state.data_selection.selected_dataframe[] = "my_df"
    state.data_selection.selected_columns[] = ["col_A", "col_B"]
    
    code = CasualPlots.generate_julia_code(state)
    
    @test occursin("function cp_load_data(; my_df)", code)
    @test occursin("data = cp_load_data(; my_df)", code)
    @test occursin("CasualPlots.clean_plot_data!(df_selected, [\"col_A\", \"col_B\"])", code)
    # Uses CasualPlots here
    @test occursin("using CasualPlots", code)
end

@testset "Code Generation String Verification - Opened File Mode" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "DataFrame"
    state.data_selection.selected_dataframe[] = "__opened_file__"
    state.file_opening.opened_file_path[] = "test_data.csv"
    state.data_selection.selected_columns[] = ["a", "b"]
    
    code = CasualPlots.generate_julia_code(state)
    
    @test occursin("function cp_load_data()", code)
    @test occursin("data = cp_load_data()", code)
    @test occursin("using CSV", code)
    @test occursin("CSV.read", code)
    @test occursin("using CasualPlots", code)
end

@testset "Code Generation String Verification - Opened File Mode with options" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "DataFrame"
    state.data_selection.selected_dataframe[] = "__opened_file__"
    state.file_opening.opened_file_path[] = "test_data.csv"
    state.data_selection.selected_columns[] = ["a", "b"]
    state.file_opening.skip_after_header[] = 2
    
    code = CasualPlots.generate_julia_code(state)
    @test occursin("CasualPlots.skip_rows!(", code)
    @test occursin("using CasualPlots", code)
end

@testset "Code Generation String Verification - Format Options" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "X, Y Arrays"
    state.data_selection.selected_x[] = "xx"
    state.data_selection.selected_y[] = "yy"
    
    # Custom Labels
    state.plotting.handles.title_text[] = "My Custom Title"
    state.plotting.handles.xlabel_text[] = "X Axis"
    
    # Disable legend
    state.plotting.format.show_legend[] = false
    
    # Custom limits
    state.plotting.format.x_min[] = 5.0
    state.plotting.format.y_max[] = 100.5
    
    # Theme
    state.plotting.format.selected_theme[] = "theme_dark"
    
    code = CasualPlots.generate_julia_code(state)
    
    @test occursin("\"My Custom Title\"", code)
    @test occursin("\"X Axis\"", code)
    @test occursin("legend=(show=false,)", code)
    @test occursin("limits = (5.0, nothing, nothing, 100.5)", code)
    @test occursin("set_theme!(theme_dark())", code)
end

@testset "Code Generation String Verification - Group-by Geometry" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "X, Y Arrays"
    state.data_selection.selected_x[] = "xx"
    state.data_selection.selected_y[] = "yy"
    state.plotting.format.selected_group_by[] = "Geometry"
    state.plotting.format.selected_plottype[] = "Lines"
    
    code = CasualPlots.generate_julia_code(state)
    @test occursin("group_mapping = (; linestyle = group_col =>", code)
    
    state.plotting.format.selected_plottype[] = "Scatter"
    code_scatter = CasualPlots.generate_julia_code(state)
    @test occursin("group_mapping = (; marker = group_col =>", code_scatter)
end

@testset "generate_julia_code file suffix logic" begin
    state = CasualPlots.initialize_app_state()
    state.data_selection.source_type[] = "X, Y Arrays"
    state.data_selection.selected_x[] = "xx"
    state.data_selection.selected_y[] = "yy"
    
    mktempdir() do tmpdir
        # File with missing suffix
        filepath_no_ext = joinpath(tmpdir, "my_plot")
        filepath_expected = filepath_no_ext * ".jl"
        
        CasualPlots.generate_julia_code(state; file=filepath_no_ext)
        @test !isfile(filepath_no_ext)
        @test isfile(filepath_expected)
        
        # Verify content matches what String version gives
        code_str = CasualPlots.generate_julia_code(state)
        @test read(filepath_expected, String) == code_str
        
        # File with existing suffix
        filepath_with_ext = joinpath(tmpdir, "my_plot_2.jl")
        CasualPlots.generate_julia_code(state; file=filepath_with_ext)
        @test isfile(filepath_with_ext)
        @test !isfile(filepath_with_ext * ".jl")
    end
end
