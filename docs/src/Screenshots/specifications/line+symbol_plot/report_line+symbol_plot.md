# Stage 1 Verification Report for line+symbol_plot

**Generated Image Evaluated:** `docs/src/Screenshots/tmp/line+symbol_plot_04.png`
**Specification File:** `docs/src/Screenshots/specifications/line+symbol_plot/line+symbol_plot.md`

## Verification Checklist

### Control Panel (Left Pane)

| Item | Spec Value | Screenshot Value | Match |
| :--- | :--- | :--- | :--- |
| **Active Tab** | `Format` | `Format` | true |
| **Plot type** | `Line+Symbol` | `Line+Symbol` | true |
| **Show group by** | `Color` | `Color` | true |
| **Theme** | `theme_ggplot2` | `theme_ggplot2` | true |
| **Show Legend** | Checked, legend title: `two functions` | Checked, legend title: `two functions` | true |
| **X-Axis** | `argument` | `argument` | true |
| **Y-Axis** | `functions` | `functions` | true |
| **Title** | `Combined plot of two functions` | `Combined plot of two functions` | true |
| **X from / to / rev.** | `0` **to:** `10`, **rev.:** unchecked | `0` **to:** `10`, **rev.:** unchecked | true |
| **Y from / to / rev.** | `0` **to:** `100`, **rev.:** unchecked | `0` **to:** `100`, **rev.:** unchecked | true |

### Plot Pane (Top-Right Floating Window)

| Item | Spec Value | Screenshot Value | Match |
| :--- | :--- | :--- | :--- |
| **Window State** | Normal split view. | Normal split view. | true |
| **Background** | Light gray ggplot2 theme with white grid lines. | Light gray ggplot2 theme with white grid lines. | true |
| **Plot Title** | `Combined plot of two functions` (centered, bold) | `Combined plot of two functions` (centered, bold) | true |
| **X-Axis** | `argument` (ticks at `0`, `5`, `10`) | `argument` (ticks at `0`, `5`, `10`) | true |
| **Y-Axis** | `functions` (ticks at `0`, `50`, `100`) | `functions` (ticks at `0`, `50`, `100`) | true |
| **Plotted Data (Series 1)** | Blue line with circle markers — quadratic curve ($y = x^2$), rising steeply from $(1, 1)$ to $(10, 100)$. | Blue line with circle markers — quadratic curve ($y = x^2$), rising steeply from $(1, 1)$ to $(10, 100)$. | true |
| **Plotted Data (Series 2)** | Orange line with circle markers — power curve ($y = x^{1.5}$), rising gently from $(1, 1)$ to $(10, \approx31.6)$. | Orange line with circle markers — power curve ($y = x^{1.5}$), rising gently from $(1, 1)$ to $(10, \approx31.6)$. | true |
| **Legend** | Right side, title **two functions** (bold). Blue line+marker: `y1`, Orange line+marker: `y2` | Right side, title **two functions** (bold). Blue line+marker: `y1`, Orange line+marker: `y2` | true |

### Table Pane (Bottom-Right Floating Window)

| Item | Spec Value | Screenshot Value | Match |
| :--- | :--- | :--- | :--- |
| **Window State** | Minimized (header bar visible, body hidden). | Minimized (header bar visible, body hidden). | true |
| **Header Bar Title** | `SOURCE: caspl_df_simple` | `SOURCE: caspl_df_simple` | true |

---
**Stage 1 Conclusion: PASS**. The generated image perfectly matches all literal values and criteria defined in the specification.
