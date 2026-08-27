# format_tab_barplot_dodged.png

## 1. Overview & Purpose
Demonstrates the **Format** tab configured for a **BarPlot** with categorical X data in **Vertical Dodged** mode, using the dark theme `theme_black`, customized axis labels, and custom plot title (`Students scores`).

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
4. Check columns: `Name` (as categorical X-axis), `Score 1`, `Score 2`.
5. Click **(Re-)Plot**.

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Set **Plot type:** to `BarPlot` (`#dropdown-plot-type`).
3. Set **Bar direction:** to `Vertical` (`#dropdown-barplot-direction`).
4. Set **Mode:** to `Dodged` (`#dropdown-barplot-mode`).
5. Set **Theme:** to `theme_black` (`#dropdown-theme`).
6. Set **Show group by:** to `Color`.
7. Ensure **Show Legend** is checked (title field empty).
8. In the **X-Axis:** input field, enter `Name`.
9. In the **Y-Axis:** input field, enter `Score`.
10. In the **Title:** input field, enter `Students scores`.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `BarPlot`
- **Bar direction:** `Vertical`
- **Mode:** `Dodged`
- **Theme:** `theme_black`
- **Show group by:** `Color`
- **Show Legend**: Checked (no title entered)
- **X-Axis:** `Name`
- **Y-Axis:** `Score`
- **Title:** `Students scores` (active input field with cursor)
- **Limits**: All X/Y limit inputs empty/placeholders, `rev.:` unchecked

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Background**: Pure black theme with faint gray gridlines and white text.
- **Plot Title**: `Students scores` (white text, centered)
- **X-Axis**: `Name` with 4 categorical ticks: `Ann`, `Bob`, `Charlie`, `Dennis`.
- **Y-Axis**: `Score` with numerical ticks at `0`, `5`, `10`, `15`.
- **Plotted Bars**:
  - Side-by-side (dodged) vertical rectangles for each student:
    - **Ann**: Blue bar (`Score 1` = 9.0), Orange bar (`Score 2` = 8.8)
    - **Bob**: Blue bar (`Score 1` = 7.8), Orange bar (`Score 2` = 12.0)
    - **Charlie**: Blue bar (`Score 1` = 7.1), Orange bar (`Score 2` = 15.2)
    - **Dennis**: Blue bar (`Score 1` = 14.6), Orange bar (`Score 2` = 5.3)
- **Legend**:
  - Right side with dark background and white outline.
  - Blue square: `Score 1`
  - Orange square: `Score 2`

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: SampleScores`
- **Displayed Columns & Types**:
  - `Index` (gray header)
  - `Name` (light yellow header - string/categorical)
  - `Score 1` (light green header - float)
  - `Score 2` (light green header - float)
- **Rows**:
  - Row 1: Index `1`, Name `Ann`, Score 1 `9.0`, Score 2 `8.8`
  - Row 2: Index `2`, Name `Bob`, Score 1 `7.8`, Score 2 `12.0`
  - Row 3: Index `3`, Name `Charlie`, Score 1 `7.1`, Score 2 `15.2`
  - Row 4: Index `4`, Name `Dennis`, Score 1 `14.6`, Score 2 `5.3`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`format_tab_barplot_dodged.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/format_tab_barplot_dodged.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Theme**: Plot area is completely dark (`theme_black`) with white text and grid.
2. **Plot Type**: Vertical dodged bar plot with pairs of blue and orange bars for `Ann`, `Bob`, `Charlie`, `Dennis`.
3. **Format Controls**: Active tab is `Format`; dropdowns show `BarPlot`, `Vertical`, `Dodged`, `theme_black`.
4. **Table View**: Header `SOURCE: SampleScores` with `Name` column colored yellow and scores colored green.
