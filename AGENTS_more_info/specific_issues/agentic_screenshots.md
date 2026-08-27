# Agentic Creation of Reproducible Screenshots

This document is the authoritative reference for AI agents tasked with generating, updating, or verifying automated screenshots of the `CasualPlots.jl` GUI on macOS.

---

## 1. Background & Challenge

`CasualPlots.jl` uses Bonito.jl and WGLMakie to render its GUI through WebSockets into an Electron window. Standard headless browser screenshot tools (e.g., `Chrome --headless --screenshot`) fail because they capture before the WebSockets establish and WGLMakie renders the plot canvas.

---

## 2. Architecture Overview

### Capture Method: Electron + macOS `screencapture`

The app launches via `Electron.jl` (with `frame=false` to strip the macOS title bar). A Swift script (`get_electron_id.swift`) discovers the Electron window's macOS Window ID, and the native `screencapture -o -l <windowID>` command captures the window content cleanly, without OS shadow or chrome.

### Prerequisites

- **macOS Screen Recording permission** must be granted to the terminal / IDE running the automation (System Settings → Privacy & Security → Screen Recording).

### File Organisation

```
test/AgenticTesting/
├── src/
│   ├── AgenticTesting.jl                    # Module definition & exports
│   ├── gui_testing_utils.jl                 # DOM interaction helpers & wait functions
│   ├── casualplots_agent_test_utils.jl      # CasualPlots-specific test utilities
│   ├── screenshot_generators.jl             # Core capture_gui_screenshot + basic generators
│   ├── screenshot_generators_advanced.jl    # Generators needing format-tab & label changes
│   ├── screenshot_generators_remaining.jl   # Generators for remaining screenshots
│   └── get_electron_id.swift                # Swift script to find Electron Window ID
├── scripts/
│   ├── run_all_screenshots.jl               # Runs all generators sequentially
│   ├── run_open_tab_screenshot.jl           # Individual runner scripts (one per screenshot)
│   ├── run_dataframe_source_screenshot.jl
│   ├── run_xy_source_screenshot.jl
│   ├── run_format_tab_barplot_dodged.jl
│   ├── run_format_tab_barplot_stacked.jl
│   ├── run_format_tab_limits.jl
│   ├── run_format_tab_lines.jl
│   ├── run_plot_pane_maximized.jl
│   ├── run_save_tab_script.jl
│   └── run_table_view.jl
docs/src/Screenshots/
├── <name>.png                               # Current reference screenshots (the "golden" files)
├── tmp/                                     # Output directory for generated screenshots
│   └── <name>.png, <name>_01.png, ...       # Auto-numbered to avoid overwrites
└── specifications/<name>/<name>.md              # Detailed spec per screenshot (see §4)
```

---

## 3. The Capture Pipeline (`capture_gui_screenshot`)

All screenshot generators delegate to [`capture_gui_screenshot`](../../test/AgenticTesting/src/screenshot_generators.jl) (in `screenshot_generators.jl`), which orchestrates the full lifecycle:

1. **Reset theme** to `DEFAULT_THEME` and populate demo data in `Main` via `CasualPlots.@populate()` / `variable_examples()`.
2. **Create app** via `casualplots_app()`, populate state observables for arrays and DataFrames.
3. **Launch Electron** with `CasualPlots.Ele.serve_app(local_app; frame=false)`.
4. **Wait for Bonito session** via `wait_for_session(local_app; timeout=...)`.
5. **Reset throttle** (`state.misc.last_update[] = 0.0`).
6. **Execute the interaction callback** — this is where the specific generator function drives the GUI to the desired state.
7. **Hide scrollbars** via `Bonito.evaljs(session, js"document.body.style.overflow = 'hidden';")`.
8. **Capture** via `screencapture -o -l <windowID> <path>`.
9. **Cleanup**: `close(local_app)` and `CasualPlots.Ele.close_display(strict=true)`.

