# dataframe_source_selection.png

## 1. Overview & Purpose
Demonstrates the **Source** tab in **File/DataFrame** mode, selecting the multi-column dataset `caspl_df_exp`, toggling specific column checkboxes (every third column: `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18`), constraining row index range from 20 to 90, and plotting the resulting data subset as a Scatter plot.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_exp`: 100-row DataFrame with column `x` (from 0.0 to 10.0) and columns `y1` through `y19` created by `make_y(xs, 19)`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Navigation & Source Configuration
1. Open the application.
2. Navigate to the **Source** tab.
3. Under **Source Type**, select the **File/DataFrame** radio button.
4. Select `caspl_df_exp` in the **Select Source:** dropdown (`#dropdown-dataframe`).
5. Click **Deselect All** button to clear default selections.
6. Check column `x` (serves as X-axis).
7. Check columns: `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18`.
8. Set **Range from:** to `20`.
9. Set **Range to:** to `90`.
10. Click the **(Re-)Plot** button (`.btn-replot`).

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Source`
- **Radio Buttons**: `X, Y Arrays` (unchecked), `File/DataFrame` (checked)
- **Select Source:** `caspl_df_exp`
- **Buttons**: `Select All`, `Deselect All` visible
- **Column Checkboxes**:
  - `x`: Checked
  - `y1`: Checked
  - `y2`, `y3`: Unchecked
  - `y4`: Checked
  - `y5`: Unchecked
  -  `y6`, `y7`: Checked
  - `y8`: Unchecked
  - (and scrolling further down: `y9`, `y12`, `y15`, `y18` checked)
- **Range from:** `20`
- **Range to:** `90`
- **(Re-)Plot Button**: Green button visible and enabled

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Plot Type**: `Scatter` (default)
- **Theme**: `Makie default` (white background)
- **Plot Title**: `Scatter Plot of caspl_df_exp vs x`
- **X-Axis Title**: `x` (ticks at 2.5, 5.0, 7.5; range ≈ 1.9 to 9.0)
- **Y-Axis Title**: `caspl_df_exp` (ticks at 2.5, 5.0, 7.5, 10.0, 12.5)
- **Plotted Data**:
  - 7 scatter point curves corresponding to indices 20 through 90:
    - `y1` (blue dots, lowest slope, up to ~1.2 at x=9)
    - `y4` (orange dots)
    - `y7` (green dots)
    - `y9` (pink dots)
    - `y12` (cyan dots)
    - `y15` (brown/red dots)
    - `y18` (yellow dots, highest slope, up to ~12.5 at x=9)
- **Legend**:
  - Positioned on the right side.
  - Entries: `y1` (blue), `y4` (orange), `y7` (green), `y9` (pink), `y12` (cyan), `y15` (brown), `y18` (yellow).

### Table Pane (Bottom-Right Floating Window)
- **Window State**: Normal split view.
- **Header Bar Title**: `SOURCE: caspl_df_exp [20:90]`
- **Displayed Columns**:
  - `Index` (gray header)
  - `x` (light green header)
  - `y1` (light green header)
  - `y4` (light green header)
  - `y7` (light green header)
  - `y9` (light green header)
  - `y12` (light green header)
  - `y15` (light green header)
  - `y18` (light green header)
- **Visible Rows**: Indices 20 to 25 visible (row indices start at 20).

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`dataframe_source_selection.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/dataframe_source_selection.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Source Tab**: "File/DataFrame" radio button selected with `caspl_df_exp` chosen; "Range from:" is 20 and "Range to:" is 90.
2. **Table Header**: Shows `SOURCE: caspl_df_exp [20:90]`.
3. **Table Columns**: Contains `Index`, `x`, `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18`.
4. **Plot Legend**: 7 entries (`y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18`).
5. **Plot Points**: Scatter curves originating at $x \approx 1.91$ ($Index = 20$).
