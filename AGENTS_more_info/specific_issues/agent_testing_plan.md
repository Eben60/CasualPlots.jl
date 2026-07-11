# Exhaustive Agent-Based GUI Testing Plan for CasualPlots.jl

## 1. Strict Rules of Execution

- **STOP AND REPORT ON FAILURE:** Any problem including failed verification step, subagent error, any unexpected result, or REPL exception MUST cause an immediate halt and report to the user.
- **NO SOURCE CHANGES:** Forbidden without explicit user permission.
- **Pure Keystroke Navigation:** ALL GUI interactions MUST be performed by the `[Subagent]` using keystrokes (e.g., `Tab`, `ArrowDown`, `Space`, `Enter`). 
- **NO SUMMARIZING OR GUESSWORK:** The `[Main Agent]` MUST NOT guess CSS selectors or keystroke counts. It MUST follow the exact sequence of `Kaimon/ex` tool calls specified below to calculate distances, and pass the exact resulting numbers to the `browser_subagent` tool.
- **Kaimon Tools:** The `[Main Agent]` MUST use the `Kaimon` MCP server's `ex` tool (via `call_mcp_tool` with `ServerName="Kaimon"`, `ToolName="ex"`) to execute all Julia commands. Do not use generic terminal commands for Julia execution.
- **Browser Subagent:** The `[Main Agent]` MUST use the `browser_subagent` tool to spawn a subagent. The `Task` parameter must include the exact keystrokes derived from the `Kaimon/ex` outputs.
- **Screenshot Location:** All screenshots must be saved to a timestamped subdirectory within `tmp/test_screenshots/`.
- **`q=false` for calculations:** All `Kaimon/ex` calls that compute values (i.e., `calculate_tab_distance`, `calculate_dropdown_keystrokes`, and any `verify_*` call) MUST use `q=false` so the result is visible in the agent context. Set `q=true` (or omit) only for fire-and-forget side effects like `sleep(...)`.
- **Text field clearing:** When instructed to "clear the text" in a text field, the `[Subagent]` MUST press `Ctrl+A` then `Delete` (or `Backspace`) to reliably clear all content before typing.

---

## 2. Exhaustive Step-by-Step Execution Flow

### Pre-requisites & Setup
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "using ShareAdd; @usingany CSV, XLSX, AgenticTesting\ninclude(\"src/scripts/casualplots_test_setup.jl\")\napp = casualplots_app()\nserver = Bonito.Server(app, \"127.0.0.1\", 9385)"}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "session = wait_for_session()"}`
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "using Dates\nts = Dates.format(now(), \"yyyy-mm-dd_HH-MM-SS\")\nscreenshot_dir = joinpath(\"tmp\", \"test_screenshots\", ts)\nmkpath(screenshot_dir)\nscreenshot(name) = joinpath(screenshot_dir, name * \".png\")"}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "verify_session_active(\"setup\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Navigate to `http://localhost:9385/`. Take a screenshot and save it as `00_app_loaded.png`."

---

### Phase 1: Arrays Source Mode (X, Y)

