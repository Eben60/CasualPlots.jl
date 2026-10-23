# dataframe_source_selection_unplotted.png

## 1. Overview & Purpose
Demonstrates the **Source** tab in **File/DataFrame/Matrix** mode when a multi-column dataset (`caspl_df_exp`) is selected, specific columns (`x`, `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18`) are checked, and the row range is constrained from 20 to 90, showing the populated Data Table **before** plotting (Plot Pane in initial blank state).

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_exp`: 100-row DataFrame with column `x` (from 0.0 to 10.0) and columns `y1` through `y19` created by `make_y(xs, 19)`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Navigation & Source Configuration
1. Open the application.
2. Navigate to the **Source** tab (default active tab).
3. Under **Source Type**, select the **File/DataFrame/Matrix** radio button.
4. Select `caspl_df_exp` in the **Select Source:** dropdown (`#dropdown-dataframe`).
5. Click **Deselect All** button to clear default selections.
6. Check column `x`.
7. Check columns: `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18`.
8. Set **Range from:** to `20`.
9. Set **Range to:** to `90`.
10. Do **not** click the `(Re-)Plot` button (leave Plot Pane unplotted).

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Source`
- **Radio Buttons**: `X, Y Arrays` (unchecked), `File/DataFrame/Matrix` (checked)
- **Select Source:** `caspl_df_exp`
- **Buttons**: `Select All` (blue button), `Deselect All` (orange button) visible
- **Column Checkboxes**:
  - `x`: Checked
  - `y1`: Checked
  - `y2`, `y3`: Unchecked
  - `y4`: Checked
  - `y5`, `y6`: Unchecked
  - `y7`: Checked
  - `y8`: Unchecked
  - (scrolling further down: `y9`, `y12`, `y15`, `y18` checked; other `y` columns unchecked)
- **Range from:** `20`
- **Range to:** `90`
- **(Re-)Plot Button**: Green button visible and enabled

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view (not maximized, not minimized).
- **Header Bar Title**: `Plot` with minimize, refresh, and maximize icons.
- **Content**: Blank unplotted state with placeholder text `Plot Pane` in the upper-left corner. No Makie axes, figure, or plotted elements.

### Table Pane (Bottom-Right Floating Window)
- **Window State**: Normal split view.
- **Header Bar Title**: `SOURCE: caspl_df_exp [20:90]`
- **Displayed Columns**:
  - `Index` (gray header background)
  - `x` (light green header background - float numeric)
  - `y1` (light green header background - float numeric)
  - `y4` (light green header background - float numeric)
  - `y7` (light green header background - float numeric)
  - `y9` (light green header background - float numeric)
  - `y12` (light green header background - float numeric)
  - `y15` (light green header background - float numeric)
  - `y18` (light green header background - float numeric)
- **Visible Rows**: Rows 20 to 25 visible (row indices start at 20):
  - Row 1: Index `20`, x `1.9192`, y1 `1.1393`, y4 `1.27`, y7 `1.4158`, y9 `1.5221`, y12 `1.6968`, y15 `1.8916`, y18 `2.1087`
  - Row 2: Index `21`, x `2.0202`, y1 `1.151`, y4 `1.2941`, y7 `1.455`, y9 `1.5733`, y12 `1.7689`, y15 `1.9889`, y18 `2.2362`
  - Row 3: Index `22`, x `2.1212`, y1 `1.1623`, y4 `1.3175`, y7 `1.4934`, y9 `1.6235`, y12 `1.8403`, y15 `2.0861`, y18 `2.3646`
  - Row 4: Index `23`, x `2.2222`, y1 `1.1732`, y4 `1.3402`, y7 `1.5309`, y9 `1.673`, y12 `1.9111`, y15 `2.1831`, y18 `2.4939`
  - Row 5: Index `24`, x `2.3232`, y1 `1.1836`, y4 `1.3622`, y7 `1.5677`, y9 `1.7216`, y12 `1.9813`, y15 `2.2801`, y18 `2.6241`
  - Row 6: Index `25`, x `2.4242`, y1 `1.1938`, y4 `1.3836`, y7 `1.6036`, y9 `1.7694`, y12 `2.0509`, y15 `2.377`, y18 `2.755`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared
> with the original screenshot ([`dataframe_source_selection_unplotted.png`](../../../../docs/src/Screenshots/dataframe_source_selection_unplotted.png)).
> First check `compare_images_ssim(ref, gen; crop=true)`. If the score is **1.0**, the visual criteria are fully satisfied and no further manual semantic analysis is needed.
> If the score is below 1.0, compare content using the `view_file` tool. If the generated image differs substantially in any
> of the criteria below, the task is **not done**.

To verify if another screenshot matches this configuration:
1. **Source Tab**: "File/DataFrame/Matrix" radio button selected with `caspl_df_exp` chosen; "Range from:" is 20 and "Range to:" is 90; columns `x`, `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18` checked.
2. **Plot Pane**: Unplotted placeholder state displaying `Plot Pane` in the top left, with no Makie canvas or axes.
3. **Table Header**: Shows `SOURCE: caspl_df_exp [20:90]`.
4. **Table Columns & Content**: Contains `Index`, `x`, `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18` with light green headers, starting at index 20.

