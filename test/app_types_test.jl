using CasualPlots
using Test
using DataStructures: DefaultDict
using Bonito
using DataFrames
using Observables

@testset "CasualPlotsState Default Construction" begin
    using CasualPlots: CasualPlotsState, FileOpening, FileSaving, Dialogs, DataSelection, Plotting, PlotFormat, PlotHandles, Misc

    state = CasualPlotsState()
    
    # Check that basic nested fields are correctly initialized
    @test state.file_opening isa FileOpening
    @test state.file_saving isa FileSaving
    @test state.dialogs isa Dialogs
    @test state.data_selection isa DataSelection
    @test state.plotting isa Plotting
    @test state.plotting.format isa PlotFormat
    @test state.plotting.handles isa PlotHandles
    @test state.misc isa Misc
    
    # Check some default observable values
    @test state.data_selection.source_type[] == "X, Y Arrays"
    @test state.plotting.format.x_min[] === nothing
    @test state.plotting.format.show_legend[] == true
    @test state.plotting.format.xreversed[] == false
    @test state.plotting.format.selected_bar_direction[] == "Vertical"
    @test state.plotting.format.selected_bar_mode[] == "Dodged"
    @test state.misc.block_format_update[] == false
end

@testset "CasualPlotsState Observable Mutation" begin
    using CasualPlots: CasualPlotsState

    state = CasualPlotsState()
    
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
    using CasualPlots: CasualPlotsState

    state = CasualPlotsState()
    
    @test state.misc.format_is_default isa DefaultDict{Symbol, Bool}
    @test state.plotting.format.x_min isa Observable{Union{Nothing, Float64}}
    @test state.file_opening.opened_file_path isa Observable{String}
    @test state.data_selection.selected_columns isa Observable{Vector{String}}
end

@testset "OutputObservables Construction" begin
    using CasualPlots: OutputObservables

    outputs = OutputObservables()
    
    @test outputs.plot[] isa Bonito.Node
    @test outputs.table[] isa Bonito.Node
    @test outputs.current_x[] === nothing
    @test outputs.current_y[] === nothing
end
