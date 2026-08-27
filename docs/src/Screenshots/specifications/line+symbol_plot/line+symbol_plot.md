# line+symbol_plot.png

## 1. Overview & Purpose
Demonstrates the **Format** tab configured for a **Line+Symbol** plot type, using the `theme_ggplot2` theme, with custom axis labels, plot title, and legend title, showing two series from the `caspl_df_simple` demo DataFrame.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_simple`: 10-row DataFrame with columns `x` (Int64: 1–10), `y1` (Int64: x²), `y2` (Float64: x^1.5).

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Tab Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_simple` from the **Select Source:** dropdown.
4. Check columns: `x`, `y1`, `y2` (all three columns — use **Select All**).
5. Range: `1` to `10` (default for this 10-row DataFrame).
6. Click **(Re-)Plot**.

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Set **Plot type:** to `Line+Symbol` (`#dropdown-plottype`).
3. Set **Show group by:** to `Color` (`#dropdown-group_by`).
4. Set **Theme:** to `theme_ggplot2` (`#dropdown-theme`).
5. Ensure **Show Legend** is checked; in the legend title field, enter `two functions`.
6. In the **X-Axis:** field, enter `argument`.
7. In the **Y-Axis:** field, enter `functions`.
8. In the **Title:** field, enter `Combined plot of two functions`.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `Line+Symbol`
- **Show group by:** `Color`
- **Theme:** `theme_ggplot2`
- **Show Legend**: Checked, legend title: `two functions`
- **X-Axis:** `argument`
- **Y-Axis:** `functions`
- **Title:** `Combined plot of two functions`
- **X from:** `0` **to:** `10`, **rev.:** unchecked
- **Y from:** `0` **to:** `100`, **rev.:** unchecked

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Background**: Light gray ggplot2 theme with white grid lines.
- **Plot Title**: `Combined plot of two functions` (centered, bold)
- **X-Axis**: `argument` (ticks at `0`, `5`, `10`)
- **Y-Axis**: `functions` (ticks at `0`, `50`, `100`)
- **Plotted Data**:
  - **Series 1 (`y1`)**: Blue line with circle markers — quadratic curve ($y = x^2$), rising steeply from $(1, 1)$ to $(10, 100)$.
  - **Series 2 (`y2`)**: Orange line with circle markers — power curve ($y = x^{1.5}$), rising gently from $(1, 1)$ to $(10, \approx31.6)$.
- **Legend**:
  - Right side, title **two functions** (bold).
  - Blue line+marker: `y1`
  - Orange line+marker: `y2`

### Table Pane (Bottom-Right Floating Window)
- **Window State**: Minimized (header bar visible, body hidden).
- **Header Bar Title**: `SOURCE: caspl_df_simple`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`line+symbol_plot.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/line+symbol_plot.png)) using the `view_file` tool. If the generated image differs substantially in any of the criteria below, the task is **not done**.

To verify if another screenshot matches this configuration:
1. **Plot Type**: Line+Symbol plot with both lines and circle markers visible on each series.
2. **Two Series**: Blue (`y1`, quadratic) and orange (`y2`, power) curves with markers, fanning out from bottom-left to upper-right.
3. **Theme & Labels**: ggplot2 theme (gray background, white grid); title is `Combined plot of two functions`; X-axis is `argument`; Y-axis is `functions`; legend title is `two functions`.
4. **Format Controls**: Active tab is `Format`; dropdowns show `Line+Symbol`, `Color`, `theme_ggplot2`.
5. **Table Pane**: Minimized, header shows `SOURCE: caspl_df_simple`.
