# Browser Dropdown Testing Procedure (Native Selects)

This document outlines the standard, robust procedure for selecting options in native HTML `<select>` dropdown elements during automated browser/GUI testing.

## The Challenge
Standard `<select>` elements render their dropdown menus at the Operating System level rather than in the browser's HTML DOM tree. Because of this:
- The subagent's `browser_get_dom` tool cannot see the expanded option elements (they are filtered out as non-interactive/hidden).
- Simulating mouse drags or coordinate-based clicks on the expanded dropdown menu is extremely unreliable and easily fails.

## The Solution
Instead of clicking the dropdown and trying to click an option, the browser agent must use keyboard focus and type matching:
1. **Focus the Dropdown**: Click the `<select>` element once at its center coordinates to focus it.
2. **Type the Option Value**: Type the exact name of the option we want to select. Chrome's native select element automatically matches the prefix/value.
3. **Confirm Selection**: Press the `Enter` key to select the matched option and trigger the `change` event.

---

## Detailed Step-by-Step Procedure for Agents

When testing data source selections (X or Y arrays):

### Step 1: Query Options from Julia (X or Y)
Do not guess option names or try to read them from `browser_get_dom`. Instead, query the live application state directly in Julia to retrieve the list of candidates:
```julia
# Get active X array candidates:
CasualPlots.collect_arrays_from_main()

# Or get congruent Y array candidates for a specific selected X (e.g. "caspl_x_100"):
dims_dict = app.state.data_selection.dims_dict_obs[]
CasualPlots.get_congruent_y_names("caspl_x_100", dims_dict)
```

### Step 2: Select the X-Variable
1. Click the Select X dropdown at its DOM coordinates (typically X: 115, Y: 119) to focus it.
2. Send text input with the exact variable name (e.g. `"caspl_x_100"`).
3. Send key press `Enter`.
4. Wait 1.5 seconds for the backend to process the selection and update the Y dropdown.

### Step 3: Select the Y-Variable
1. Get the DOM tree to verify coordinates for the Select Y dropdown (normally located directly below Select X, around Y: 145 or 148).
2. Click the Select Y dropdown to focus it.
3. Send text input with the exact congruent variable name retrieved in Step 1 (e.g. `"caspl_z100"`).
4. Send key press `Enter`.
5. Wait 1 second for the range bounds to settle and the "(Re-)Plot" button to turn green.
