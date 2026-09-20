# xy_source_selection.png

## 1. Overview & Purpose
Demonstrates the **Source** tab in **X, Y Arrays** mode, where independent 1D/2D array variables from `Main` are selected for the X and Y axes, plotted as a default scatter plot, and inspected in the Data Table pane.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variables:
  - `caspl_x_10 = 1:10`
  - `caspl_ys10 = hcat((1:10).^2, (1:10).^1.5)` (2-column matrix of size 10×2)

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Navigation & Source Configuration
1. Open the application.
2. Navigate to the **Source** tab (default active tab).
3. Under **Source Type**, select the **X, Y Arrays** radio button.
4. Select `caspl_x_10` in the **Select X:** dropdown (`#dropdown-x`).
5. Select `caspl_ys10` in the **Select Y:** dropdown (`#dropdown-y`).
6. Set **Range from:** to `1`.
7. Set **Range to:** to `10`.
8. Click the **(Re-)Plot** button (`.btn-replot`).

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Source`
- **Radio Buttons**: `X, Y Arrays` (checked), `File/DataFrame` (unchecked)
- **Select X:** `caspl_x_10`
- **Select Y:** `caspl_ys10`
- **Range from:** `1`
- **Range to:** `10`
- **(Re-)Plot Button**: Visible and enabled (green button)
- **Mouse Controls Help**: Visible at the bottom of the sidebar

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view (not maximized, not minimized).
- **Plot Type**: `Scatter` (default)
- **Theme**: `Makie default` (white background with subtle grid lines)
- **Plot Title**: `Scatter Plot of caspl_ys10 vs caspl_x_10`
- **X-Axis Title**: `caspl_x_10` (ticks at 2, 4, 6, 8, 10)
- **Y-Axis Title**: `caspl_ys10` (ticks at 0, 50, 100)
- **Plotted Data**:
  - Two series of 10 points each:
    - **Series 1 (`caspl_ys10_1`)**: Blue circles ($y = x^2$), starting at $(1, 1.0)$ up to $(10, 100.0)$.
    - **Series 2 (`caspl_ys10_2`)**: Orange circles ($y = x^{1.5}$), starting at $(1, 1.0)$ up to $(10, 31.62)$.
- **Legend**:
  - Positioned on the right side.
  - Blue marker: `caspl_ys10_1`
  - Orange marker: `caspl_ys10_2`

### Table Pane (Bottom-Right Floating Window)
- **Window State**: Normal split view.
- **Header Bar Title**: `SOURCE: caspl_ys10 vs caspl_x_10`
- **Displayed Columns**:
  - `Index` (gray header background)
  - `caspl_x_10` (light green header background - integer numeric)
  - `caspl_ys10_1` (light green header background - float numeric)
  - `caspl_ys10_2` (light green header background - float numeric)
- **Visible Rows**: Rows 1 to 6 visible:
  - Row 1: Index `1`, x `1`, y1 `1.0`, y2 `1.0`
  - Row 2: Index `2`, x `2`, y1 `4.0`, y2 `2.8284271247461903`
  - Row 3: Index `3`, x `3`, y1 `9.0`, y2 `5.196152422706632`
  - Row 4: Index `4`, x `4`, y1 `16.0`, y2 `8.0`
  - Row 5: Index `5`, x `5`, y1 `25.0`, y2 `11.180339887498949`
  - Row 6: Index `6`, x `6`, y1 `36.0`, y2 `14.696938456699069`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`xy_source_selection.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/xy_source_selection.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Source Tab**: "X, Y Arrays" radio button is checked with `caspl_x_10` and `caspl_ys10` selected.
2. **Plot Type**: Scatter plot with blue and orange dots.
3. **Plot Content**: Title is `Scatter Plot of caspl_ys10 vs caspl_x_10`; X-axis ranges from 1 to 10; Y-axis ranges from 0 to 100.
4. **Table Header**: Exactly matches `SOURCE: caspl_ys10 vs caspl_x_10` with 3 data columns (`caspl_x_10`, `caspl_ys10_1`, `caspl_ys10_2`) colored green.
