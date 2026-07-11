# Implementation Plan: Agent-Based GUI Testing Plan

## Goal
Create a detailed, step-by-step document (`agent_testing_plan.md`) that translates the `manual_testing_plan.md` into an executable script for an AI agent. The target executor is an **economical agent model operating within a limited quota**. The plan must therefore maximize reliability and minimize unnecessary subagent invocations and in-context reasoning.

---

## Proposed Output Files

### [NEW] `AGENTS_more_info/specific_issues/agent_testing_plan.md`
The primary testing plan document, structured as below.

### [NEW] `test/agentic/casualplots_agent_test_utils.jl`
All verification logic encapsulated as callable Julia functions. The testing plan references these by name; no raw snippets appear in the plan itself.

---

## Structure of `agent_testing_plan.md`

### 1. Strict Rules of Execution
- **STOP AND REPORT ON FAILURE:** Any failed verification step, subagent error, or REPL exception must cause immediate halt and report to the user.
- **NO SOURCE CHANGES:** Forbidden without explicit user permission.
- **Granularity rule:** Subagent calls may batch 3–5 logically related, low-risk actions (e.g., navigate to tab → interact with control → take screenshot). Granularity is increased (one action per call) only when a prior step has failed or for high-stakes actions (e.g., clicking a button that triggers a modal).
- **Log results:** Every verification step must append a `pass`/`fail` line to `test/agentic/results.md`, not surface each result to the user individually.

### 2. Expected Step Count Budget
Each phase will carry an approximate subagent call count to guide the agent's self-monitoring:

| Phase | Approximate Subagent Calls |
|---|---|
| Setup | 1–2 |
| Phase 1 (Arrays) | 5–8 |
| Phase 2 (DataFrames) | 6–9 |
| Phase 3 (Formatting) | 5–7 |
| Phase 4 (File Import) | 8–12 |
| Phase 5 (Saving & Code Gen) | 5–7 |
| **Total** | **~30–45** |

If the running count exceeds 1.5× the expected budget for a phase, the agent must stop and report.

### 3. Pre-requisites & Recovery
The `[Main Agent]` must:
1. Run `include("src/scripts/casualplots_test.jl")` in the REPL (with CSV/XLSX loaded first).
2. Call `verify_session_active()` from the utility file.
3. **If session is not active:** Do NOT attempt recovery autonomously. Stop and report the exact error to the user.
4. Spawn one `[Subagent]` to navigate to `http://localhost:9385/` and take screenshot `00_app_loaded`.

### 4. Phase-by-Phase Translation

Each phase is a sequence of numbered steps. Every step carries:
- Its **sequential screenshot number** (e.g., `📸 04`)
- Its **role tag**: `[Subagent]` or `[Main Agent]`
- Its **exact keystroke sequence** for any browser interaction
- Its **utility function call** for verification

#### Phase 1 — Arrays Source Mode
The `[Subagent]` uses keyboard navigation for native `<select>` dropdowns per `browser_testing_dropdowns.md` (`TAB` to focus, `Arrow` keys or typed characters to select, `Enter`/`Space` to confirm). The `[Main Agent]` verifies observable state via `verify_x_selected()`, `verify_y_options_filtered()`, `verify_plot_rendered()`, etc.

#### Phase 2 — DataFrame Source Mode
The `[Subagent]` uses `TAB`/`Space` for checkboxes and `Arrow` keys for radio buttons. The `[Main Agent]` uses `verify_modal_visible()` and `verify_observable_value()` for data-cleansing warning modals.

#### Phase 3 — Formatting
The `[Subagent]` uses `TAB` to focus text fields, `Ctrl+A` to select all, types replacement text, then `Tab`/`Enter` to commit. The `[Main Agent]` calls `verify_format_is_custom(:title)`, `verify_axis_limits()`, etc.

#### Phase 4 — File Import (Open Tab)
- **OS dialog bypass:** The `[Main Agent]` calls the utility function `set_opened_file_path(app, path)` which sets `app.state.file_opening.opened_file_path[]` directly in the REPL. This fully replaces clicking "Open File".
- After loading, the `[Subagent]` interacts with Reload, sheet selectors, and option controls normally (no OS dialog involved).
- The `[Main Agent]` calls `verify_table_loaded()` and `verify_row_count()` after each load.

#### Phase 5 — Saving & Code Generation
- **Save path entry:** The `[Subagent]` types the file path directly into the **"File Path:" textarea** (element id `save-path-input`), using `Ctrl+A` then typing the path, without ever clicking "Select File..." (which would open an OS dialog). This avoids OS dialog interaction entirely.
- The `[Main Agent]` calls `verify_file_on_disk(path)` after each save.
- For code generation, the `[Main Agent]` calls `verify_script_runs_cleanly(path)`.

### 5. Screenshot Management
- The `[Subagent]` is instructed to take a screenshot **after every call that results in a visible UI state change**, but must **NOT analyze the screenshot**.
- Screenshots are saved as `NN_description.png` where `NN` is the sequential number listed in the plan for that step.
- The `agent_testing_plan.md` will carry a master screenshot index table at the top listing all expected screenshot filenames.
- Screenshots are saved to `test/agentic/screenshots/`.

### 6. Code Snippet Encapsulation (`test/agentic/casualplots_agent_test_utils.jl`)
All helper functions will return `(pass::Bool, message::String)` — unambiguous, log-friendly. No function may return `nothing` or throw on a recoverable failure. The testing plan calls these directly by name. Key planned functions:

| Function | Purpose |
|---|---|
| `verify_session_active()` | Check Bonito session is alive |
| `set_opened_file_path(app, path)` | Bypass Open File OS dialog for Phase 4 |
| `verify_table_loaded(app, min_rows)` | Confirm data table populated |
| `verify_row_count(app, expected)` | Check exact row count after option changes |
| `verify_x_selected(app, name)` | Check X variable observable |
| `verify_y_options_filtered(app, x_name)` | Check Y dropdown shows only congruent options |
| `verify_plot_rendered(app)` | Check `current_figure[]` is not `nothing` |
| `verify_observable_value(obs, expected)` | Generic observable value check |
| `verify_format_is_custom(app, key)` | Check `format_is_default[key] == false` |
| `verify_axis_limits(app, xmin, xmax)` | Check axis limit observables |
| `verify_modal_visible(app)` | Check `show_modal[]` is `true` |
| `verify_file_on_disk(path)` | Check file was saved on filesystem |
| `verify_script_runs_cleanly(path)` | Include generated script in a fresh Module |
| `log_result(step_id, pass, message)` | Append result line to `test/agentic/results.md` |

### 7. Results Logging
A `test/agentic/results.md` file will be created at the start of each test run. Every utility function call result is appended via `log_result()`. The user reviews this file after the run, not during it. Format per line:
```
[PASS|FAIL] NN_step_name — message
```

---

## Open Questions

> [!NOTE]
> **OS Dialog Bypass — Resolved**
> - **Phase 5 (Save):** The `[Subagent]` types the path directly into the "File Path:" textarea (id: `save-path-input`), bypassing the "Select File..." OS dialog button entirely.
> - **Phase 4 (Open):** The Open tab has no equivalent path textarea in the UI. The `[Main Agent]` will bypass the OS dialog by setting `app.state.file_opening.opened_file_path[]` directly via the REPL utility function `set_opened_file_path()`.