**Step 1.1 — Basic Plotting**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-x\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-x\", \"caspl_x_10\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#dropdown-x`. Then press `ArrowDown` or `ArrowUp` `[|result of step 2|]` times (down if positive, up if negative) to select `caspl_x_10`. Press `Enter` to confirm."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_y_options_filtered_dom(session, \"caspl_x_10\", \"1.1-y-opts\")", "q": false}`
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-y\")", "q": false}`
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-y\", \"caspl_x_to_3by2\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 5]` times to focus `#dropdown-y`. Then press `ArrowDown` or `ArrowUp` `[|result of step 6|]` times to select `caspl_x_to_3by2`. Press `Enter`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "verify_x_selected(app, \"caspl_x_10\", \"1.1-x\"); verify_y_selected(app, \"caspl_x_to_3by2\", \"1.1-y\")", "q": false}`
9. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
10. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 9]` times to focus `#btn-replot`. Press `Space`. Take a screenshot named `01_arrays_basic.png`."
11. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"1.1\")", "q": false}`

**Step 1.2 — Matrix as Y Variable**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-y\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-y\", \"caspl_ys10\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#dropdown-y`. Press `ArrowDown/Up` `[|result of step 2|]` times to select `caspl_ys10`. Press `Enter`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times. Press `Space`. Take a screenshot named `02_matrix_y.png`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"1.2\")", "q": false}`

**Step 1.3 — Range Selection**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#range-from-input\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#range-from-input`. Press `Ctrl+A`, then `Delete` to clear. Type `2`. Press `Tab` to move to `#range-to-input`. Press `Ctrl+A`, then `Delete` to clear. Type `8`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times. Press `Space`. Take a screenshot named `03_range_selection.png`."
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"1.3\"); verify_range_selection(app, 2, 8, \"1.3-range\")", "q": false}`

**Step 1.4 — Unitful Arrays**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#range-from-input\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#range-from-input`. Press `Ctrl+A`, then `Delete` to clear. Press `Tab` to move to `#range-to-input`. Press `Ctrl+A`, then `Delete` to clear."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-y\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-y\", \"caspl_u_10\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times to focus `#dropdown-y`. Press `ArrowDown/Up` `[|result of step 4|]` times to select `caspl_u_10`. Press `Enter`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times. Press `Space`. Take a screenshot named `04_unitful_arrays.png`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"1.4\")", "q": false}`

**Step 1.5 — REPL Export Check**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "@assert cp_figure isa Makie.Figure \"cp_figure is not a Figure\"\n@assert cp_figure_ax isa Makie.Axis \"cp_figure_ax is not an Axis\"\ncp_figure_ax.title = \"REPL Test Title\"\nlog_result(\"1.5-repl\", true, \"REPL exports verified\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Take a screenshot named `05_repl_title.png`."

---

### Phase 2: DataFrame Source Mode & Normalization

**Step 2.1 — Simple DataFrame**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#radio-source-dataframe\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#radio-source-dataframe`. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"caspl_df_simple\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times to focus `#dropdown-dataframe`. Press `ArrowDown/Up` `[|result of step 4|]` times to select `caspl_df_simple`. Press `Enter`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times to focus `#btn-deselect-all`. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"x\\\"]\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times to focus the `x` checkbox. Press `Space`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"y1\\\"]\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times to focus the `y1` checkbox. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"y2\\\"]\")", "q": false}`
13. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times to focus the `y2` checkbox. Press `Space`."
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
15. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 14]` times. Press `Space`. Take a screenshot named `06_df_simple.png`."
16. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"2.1\")", "q": false}`

**Step 2.2 — Large DataFrame**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"caspl_df_exp\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#dropdown-dataframe`. Press `ArrowDown/Up` `[|result of step 2|]` times to select `caspl_df_exp`. Press `Enter`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times. Press `Space`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"x\\\"]\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times to focus the `x` checkbox. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"y2\\\"]\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times to focus the `y2` checkbox. Press `Space`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"y4\\\"]\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times to focus the `y4` checkbox. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
13. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times. Press `Space`. Take a screenshot named `07_df_large.png`."
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"2.2\")", "q": false}`

**Step 2.3 — Unitful DataFrame (Incompatible)**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"caspl_df_unitful\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `ArrowDown/Up` `[|result of step 2|]` times to select `caspl_df_unitful`. Press `Enter`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times. Press `Space`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"index\\\"]\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times to focus the `index` checkbox. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"area\\\"]\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times to focus the `area` checkbox. Press `Space`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"linear\\\"]\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times to focus the `linear` checkbox. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
13. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times. Press `Space`. Take a screenshot named `08_df_incompatible_modal.png`."
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_modal_visible(app, \"2.3-modal\")", "q": false}`
15. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
16. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 15]` times. Press `Space`. Take a screenshot named `09_df_incompatible_plot.png`."
17. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"2.3\")", "q": false}`

