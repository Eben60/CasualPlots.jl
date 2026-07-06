# Testing Plan: DOM Corruption Bug — Reproduction & Root Cause Investigation

* Update - we couldn't reproduce the bug, however then still refactored the code. The file left here for documentation as an example of how to proceed

## Reference
See [dom_corruption_bug.md](dom_corruption_bug.md) for the full bug description, symptoms, trigger steps, and technical hypothesis.

## Strict Rules of Execution

> [!CAUTION]
> **STOP AND REPORT ON FAILURE:** If at any point an unexpected error occurs (in the subagent, Julia REPL, or Kaimon), the agent MUST immediately stop, report the exact failure to the user, and wait for instructions.
>
> **NO SOURCE CHANGES:** The agent is strictly forbidden from modifying any source code or test files without first receiving explicit permission from the user.

---

## Phase 1: Environment Setup

**Goal:** Start the app and open the browser in a known-clean state.

- **[Julia/REPL]** Activate the package environment and run the test setup:
  ```julia
  using Pkg; Pkg.activate(".")
  include("src/scripts/casualplots_test_setup.jl")
  app = casualplots_app()
  server = Bonito.Server(app, "127.0.0.1", 9385)
  ```
- **[Julia/REPL]** Confirm server is running: `server.isrunning`.
- **[Subagent]** Navigate to `http://localhost:9385/`. Wait for full page load. Take a baseline screenshot and report back.
- **[Main Agent]** Confirm via Julia: `isnothing(app.app.session[])` should be `false` and status `OPEN`.
- **[Main Agent]** Record the initial session ID: `get_active_session().id`.

---

## Phase 2: Reproduce the Bug

**Goal:** Confirm the bug is reproducible by triggering a page reload.

- **[Subagent]** On the currently loaded page (`http://localhost:9385/`), press `F5` to reload the page. Wait 3 seconds for the page to fully reconnect. Take a screenshot of the resulting page state and report back.
- **[Main Agent]** Inspect the DOM for corruption:
  ```julia
  session = get_active_session()
  # Check if a <select> element has been injected inside the Source tab button
  result = Bonito.evaljs_value(session, js"""
      (function() {
          const srcBtn = document.querySelector('button.tab-button.active');
          if (!srcBtn) return "Source button not found";
          const sel = srcBtn.querySelector('select');
          return sel ? "BUG CONFIRMED: <select> found inside Source tab button" : "OK: No corruption detected";
      })()
  """)
  @info result
  ```
- **[Main Agent]** Additionally check the tab button's child count:
  ```julia
  child_count = Bonito.evaljs_value(session, js"document.querySelector('button.tab-button.active').childElementCount")
  @info "Source button child count" child_count
  ```
  A healthy button should have `0` child elements. A corrupted one will have `> 0`.

> [!IMPORTANT]
> If **both** checks confirm the bug, proceed to Phase 3. If the bug does **not** reproduce, stop and report to the user before continuing.

---

## Phase 3: Characterise the Corruption

**Goal:** Gather precise diagnostic data about *what* is injected and *where*.

- **[Main Agent]** Query the full inner HTML of the corrupted Source tab button:
  ```julia
  session = get_active_session()
  inner = Bonito.evaljs_value(session, js"document.querySelector('button.tab-button.active').innerHTML")
  @info "Source button innerHTML" inner
  ```
- **[Main Agent]** Query the `data-jscall-id` attribute of the injected `<select>` element (if present), to identify which Bonito observable node it corresponds to:
  ```julia
  jscall_id = Bonito.evaljs_value(session, js"""
      (function() {
          const sel = document.querySelector('button.tab-button.active select');
          return sel ? sel.getAttribute('data-jscall-id') : 'not found';
      })()
  """)
  @info "Injected element data-jscall-id" jscall_id
  ```
- **[Main Agent]** Cross-reference the `data-jscall-id` with the known observables by querying the full observable registry:
  ```julia
  # Check if the session's observable map reveals which observable owns this ID
  session = get_active_session()
  @info "Session observable count" length(session.observables)
  ```

---

## Phase 4: Trace the Reactive Node Lifecycle

**Goal:** Verify which specific `map()` block in `create_control_panel_ui.jl` is responsible for the mis-routed DOM update.

- **[Main Agent]** After the reload, manually notify the `source_type` observable and observe if the DOM corruption changes or updates:
  ```julia
  # First, read the current value
  current = app.state.data_selection.source_type[]
  @info "Current source_type" current
  # Now notify it (without changing the value) to trigger a reactive re-render
  notify(app.state.data_selection.source_type)
  sleep(1.0)
  ```
- **[Subagent]** Take a screenshot immediately after the `notify` call to check if the corruption changes (e.g., disappears, doubles, or moves).
- **[Main Agent]** Re-run the DOM corruption check from Phase 2 to see if the state changed.

---

## Phase 5: Verify Multi-Session Behaviour

**Goal:** Confirm that opening a *second* tab (without reloading) causes the same corruption.

- **[Subagent]** Open a **new browser tab** and navigate to `http://localhost:9385/`. Wait for page load. Take a screenshot and report.
- **[Main Agent]** Check if a **second session** was created:
  ```julia
  # Bonito server tracks sessions — check if there are now 2
  @info "Session" app.app.session[]
  ```
- **[Main Agent]** Re-run the DOM corruption check on the new tab's session.

---

## Phase 6: Summary Report

After completing all phases, the agent should compile a brief report containing:
1. Whether the bug was **reproduced** (Phase 2 result).
2. The **exact element** that was injected (Phase 3: `innerHTML`, `data-jscall-id`).
3. The **effect of `notify`** on the corrupted DOM (Phase 4 result).
4. Whether a **second tab** triggers the same corruption (Phase 5 result).
5. Any divergence from the existing Technical Hypothesis in [dom_corruption_bug.md](dom_corruption_bug.md).
