# table_view.png

## 1. Overview & Purpose
Demonstrates the **Maximized Data Table Pane** view, showcasing dynamic column header coloring based on Julia data types (Numeric = Green, Unitful = Blue, String/Mixed/Missing = Yellow) and displaying the full 25 rows of `caspl_df_unitmix`.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_unitmix`: 25-row DataFrame containing columns `index`, `area` (Unitful `mm²`), `linear` (Unitful `mm`), `unimix`, `unimiss` (contains missing and string values), `areacm`, `areammcm`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_unitmix` from the **Select Source:** dropdown.
4. Check columns: `index` (as X), `area`, `linear`, `unimiss`.
5. Click **(Re-)Plot**.

### B. Maximizing the Table Window
1. Locate the window controls at the top right of the **Table Pane** header.
2. Click the **Maximize** button (the square expand icon `.floating-window-maximize`).
3. The Table Pane expands to fill the entire application workspace, showing all 25 rows.

---

## 4. UI State & Values

### Window & Panes State
- **Control Panel**: Hidden (covered by maximized table pane).
- **Plot Pane**: Hidden (covered by maximized table pane).
- **Table Pane**: **Maximized** (occupies the full application window).
- **Header Bar**: Displays `SOURCE: caspl_df_unitmix` on the left and window controls (Minimize, Restore/Reload, Maximize) on the top right.

### Table Content & Column Header Styling
- **Total Rows Displayed**: All 25 rows (indices 1 to 25).
- **Columns**:
  1. `Index`: Gray header background.
  2. `index`: **Light Green** header background (standard numeric integer). Values `1` to `25`.
  3. `area`: **Light Blue** header background (Unitful quantity `mm²`). Values `1.1 mm²` to `27.5 mm²`.
  4. `linear`: **Light Blue** header background (Unitful quantity `mm`). Values `0.90909090909091 mm` to `22.7272727272727 mm`.
  5. `unimiss`: **Light Yellow** header background (Mixed/Union type containing missing, strings, and quantities).
     - Row 4 shows `n/a` (missing value).
     - Row 5 shows `Missis` (string value).
     - All other rows show quantities `1 mm²` to `25 mm²`.

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`table_view.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/table_view.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Full-Screen Table**: The Table pane occupies the entire screen; no sidebar or plot is visible.
2. **Header Title**: Shows `SOURCE: caspl_df_unitmix`.
3. **Distinct Header Colors**:
   - `index` is Green.
   - `area` and `linear` are Blue.
   - `unimiss` is Yellow.
4. **All 25 Rows Visible**: Table displays rows 1 through 25 with row 4 showing `n/a` and row 5 showing `Missis`.