**Step 2.4 — Data Cleansing (Compatible)**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"caspl_df_unitmix\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `ArrowDown/Up` `[|result of step 2|]` times to select `caspl_df_unitmix`. Press `Enter`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times. Press `Space`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"index\\\"]\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times to focus the `index` checkbox. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"areacm\\\"]\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times to focus the `areacm` checkbox. Press `Space`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"areammcm\\\"]\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times to focus the `areammcm` checkbox. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
13. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times. Press `Space`. Take a screenshot named `10_df_compatible.png`."
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"2.4\")", "q": false}`

**Step 2.5 — Data Cleansing (Missing/Non-Numeric)**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"index\\\"]\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times to focus the `index` checkbox. Press `Space`."
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"unimiss\\\"]\")", "q": false}`
6. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 5]` times to focus the `unimiss` checkbox. Press `Space`."
7. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
8. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 7]` times. Press `Space`. Take a screenshot named `11_df_missing_modal.png`."
9. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_modal_visible(app, \"2.5-modal\")", "q": false}`
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times. Press `Space`. Take a screenshot named `12_df_missing_plot.png`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"2.5\")", "q": false}`

---

### Phase 3: Plot Formatting

**Step 3.1 — Labels & Axis Limits**

> **Note:** The DOM order of label inputs in the Format tab is: `#input-xlabel` → `#input-ylabel` → `#input-title`. TAB through them in that order.

1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-format\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#tab-button-format`. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#input-xlabel\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times to focus `#input-xlabel`. Press `Ctrl+A`, then `Delete`. Type `Custom X`. Press `Tab` to focus `#input-ylabel`. Press `Ctrl+A`, then `Delete`. Type `Custom Y`. Press `Tab` to focus `#input-title`. Press `Ctrl+A`, then `Delete`. Type `Custom Title`. Press `Enter`."
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_format_is_custom(app, :xlabel, \"3.1a\"); verify_format_is_custom(app, :ylabel, \"3.1b\"); verify_format_is_custom(app, :title, \"3.1c\")", "q": false}`
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#axis-x-min-input\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times to focus `#axis-x-min-input`. Press `Ctrl+A`, then `Delete`. Type `0`. Press `Tab` to focus `#axis-x-max-input`. Press `Ctrl+A`, then `Delete`. Type `10`. Press `Tab` to focus `#axis-x-reversed-checkbox`. Press `Space`. Take screenshot named `13_format_labels.png`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_axis_limits(app, 0.0, 10.0, \"3.1d\"); verify_format_is_custom(app, :x_min, \"3.1e\"); verify_format_is_custom(app, :xreversed, \"3.1f\")", "q": false}`

**Step 3.2 — Persistence Through Plot Type**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-plottype\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-plottype\", \"Lines\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `ArrowDown/Up` `[|result of step 2|]` times to select `Lines`. Press `Enter`. Take screenshot `14_format_lines.png`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"3.2\"); verify_format_is_custom(app, :title, \"3.2-title-persist\"); verify_format_is_custom(app, :xlabel, \"3.2-xlabel-persist\")", "q": false}`

**Step 3.3 — Persistence Through Theme**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-theme\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-theme\", \"theme_ggplot2\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `ArrowDown/Up` `[|result of step 2|]` times to select `theme_ggplot2`. Press `Enter`. Take screenshot `15_format_theme.png`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"3.3\"); verify_format_is_custom(app, :title, \"3.3-title-persist\")", "q": false}`

**Step 3.4 — Group Differentiation**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-groupby\")", "q": false}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-groupby\", \"Geometry\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `ArrowDown/Up` `[|result of step 2|]` times to select `Geometry`. Press `Enter`. Take screenshot `16_format_geometry.png`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"3.4a\")", "q": false}`
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-plottype\")", "q": false}`
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-plottype\", \"BarPlot\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 5]` times. Press `ArrowDown/Up` `[|result of step 6|]` times to select `BarPlot`. Press `Enter`. Take screenshot `17_format_barplot_geometry_fallback.png`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"3.4b\")", "q": false}`

**Step 3.5 — Legend Toggle & Title**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#chk-show-legend\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times to focus `#chk-show-legend`. Press `Space` to toggle legend on (if it was off). Press `Tab` to focus `#input-legend-title`. Type `Custom Legend`. Press `Shift+Tab` to return to `#chk-show-legend`. Press `Space`. Take screenshot `18_format_legend.png`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_format_is_custom(app, :show_legend, \"3.5-legend\"); verify_format_is_custom(app, :legend_title, \"3.5-legend-title\")", "q": false}`

