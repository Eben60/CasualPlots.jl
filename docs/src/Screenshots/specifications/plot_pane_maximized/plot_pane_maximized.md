# plot_pane_maximized.png

## 1. Overview & Purpose
Demonstrates the **Maximized Plot Pane** view where the Plot floating window expands to fill the entire application workspace, automatically resizing the Makie figure to high resolution while hiding the Control Panel and Table pane.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_exp`: 100-row DataFrame containing `x` and `y1` through `y19`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source & Format Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_exp` from the **Select Source:** dropdown.
4. Click **Select All** button (so `x` is X-axis and all 19 columns `y1` to `y19` are selected).
5. Click **(Re-)Plot**.
6. Navigate to the **Format** tab.
7. Select **Lines** in the **Plot type:** dropdown (`#dropdown-plot-type`).

### B. Maximizing the Plot Window
1. Locate the window controls at the top right of the **Plot Pane** header.
2. Click the **Maximize** button (the square expand icon `.floating-window-maximize`).
3. The Plot Pane expands to fill the full viewport ($1200 \times 960$), and the figure re-renders at the expanded aspect ratio.

---

## 4. UI State & Values

### Window & Panes State
- **Control Panel**: Hidden (covered by maximized plot pane).
- **Table Pane**: Hidden (covered by maximized plot pane).
- **Plot Pane**: **Maximized** (occupies the full application window).
- **Header Bar**: Displays `Plot` on the left and window controls (Minimize, Restore/Reload, Maximize) on the top right.

### Plot Content
- **Plot Type**: `Lines`
- **Theme**: `Makie default` (white background, standard thin grey grid lines).
- **Title**: `Lines Plot of caspl_df_exp vs x` (centered at the top of the plot).
- **X-Axis**: `x` with ticks at `0`, `5`, `10`.
- **Y-Axis**: `caspl_df_exp` with ticks at `0`, `5`, `10`, `15`.
- **Plotted Data**:
  - 19 distinct colored curves (`y1` through `y19`) intersecting near $(x=1, y=1)$ and fanning out upward to $x=10$, where $y$ ranges from $\approx 2.0$ (`y1`) to $\approx 16.0$ (`y19`).
- **Legend**:
  - Right side box listing all 19 line entries: `y1`, `y2`, `y3`, `y4`, `y5`, `y6`, `y7`, `y8`, `y9`, `y10`, `y11`, `y12`, `y13`, `y14`, `y15`, `y16`, `y17`, `y18`, `y19`.

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`plot_pane_maximized.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/plot_pane_maximized.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Full-Screen Plot**: No Control Panel or Data Table is visible; the Plot pane fills the entire window frame.
2. **19 Line Series**: 19 colored curves fanning out from $x=1$ up to $x=10$.
3. **Full Legend**: A tall legend on the right showing all 19 labels from `y1` to `y19`.
4. **Header**: Top-level header contains the `Plot` title and window control icons.
