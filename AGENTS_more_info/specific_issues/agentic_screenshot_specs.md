# Creating Screenshot Specification Files

This document describes how to create a per-screenshot specification file for `CasualPlots.jl`. These specs serve as the single source of truth for both the generator code and the verification step.

For the overall screenshot reproduction workflow (running generators, interaction toolkit, synchronisation, verification protocol), see [Agentic Screenshots](agentic_screenshots.md).

---

## Location & Naming

Each spec lives in its own subdirectory:
```
docs/src/Screenshots/specifications/<name>/<name>.md
```
where `<name>` matches the screenshot filename without the `.png` extension (e.g., `format_tab_barplot_dodged`).

---

## How to Create a Spec

### Information Sources

There are two complementary ways to gather the information needed for a spec:

1. **Inspect the reference screenshot** using `view_file` on `docs/src/Screenshots/<name>.png`. Extract every visible detail: active tab, dropdown values, checkbox states, plot type, axis labels/ticks, title, legend, theme, table headers and data.

2. **Query the live GUI state** (when available). If the user has the GUI open and `Main.app` is accessible via Kaimon, you can read the exact observable values programmatically. This is more reliable than reverse-engineering from pixels alone. Key queries:
   ```julia
   # Data selection state
   Main.app.state.data_selection.source_type[]           # "X, Y Arrays" or "DataFrame"
   Main.app.state.data_selection.selected_dataframe[]     # e.g. "caspl_df_exp"
   Main.app.state.data_selection.selected_columns[]       # Vector of checked column names
   Main.app.state.data_selection.selected_x[]             # X variable name (array mode)
   Main.app.state.data_selection.selected_y[]             # Y variable name (array mode)
   Main.app.state.data_selection.range_from[]             # Range start
   Main.app.state.data_selection.range_to[]               # Range end

   # Plot format state
   Main.app.state.plotting.format.selected_plottype[]     # "Scatter", "Lines", "BarPlot"
   Main.app.state.plotting.format.selected_theme[]        # e.g. "theme_ggplot2"
   Main.app.state.plotting.format.show_legend[]           # true/false
   Main.app.state.plotting.format.dynamic_attributes      # Dict of plot-type-specific options

   # Labels & titles
   Main.app.state.plotting.handles.xlabel_text[]
   Main.app.state.plotting.handles.ylabel_text[]
   Main.app.state.plotting.handles.title_text[]
   Main.app.state.plotting.handles.legend_title_text[]

   # Axis limits
   Main.app.state.plotting.format.x_min[]
   Main.app.state.plotting.format.x_max[]
   Main.app.state.plotting.format.y_min[]
   Main.app.state.plotting.format.y_max[]
   Main.app.state.plotting.format.xreversed[]
   Main.app.state.plotting.format.yreversed[]
   ```
   Use `fieldnames(typeof(Main.app.state.data_selection))` etc. to discover additional observables.

### Steps

1. **Gather information** from the screenshot and/or the live state (whichever are available). Use both when possible — the screenshot shows the visual result, the state gives exact values.
   > **Note**: Reference screenshots may have been taken manually and can include macOS window chrome (title bar, traffic-light buttons). The generator must always use `frame=false` (as enforced by `capture_gui_screenshot`), so ignore the window frame when writing the spec — focus only on the GUI content inside it.
2. **Reverse-engineer the reproduction steps** from the gathered information. The CasualPlots UI is straightforward — the active tab, selected dropdowns, and data content directly tell you how to reproduce the state. Cross-reference with `AGENTS.md` and `app_state.jl` for observable names if needed.
3. **Ask the user only if** the data source or a specific step cannot be determined from the screenshot and state alone (e.g., a custom DataFrame not created by `@populate`, an obscure file import, or non-obvious UI state hidden behind a tab).
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
> ([`<name>.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/<name>.png))
> using the `view_file` tool. If the generated image differs substantially in any
> of the criteria below, the task is **not done**.

To verify if another screenshot matches this configuration:
1. (3–5 bullet points covering the most important visual elements)
````

---

## Existing Specs

Specifications already exist for all current screenshots and are located in `docs/src/Screenshots/specifications/`. Before creating a new spec, always check if one already exists for the target screenshot.