**Step 3.6 — Label Reset on Source Change**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"caspl_df_exp\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times. Press `ArrowDown/Up` `[|result of step 4|]` times to select `caspl_df_exp`. Press `Enter`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"x\\\"]\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times to focus the `x` checkbox. Press `Space`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"y2\\\"]\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times to focus the `y2` checkbox. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
13. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times. Press `Space`."
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"3.6\")", "q": false}`
15. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-format\")", "q": false}`
16. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 15]` times. Press `Space`. Take screenshot `19_format_reset.png`."
17. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_format_is_default(app, :title, \"3.6-title-reset\"); verify_format_is_default(app, :xlabel, \"3.6-xlabel-reset\"); verify_format_is_default(app, :ylabel, \"3.6-ylabel-reset\")", "q": false}`

---

### Phase 4: File Import (Open Tab)

**Step 4.1 — Load Standard CSV**

> **Note:** `sample_data.csv` has columns: `id`, `name`, `value`, `active`. We plot `id` (X) and `value` (Y).

1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-open\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "set_opened_file_path(app, \"test/assets/sample_data.csv\", \"4.1-set\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-reload\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times to focus `#btn-reload`. Press `Space`."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_file_loaded(app, \"4.1-loaded\"); verify_file_row_count(app, 5, \"4.1-rows\")", "q": false}`
7. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
8. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 7]` times. Press `Space`."
9. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"__opened_file__\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 9]` times to focus `#dropdown-dataframe`. Press `ArrowDown/Up` `[|result of step 10|]` times to select the opened file entry. Press `Enter`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
13. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times. Press `Space`."
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"id\\\"]\")", "q": false}`
15. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 14]` times to focus the `id` checkbox. Press `Space`."
16. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"value\\\"]\")", "q": false}`
17. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 16]` times to focus the `value` checkbox. Press `Space`."
18. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
19. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 18]` times. Press `Space`."
20. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.1-plot\")", "q": false}`
21. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-format\")", "q": false}`
22. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 21]` times. Press `Space`."
23. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-plottype\")", "q": false}`
24. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-plottype\", \"Lines\")", "q": false}`
25. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 23]` times. Press `ArrowDown/Up` `[|result of step 24|]` times to select `Lines`. Press `Enter`."
26. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-theme\")", "q": false}`
27. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-theme\", \"theme_light\")", "q": false}`
28. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 26]` times. Press `ArrowDown/Up` `[|result of step 27|]` times to select `theme_light`. Press `Enter`. Take screenshot `20_csv_loaded.png`."
29. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.1-final\")", "q": false}`

**Step 4.2 — Load TSV and Delimiter Options**

> **Note:** `empty_rows_sample.tsv` has columns `A`, `B`, `C` (verify first by checking `app.state.file_opening.opened_file_df[]` after reload). We select the first two non-empty columns.

1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-open\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "set_opened_file_path(app, \"test/assets/empty_rows_sample.tsv\", \"4.2-set\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-delimiter\")", "q": false}`
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-delimiter\", \"Tab\")", "q": false}`
6. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times to focus `#dropdown-delimiter`. Press `ArrowDown/Up` `[|result of step 5|]` times to select `Tab`. Press `Enter`."
7. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-reload\")", "q": false}`
8. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 7]` times. Press `Space`."
9. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_file_loaded(app, \"4.2-loaded\")", "q": false}`
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "df = app.state.file_opening.opened_file_df[]\ncol1, col2 = string(names(df)[1]), string(names(df)[2])\nlog_result(\"4.2-cols\", true, \"TSV columns: $(names(df)). Will select $col1 and $col2.\")", "q": false}`
    *(Note the returned column names — use them in steps 14 and 16 below.)*
11. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
12. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 11]` times. Press `Space`."
13. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"__opened_file__\")", "q": false}`
15. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 13]` times to focus `#dropdown-dataframe`. Press `ArrowDown/Up` `[|result of step 14|]` times. Press `Enter`."
16. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
17. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 16]` times. Press `Space`."
18. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col1)\\\"]\")", "q": false}`
19. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 18]` times to focus the first column checkbox. Press `Space`."
20. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col2)\\\"]\")", "q": false}`
21. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 20]` times to focus the second column checkbox. Press `Space`."
22. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
23. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 22]` times. Press `Space`."
24. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.2-plot\")", "q": false}`
25. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-format\")", "q": false}`
26. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 25]` times. Press `Space`."
27. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-plottype\")", "q": false}`
28. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-plottype\", \"Scatter\")", "q": false}`
29. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 27]` times. Press `ArrowDown/Up` `[|result of step 28|]` times. Press `Enter`."
30. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#chk-show-legend\")", "q": false}`
31. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 30]` times. Press `Space`."
32. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#input-xlabel\")", "q": false}`
33. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 32]` times to focus `#input-xlabel`. Press `Ctrl+A`, then `Delete`. Type `Custom TSV X`. Press `Enter`. Take screenshot `21_tsv_loaded.png`."
34. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.0); verify_plot_rendered(app, \"4.2-final\"); verify_format_is_custom(app, :xlabel, \"4.2-xlabel\")", "q": false}`

**Step 4.3 — Empty Rows & Non-Standard Headers (XLSX)**

> **Note:** We need to load `empty_rows_top-header_sample.xlsx` with "Skip empty rows" checked, then separately `row2-header_sample.xlsx` with header row = 2. After each reload we switch to Source, select `opened file`, select 2 columns, then Replot.

1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-open\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "set_opened_file_path(app, \"test/assets/empty_rows_top-header_sample.xlsx\", \"4.3a-set\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#chk-skip-empty-rows\")", "q": false}`
5. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times to focus `#chk-skip-empty-rows`. Press `Space` to enable it."
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-reload\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_file_loaded(app, \"4.3a-loaded\")", "q": false}`
9. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "df = app.state.file_opening.opened_file_df[]\ncol1, col2 = string(names(df)[1]), string(names(df)[2])\nlog_result(\"4.3a-cols\", true, \"XLSX columns: $(names(df)). Selecting $col1, $col2.\")", "q": false}`
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
13. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"__opened_file__\")", "q": false}`
14. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 12]` times. Press `ArrowDown/Up` `[|result of step 13|]` times. Press `Enter`."
15. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
16. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 15]` times. Press `Space`."
17. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col1)\\\"]\")", "q": false}`
18. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 17]` times. Press `Space`."
19. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col2)\\\"]\")", "q": false}`
20. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 19]` times. Press `Space`."
21. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
22. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 21]` times. Press `Space`."
23. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.3a-plot\")", "q": false}`
24. *(Now test row2-header XLSX)*
25. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-open\")", "q": false}`
26. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 25]` times. Press `Space`."
27. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "set_opened_file_path(app, \"test/assets/row2-header_sample.xlsx\", \"4.3b-set\")", "q": false}`
28. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#input-header-row\")", "q": false}`
29. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 28]` times to focus `#input-header-row`. Press `Ctrl+A`, then `Delete`. Type `2`. Press `Enter`."
30. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-reload\")", "q": false}`
31. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 30]` times. Press `Space`."
32. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_file_loaded(app, \"4.3b-loaded\")", "q": false}`
33. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "df = app.state.file_opening.opened_file_df[]\ncol1, col2 = string(names(df)[1]), string(names(df)[2])\nlog_result(\"4.3b-cols\", true, \"XLSX row2-header columns: $(names(df)). Selecting $col1, $col2.\")", "q": false}`
34. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
35. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 34]` times. Press `Space`."
36. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
37. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"__opened_file__\")", "q": false}`
38. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 36]` times. Press `ArrowDown/Up` `[|result of step 37|]` times. Press `Enter`."
39. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
40. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 39]` times. Press `Space`."
41. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col1)\\\"]\")", "q": false}`
42. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 41]` times. Press `Space`."
43. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col2)\\\"]\")", "q": false}`
44. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 43]` times. Press `Space`."
45. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
46. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 45]` times. Press `Space`."
47. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.3b-plot\")", "q": false}`
48. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-format\")", "q": false}`
49. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 48]` times. Press `Space`."
50. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-plottype\")", "q": false}`
51. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-plottype\", \"BarPlot\")", "q": false}`
52. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 50]` times. Press `ArrowDown/Up` `[|result of step 51|]` times. Press `Enter`."
53. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-theme\")", "q": false}`
54. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-theme\", \"theme_ggplot2\")", "q": false}`
55. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 53]` times. Press `ArrowDown/Up` `[|result of step 54|]` times. Press `Enter`. Take screenshot `22_xlsx_headers.png`."
56. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.3b-final\")", "q": false}`

**Step 4.4 — Multisheet XLSX & Subheader Skipping**

> **Note:** The `#dropdown-sheet` is only populated after setting the file path triggers the XLSX sheet-detection logic. Set the path, then TAB to the sheet dropdown and select a sheet.

