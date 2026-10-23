# xy_source_selection_unplotted.png

## 1. Overview & Purpose
Demonstrates the **Source** tab in **X, Y Arrays** mode when selecting array variables `caspl_x_10` for X and matrix `caspl_ys10` for Y with range set from 1 to 10, showing the populated Data Table **before** plotting (Plot Pane in initial blank state).

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
8. Do **not** click the `(Re-)Plot` button (leave Plot Pane unplotted).

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Source`
- **Radio Buttons**: `X, Y Arrays` (checked), `File/DataFrame/Matrix` (unchecked)
- **Select X:** `caspl_x_10`
- **Select Y:** `caspl_ys10`
- **Range from:** `1`
- **Range to:** `10`
- **(Re-)Plot Button**: Visible and enabled (green button)

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view (not maximized, not minimized).
- **Header Bar Title**: `Plot` with minimize, refresh, and maximize icons.
- **Content**: Blank unplotted state with placeholder text `Plot Pane` in the upper-left corner. No Makie axes, figure, or plotted elements.

### Table Pane (Bottom-Right Floating Window)
- **Window State**: Normal split view.
- **Header Bar Title**: `SOURCE: caspl_ys10 vs caspl_x_10`
- **Displayed Columns**:
  - `Index` (gray header background)
  - `caspl_x_10` (light green header background - integer numeric)
  - `caspl_ys10_1` (light green header background - float numeric)
  - `caspl_ys10_2` (light green header background - float numeric)
- **Visible Rows**: Rows 1 to 6 visible:
  - Row 1: Index `1`, caspl_x_10 `1`, caspl_ys10_1 `1`, caspl_ys10_2 `1`
  - Row 2: Index `2`, caspl_x_10 `2`, caspl_ys10_1 `4`, caspl_ys10_2 `2.8284`
  - Row 3: Index `3`, caspl_x_10 `3`, caspl_ys10_1 `9`, caspl_ys10_2 `5.1962`
  - Row 4: Index `4`, caspl_x_10 `4`, caspl_ys10_1 `16`, caspl_ys10_2 `8`
  - Row 5: Index `5`, caspl_x_10 `5`, caspl_ys10_1 `25`, caspl_ys10_2 `11.18`
  - Row 6: Index `6`, caspl_x_10 `6`, caspl_ys10_1 `36`, caspl_ys10_2 `14.697`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared
> with the original screenshot ([`xy_source_selection_unplotted.png`](../../../../docs/src/Screenshots/xy_source_selection_unplotted.png)).
> First check `compare_images_ssim(ref, gen; crop=true)`. If the score is **1.0**, the visual criteria are fully satisfied and no further manual semantic analysis is needed.
> If the score is below 1.0, compare content using the `view_file` tool. If the generated image differs substantially in any
> of the criteria below, the task is **not done**.

To verify if another screenshot matches this configuration:
1. **Source Tab**: "X, Y Arrays" radio button is checked with `caspl_x_10` and `caspl_ys10` selected; "Range from:" is 1 and "Range to:" is 10.
2. **Plot Pane**: Unplotted placeholder state displaying `Plot Pane` in the top left, with no Makie canvas or axes.
3. **Table Header**: Exactly matches `SOURCE: caspl_ys10 vs caspl_x_10`.
4. **Table Columns & Content**: Contains `Index` (gray), `caspl_x_10` (green), `caspl_ys10_1` (green), `caspl_ys10_2` (green), with row 1 starting at index 1 and visible values matching the specified data.

