# Creating Screenshot Specification Files

This document describes how to create a per-screenshot specification file for `CasualPlots.jl`. These specs serve as the single source of truth for both the generator code and the verification step.

For the overall screenshot reproduction workflow (running generators, interaction toolkit, synchronisation, verification protocol), see [Agentic Screenshots](../SKILL.md).

---

## Location & Naming

Specifications live directly in:
```
test/AgenticTesting/screenshots/specifications/<name>.md
```
where `<name>` matches the screenshot filename without the `.png` extension (e.g., `format_tab_barplot_dodged.md`).

> **Note on Paths**: The reference screenshots themselves are located at `docs/src/Screenshots/` relative to the package root. The template below uses `../../../../docs/src/Screenshots/<name>.png` to correctly link to them from the `specifications/` directory. Do not alter this relative path structure.

---

## Understanding the Application State

The active GUI state is accessible via Kaimon at `Main.app.state`. This object is of type `CasualPlots.CasualPlotsState`.

This type is fully documented, and each of its nested component types (e.g., `DataSelection`, `PlotFormat`, `PlotHandles`) are documented recursively. Before querying or reverse-engineering the UI state, use the REPL to read these docstrings to understand exactly which UI elements control which observables.

```julia
@doc CasualPlots.CasualPlotsState
# And then recursively explore the components you need:
@doc CasualPlots.PlotFormat
```

---

## How to Create a Spec

### Information Sources

There are two complementary ways to gather the information needed for a spec:

1. **Inspect the reference screenshot** using `view_file` on `docs/src/Screenshots/<name>.png`. Extract every visible detail: active tab, dropdown values, checkbox states, plot type, axis labels/ticks, title, legend, theme, table headers and data.

2. **Query the live GUI state** (when available). If live GUI state is available via Kaimon, you can read the exact observable values programmatically rather than guessing from pixels. If live GUI state is not available, ask the user if they can provide it.
   
   - Refer to the **Understanding the Application State** section above to learn the schema via docstrings.
   - To inspect the current live values, examine the top-level categories:
     ```julia
     Main.app.state.data_selection
     Main.app.state.plotting.format
     Main.app.state.plotting.handles
     Main.app.state.misc
     ```

### Steps

1. **Gather information** from the screenshot and/or the live state (whichever are available). Use both when possible — the screenshot shows the visual result, the state gives exact values.
   > **Note**: Reference screenshots may have been taken manually and can include macOS window chrome (title bar, traffic-light buttons). The generator must always use `frame=false` (as enforced by `capture_gui_screenshot`), so ignore the window frame when writing the spec — focus only on the GUI content inside it.

2. **Reverse-engineer the reproduction steps** from the gathered information. Once you have the target values from `Main.app.state`, map them to the corresponding UI interactions.
   
   > [!WARNING]
   > **Never update observables directly** (e.g., `app.state.plotting.handles.xlabel_text[] = "X"`). This bypasses the reactive callbacks (`do_replot`, `block_format_update`, etc.) and causes the UI to break or reset.
   
   Instead, you must use the DOM interaction helpers from `gui_testing_utils.jl` to simulate real user behavior:
   - For dropdowns (e.g., changing `selected_plottype`), use `select_dropdown_value(...)`.
   - For text fields (e.g., changing `xlabel_text`), use `set_input_value(...)`.
   - For checkboxes (e.g., changing `show_legend`), use `toggle_checkbox(...)`.
   
   Cross-reference the state docstrings mentioned in **Understanding the Application State** to learn which observable maps to which DOM interaction.

3. **Ask the user if** you cannot determine the data source or a specific step from the screenshot and state alone (e.g., a custom DataFrame not created by `@populate`, an obscure file import, or non-obvious UI state hidden behind a tab).

4. **Write the spec** following the template below.

---

## Template

````markdown
# <name>.png

## 1. Overview & Purpose
One-sentence description of what this screenshot demonstrates.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable(s):
  - `variable_name`: Description and shape/type.
  - (If a custom DataFrame is needed, include the Julia code to create it.)

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Configuration
1. Open the application.
2. (Tab navigation, source type selection, dropdown selections, column checks, range settings, (Re-)Plot click)

### B. Format Configuration (if applicable)
1. (Plot type, theme, group-by, legend, labels, limits)

### C. Additional Actions (if applicable)
1. (Maximize window, navigate to Save tab, enter file path, etc.)

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: ...
- (All visible dropdown values, checkbox states, text field contents)

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal / Maximized / Minimized
- **Plot Type**: ...
- **Theme**: ...
- **Title**: ...
- **X-Axis**: label, tick values
- **Y-Axis**: label, tick values
- **Plotted Data**: describe series, colors, shapes
- **Legend**: position, entries

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: ...`
- **Displayed Columns**: column names with header background colors (Gray=Index, Green=numeric, Blue=Unitful, Yellow=string/mixed)
- **Visible Rows**: row count and key data values

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared
> content-wise with the original screenshot
> ([`<name>.png`](../../../../docs/src/Screenshots/<name>.png))
> using the `view_file` tool. If the generated image differs substantially in any
> of the criteria below, the task is **not done**.

To verify if another screenshot matches this configuration:
1. (3–5 bullet points covering the most important visual elements)
````

---

## Existing Specs

Specifications already exist for all current screenshots and are located in `test/AgenticTesting/screenshots/specifications/`. Before creating a new spec, always check if one already exists for the target screenshot.
