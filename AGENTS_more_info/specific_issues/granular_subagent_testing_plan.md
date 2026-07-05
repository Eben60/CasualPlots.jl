# Detailed GUI Testing Plan: Granular Subagent Chunking

## Goal
Execute a GUI test sequence using highly granular, single-action browser subagent calls. Between each subagent call, the main agent will verify the DOM state using Kaimon/Julia REPL tools via the active Bonito session. This prevents exponential context growth while ensuring real browser interaction.

## Strict Rules of Execution
> [!CAUTION]
> **STOP AND REPORT ON FAILURE:** If at any point the verification step fails, or if an error is encountered in the subagent or Julia REPL, the agent MUST immediately stop execution, report the exact failure to the user, and wait for instructions.
>
> **NO SOURCE CHANGES:** The agent is strictly forbidden from changing any application source code or testing utility files without first getting explicit permission from the user.

## Pre-requisites
1. The `CasualPlots.jl` application must be running on `http://localhost:9385/`.
2. A Bonito session must be active and accessible via `get_active_session()` in the REPL.
3. The browser window must be freshly opened to the app url.

## Test Sequence

### Phase 1: X Variable Selection
- **[Subagent]** Navigate to the X selection dropdown by pressing `TAB` the required number of times.
- **[Main Agent]** Verify the proper control is focused (e.g., using `get_active_element_id(session)`). If incorrect, iterate via subagent to correct focus.
- **[Main Agent]** Get the list of option names for the currently focused dropdown using `get_dropdown_options(session)`.
- **[Subagent]** Type `caspl_x_100` and press `Enter` to select the option.
- **[Main Agent]** Verify the selected option matches `caspl_x_100` via Julia.

### Phase 2: Y Variable Selection
- **[Subagent]** Navigate to the Y selection dropdown (e.g., press `TAB` to move to the next control).
- **[Main Agent]** Verify the proper control is focused (Y dropdown).
- **[Main Agent]** Get the list of option names for the Y dropdown.
- **[Subagent]** Type `caspl_z100` and press `Enter`.
- **[Main Agent]** Verify the selected option matches `caspl_z100` via Julia.

### Phase 3: Plot Array Data
- **[Subagent]** Navigate to the `(Re-)Plot` button (using `TAB`).
- **[Main Agent]** Verify the plot button is focused.
- **[Subagent]** Press `Enter` or `Space` to click the plot button.
- **[Main Agent]** Verify that the plot was successfully generated (e.g., checking if the global `cp_figure` was updated or if the plot pane DOM changed).

### Phase 4: Switch to DataFrame Mode
- **[Subagent]** Navigate to the "File/DataFrame" radio button (using `Shift+TAB` or `TAB` as needed).
- **[Main Agent]** Verify the radio button is focused.
- **[Subagent]** Select the radio button (e.g., using `Space` or `ArrowDown`).
- **[Main Agent]** Verify the source mode changed to DataFrame.

### Phase 5: DataFrame Selection
- **[Subagent]** Navigate to the DataFrame selection dropdown.
- **[Main Agent]** Verify the DataFrame dropdown is focused.
- **[Subagent]** Type `caspl_df_exp` and press `Enter`.
- **[Main Agent]** Verify the selected DataFrame is `caspl_df_exp`.

### Phase 6: Column Selection
- **[Subagent]** Navigate through the column checkboxes and use `Space` to select columns `x`, `y2`, and `y4`.
- **[Main Agent]** Verify the correct columns are selected via Julia.

### Phase 7: Plot DataFrame Data
- **[Subagent]** Navigate to the `(Re-)Plot` button.
- **[Main Agent]** Verify focus.
- **[Subagent]** Press `Enter` or `Space`.
- **[Main Agent]** Verify the plot was generated via Julia.

### Phase 8: Final Visual Verification
- **[Subagent]** Take a single screenshot of the browser page to visually confirm the final rendered plot. Report findings to the user.
