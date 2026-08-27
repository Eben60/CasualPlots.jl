# save_tab_script.png

## 1. Overview & Purpose
Demonstrates the **Save** tab configured for Julia script generation, displaying the specified output path (`/Volumes/V2/tmp/Why-vs-Ex_script.jl`), the `Save Plot` and `Create Script` buttons, and a customized Lines plot using `theme_ggplot2` with custom labels (`Why vs Ex`).

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_exp`: 100-row DataFrame containing `x` and `y1` through `y19`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source & Plot Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_exp` from the **Select Source:** dropdown.
4. Click **Select All** to select all columns (`x` and `y1` through `y19`).
5. Click **(Re-)Plot**.

### B. Format Configuration
1. Navigate to the **Format** tab.
2. Set **Plot type:** to `Lines` (`#dropdown-plot-type`).
3. Set **Theme:** to `theme_ggplot2` (`#dropdown-theme`).
4. In the legend title field (next to "Show Legend"), enter `Column`.
5. In the **X-Axis:** field, enter `Ex`.
6. In the **Y-Axis:** field, enter `Why`.
7. In the **Title:** field, enter `Why vs Ex`.

### C. Save Tab Configuration
1. Navigate to the **Save** tab.
2. In the **File Path:** text area, enter `/Volumes/V2/tmp/Why-vs-Ex_script.jl`.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Save`
- **Buttons**:
  - `Select File...` button (blue)
  - `Save Plot` button (green)
  - `Create Script` button (blue)
- **File Path:** input box contains `/Volumes/V2/tmp/Why-vs-Ex_script.jl`

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Background**: Light gray ggplot2 theme with white grid lines.
- **Plot Title**: `Why vs Ex` (centered)
- **X-Axis**: `Ex` (ticks at `-3`, `0`, `3`, `6`, `9`)
- **Y-Axis**: `Why` (ticks at `-5`, `0`, `5`, `10`, `15`)
- **Plotted Data**:
  - 19 colored curves fanning out from $(0, 0)$ up to $x=10, y=16$.
- **Legend**:
  - Positioned on the right side with title **Column**.
  - 19 line entries: `y1`, `y2`, ..., `y19`.

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: caspl_df_exp`
- **Displayed Columns**:
  - `Index` (gray header)
  - `x` (green header)
  - `y1`, `y2`, `y3`, `y4`, `y5`, `y6` (green headers)
- **Visible Rows**: Indices 1 to 6.

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`save_tab_script.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/save_tab_script.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Save Tab Active**: Tab is `Save` with `Select File...`, `Save Plot`, and `Create Script` buttons visible.
2. **File Path**: Textarea displays `/Volumes/V2/tmp/Why-vs-Ex_script.jl`.
3. **Plot Theme & Labels**: Plot is `theme_ggplot2` (grey); title is `Why vs Ex`; X-axis is `Ex`; Y-axis is `Why`; legend title is `Column`.
4. **Table Header**: Shows `SOURCE: caspl_df_exp`.