Output files are auto-numbered (e.g., `format_tab_barplot_dodged.png`, `_01.png`, `_02.png`, …) to avoid overwriting earlier attempts.

---

## 4. Using Per-Screenshot Specification Files

Each screenshot has a detailed Markdown specification in `docs/src/Screenshots/specifications/<name>/<name>.md`. These specs are the single source of truth for both writing generator code and verifying output.

Before running or modifying a generator, **always read the corresponding spec first** using `view_file`. It contains:
- The exact prerequisites and data sources required.
- The step-by-step UI reproduction sequence.
- The expected UI state (dropdown values, labels, plot content, table data).
- The key visual verification criteria to check after generation.

Specifications exist for all current screenshots. If you are asked to add a **new** screenshot and no spec exists yet, see [Creating Screenshot Specification Files](agentic_screenshot_specs.md) for the creation workflow and template.

---

## 5. Interaction Toolkit

All DOM interaction helpers are in [`gui_testing_utils.jl`](../../test/AgenticTesting/src/gui_testing_utils.jl). The key functions are:

### Navigation & Clicks
| Function | Purpose |
| :--- | :--- |
| `click_element_by_text(session, "Text")` | Click tabs, buttons, or labels by visible text |
| `click_button(session, "#css-selector")` | Click a button by CSS selector |
| `select_dropdown_value(session, "#dropdown-id", "value")` | Set a `<select>` dropdown and fire `change` |
| `set_radio_value(session, "name", "value")` | Select a radio button |
| `toggle_checkbox(session, "#checkbox-id")` | Toggle a checkbox |

### Text Input (`set_input_value`)
Defined in [`screenshot_generators_advanced.jl`](../../test/AgenticTesting/src/screenshot_generators_advanced.jl). Dispatches `input`, `change`, and `blur` events on a text field:
```julia
set_input_value(session, "#input-xlabel", "My X Label")
```

### Checkbox Columns
Column checkboxes use a specific CSS class. To check a column:
```julia
Bonito.evaljs(session, js"""
    (function() {
        const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
        if (cb && !cb.checked) {
            cb.checked = true;
            cb.dispatchEvent(new Event('change', {bubbles: true}));
        }
    })()
""")
```

### Maximizing Floating Windows
The Plot and Table panes are `BonitoWidgets.FloatingWindow`s wrapped in `<div>` elements with classes `cp-plot-fw` and `cp-table-fw`. To click the Maximize button:
```julia
Bonito.evaljs(session, js"""
    (function() {
        const maxBtn = document.querySelector('.cp-plot-fw .bw-icon-btn[title="Maximize"]');
        if (maxBtn) { maxBtn.click(); }
    })()
""")
```
> **⚠ Important**: The wrapper classes are `cp-plot-fw` and `cp-table-fw` (not `cp-plot-window` / `cp-table-window`). Using wrong selectors causes silent failures where the button is never found.

### File Dialog Mocking
For the `open_file_tab` screenshot, the native file picker must be temporarily overridden:
```julia
@eval CasualPlots.FileDialogWorkAround begin
    function pick_file(path=""; filterlist="")
        return $target_xlsx
    end
end
```
Always restore the original implementation in a `finally` block.

---

## 6. Synchronisation: Wait Functions & the `do_replot` Cycle

GUI state is inherently asynchronous. **Never use bare `sleep()` for synchronisation.** Use the reactive wait functions instead.

### Wait Functions (in `gui_testing_utils.jl`)

| Function | Purpose |
| :--- | :--- |
| `wait_for_observable(obs, target_value; timeout=10.0)` | Block until an Observable reaches a specific value |
| `wait_until(condition; timeout=10.0, interval=0.1)` | Poll a predicate until true or timeout |
| `wait_for_ui_settle(session; delay=1.0)` | WebSocket roundtrip flush + sleep for visual rendering |

### The `do_replot` / `block_format_update` Cycle

This is the most important concurrency pattern to understand. When a plot-triggering action occurs (changing data source, plot type, theme, etc.), the `do_replot` function in `setup_callbacks.jl`:

