const RESULTS_FILE = joinpath(@__DIR__, "..", "results.md")

# -------------------------------------------------------------------------
# Logging
# -------------------------------------------------------------------------

"""
    log_result(step_id, pass, message)

Append a `[PASS]` or `[FAIL]` line to `test/agentic/results.md`.
Returns `(pass::Bool, message::String)`.
"""
function log_result(step_id::String, pass::Bool, message::String)
    status = pass ? "[PASS]" : "[FAIL]"
    timestamp = Dates.format(now(), "HH:MM:SS")
    line = "$status $step_id — $message ($timestamp)\n"
    open(RESULTS_FILE, "a") do io
        write(io, line)
    end
    return (pass, message)
end

# -------------------------------------------------------------------------
# Session
# -------------------------------------------------------------------------

"""
    verify_session_active(step_id)

Check that a Bonito session is active by calling `get_active_session()`.
If it throws, the session is not ready.
"""
function verify_session_active(step_id::String = "setup")
    try
        session = get_active_session()   # throws if no session
        return log_result(step_id, true, "Session is active")
    catch e
        return log_result(step_id, false, "Session not active: $e")
    end
end

# -------------------------------------------------------------------------
# File Opening (Open Tab)
# -------------------------------------------------------------------------

"""
    set_opened_file_path(app, path, step_id)

Bypass the OS file dialog by programmatically setting the file path.
Also sets `opened_file_name` (so the Reload button becomes enabled) and
clears `opened_file_df` (so `verify_file_loaded` can detect new data).

After calling this, click the "Reload" button (or call `click_button`)
to trigger the actual file load callback.

**Note:** `path` is resolved via `abspath()`, so the REPL's working directory
must be the project root.
"""
function set_opened_file_path(app, path::String, step_id::String)
    try
        abs_path = abspath(path)
        # Clear previous data so verify_file_loaded detects the new load
        app.state.file_opening.opened_file_df[] = nothing
        # Set path and name (name is needed to enable the Reload button)
        app.state.file_opening.opened_file_path[] = abs_path
        app.state.file_opening.opened_file_name[] = basename(abs_path)
        return log_result(step_id, true, "File path set to $abs_path")
    catch e
        return log_result(step_id, false, "Error setting file path: $e")
    end
end

"""
    verify_file_loaded(app, step_id)

Verify that `app.state.file_opening.opened_file_df[]` is not `nothing`
after a file has been opened/reloaded.
"""
function verify_file_loaded(app, step_id::String)
    try
        df = app.state.file_opening.opened_file_df[]
        pass = !isnothing(df)
        return log_result(step_id, pass, pass ? "File DataFrame loaded ($(nrow(df)) rows)" : "File DataFrame is nothing")
    catch e
        return log_result(step_id, false, "Error checking file DataFrame: $e")
    end
end

"""
    verify_file_row_count(app, expected, step_id)

Verify the loaded file DataFrame has exactly `expected` rows.
"""
function verify_file_row_count(app, expected::Int, step_id::String)
    try
        df = app.state.file_opening.opened_file_df[]
        if isnothing(df)
            return log_result(step_id, false, "File DataFrame is nothing")
        end
        n = nrow(df)
        pass = n == expected
        return log_result(step_id, pass, "File has $n rows (expected $expected)")
    catch e
        return log_result(step_id, false, "Error checking row count: $e")
    end
end

# -------------------------------------------------------------------------
# Array Selection (Source Tab)
# -------------------------------------------------------------------------

"""
    verify_x_selected(app, name, step_id)

Verify that the X variable observable is set to `name`.
"""
function verify_x_selected(app, name::String, step_id::String)
    try
        val = app.state.data_selection.selected_x[]
        pass = val == name
        return log_result(step_id, pass, "X selection is $(repr(val)) (expected $(repr(name)))")
    catch e
        return log_result(step_id, false, "Error checking X selection: $e")
    end
end

"""
    verify_y_selected(app, name, step_id)

Verify that the Y variable observable is set to `name`.
"""
function verify_y_selected(app, name::String, step_id::String)
    try
        val = app.state.data_selection.selected_y[]
        pass = val == name
        return log_result(step_id, pass, "Y selection is $(repr(val)) (expected $(repr(name)))")
    catch e
        return log_result(step_id, false, "Error checking Y selection: $e")
    end
end

"""
    verify_y_options_filtered_dom(session, x_name, step_id)

Verify via DOM query that the Y dropdown is populated (non-empty options).
Uses `get_dropdown_options` from `gui_testing_utils.jl`.
"""
function verify_y_options_filtered_dom(session, x_name::String, step_id::String)
    try
        opts = get_dropdown_options(session; css_selector="#dropdown-y")
        # Filter out disabled placeholder options
        real_opts = filter(o -> get(o, "value", "") != "", opts)
        pass = !isempty(real_opts)
        return log_result(step_id, pass, "Y dropdown has $(length(real_opts)) options for X=$x_name")
    catch e
        return log_result(step_id, false, "Error querying Y dropdown: $e")
    end
end

