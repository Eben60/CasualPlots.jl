"""
    generate_open_tab_screenshot(filename::String="open_file_tab.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates opening the CasualPlots app via Electron, navigating to the 'Open' tab,
loading `sample_data-multisheet.xlsx`, selecting sheet `TestData2`, and capturing
the screenshot using the Electron capture API.
"""
generate_open_tab_screenshot() = "open_file_tab.png"
function generate_open_tab_screenshot(session, local_app)
    # 3. Navigate to "Open" Tab
    println("Clicking 'Open' tab...")
    click_element_by_text(session, "Open")
    wait_for_ui_settle(session; delay=1.0)
    
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
        wait_for_observable(local_app.state.file_opening.opened_file_path, target_xlsx)
        
        # 5. Select 'TestData2' from sheet dropdown
        println("Selecting 'TestData2' sheet...")
        select_dropdown_value(session, "#dropdown-sheet", "TestData2")
        wait_for_observable(local_app.state.file_opening.sheet_name, "TestData2")
        wait_for_ui_settle(session; delay=1.0)
    finally
        # Restore standard pick_file implementation
        @eval CasualPlots.FileDialogWorkAround begin
            function pick_file(path=""; filterlist="")
                path = path |> os_spec_path
                BUGGY_MACOS || return NativeFileDialog.pick_file(path; filterlist) |> posixpathstring
                return pick_workaround(path, :pickfile; filterlist) |> posixpathstring
            end
        end
    end
end
