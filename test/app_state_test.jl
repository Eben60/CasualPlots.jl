using CasualPlots
using Test
using Bonito

@testset "initialize_app_state" begin
    state = CasualPlots.initialize_app_state()
    @test state isa CasualPlots.CasualPlotsState
    @test state.data_selection.source_type[] == "X, Y Arrays"
    
    # Test destructuring
    (; file_opening, data_selection) = state
    (; format, handles) = state.plotting
    
    @test file_opening isa CasualPlots.FileOpening
    @test data_selection isa CasualPlots.DataSelection
    @test format isa CasualPlots.PlotFormat
    @test handles isa CasualPlots.PlotHandles
end

@testset "initialize_output_observables" begin
    outputs = CasualPlots.initialize_output_observables()
    @test outputs isa CasualPlots.OutputObservables
    @test outputs.current_x[] === nothing
end

@testset "CasualPlotApp Wrapper Fallbacks" begin
    state = CasualPlots.initialize_app_state()
    # Create a dummy Bonito app (it needs a handler function)
    app = Bonito.App(session -> DOM.div("Test"))
    
    cp_app = CasualPlotApp(app, state)
    
    @test cp_app.state === state
    @test cp_app.app === app
    
    # Test convert fallback
    @test convert(Bonito.App, cp_app) === app
end

@testset "Format Defaults Reset Logic" begin
    state = CasualPlots.initialize_app_state()
    
    # Mutate some format options
    state.plotting.format.x_min[] = 10.0
    state.plotting.handles.title_text[] = "Custom Title"
    
    state.misc.format_is_default[:x_min] = false
    state.misc.format_is_default[:title] = false
    
    # Test semipersistent reset
    CasualPlots.reset_semipersistent_format_options!(state)
    
    @test state.plotting.format.x_min[] === nothing
    @test state.misc.format_is_default[:x_min] == true
    # semipersistent reset shouldn't touch title
    @test state.plotting.handles.title_text[] == "Custom Title"
    @test state.misc.format_is_default[:title] == false
    
    # Test full format reset
    # Note: reset_format_defaults! only clears the format_is_default tracking dictionary.
    # It does not mutate the observable values themselves, which is handled elsewhere.
    CasualPlots.reset_format_defaults!(state.misc.format_is_default)
    @test state.misc.format_is_default[:title] == true
end
