# Stage 1 Verification Report for dataframe_source_selection

**Generated Image Evaluated:** `docs/src/Screenshots/tmp/dataframe_source_selection.png`  
**Specification File:** `docs/src/Screenshots/specifications/dataframe_source_selection/dataframe_source_selection.md`

## Verification Checklist

### Control Panel (Left Pane)

| Item | Spec Value | Screenshot Value | Match |
| :--- | :--- | :--- | :--- |
| **Active Tab** | `Source` | Source tab is active | true |
| **Radio Buttons** | `X, Y Arrays` (unchecked), `File/DataFrame` (checked) | `X, Y Arrays` (unchecked), `File/DataFrame/Matrix` (checked) | false (Minor string variation) |
| **Select Source** | `caspl_df_exp` | `caspl_df_exp` is selected | true |
| **Buttons** | `Select All`, `Deselect All` visible | Both buttons are visible | true |
| **Column Checkboxes** | `x`, `y1`, `y4`, **`y6`**, `y7`, `y9`, `y12`, `y15`, `y18` Checked | `x`, `y1`, `y4`, `y7`, `y9`, `y12`, `y15`, `y18` are Checked (**`y6` is unchecked**) | **false** |
| **Range from** | `20` | `20` | true |
| **Range to** | `90` | `90` | true |
| **(Re-)Plot Button** | Green button visible and enabled | Green button visible and enabled | true |

### Plot Pane (Top-Right Floating Window)

| Item | Spec Value | Screenshot Value | Match |
| :--- | :--- | :--- | :--- |
| **Window State** | Normal split view | Normal split view | true |
| **Plot Type** | `Scatter` (default) | `Scatter` | true |
| **Theme** | `Makie default` (white background) | White background | true |
| **Plot Title** | `Scatter Plot of caspl_df_exp vs x` | `Scatter Plot of caspl_df_exp vs x` | true |
| **Legend** | Positioned on the right side. Entries: `y1` (blue), `y4` (orange), `y7` (green), `y9` (pink), `y12` (cyan), `y15` (brown), `y18` (yellow). | Positioned on the right side. Entries: `y1` (blue), `y4` (orange), `y7` (green), `y9` (pink), `y12` (cyan), `y15` (brown), `y18` (yellow). | true |
| **Plotted Data** | 7 scatter point curves corresponding to indices 20 through 90: `y1` (blue dots, lowest slope, up to ~1.2 at x=9), `y4` (orange dots), `y7` (green dots), `y9` (pink dots), `y12` (cyan dots), `y15` (brown/red dots), `y18` (yellow dots, highest slope, up to ~12.5 at x=9) | 7 scatter point curves corresponding to indices 20 through 90: `y1` (blue dots, lowest slope, up to ~1.2 at x=9), `y4` (orange dots), `y7` (green dots), `y9` (pink dots), `y12` (cyan dots), `y15` (brown/red dots), `y18` (yellow dots, highest slope, up to ~12.5 at x=9) | true |

### Table Pane (Bottom-Right Floating Window)

| Item | Spec Value | Screenshot Value | Match |
| :--- | :--- | :--- | :--- |
| **Header Bar Title** | `SOURCE: caspl_df_exp [20:90]` | `SOURCE: caspl_df_exp [20:90]` | true |
| **Displayed Columns** | `Index` (gray header), `x` (light green header), `y1` (light green header), `y4` (light green header), `y7` (light green header), `y9` (light green header), `y12` (light green header), `y15` (light green header), `y18` (light green header) | `Index` (gray header), `x` (light green header), `y1` (light green header), `y4` (light green header), `y7` (light green header), `y9` (light green header), `y12` (light green header), `y15` (light green header), `y18` (light green header) | true |

---
**Stage 1 Conclusion:** **FAIL**. The generated image does not match the recently updated specification because the column **`y6`** is not checked in the UI, and therefore does not appear in the Table pane or the Plot pane. 
