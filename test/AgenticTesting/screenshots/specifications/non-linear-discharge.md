# non-linear-discharge.png

## 1. Overview & Purpose
Demonstrates a **Lines** plot for discharging onto a non-linear load using the `caspl_df_dissip` dataset. It showcases plotting multiple `Unitful` series (`U` in V and `I` in nA) on the same plot against `time` (in s), displaying a visible gap for missing data (missing `I` at row 37) and an anomaly spike (`U` at row 37), customized axis limits (lower bounds set to `0`), and customized axis and plot titles.

---

## 2. Prerequisites & Environment Setup
- Execute `CasualPlots.@populate` to inject standard demo data into `Main`.
- Required variable:
  - `caspl_df_dissip`: 121-row DataFrame containing columns `time` (Unitful `s`), `U` (Unitful `V`), `I` (Unitful `nA` with simulated noise), `remarks` (String/Missing).

---

## 3. Step-by-Step UI Reproduction Sequence

### A. Source Tab Configuration
1. Open the application.
2. In the **Source** tab, select **DataFrame** mode (`input[name="source_type"][value="DataFrame"]`).
3. Select `caspl_df_dissip` from the **Select Source:** dropdown (`#dropdown-dataframe`).
4. Deselect all columns, then check columns `time` (as X), `U`, `I`.
5. Click **(Re-)Plot** (`#btn-replot`).

### B. Format Tab Customization
1. Navigate to the **Format** tab.
2. Ensure **Plot type:** is set to `Lines` (`#dropdown-plottype`).
3. Ensure **Show group by:** is set to `Color` (`#dropdown-group_by`).
4. Ensure **Theme:** is set to `Makie default` (`#dropdown-theme`).
5. Ensure **Show Legend** checkbox is checked (`#checkbox-show_legend`).
6. Set **X-Axis:** input field to `time [s]` (`#input-xlabel`).
7. Set **Y-Axis:** input field to `U[V], I[nA]` (`#input-ylabel`).
8. Set **Title:** input field to `Discharge onto non-linear load` (`#input-title`).
9. Set **X lim:** lower bound input field to `0` (`#axis-x-min-input`).
10. Set **Y lim:** lower bound input field to `0` (`#axis-y-min-input`).
11. Leave **log:** and **rev.:** unchecked for both X and Y axes.

---

## 4. UI State & Values

### Control Panel (Left Pane)
- **Active Tab**: `Format`
- **Plot type:** `Lines`
- **Show group by:** `Color`
- **Theme:** `Makie default`
- **Show Legend**: Checked; input text: empty (placeholder `Legend Title`)
- **X-Axis:** `time [s]`
- **Y-Axis:** `U[V], I[nA]`
- **Title:** `Discharge onto non-linear load`
- **X lim:** `0` – `1260` (placeholder) | **log:** Unchecked | **rev.:** Unchecked
- **Y lim:** `0` – `12.084` (placeholder) | **log:** Unchecked | **rev.:** Unchecked

### Plot Pane (Top-Right Floating Window)
- **Window State**: Normal split view.
- **Plot Title**: `Discharge onto non-linear load`
- **X-Axis Title**: `time [s]` (ticks at 0, 500, 1000)
- **Y-Axis Title**: `U[V], I[nA]` (ticks at 0, 5, 10)
- **Plotted Lines**:
  - **Blue line (`I`)**: starts around 11.5 at $t=0$, decreases with simulated noise fluctuations, has a visible gap at $t=360$, continues down to ~0.6–0.7 at $t=1200$.
  - **Orange line (`U`)**: starts around 3.1 at $t=0$, decreases smoothly, has a sharp upward spike at $t=360$, continues down to ~0.7 at $t=1200$.
- **Legend**:
  - Positioned on the right side in a bordered box.
  - Blue line: `I`
  - Orange line: `U`

### Table Pane (Bottom-Right Floating Window)
- **Header Bar Title**: `SOURCE: caspl_df_dissip`
- **Displayed Columns & Types**:
  - `Index` (gray header)
  - `time` (light blue header - Unitful `s`)
  - `U` (light blue header - Unitful `V`)
  - `I` (light blue header - Unitful `nA`)
- **Sample Cell Values**:
  - Row 1: Index `1`, time `0 s`, U `3.1 V`, I `11.538 nA`
  - Row 2: Index `2`, time `10 s`, U `3.0219 V`, I `11.036 nA`
  - Row 3: Index `3`, time `20 s`, U `2.9477 V`, I `10.401 nA`
  - Row 4: Index `4`, time `30 s`, U `2.877 V`, I `9.99 nA`
  - Row 5: Index `5`, time `40 s`, U `2.8097 V`, I `9.4149 nA`
  - Row 6: Index `6`, time `50 s`, U `2.7454 V`, I `9.1451 nA`

---

## 5. Key Visual Verification Criteria
> [!IMPORTANT]
> **Mandatory Comparison Requirement**: The produced PNG file must be compared content-wise with the original screenshot ([`non-linear-discharge.png`](../../../../docs/src/Screenshots/non-linear-discharge.png)). If the generated image differs substantially in any of the criteria below or overall visual appearance, the task is **not done** and the generator script must be adjusted and re-run.

To verify if another screenshot matches this configuration:
1. **Format Tab Active**: Tab is `Format`, Plot type is `Lines`, Theme is `Makie default`, Group by is `Color`.
2. **Custom Labels**: Title is `Discharge onto non-linear load`, X title is `time [s]`, Y title is `U[V], I[nA]`.
3. **Plotted Series & Anomalies**: Blue line (`I`) exhibits simulated noise fluctuations and has a visible gap at $t=360$; orange line (`U`) is smooth with a sharp upward spike at $t=360$.
4. **Axis Limits**: Lower bound is set to `0` for both X and Y axes (`X lim: 0`, `Y lim: 0`).
5. **Table Header Colors & Content**: Table source is `caspl_df_dissip` with columns `Index`, `time`, `U`, `I`; all 3 data headers are light blue (Unitful).

