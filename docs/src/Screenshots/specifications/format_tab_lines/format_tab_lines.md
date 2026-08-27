# format_tab_lines.png

## 1. Overview & Purpose
Demonstrates the **Format** tab configured for a **Lines** plot with custom formatting options: `theme_ggplot2`, geometry-based grouping (different linestyles rather than colors), custom axis titles, custom legend title (`Some Legend`), and manual X-axis limits (from `-5` to `30`). It also showcases plotting `Unitful` and mixed-type data from `caspl_df_unitmix`.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_unitmix`: 25-row DataFrame containing columns `index`, `area` (Unitful `mm²`), `linear` (Unitful `mm`), `unimix`, `unimiss` (contains missing and string values), `areacm`, `areammcm`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Tab Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_unitmix` from the **Select Source:** dropdown.
4. Check columns: `index` (as X), `area`, `linear`, `unimiss`.
5. Click **(Re-)Plot**.

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Set **Plot type:** to `Lines` (`#dropdown-plot-type`).
3. Set **Theme:** to `theme_ggplot2` (`#dropdown-theme`).
4. Set **Show group by:** to `Geometry` (`#dropdown-group-by`).
5. Ensure **Show Legend** checkbox is checked.
6. In the legend title input field next to "Show Legend", enter `Some Legend`.
7. In the **X-Axis:** input field, enter `Custom X axis title`.
8. In the **Y-Axis:** input field, enter `Custom Y title`.
9. The **Title:** field displays `Lines Plot of caspl_df_unitmix vs index`.
10. In the **X from:** input field, enter `-5`.
11. In the **to:** input field for X, enter `30`.
12. Leave **rev.:** unchecked for both X and Y.
13. Leave Y limits as default/unconstrained.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `Lines`
- **Theme:** `theme_ggplot2`
- **Show group by:** `Geometry`
- **Show Legend**: Checked; input text: `Some Legend`
- **X-Axis:** `Custom X axis title`
- **Y-Axis:** `Custom Y title`
- **Title:** `Lines Plot of caspl_df_unitmix vs index`
- **X from:** `-5` | **to:** `30` | **rev.:** Unchecked
- **Y from:** `-0.42` (placeholder) | **to:** `28.83` (placeholder) | **rev.:** Unchecked

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Background**: Light gray ggplot2-style background with solid white grid lines.
- **Plot Title**: `Lines Plot of caspl_df_unitmix vs index`
- **X-Axis Title**: `Custom X axis title` (ticks at -5, 0, 5, 10, 15, 20, 25, 30)
- **Y-Axis Title**: `Custom Y title` (ticks at 0, 10, 20)
- **Plotted Lines**:
  - All lines are black (due to `Geometry` grouping):
    - **Solid line**: `area` ($y = 1.1x$), continuous from $x=1$ to $x=25$.
    - **Dashed line**: `linear` ($y = x / 1.1$), continuous from $x=1$ to $x=25$.
    - **Dotted line**: `unimiss`, plotted with a gap between $x=3$ and $x=6$ due to missing data (`missing` at row 4, string `"Missis"` at row 5).
- **Legend**:
  - Positioned on the right side with title **Some Legend**.
  - Solid line: `area`
  - Dashed line: `linear`
  - Dotted line: `unimiss`

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: caspl_df_unitmix`
- **Displayed Columns & Types**:
  - `Index` (gray header)
  - `index` (light green header - integer)
  - `area` (light blue header - Unitful `mm²`)
  - `linear` (light blue header - Unitful `mm`)
  - `unimiss` (light yellow header - mixed/string/missing)
- **Sample Cell Values**:
  - Row 1: Index `1`, index `1`, area `1.1 mm²`, linear `0.90909090909091 mm`, unimiss `1 mm²`
  - Row 4: unimiss shows `n/a`
  - Row 5: unimiss shows `Missis`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`format_tab_lines.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/format_tab_lines.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Format Tab Active**: Tab is `Format`, Plot type is `Lines`, Theme is `theme_ggplot2`, Group by is `Geometry`.
2. **Custom Labels**: X title is `Custom X axis title`, Y title is `Custom Y title`, Legend title is `Some Legend`.
3. **Geometry/Linestyles**: All 3 lines are black with different linestyles (solid, dashed, dotted); dotted line has a visible gap around $x=4\text{–}5$.
4. **Axis Limits**: X-axis bounds are explicitly from `-5` to `30`.
5. **Table Header Colors**: `area` and `linear` headers are blue (Unitful), `unimiss` is yellow (mixed/string).
