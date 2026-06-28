using CasualPlots
using Test
using DataStructures: DefaultDict
using Bonito
using DataFrames
using Observables
@testset "CasualPlotsState Default Construction" begin
    state = CasualPlots.CasualPlotsState()
    
    # Check that basic nested fields are correctly initialized
    @test state.file_opening isa CasualPlots.FileOpening
    @test state.file_saving isa CasualPlots.FileSaving
    @test state.dialogs isa CasualPlots.Dialogs
    @test state.data_selection isa CasualPlots.DataSelection
    @test state.plotting isa CasualPlots.Plotting
    @test state.plotting.format isa CasualPlots.PlotFormat
    @test state.plotting.handles isa CasualPlots.PlotHandles
    @test state.misc isa CasualPlots.Misc
    
    # Check some default observable values
    @test state.data_selection.source_type[] == "X, Y Arrays"
    @test state.plotting.format.x_min[] === nothing
    @test state.plotting.format.show_legend[] == true
    @test state.plotting.format.xreversed[] == false
    @test state.misc.block_format_update[] == false
end

@testset "CasualPlotsState Observable Mutation" begin
    state = CasualPlots.CasualPlotsState()
    
    # Verify we can mutate observables within the immutable struct
    state.data_selection.source_type[] = "DataFrame"
    @test state.data_selection.source_type[] == "DataFrame"
    
    state.plotting.format.x_min[] = 10.5
    @test state.plotting.format.x_min[] == 10.5
    
    state.file_opening.opened_file_df[] = DataFrame(a=[1, 2], b=[3, 4])
    @test state.file_opening.opened_file_df[] isa DataFrame
    @test nrow(state.file_opening.opened_file_df[]) == 2
end

@testset "CasualPlotsState Field Type Assertions" begin
    state = CasualPlots.CasualPlotsState()
    
    @test state.misc.format_is_default isa DefaultDict{Symbol, Bool}
    @test state.plotting.format.x_min isa Observable{Union{Nothing, Float64}}
    @test state.file_opening.opened_file_path isa Observable{String}
    @test state.data_selection.selected_columns isa Observable{Vector{String}}
end

@testset "OutputObservables Construction" begin
    outputs = CasualPlots.OutputObservables()
    
    @test outputs.plot[] isa Bonito.Node
    @test outputs.table[] isa Bonito.Node
    @test outputs.current_x[] === nothing
    @test outputs.current_y[] === nothing
end
