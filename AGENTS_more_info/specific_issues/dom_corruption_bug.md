# DOM Corruption Bug Document
**Issue**: Reactive DOM content is injected into incorrect parent nodes upon page reload.

* Update - we couldn't reproduce the bug, however then still refactored the code. The file left here for documentation.

## Symptoms
When a user reloads the browser page (F5) or opens a concurrent connection to the same server port, a duplicate `<select>` dropdown (specifically the "Select X" dropdown) is injected directly inside the text of the "Source" tab button (`<button class="tab-button active">`). 

This breaks the visual layout of the tab bar, although it does not explode the page height infinitely like the previous `active_tab` bug.

**Evidence:**
This screenshot captured during automated testing shows the "Select X" dropdown visibly rendering inside the "Source" button:
![Corrupted Source Button](/Users/elk/.gemini/antigravity-ide/brain/07655dc3-1291-4939-8ef6-eea7d888c752/.system_generated/click_feedback/click_feedback_1783267194695.png)

## Trigger
1. Launch the `casualplots_app()` which binds the `App` globally.
2. Open `http://localhost:9385/` in the browser.
3. Refresh the page (F5) to simulate a new connection while the old session hasn't garbage collected.

## Technical Hypothesis
1. **Global App State**: The app is served outside of a `session` block, meaning all WebSockets share the same underlying Julia `DOM` nodes and `Observables`.
2. **Reactive DOM Nodes**: In `create_control_panel_ui.jl`, the `source_content` pane (which contains the dropdowns) is constructed using a reactive map:
   ```julia
   source_content = map(source_type) do st
       if st == "DataFrame" ... else ... end
   end
   ```
3. **The Broadcast Failure**: When the page is refreshed, the new JS client connects and requests the current state of all observables. Bonito re-evaluates the `map(source_type)` and broadcasts the HTML payload. 
4. **Client-side Confusion**: Because the DOM tree structure relies on internal `data-jscall-id` tracking, the new JS client gets confused when receiving a DOM patch for an already-existing reactive element in a shared state. Instead of placing the new `source_content` into its designated `div`, the Javascript fallback logic appends the payload into an incorrect parent node (the first available node, which happens to be the `Source` tab button).

## Future Mitigation
To fix this, we will likely need to refactor `create_control_panel_ui.jl` to remove the `map(source_type) do st...` block that dynamically generates HTML. Instead, we can statically render *both* the DataFrame dropdowns and the Array dropdowns, and use simple Javascript/CSS (e.g., `display: none`) to toggle their visibility based on the `source_type` radio button, completely eliminating Bonito DOM patching for this section.
