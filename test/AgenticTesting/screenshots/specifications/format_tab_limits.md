# format_tab_limits.png

## 1. Overview & Purpose
Demonstrates setting manual **Axis Limits** and enabling **Axis Reversal** in the **Format** tab, specifically setting `X lim: 2` – `15` and ticking the `rev.` checkbox to invert the horizontal axis direction. Controls also display the `log:` scale checkboxes, active for numeric data.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_large`: 101-row DataFrame with columns `time` ($0:0.1:10$), `sqrt_val`, `col1`, `col2`, `col3`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Tab Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_large` from the **Select Source:** dropdown.
4. Check columns: `time` (as X), `sqrt_val`, `col2`, `col3`.
5. Click **(Re-)Plot**.

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Confirm **Plot type:** is `Scatter` and **Theme:** is `Makie default`.
3. In the **X lim:** inputs, enter `2` for lower bound and `15` for upper bound (separated by an en-dash).
4. In the X row, leave **log:** unchecked, and check the **rev.:** checkbox to reverse the X-axis.
5. Leave Y limit fields as placeholder defaults, with **log:** and **rev.:** unchecked.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `Scatter`
- **Theme:** `Makie default`
- **Show group by:** `Color`
- **Show Legend**: Checked (empty title)
- **X-Axis:** `time`
- **Y-Axis:** `caspl_df_large`
- **Title:** `Scatter Plot of caspl_df_large vs time`
- **X lim:** `2` – `15` | **log:** Unchecked (enabled) | **rev.:** **Checked** (active blue checkmark, enabled)
- **Y lim:** `-0.251` (placeholder) – `5.262` (placeholder) | **log:** Unchecked (enabled) | **rev.:** Unchecked (enabled)

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Plot Title**: `Scatter Plot of caspl_df_large vs time`
- **X-Axis**: `time` with reversed ticks displaying `15` on the far left, `10` in the center, and `5` toward the right (visible range $[15, 2]$).
- **Y-Axis**: `caspl_df_large` with ticks at `0`, `2`, `4`.
- **Plotted Data**:
  - Three scatter series sloping downward toward the right due to X axis inversion:
    - **Orange (`col3`)**: Top curve (starting at $y \approx 5.26$ at $x=10$ on left, down to $y \approx 1.5$ at $x=2$ on right).
    - **Blue (`col2`)**: Middle curve (starting at $y \approx 4.0$ at $x=10$ on left, down to $y \approx 1.4$ at $x=2$ on right).
    - **Green (`sqrt_val`)**: Lower curve (starting at $y \approx 3.16$ at $x=10$ on left, down to $y \approx 1.4$ at $x=2$ on right).
  - Empty space on the left side between $x=15$ and $x=10$ because data only extends up to $x=10$.
- **Legend**:
  - Right side box with:
    - Blue dot: `col2`
    - Orange dot: `col3`
    - Green dot: `sqrt_val`

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: caspl_df_large`
- **Displayed Columns**:
  - `Index` (gray header)
  - `time` (green header)
  - `sqrt_val` (green header)
  - `col2` (green header)
  - `col3` (green header)
- **Visible Rows**: Indices 1 to 6.

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`format_tab_limits.png`](file:///Users/elk/Julia/1-Registered-Packages/CasualPlots.jl/docs/src/Screenshots/format_tab_limits.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Reversed X-Axis**: Horizontal axis values decrease from left to right ($15 \to 10 \to 5$), with empty space on the left $[15, 10]$.
2. **Format Tab Inputs**: `X lim: 2` – `15`, `log:` unchecked, with X `rev.` checkbox clearly checked. Both X and Y limits and scale checkboxes are enabled.
3. **Legend Order**: `col2` (blue), `col3` (orange), `sqrt_val` (green).
4. **Table Header**: Shows `SOURCE: caspl_df_large`.