1. Sets `state.misc.block_format_update[] = true`.
2. Rebuilds the entire plot (resets axis labels to defaults from the data source).
3. Sets `state.misc.block_format_update[] = false`.

**Consequence**: Any attempt to set custom axis labels (via `set_input_value` or direct observable assignment) while `block_format_update` is `true` will be silently ignored, because the label update callbacks check this flag and skip when it's set.

**Solution**: After triggering any action that causes `do_replot` (e.g., changing plot type, theme, group_by), wait for the full cycle to complete before setting labels:
```julia
# Trigger the replot (e.g., changing group_by)
select_dropdown_value(session, "#dropdown-group_by", "Color")
wait_for_ui_settle(session; delay=0.5)  # let the websocket message trigger do_replot
wait_for_observable(local_app.state.misc.block_format_update, false; timeout=15.0)

# NOW it is safe to set custom labels
local_app.state.plotting.handles.xlabel_text[] = "Name"
local_app.state.plotting.handles.ylabel_text[] = "Score"
local_app.state.plotting.handles.title_text[] = "Students scores"
```

### Direct Observable Assignment vs. DOM Events

For label text fields, **direct Observable assignment** is more reliable than `set_input_value` when the `do_replot` cycle is involved, because it bypasses the DOM event pipeline entirely:
```julia
# Preferred for labels after a replot cycle:
local_app.state.plotting.handles.xlabel_text[] = "My Label"

# Also works, but sensitive to timing:
set_input_value(session, "#input-xlabel", "My Label")
```

### Standard Synchronisation Pattern for Plot Changes

```julia
# 1. Remember current figure reference
current_plot = local_app.state.plotting.handles.current_figure[]

# 2. Trigger action
click_button(session, "#btn-replot")

# 3. Wait for new figure
wait_until(() -> local_app.state.plotting.handles.current_figure[] !== current_plot)

# 4. Settle
wait_for_ui_settle(session; delay=1.0)
```

---

## 7. Running Screenshots

### Execution Method

Each screenshot has a standalone runner script in `test/AgenticTesting/scripts/`. Execute it via **Kaimon `ex`**:

```julia
include("test/AgenticTesting/scripts/run_format_tab_barplot_dodged.jl")
```

The Kaimon `ex` tool may promote long-running inclusions to background jobs. Use `list_jobs`, `check_eval`, and `agent_output` to monitor progress.

**Do NOT run the code line-by-line in the REPL.** Each runner script handles environment setup (`using ShareAdd; @usingany CasualPlots, AgenticTesting; CasualPlots.@populate()`), generator invocation, and cleanup as a single unit.

### Running All Screenshots

```julia
include("test/AgenticTesting/scripts/run_all_screenshots.jl")
```

---

## 8. Mandatory Verification Protocol

After each screenshot generation, the agent **must** perform a detailed two-stage visual verification using the `view_file` tool:

### Stage 1: Specification Comparison

> [!CAUTION]
> **No shortcuts, no inferred values.** Every value in the report must be independently read and transcribed in full—first from the spec file, then from the screenshot. Do not summarize, abbreviate, or use phrases like "7 entries" or "same as spec". The comparison (Match column) must only be determined **after** both the Spec Value and Screenshot Value columns have been fully populated with explicit literal values.

**Procedure:**

1. **Read the spec.** Use `view_file` on `docs/src/Screenshots/specifications/<name>/<name>.md`. DO NOT edit this file!
2. **View the generated image.** Use `view_file` on the **latest numbered** generated image in `docs/src/Screenshots/tmp/` (e.g., `_04.png` not `_01.png`). You **must** call `view_file` at this exact point in the workflow—do not rely on images viewed in earlier turns.
3. **Build the report table.** For **each and every** element listed in the spec's "§4. UI State & Values" and "§5. Key Visual Verification Criteria" sections:
   - **Spec Value column**: Transcribe the literal value from the spec (e.g., the exact checkbox names, exact label strings, exact legend entries with their colors).
   - **Screenshot Value column**: Independently describe what you actually see in the generated image, using the same level of detail and the same format. List every individual item explicitly (e.g., every legend entry, every column header, every checkbox state).
   - **Match column**: Set to `true` or `false` only **after** both value columns are filled. Compare them value-by-value.