"""
    verify_range_selection(app, from_val, to_val, step_id)

Verify that the range_from and range_to observables match the expected values.
"""
function verify_range_selection(app, from_val, to_val, step_id::String)
    try
        act_from = app.state.data_selection.range_from[]
        act_to = app.state.data_selection.range_to[]
        pass = act_from == from_val && act_to == to_val
        return log_result(step_id, pass, "Range is [$act_from, $act_to] (expected [$from_val, $to_val])")
    catch e
        return log_result(step_id, false, "Error checking range: $e")
    end
end

# -------------------------------------------------------------------------
# Plot Rendering
# -------------------------------------------------------------------------

"""
    verify_plot_rendered(app, step_id)

Verify that `state.plotting.handles.current_figure[]` is not `nothing`.
"""
function verify_plot_rendered(app, step_id::String)
    try
        fig = app.state.plotting.handles.current_figure[]
        pass = !isnothing(fig)
        return log_result(step_id, pass, pass ? "Plot figure is rendered" : "Plot figure is nothing")
    catch e
        return log_result(step_id, false, "Error checking plot: $e")
    end
end

# -------------------------------------------------------------------------
# Observable Values
# -------------------------------------------------------------------------

"""
    verify_observable_value(obs, expected, step_id)

Verify that `obs[]` equals `expected`. `obs` must be an `Observable`.
"""
function verify_observable_value(obs::Observable, expected, step_id::String)
    try
        val = obs[]
        pass = val == expected
        return log_result(step_id, pass, "Observable is $(repr(val)) (expected $(repr(expected)))")
    catch e
        return log_result(step_id, false, "Error checking observable: $e")
    end
end

# -------------------------------------------------------------------------
# Formatting
# -------------------------------------------------------------------------

"""
    verify_format_is_custom(app, key, step_id)

Verify that `format_is_default[key]` is `false` (i.e. user has customized it).
The dict lives in `app.state.misc.format_is_default`.
"""
function verify_format_is_custom(app, key::Symbol, step_id::String)
    try
        is_default = app.state.misc.format_is_default[key]
        pass = !is_default
        return log_result(step_id, pass, "format_is_default[:$key] = $is_default (expected false)")
    catch e
        return log_result(step_id, false, "Error checking format_is_default[:$key]: $e")
    end
end

"""
    verify_format_is_default(app, key, step_id)

Verify that `format_is_default[key]` is `true` (i.e. not yet customized / was reset).
The dict lives in `app.state.misc.format_is_default`.
"""
function verify_format_is_default(app, key::Symbol, step_id::String)
    try
        is_default = app.state.misc.format_is_default[key]
        pass = is_default
        return log_result(step_id, pass, "format_is_default[:$key] = $is_default (expected true)")
    catch e
        return log_result(step_id, false, "Error checking format_is_default[:$key]: $e")
    end
end

"""
    verify_axis_limits(app, xmin, xmax, step_id)

Verify that `app.state.plotting.format.x_min[]` and `x_max[]` match expected values.
Pass `nothing` to assert the limit is unset.
"""
function verify_axis_limits(app, xmin, xmax, step_id::String)
    try
        act_xmin = app.state.plotting.format.x_min[]
        act_xmax = app.state.plotting.format.x_max[]
        pass_min = isnothing(xmin) ? isnothing(act_xmin) : act_xmin == xmin
        pass_max = isnothing(xmax) ? isnothing(act_xmax) : act_xmax == xmax
        pass = pass_min && pass_max
        return log_result(step_id, pass, "X limits: [$act_xmin, $act_xmax] (expected [$xmin, $xmax])")
    catch e
        return log_result(step_id, false, "Error checking axis limits: $e")
    end
end

# -------------------------------------------------------------------------
# Modal
# -------------------------------------------------------------------------

"""
    verify_modal_visible(app, step_id)

Verify that a modal dialog is currently shown (`state.dialogs.show_modal[] == true`).
"""
function verify_modal_visible(app, step_id::String)
    try
        vis = app.state.dialogs.show_modal[]
        return log_result(step_id, vis, vis ? "Modal is visible" : "Modal is NOT visible")
    catch e
        return log_result(step_id, false, "Error checking modal: $e")
    end
end

# -------------------------------------------------------------------------
# Saving
# -------------------------------------------------------------------------

"""
    verify_file_on_disk(path, step_id)

Verify that a file exists at `path` on the local filesystem.
"""
function verify_file_on_disk(path::String, step_id::String)
    pass = isfile(path)
    return log_result(step_id, pass, pass ? "File exists: $path" : "File NOT found: $path")
end

"""
    verify_script_runs_cleanly(path, step_id)

Evaluate the generated Julia script in a fresh anonymous `Module` to check
it runs without errors.

**Caveats:**
- This runs in the current Julia process. If the script calls
  `casualplots_app()` or `Ele.serve_app()`, it will start a second GUI.
  Inspect the generated script before running this function.
- The sandbox module has no pre-loaded packages; any `using` statements in
  the script will load packages from the current environment, which may
  produce `WARNING: replacing module` messages. These are harmless.
"""
function verify_script_runs_cleanly(path::String, step_id::String)
    try
        if !isfile(path)
            return log_result(step_id, false, "Script not found: $path")
        end
        m = Module(:_CasualPlotsScriptSandbox)
        Base.include(m, abspath(path))
        return log_result(step_id, true, "Script evaluated cleanly")
    catch e
        return log_result(step_id, false, "Script evaluation failed: $e")
    end
end

