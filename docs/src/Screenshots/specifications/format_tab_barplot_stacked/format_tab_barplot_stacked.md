# format_tab_barplot_stacked.png

## 1. Overview & Purpose
Demonstrates the **Format** tab configured for a **BarPlot** with categorical data in **Horizontal Stacked** mode, using `theme_ggplot2`, custom axis labels, and custom plot title (`Students scores`).

---

## 2. Prerequisites & Environment Setup
- Inject a custom DataFrame into `Main`:
  ```julia
  using DataFrames
  SampleScores = DataFrame(
      Name = ["Ann", "Bob", "Charlie", "Dennis"],
      Symbol("Score 1") => [9.0, 7.8, 7.1, 14.6],
      Symbol("Score 2") => [8.8, 12.0, 15.2, 5.3]
  )
  ```

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Tab Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `SampleScores` from the **Select Source:** dropdown.
4. Check columns: `Name` (categorical axis), `Score 1`, `Score 2`.
5. Click **(Re-)Plot**.

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Set **Plot type:** to `BarPlot` (`#dropdown-plot-type`).
3. Set **Bar direction:** to `Horizontal` (`#dropdown-barplot-direction`).
4. Set **Mode:** to `Stacked` (`#dropdown-barplot-mode`).
5. Set **Theme:** to `theme_ggplot2` (`#dropdown-theme`).
6. Set **Show group by:** to `Color`.
7. Ensure **Show Legend** is checked (title empty).
8. In the **X-Axis:** input field, enter `Name`.
9. In the **Y-Axis:** input field, enter `Score`.
10. In the **Title:** input field, enter `Students scores`.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `BarPlot`
- **Bar direction:** `Horizontal`
- **Mode:** `Stacked`
- **Theme:** `theme_ggplot2`
- **Show group by:** `Color`
- **Show Legend**: Checked (empty title)
- **X-Axis:** `Name`
- **Y-Axis:** `Score`
- **Title:** `Students scores`
- **Limits**: Placeholders visible, `rev.:` unchecked

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Background**: Light gray ggplot2 theme with white gridlines.
- **Plot Title**: `Students scores` (centered)
- **Vertical Axis**: Categorical ticks from bottom to top: `Ann`, `Bob`, `Charlie`, `Dennis`. Axis label at left is `Score`.
- **Horizontal Axis**: Numerical ticks at `0`, `5`, `10`, `15`, `20`. Axis label at bottom is `SampleScores`.
- **Plotted Bars**:
  - Horizontal composite bars with blue (`Score 1`) segment on the left and orange (`Score 2`) segment stacked to its right:
    - **Ann**: Blue segment $[0, 9.0]$, Orange segment $[9.0, 17.8]$ (Total = 17.8)
    - **Bob**: Blue segment $[0, 7.8]$, Orange segment $[7.8, 19.8]$ (Total = 19.8)
    - **Charlie**: Blue segment $[0, 7.1]$, Orange segment $[7.1, 22.3]$ (Total = 22.3)
    - **Dennis**: Blue segment $[0, 14.6]$, Orange segment $[14.6, 19.9]$ (Total = 19.9)
- **Legend**:
  - Right side with blue square (`Score 1`) and orange square (`Score 2`).

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: SampleScores`
- **Displayed Columns**:
  - `Index` (gray header)
  - `Name` (yellow header)
  - `Score 1` (green header)
  - `Score 2` (green header)
- **Rows**: Rows 1 to 4 visible (Ann, Bob, Charlie, Dennis).

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`format_tab_barplot_stacked.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/format_tab_barplot_stacked.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Format Tab Active**: `BarPlot`, `Horizontal`, `Stacked`, `theme_ggplot2` selected.
2. **Plot Layout**: Horizontal stacked bars with ggplot2 gray background.
3. **Bar Stacking**: Blue segment on left, orange segment on right; Charlie has the longest total bar ($22.3$).
4. **Table**: Matches `SOURCE: SampleScores` table.
