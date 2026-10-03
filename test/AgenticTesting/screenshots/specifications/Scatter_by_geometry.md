# Scatter_by_geometry.png

## 1. Overview & Purpose
Demonstrates a basic **Scatter** plot with geometry-based grouping. Two columns (`y1` and `y2`) are plotted against `x` from `caspl_df_simple`. Instead of differentiating the series by color, they are differentiated by marker shape (Geometry).

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate()` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_simple`: 10-row DataFrame containing columns `x`, `y1`, `y2`.

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Tab Configuration
1. Open the application.
2. In the **Source** tab, select **File/DataFrame** mode.
3. Select `caspl_df_simple` from the **Select Source:** dropdown.
4. Check columns: `x` (as X), `y1`, `y2`.
5. Click **(Re-)Plot**.

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Set **Plot type:** to `Scatter` (`#dropdown-plot-type`).
3. Set **Theme:** to `Makie default` (`#dropdown-theme`).
4. Set **Show group by:** to `Geometry` (`#dropdown-group-by`).
5. Ensure **Show Legend** checkbox is checked, and legend title input is empty.
6. In the **X-Axis:** input field, enter `X`.
7. In the **Y-Axis:** input field, enter `Y`.
8. In the **Title:** input field, enter `Y vs X`.
9. Axis limits remain at default/unconstrained.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `Scatter`
- **Show group by:** `Geometry`
- **Theme:** `Makie default`
- **Show Legend**: Checked; input text: `Legend Title` (placeholder text, no value)
- **X-Axis:** `X`
- **Y-Axis:** `Y`
- **Title:** `Y vs X`
- **X lim:** `0.55` (placeholder) – `10.45` (placeholder) | **log:** Unchecked | **rev.:** Unchecked
- **Y lim:** `-3.95` (placeholder) – `104.95` (placeholder) | **log:** Unchecked | **rev.:** Unchecked

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Background**: Standard Makie white background with light gray grid lines.
- **Plot Title**: `Y vs X`
- **X-Axis Title**: `X` (ticks at 2, 4, 6, 8, 10)
- **Y-Axis Title**: `Y` (ticks at 0, 50, 100)
- **Plotted Markers**:
  - All markers are black (due to `Geometry` grouping):
    - **Circle (`•`)**: `y1` ($y = x^2$)
    - **Triangle (`▲`)**: `y2` ($y = x^{1.5}$)
- **Legend**:
  - Positioned on the right side with no title.
  - Circle marker: `y1`
  - Triangle marker: `y2`

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: caspl_df_simple`
- **Displayed Columns & Types**:
  - `Index` (gray header)
  - `x` (light green header - integer)
  - `y1` (light green header - integer)
  - `y2` (light green header - float)
- **Sample Cell Values**:
  - Row 1: Index `1`, x `1`, y1 `1`, y2 `1.0`
  - Row 2: Index `2`, x `2`, y1 `4`, y2 `2.8284`
  - Row 5: Index `5`, x `5`, y1 `25`, y2 `11.18`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`Scatter_by_geometry.png`](../../../../docs/src/Screenshots/Scatter_by_geometry.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Format Tab Active**: Tab is `Format`, Plot type is `Scatter`, Theme is `Makie default`, Group by is `Geometry`.
2. **Custom Labels**: X title is `X`, Y title is `Y`, Plot title is `Y vs X`.
3. **Geometry/Markers**: All markers are black. `y1` uses circles (`•`), `y2` uses triangles (`▲`).
4. **Table Header Colors**: `x` and `y1` headers are light green, `y2` header is also light green (numeric).