4. **Write the report.** Create (or **overwrite** if it already exists) a file named `report_<name>.md` next to the spec file. The report must be **rewritten from scratch** on every iteration—never append to or patch a previous report. Use the 4-column table format (see [report_dataframe_source_selection.md](report_dataframe_source_selection.md) as the template):

   ```
   | Item | Spec Value | Screenshot Value | Match |
   ```

5. **Conclude.** At the bottom, write `Stage 1 Conclusion: **PASS**` or `**FAIL**` with a brief explanation of any mismatches.

### Stage 2: Reference Comparison
Execute Stage 2 only if Stage 1 passed. Otherwise skip directly to Failure Protocol.
1. Use `view_file` on the original reference screenshot at `docs/src/Screenshots/<name>.png`.
2. Compare the generated image against it. Minor differences due to GUI evolution (e.g., updated number formatting, renamed radio button text, changed positions of controls),  are acceptable. Layout, data content, and overall appearance must match. In case of substantial deviations due GUI evolution, ask user what to do.

### Failure Protocol
- If the image fails either stage, diagnose the root cause (wrong CSS selector, timing issue, missing wait, wrong observable).
- Fix the generator code in `test/AgenticTesting/src/`.
- Re-run and re-verify.
- After **3 consecutive failed attempts** at the same screenshot, stop and report to the user.

---

## 9. Writing a New Screenshot Generator

When asked to create a generator for a new screenshot that doesn't have one yet:

1. **Ask the user** how the screenshot was originally produced (which tab, which data source, which format options, etc.), or consult the existing reference image via `view_file`.
2. **Create the `.md` specification** in `docs/src/Screenshots/specifications/<name>/<name>.md` following the established format (Overview, Prerequisites, Step-by-Step, UI State, Verification Criteria).
3. **Write the generator function** in the appropriate file:
   - `screenshot_generators.jl` — for basic screenshots (source tab, simple plots)
   - `screenshot_generators_advanced.jl` — for screenshots needing format changes, label overrides, or complex replot synchronisation
   - `screenshot_generators_remaining.jl` — overflow file for additional generators
4. **Export** the new function from `AgenticTesting.jl`.
5. **Create the runner script** in `test/AgenticTesting/scripts/run_<name>.jl`:
   ```julia
   using ShareAdd
   @usingany CasualPlots, AgenticTesting
   CasualPlots.@populate()

   println("Starting screenshot generation for <name>.png...")
   screenshot_path = generate_<name>_screenshot("<name>.png")
   println("Done. Screenshot saved at: ", screenshot_path)
   ```
6. **Add** the new runner to `run_all_screenshots.jl`.
7. **Run, verify** (§8), and iterate until the output matches.

---

## 10. Known CSS Selectors Reference

| UI Element | CSS Selector |
| :--- | :--- |
| Plot type dropdown | `#dropdown-plottype` |
| Theme dropdown | `#dropdown-theme` |
| DataFrame dropdown | `#dropdown-dataframe` |
| X dropdown | `#dropdown-x` |
| Y dropdown | `#dropdown-y` |
| Bar direction dropdown | `#dropdown-bar_direction` |
| Bar mode dropdown | `#dropdown-bar_mode` |
| Group-by dropdown | `#dropdown-group_by` |
| (Re-)Plot button | `#btn-replot` |
| Show legend checkbox | `input[type="checkbox"][id="checkbox-show_legend"]` |
| X-axis label input | `#input-xlabel` |
| Y-axis label input | `#input-ylabel` |
| Title input | `#input-title` |
| Legend title input | `#input-legend-title` |
| X min input | `#axis-x-min-input` |
| X max input | `#axis-x-max-input` |
| X reversed checkbox | `input[type="checkbox"][id="axis-x-reversed-checkbox"]` |
| Save path input | `#save-path-input` |
| Modal OK button | `#btn-modal-ok` |
| Range from input | `#range-from-input` |
| Range to input | `#range-to-input` |
| Column checkbox | `input.column-checkbox[value="<column_name>"]` |
| Source type radio | `input[type=radio][name="source_type"][value="..."]` |
| Plot pane wrapper | `.cp-plot-fw` |
| Table pane wrapper | `.cp-table-fw` |
| Maximize button (within a pane) | `.<pane-class> .bw-icon-btn[title="Maximize"]` |

