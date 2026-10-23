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
    @test state.plotting.format.xlog[] == false
    @test state.plotting.format.ylog[] == false
    @test state.plotting.format.x_is_categorical[] == false
    @test state.plotting.format.y_is_categorical[] == false
    @test isempty(state.plotting.format.dynamic_attributes)
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
    using CasualPlots: CasualPlotsState, SourceSignature

    state = CasualPlotsState()
    
    @test state.misc.format_is_default isa DefaultDict{Symbol, Bool}
    @test state.plotting.format.x_min isa Observable{Union{Nothing, Float64}}
    @test state.file_opening.opened_file_path isa Observable{String}
    @test state.data_selection.selected_columns isa Observable{Vector{String}}
    @test state.dialogs.modal_primary_label isa Observable{String}
    @test state.dialogs.modal_secondary_label isa Observable{Union{Nothing, String}}
    @test state.dialogs.modal_action_primary isa Observable{Int}
    @test state.dialogs.modal_action_secondary isa Observable{Int}
    @test state.dialogs.modal_callbacks isa Ref{Any}
    @test state.misc.source_signature isa Ref{Union{Nothing, SourceSignature}}
    @test state.misc.source_refresh isa Observable{Int}
end

@testset "show_modal! Unified Dialog States" begin
    using CasualPlots: CasualPlotsState, show_modal!

    state = CasualPlotsState()

    # 1-button default
    show_modal!(state, "Info msg"; type=:info)
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :info
    @test state.dialogs.modal_primary_label[] == "OK"
    @test state.dialogs.modal_secondary_label[] === nothing
    @test state.dialogs.modal_callbacks[].on_primary === nothing
    @test state.dialogs.modal_callbacks[].on_secondary === nothing

    # :confirm defaults
    show_modal!(state, "Overwrite confirm?"; type=:confirm)
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :confirm
    @test state.dialogs.modal_primary_label[] == "Overwrite"
    @test state.dialogs.modal_secondary_label[] == "Cancel"

    # 2-button custom warning
    called_primary = Ref(false)
    called_secondary = Ref(false)
    show_modal!(
        state,
        "Structural changes detected.";
        type=:warning,
        primary_label="Continue",
        secondary_label="Select data anew",
        on_primary=() -> (called_primary[] = true),
        on_secondary=() -> (called_secondary[] = true),
    )
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :warning
    @test state.dialogs.modal_primary_label[] == "Continue"
    @test state.dialogs.modal_secondary_label[] == "Select data anew"
    @test !isnothing(state.dialogs.modal_callbacks[].on_primary)
    @test !isnothing(state.dialogs.modal_callbacks[].on_secondary)
    state.dialogs.modal_callbacks[].on_primary()
    @test called_primary[] == true
    state.dialogs.modal_callbacks[].on_secondary()
    @test called_secondary[] == true

    # No leakage between calls: subsequent call clears custom labels and callbacks
    show_modal!(state, "All good"; type=:success)
    @test state.dialogs.modal_primary_label[] == "OK"
    @test state.dialogs.modal_secondary_label[] === nothing
    @test state.dialogs.modal_callbacks[].on_primary === nothing
    @test state.dialogs.modal_callbacks[].on_secondary === nothing

    # :error without exception throws ArgumentError
    @test_throws ArgumentError show_modal!(state, "Error without exception"; type=:error)
end

@testset "OutputObservables Construction" begin
    using CasualPlots: OutputObservables

    outputs = OutputObservables()
    
    @test outputs.plot[] isa Bonito.Node
    @test outputs.table[] isa Bonito.Node
    @test outputs.current_x[] === nothing
    @test outputs.current_y[] === nothing
end

@testset "Attribute Display Order" begin
    for config in CasualPlots.PLOT_TYPES
        for attr in CasualPlots.get_attributes(config)
            @test attr.name in CasualPlots.ATTRIBUTE_DISPLAY_ORDER
        end
    end
end

@testset "SinglePlotConfig Interface" begin
    using CasualPlots: SinglePlotConfig, GroupConfig
    
    @test hasfield(SinglePlotConfig, :group_config)
    @test fieldtype(SinglePlotConfig, :group_config) == GroupConfig
    
    @test hasfield(SinglePlotConfig, :visual_type)
    @test fieldtype(SinglePlotConfig, :visual_type) == Type
end