1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-open\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "set_opened_file_path(app, \"test/assets/sample_data-multisheet.xlsx\", \"4.4-set\")", "q": false}`
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#dropdown-sheet\")", "q": false}`
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-sheet\", \"Sheet2\")", "q": false}`
6. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 4]` times to focus `#dropdown-sheet`. Press `ArrowDown/Up` `[|result of step 5|]` times to select `Sheet2`. Press `Enter`."
7. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_file_loaded(app, \"4.4-sheet-loaded\")", "q": false}`
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#input-skip-subheaders\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times to focus `#input-skip-subheaders`. Press `Ctrl+A`, then `Delete`. Type `1`. Press `Enter`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-reload\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times. Press `Space`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_file_loaded(app, \"4.4-reloaded\")", "q": false}`
13. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "df = app.state.file_opening.opened_file_df[]\ncol1, col2 = string(names(df)[1]), string(names(df)[2])\nlog_result(\"4.4-cols\", true, \"Multisheet columns: $(names(df)). Selecting $col1, $col2.\")", "q": false}`
14. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
15. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 14]` times. Press `Space`."
16. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-dataframe\")", "q": false}`
17. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-dataframe\", \"__opened_file__\")", "q": false}`
18. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 16]` times. Press `ArrowDown/Up` `[|result of step 17|]` times. Press `Enter`."
19. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); calculate_tab_distance(session, \"#btn-deselect-all\")", "q": false}`
20. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 19]` times. Press `Space`."
21. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col1)\\\"]\")", "q": false}`
22. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 21]` times. Press `Space`."
23. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"input.column-checkbox[value=\\\"$(col2)\\\"]\")", "q": false}`
24. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 23]` times. Press `Space`."
25. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
26. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 25]` times. Press `Space`."
27. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.4-plot\")", "q": false}`
28. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-format\")", "q": false}`
29. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 28]` times. Press `Space`."
30. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#axis-x-min-input\")", "q": false}`
31. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 30]` times to focus `#axis-x-min-input`. Press `Ctrl+A`, then `Delete`. Type `0`. Press `Tab`. Press `Ctrl+A`, then `Delete`. Type `10`. Press `Enter`."
32. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#dropdown-groupby\")", "q": false}`
33. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_dropdown_keystrokes(session, \"#dropdown-groupby\", \"Color\")", "q": false}`
34. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 32]` times. Press `ArrowDown/Up` `[|result of step 33|]` times. Press `Enter`. Take screenshot `23_xlsx_multisheet.png`."
35. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"4.4-final\")", "q": false}`

---

### Phase 5: Saving & Code Generation

**Step 5.1 — Save Plot in Multiple Formats**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-save\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#save-path-input\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times to focus `#save-path-input`. Press `Ctrl+A`, then `Delete`. Type `my_plot.png`. Press `Tab` to move focus away (to trigger `onblur`)."
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-save-plot\")", "q": false}`
6. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 5]` times. Press `Space`. Take screenshot `24_save_png_modal.png`."
7. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.1a-modal\")", "q": false}`
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times. Press `Space`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_file_on_disk(\"my_plot.png\", \"5.1a-png\")", "q": false}`
11. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#save-path-input\")", "q": false}`
12. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 11]` times. Press `Ctrl+A`, then `Delete`. Type `my_plot.svg`. Press `Tab`."
13. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-save-plot\")", "q": false}`
14. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 13]` times. Press `Space`. Take screenshot `24b_save_svg_modal.png`."
15. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.1b-modal\")", "q": false}`
16. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
17. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 16]` times. Press `Space`."
18. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_file_on_disk(\"my_plot.svg\", \"5.1b-svg\")", "q": false}`
19. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#save-path-input\")", "q": false}`
20. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 19]` times. Press `Ctrl+A`, then `Delete`. Type `my_plot.pdf`. Press `Tab`."
21. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-save-plot\")", "q": false}`
22. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 21]` times. Press `Space`. Take screenshot `24c_save_pdf_modal.png`."
23. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.1c-modal\")", "q": false}`
24. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
25. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 24]` times. Press `Space`."
26. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_file_on_disk(\"my_plot.pdf\", \"5.1c-pdf\")", "q": false}`

