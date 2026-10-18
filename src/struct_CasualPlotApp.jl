"""
    CasualPlotApp

A wrapper around `Bonito.App` that also holds the application state.
This prevents the state from being garbage collected prematurely and allows
programmatic interaction with the UI via `app.state`.
"""
struct CasualPlotApp
    app::Bonito.App
    state::CasualPlotsState
end

# Forward lifecycle
function Base.close(cp::CasualPlotApp)
    close(cp.app)
    set_theme!()
    return nothing
end

# Forward Display (REPL, Notebooks, IDEs)
Base.show(io::IO, m::MIME, cp::CasualPlotApp) = show(io, m, cp.app)
Base.show(io::IO, m::MIME"text/plain", cp::CasualPlotApp) = show(io, m, cp.app)
# Forward 2-argument `display` for all `AbstractDisplay` subtypes defined in `Bonito`
# (e.g., BrowserDisplay, ElectronDisplay). Generating methods only for Bonito's concrete
# display types forwards Bonito-specific displays while preventing method ambiguities
# with standard Julia displays (TextDisplay, REPLDisplay, VSCode inline displays).
for D in subtypes(AbstractDisplay)
    if Base.moduleroot(parentmodule(D)) === Bonito
        @eval Base.display(d::$D, cp::CasualPlotApp) = display(d, cp.app)
    end
end
Base.display(cp::CasualPlotApp) = display(cp.app)

# Forward Web serving
Bonito.Server(cp::CasualPlotApp, args...; kwargs...) = Bonito.Server(cp.app, args...; kwargs...)
Bonito.route!(server::Bonito.Server, path::String, cp::CasualPlotApp) = Bonito.route!(server, path, cp.app)
Bonito.export_static(dir::AbstractString, cp::CasualPlotApp; kwargs...) = Bonito.export_static(dir, cp.app; kwargs...)

# Catch-all fallback
Base.convert(::Type{Bonito.App}, cp::CasualPlotApp) = cp.app

# Forward Electron Serving
Ele.serve_app(cp::CasualPlotApp; kwargs...) = Ele.serve_app(cp.app; kwargs...)
