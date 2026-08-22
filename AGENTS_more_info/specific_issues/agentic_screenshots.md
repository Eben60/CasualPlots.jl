# Agentic Creation of Reproducible Screenshots

This document summarizes the established workflow for taking reproducible, automated screenshots of the `CasualPlots.jl` GUI via AI agents (or automated scripts) on macOS.

## The Challenge
`CasualPlots.jl` uses Bonito and WGLMakie, which rely heavily on WebSockets and JavaScript to render the DOM *after* the initial page load. 
Because of this, standard headless browser capture commands (like `Google Chrome --headless --screenshot`) often fail or capture a blank 32KB white screen, because they execute the screenshot before the WebSockets have fully established and rendered the UI. 

## The Solution: Electron + macOS `screencapture`
The most robust native approach involves launching the app via `Electron.jl` (with the `frame=false` option to disable the macOS title bar), driving the UI programmatically using DOM interactions, and then using the macOS `screencapture` utility targeted at the Electron window's specific Window ID. 

Using `screencapture -o -l <windowID>` captures the window cleanly without the OS drop shadow or window chrome, yielding a perfect crop of the internal Bonito UI.

### Prerequisites
- **Screen Recording Permissions**: The terminal running the automation (or the Antigravity agent) *must* be granted "Screen Recording" privileges in macOS System Settings > Privacy & Security.

---

## Complete Instructions for Agents to Reproduce a Snapshot

If you (the Agent) are asked to update or reproduce a screenshot (for example, `docs/src/Screenshots/open_file_tab.png`), follow this exact protocol:

1. **Locate the Generator**:
   The logic for driving the GUI state is housed in `test/AgenticTesting/src/screenshot_generators.jl` inside the `AgenticTesting` module.
   
2. **Review/Update the GUI State**:
   Open `screenshot_generators.jl` and ensure the function sets the GUI to the desired state. To simulate user interaction seamlessly, you can:
   - Use `click_element_by_text(session, "Text")` to click buttons/tabs.
   - Use `select_dropdown_value(session, css_selector, value)` to trigger dropdown changes.
   - Temporarily `@eval` and override functions like `CasualPlots.FileDialogWorkAround.pick_file` if you need to bypass native OS dialogs (e.g., to force load a specific test file).
   - Use `sleep()` strategically to wait for DOM updates and WebSocket communication.

3. **Run the Standalone Script**:
   Do **not** try to run the code line-by-line via the REPL. Instead, execute the prepared standalone runner script using the Kaimon subprocess workaround via the `ex` tool (to comply with development workflow rules regarding OS shell commands). This script activates the correct environment, loads necessary weak dependencies (like `CSV` and `XLSX`), and triggers the generator:
   
   **Run Command (via Kaimon `ex`):**
   ```julia
   run(pipeline(ignorestatus(`julia --project=test/AgenticTesting test/AgenticTesting/scripts/run_open_tab_screenshot.jl`), stdout="test_output.log", stderr="test_output.log"))
   ```
   *(Note: The `ex` tool may promote this to a background job; use `check_eval` and `agent_output` or view `test_output.log` to track progress and verify success.)*

4. **Review and Iterate**:
   The screenshot will be saved to `docs/src/Screenshots/tmp/open_file_tab_1.png` (or whichever path the script specifies). Review the generated image dimensions and UI state. If changes are needed, adapt the logic in `screenshot_generators.jl` and re-run.

## Recent Improvements & Troubleshooting
- **Scrollbar Removal**: To ensure the screenshot perfectly matches the 1200x960 viewport without Chromium's scrollbars, we programmatically hide them immediately before the macOS `screencapture` command:
  ```julia
  Bonito.evaljs(session, js"document.body.style.overflow = 'hidden';")
  ```
- **Session Initialization Bugs**: If the standalone script times out waiting for the Bonito session, it is likely because `Core.eval(Main, :(app = $local_app))` failed to correctly populate `Main.app` in a way that `get_active_session` could resolve. The robust fix is to pass the `app_obj` directly: `wait_for_session(local_app; timeout=15)`.

### Reference Files
- **Generator Logic**: [`test/AgenticTesting/src/screenshot_generators.jl`](../../test/AgenticTesting/src/screenshot_generators.jl)
- **Standalone Runner Script**: [`test/AgenticTesting/scripts/run_open_tab_screenshot.jl`](../../test/AgenticTesting/scripts/run_open_tab_screenshot.jl)
- **Swift Window ID Fetcher**: [`test/AgenticTesting/scripts/get_electron_id.swift`](../../test/AgenticTesting/scripts/get_electron_id.swift)
