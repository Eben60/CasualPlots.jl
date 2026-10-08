# screenshot_generators.jl
"""
    get_unique_filepath(dir::AbstractString, filename::AbstractString) -> String
Checks if `joinpath(dir, filename)` exists using a numbered suffix ("_01", "_02", etc.)
right from the start, returning the first non-existent numbered path.
"""
function get_unique_filepath(dir, filename)
    base, ext = splitext(filename)
    i = 1
    while true
        new_filename = string(base, "_", lpad(i, 2, "0"), ext)
        new_path = normpath(joinpath(dir, new_filename))
        isfile(new_path) || return new_path
        i += 1
    end
end
"""
    capture_gui_screenshot(interaction_callback; filename, dir, timeout=15) -> String

Starts the CasualPlots GUI via Electron, waits for the session, calls `interaction_callback(session, local_app)`,
and then captures a screenshot. Safely handles cleanup of the Electron window.
"""
function capture_gui_screenshot(
    interaction_callback;
    filename,
    dir,
    timeout=15,
)
    # 1. Reset theme and start App
    CasualPlots.apply_theme!(nothing, CasualPlots.DEFAULT_THEME)
    for (k, v) in pairs(CasualPlots.variable_examples())
        Core.eval(Main, :($k = $v))
    end
    local_app = casualplots_app()
    Core.eval(Main, :(app = $local_app))
    # Ensure data is populated in the state observables.
    # `invokelatest` is required (Julia ≥ 1.12): globals created via `Core.eval` after the
    # caller started (e.g. `caspl_df_scores`) are invisible in the caller's world age.
    local_app.state.data_selection.dims_dict_obs[] = Base.invokelatest(CasualPlots.get_dims_of_arrays)
    local_app.state.data_selection.dataframes_dict_obs[] = Base.invokelatest(CasualPlots.collect_dataframes_from_main)
    CasualPlots.Ele.serve_app(local_app; frame=false)
    # 2. Wait for Session and UI load
    println("Waiting for Bonito session...")
    session = wait_for_session(local_app; timeout=timeout)
    
    # 3. Force timeout reset so that subsequent `trigger_update` won't be throttled
    local_app.state.misc.last_update[] = 0.0
    screenshot_path = ""
    try
        # Let the specific function do its clicks and wait
        interaction_callback(session, local_app)
        
        # 6. Capture via Electron API
        screenshot_path = get_unique_filepath(dir, filename)
        mkpath(dirname(screenshot_path))
        
        println("Hiding scrollbars...")
        Bonito.evaljs(session, js"document.body.style.overflow = 'hidden';")
        sleep(0.5)
        println("Capturing screenshot via Electron API...")
        electron_app = CasualPlots.Ele.get_electron_app()
        electron_win = CasualPlots.Ele.get_electron_window()
        
        # Escape path for JS string (cross-platform safety)
        safe_path = replace(screenshot_path, "\\" => "\\\\", "\"" => "\\\"")
        
        js_code = """
        (function() {
            const fs = require('fs');
            const win = electron.BrowserWindow.fromId($(electron_win.id));
            return win.webContents.capturePage().then(image => {
                fs.writeFileSync("$(safe_path)", image.toPNG());
                return "success";
            }).catch(err => {
                return err.toString();
            });
        })()
        """
        Base.run(electron_app, js_code)
        
        # Wait for file to be written asynchronously
        t0 = time()
        while !isfile(screenshot_path) && time() - t0 < 5.0
            sleep(0.1)
        end
        
        if isfile(screenshot_path)
            println("Screenshot saved to: ", screenshot_path)
        else
            error("Capture failed: screenshot file was not created within timeout.")
        end
    catch e
        println("Error during capture: ", e)
        rethrow(e)
    finally
        # 7. Cleanup
        println("Closing App and Electron window...")
        close(local_app)
        CasualPlots.Ele.close_display(strict=true)
    end
    
    return screenshot_path
end
"""
    with_screenshot_env(f; nofancy=true)

Context manager executing `f()` with optional unification of Unitful fancy exponents.
Restores initial `UNITFUL_FANCY_EXPONENTS` environment setting on exit.
"""
function with_screenshot_env(f; nofancy=true)
    had_fancy = haskey(ENV, "UNITFUL_FANCY_EXPONENTS")
    old_fancy = get(ENV, "UNITFUL_FANCY_EXPONENTS", nothing)
    
    result = nothing
    try
        nofancy && (ENV["UNITFUL_FANCY_EXPONENTS"] = "false")
        result = f()
    finally
        if nofancy
            had_fancy ? (ENV["UNITFUL_FANCY_EXPONENTS"] = old_fancy) : delete!(ENV, "UNITFUL_FANCY_EXPONENTS")
        end
    end
    return result
end

function run_screenshot_generator(generator_func; filename = nothing, dir = nothing)
    isnothing(filename) &&  (filename = generator_func())
    isnothing(dir) && (dir = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")))
    println("--- Generating screenshot: $filename ---")

    capture_gui_screenshot(generator_func; filename, dir)

    println("--- Generation complete ---")
    return nothing
end