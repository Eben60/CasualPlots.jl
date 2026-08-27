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
    capture_gui_screenshot(interaction_callback::Function; filename::AbstractString, dir::AbstractString=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Starts the CasualPlots GUI via Electron, waits for the session, calls `interaction_callback(session)`,
and then captures a screenshot. Safely handles cleanup of the Electron window.
"""
function capture_gui_screenshot(
    interaction_callback::Function;
    filename::AbstractString,
    dir::AbstractString=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout::Real=15,
)
    # 1. Reset theme and start App
    CasualPlots.apply_theme!(nothing, CasualPlots.DEFAULT_THEME)
    for (k, v) in pairs(CasualPlots.variable_examples())
        Core.eval(Main, :($k = $v))
    end
    local_app = casualplots_app()
    Core.eval(Main, :(app = $local_app))
    # Ensure data is populated in the state observables
    local_app.state.data_selection.dims_dict_obs[] = CasualPlots.get_dims_of_arrays()
    local_app.state.data_selection.dataframes_dict_obs[] = CasualPlots.collect_dataframes_from_main()
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
        
        # 6. Fetch Window ID and Capture
        swift_script = normpath(joinpath(@__DIR__, "get_electron_id.swift"))
        screenshot_path = get_unique_filepath(dir, filename)
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
        # 7. Cleanup
        println("Closing App and Electron window...")
        close(local_app)
        CasualPlots.Ele.close_display(strict=true)
    end
    
    return screenshot_path
end

"""
    generate_open_tab_screenshot(filename::String="open_file_tab.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates opening the CasualPlots app via Electron, navigating to the 'Open' tab,
loading `sample_data-multisheet.xlsx`, selecting sheet `TestData2`, and capturing
the screenshot using macOS `screencapture`.
"""
function generate_open_tab_screenshot(
    filename="open_file_tab.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, app
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
            wait_for_observable(app.state.file_opening.opened_file_path, target_xlsx)
            
            # 5. Select 'TestData2' from sheet dropdown
            println("Selecting 'TestData2' sheet...")
            select_dropdown_value(session, "#dropdown-sheet", "TestData2")
            wait_for_observable(app.state.file_opening.sheet_name, "TestData2")
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
end

"""
    generate_dataframe_source_screenshot(filename::String="dataframe_source_selection.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates opening the CasualPlots app via Electron, navigating to the 'Source' tab,
selecting the 'DataFrame' mode, choosing 'caspl_df_exp', selecting columns x, y1, y4, y7, y9, y12, y15, y18,
setting the range from 20 to 90, and capturing the screenshot.
"""
function generate_dataframe_source_screenshot(
    filename="dataframe_source_selection.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
        # Navigate to "Source" Tab
        println("Clicking 'Source' tab...")
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select DataFrame mode
        println("Selecting 'DataFrame' source type...")
        set_radio_value(session, "source_type", "DataFrame")
        wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
        
        # Diagnostic print of dropdown HTML
        html = Bonito.evaljs_value(session, js"document.querySelector('#dropdown-dataframe') ? document.querySelector('#dropdown-dataframe').innerHTML : 'not found'")
        println("DEBUG dropdown HTML: ", html)
        
        # Select caspl_df_exp
        println("Selecting 'caspl_df_exp' from dropdown...")
        select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
        wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")

        
        # Click Deselect All
        println("Clicking 'Deselect All'...")
        click_element_by_text(session, "Deselect All")
        wait_until(() -> isempty(local_app.state.data_selection.selected_columns[]))

        # Check columns
        cols_to_check = ["x", "y1", "y4", "y7", "y9", "y12", "y15", "y18"]
        println("Checking columns: ", join(cols_to_check, ", "))
        for col in cols_to_check
            # The value of the checkbox is the column name
            Bonito.evaljs(session, js"""
                (function() {
                    const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
                    if (cb && !cb.checked) {
                        cb.checked = true;
                        cb.dispatchEvent(new Event('change', {bubbles: true}));
                    }
                })()
            """)
        end
        wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], cols_to_check))

        # Set range
        println("Setting range 20 to 90...")
        Bonito.evaljs(session, js"""
            (function() {
                const fromInput = document.getElementById('range-from-input');
                if (fromInput) {
                    fromInput.value = '20';
                    fromInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
                const toInput = document.getElementById('range-to-input');
                if (toInput) {
                    toInput.value = '90';
                    toInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
        wait_until(() -> local_app.state.data_selection.range_from[] == 20 && local_app.state.data_selection.range_to[] == 90)

        # Click (Re-)Plot
        println("Clicking '(Re-)Plot' button...")
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)
    end
end

"""
    generate_xy_source_screenshot(filename::String="xy_source_selection.png"; dir::String=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")), timeout::Real=15) -> String

Automates opening the CasualPlots app, selecting X, Y Arrays mode, selecting `caspl_x_10` and `caspl_ys10`,
setting range from 1 to 10, and plotting.
"""
function generate_xy_source_screenshot(
    filename="xy_source_selection.png";
    dir=normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots", "tmp")),
    timeout=15,
)
    return capture_gui_screenshot(; filename=filename, dir=dir, timeout=timeout) do session, local_app
        # Navigate to "Source" Tab
        println("Clicking 'Source' tab...")
        click_element_by_text(session, "Source")
        wait_for_ui_settle(session; delay=1.0)

        # Select X, Y Arrays mode
        println("Selecting 'X, Y Arrays' source type...")
        set_radio_value(session, "source_type", "X, Y Arrays")
        wait_for_observable(local_app.state.data_selection.source_type, "X, Y Arrays")
        
        # Select caspl_x_10
        println("Selecting 'caspl_x_10' for X...")
        select_dropdown_value(session, "#dropdown-x", "caspl_x_10")
        wait_for_observable(local_app.state.data_selection.selected_x, "caspl_x_10")

        # Select caspl_ys10
        println("Selecting 'caspl_ys10' for Y...")
        select_dropdown_value(session, "#dropdown-y", "caspl_ys10")
        wait_for_observable(local_app.state.data_selection.selected_y, "caspl_ys10")

        # Set range
        println("Setting range 1 to 10...")
        Bonito.evaljs(session, js"""
            (function() {
                const fromInput = document.getElementById('range-from-input');
                if (fromInput) {
                    fromInput.value = '1';
                    fromInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
                const toInput = document.getElementById('range-to-input');
                if (toInput) {
                    toInput.value = '10';
                    toInput.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
        wait_until(() -> local_app.state.data_selection.range_from[] == 1 && local_app.state.data_selection.range_to[] == 10)

        # Click (Re-)Plot
        println("Clicking '(Re-)Plot' button...")
        current_plot = local_app.state.plotting.handles.current_figure[]
        click_button(session, "#btn-replot")
        wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)
        wait_for_ui_settle(session; delay=1.0)
    end
end

