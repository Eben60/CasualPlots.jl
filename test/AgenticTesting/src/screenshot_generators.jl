# screenshot_generators.jl

"""
    generate_open_tab_screenshot(filename="open_file_tab_1.png"; timeout=60)

Automates opening the CasualPlots app via Electron, navigating to the 'Open' tab,
loading `sample_data-multisheet.xlsx`, selecting sheet `TestData2`, and capturing
the screenshot using macOS `screencapture`.
"""
function generate_open_tab_screenshot(filename::String="open_file_tab_1.png"; timeout::Real=15)
    # 1. Start App and serve via Electron without a frame
    CasualPlots.@populate
    local_app = casualplots_app()
    Core.eval(Main, :(app = $local_app))
    println("DEBUG: isdefined(Main, :app) = ", isdefined(Main, :app))
    CasualPlots.Ele.serve_app(local_app; frame=false)

    # 2. Wait for Session and UI load
    println("Waiting for Bonito session...")
    session = wait_for_session(local_app; timeout=timeout)
    
    # 3. Navigate to "Open" Tab
    println("Clicking 'Open' tab...")
    click_element_by_text(session, "Open")
    sleep(1.5)
    
    # 4. Mock file picker to return sample_data-multisheet.xlsx and click "Open File"
    target_xlsx = normpath(joinpath(pkgdir(CasualPlots), "test", "assets", "sample_data-multisheet.xlsx"))
    println("Mocking file picker for: ", target_xlsx)
    
    # Define a temporary hook for pick_file
    @eval CasualPlots.FileDialogWorkAround begin
        function pick_file(path=""; filterlist="")
            return $target_xlsx
        end
    end
    
    try
        println("Clicking 'Open File' button...")
        click_element_by_text(session, "Open File")
        sleep(2)
        
        # 5. Select 'TestData2' from sheet dropdown
        println("Selecting 'TestData2' sheet...")
        select_dropdown_value(session, "#dropdown-sheet", "TestData2")
        sleep(2)
        
        # 6. Fetch Window ID and Capture
        swift_script = normpath(joinpath(@__DIR__, "..", "scripts", "get_electron_id.swift"))
        screenshot_path = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp", filename))
        mkpath(dirname(screenshot_path))
        
        id_str = readchomp(`swift $swift_script`)
        println("Found Electron Window ID: ", id_str)
        
        println("Hiding scrollbars...")
        Bonito.evaljs(session, js"document.body.style.overflow = 'hidden';")
        sleep(0.5)

        # -o removes shadow
        run(`screencapture -o -l $id_str $screenshot_path`)
        println("Screenshot saved to: ", screenshot_path)
    catch e
        println("Error during capture: ", e)
        rethrow(e)
    finally
        # Restore standard pick_file implementation
        @eval CasualPlots.FileDialogWorkAround begin
            function pick_file(path=""; filterlist="")
                path = path |> os_spec_path
                BUGGY_MACOS || return NativeFileDialog.pick_file(path; filterlist) |> posixpathstring
                return pick_workaround(path, :pickfile; filterlist) |> posixpathstring
            end
        end
        
        # 7. Cleanup
        println("Closing App and Electron window...")
        close(local_app)
        CasualPlots.Ele.close_display(strict=true)
    end
end