**Step 5.2 — Error Handling (No Plot)**

> **Note:** We force the "no plot" state by directly setting `current_figure[]` to `nothing`. This is a deliberate programmatic state setup (not a GUI actuation) to exercise the error-handling path without needing to restart the app.

1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "app.state.plotting.handles.current_figure[] = nothing"}`
2. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-save-plot\")", "q": false}`
3. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 2]` times. Press `Space`. Take screenshot `25_save_no_plot_error.png`."
4. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.2-modal\")", "q": false}`
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
6. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 5]` times. Press `Space`."

**Step 5.3 — Error Handling (Invalid Path)**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-source\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Space`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-replot\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times. Press `Space`." *(Re-plot to restore `current_figure`.)*
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(1.5); verify_plot_rendered(app, \"5.3-replot\")", "q": false}`
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#tab-button-save\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#save-path-input\")", "q": false}`
9. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 8]` times. Press `Ctrl+A`, then `Delete`. Type `/nonexistent_dir/my_plot.png`. Press `Tab`."
10. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-save-plot\")", "q": false}`
11. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 10]` times. Press `Space`. Take screenshot `26_save_invalid_path.png`."
12. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.3-modal\")", "q": false}`
13. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
14. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 13]` times. Press `Space`."

**Step 5.4 — Overwrite Warning**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#save-path-input\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Ctrl+A`, then `Delete`. Type `my_plot.png`. Press `Tab`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-save-plot\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times. Press `Space`. Take screenshot `27_save_overwrite_modal.png`."
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.4-modal\")", "q": false}`
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-overwrite\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_file_on_disk(\"my_plot.png\", \"5.4-overwrite\")", "q": false}`

**Step 5.5 — Code Generation**
1. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#save-path-input\")", "q": false}`
2. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 1]` times. Press `Ctrl+A`, then `Delete`. Type `my_plot_script.jl`. Press `Tab`."
3. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-create-script\")", "q": false}`
4. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 3]` times. Press `Space`. Take screenshot `28_create_script_modal.png`."
5. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_modal_visible(app, \"5.5-modal\")", "q": false}`
6. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "calculate_tab_distance(session, \"#btn-modal-ok\")", "q": false}`
7. **[Main Agent]** Call `browser_subagent` with `Task`: "Press `Tab` `[result of step 6]` times. Press `Space`."
8. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "sleep(0.5); verify_file_on_disk(\"my_plot_script.jl\", \"5.5-script-exists\")", "q": false}`
9. **[Main Agent]** Execute `call_mcp_tool` — `ServerName="Kaimon"`, `ToolName="ex"`, `Arguments={"e": "verify_script_runs_cleanly(\"my_plot_script.jl\", \"5.5-script-clean\")", "q": false}`

---

## PS: Architectural Deadlock and Future Resolution

**The Current Deadlock:**
The step-by-step execution plan written above currently encounters a systemic deadlock due to browser lifecycle constraints. The plan relies on a back-and-forth "ping-pong" interaction:
1. The Main Agent computes exact tab distances dynamically using the active Bonito session.
2. The Subagent is dispatched to press those exact keys.

However, the `browser_subagent` tool currently destroys its Chromium browser context the moment it returns control. When the browser closes, Bonito drops the WebSocket connection and destroys the session. Because Bonito/WGLMakie state (like the rendered plot canvas and DOM) is tied to the lifecycle of a specific session and is not persisted across browser reloads, each subsequent subagent call launches a brand-new session with completely reset UI state. This makes sequential, multi-step subagent testing impossible.

**Possible Solution (`ReusedSubagentId`):**
The `browser_subagent` tool schema includes a parameter called `ReusedSubagentId` designed to resume a previous browser context. Currently, the tool does not return a subagent ID upon completion, preventing resumption. 

If/when the `ReusedSubagentId` functionality begins returning a valid ID, *and* the system successfully suspends the Chromium browser in the background without dropping its active WebSocket connection, the step-by-step plan outlined above will function perfectly without structural modifications.