---

## 11. Existing Screenshot Inventory

| Screenshot | Generator Function | Source File | Runner Script |
| :--- | :--- | :--- | :--- |
| `open_file_tab.png` | `generate_open_tab_screenshot` | `screenshot_generators.jl` | `run_open_tab_screenshot.jl` |
| `dataframe_source_selection.png` | `generate_dataframe_source_screenshot` | `screenshot_generators.jl` | `run_dataframe_source_screenshot.jl` |
| `xy_source_selection.png` | `generate_xy_source_screenshot` | `screenshot_generators.jl` | `run_xy_source_screenshot.jl` |
| `format_tab_barplot_dodged.png` | `generate_format_tab_barplot_dodged_screenshot` | `screenshot_generators_advanced.jl` | `run_format_tab_barplot_dodged.jl` |
| `format_tab_barplot_stacked.png` | `generate_format_tab_barplot_stacked_screenshot` | `screenshot_generators_remaining.jl` | `run_format_tab_barplot_stacked.jl` |
| `format_tab_limits.png` | `generate_format_tab_limits_screenshot` | `screenshot_generators_remaining.jl` | `run_format_tab_limits.jl` |
| `format_tab_lines.png` | `generate_format_tab_lines_screenshot` | `screenshot_generators_remaining.jl` | `run_format_tab_lines.jl` |
| `plot_pane_maximized.png` | `generate_plot_pane_maximized_screenshot` | `screenshot_generators_remaining.jl` | `run_plot_pane_maximized.jl` |
| `save_tab_script.png` | `generate_save_tab_script_screenshot` | `screenshot_generators_remaining.jl` | `run_save_tab_script.jl` |
| `table_view.png` | `generate_table_view_screenshot` | `screenshot_generators_remaining.jl` | `run_table_view.jl` |

All generators listed above have been verified as producing correct output as of the current codebase. If the GUI changes, simply re-run the corresponding runner script to regenerate.

---

## 12. Troubleshooting

| Symptom | Likely Cause | Fix |
| :--- | :--- | :--- |
| Blank / white screenshot (≈32KB) | Session not yet established when capture runs | Increase `timeout` in `wait_for_session`; check Electron launched |
| Scrollbars visible in screenshot | `overflow: hidden` not applied | Ensure `Bonito.evaljs(session, js"document.body.style.overflow = 'hidden';")` runs before capture |
| Maximise button click has no effect | Wrong CSS selector for floating window wrapper | Use `.cp-plot-fw` / `.cp-table-fw` (not `.cp-plot-window` / `.cp-table-window`) |
| Custom labels reset to defaults | Labels set during active `do_replot` cycle | Wait for `block_format_update` to return to `false` before setting labels (see §6) |
| `set_input_value` has no effect | Race condition with WebSocket round-trip | Use direct observable assignment (`state.plotting.handles.xlabel_text[] = "..."`) instead |
| Screenshot shows modal dialog | A warning modal appeared (e.g., mixed Unitful types) | Wait for modal, dismiss with `click_button(session, "#btn-modal-ok")`, then continue |
| Session timeout error | `Main.app` not correctly populated | Pass `local_app` directly to `wait_for_session(local_app; timeout=15)` |
