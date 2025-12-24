module Ele # code from NetworkDynamicsInspectorElectronExt

using Electron: Electron, windows
using Bonito: Bonito, HTTPServer

const ELECTRON_APP = Ref{Any}(nothing)
const ELECTRON_DISP = Ref{Any}(nothing)

"""
    serve_app(app; show=true)

Display the app in an Electron window.

# Arguments
- `app`: The Bonito app to display
- `show::Bool=true`: If `false`, the window is created but hidden (useful for precompilation/testing)
"""
function serve_app(app; show::Bool=true)
    disp = get_electron_display(; show)
    display(disp, app)
    nothing
end

function close_display(; strict)
    if haswindow()
        @info "Close existing Windows"
        while length(windows(ELECTRON_APP[]))>0
            close(first(windows(ELECTRON_APP[])))
        end
    end
    if strict
        close_application()
    end
end

function get_electron_display(; show::Bool=true)
    app = get_electron_app()
    window = get_electron_window(; show)
    return HTTPServer.ElectronDisplay(
        HTTPServer.EWindow(app, window),
        HTTPServer.BrowserDisplay(; open_browser=false)
    )
end

function get_electron_window(; show::Bool=true)
    app = get_electron_app()

    any(w -> !w.exists, windows(app)) && @warn "App contains reference to nonexistent window(s)"

    window = if isempty(windows(app))
        # x, y = CURRENT_DISPLAY[] isa ElectronDisp ? CURRENT_DISPLAY[].resolution : (1200, 800)
        x,y = (1200, 900)
        opts = Dict(
            :width => x, 
            :height => y, 
            :show => show,  # Control window visibility
            :webPreferences => Dict(:enableRemoteModule => true)
        )
        @info "Create new Electron Window with $opts"
        Electron.Window(app, opts)
    else
        length(windows(app)) != 1 && @warn "App contains multiple windows"
        first(windows(app))
    end

    return window
end
haswindow() = hasapp() && !isempty(windows(ELECTRON_APP[]))

function get_electron_app()
    if !hasapp()
        additional_electron_args = [
            "--disable-logging",
            "--no-sandbox",
            "--user-data-dir=$(mktempdir())",
            "--disable-features=AccessibilityObjectModel",
            "--enable-unsafe-swiftshader",        # ← allow SwiftShader fallback
        ]
        if haskey(ENV, "GITHUB_ACTIONS")
            append!(additional_electron_args, [
                "--use-gl=swiftshader",               # ← explicitly request software GL
                "--disable-gpu",                      # ← disable GPU to avoid GPU errors
            ])
        end
        ELECTRON_APP[] = Electron.Application(; additional_electron_args)
    end
    ELECTRON_APP[]
end
hasapp() = !isnothing(ELECTRON_APP[]) && ELECTRON_APP[].exists

function close_application()
    if hasapp()
        @info "Close Electron Application"
        close(ELECTRON_APP[])
    end
end

function toggle_devtools()
    if haswindow()
        Electron.toggle_devtools(get_electron_window())
    else
        error("No window to toggle devtools!")
    end
end
has_electron_window() = haswindow()


end
