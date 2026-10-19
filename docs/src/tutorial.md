# CasualPlots Tutorial

This tutorial provides a step-by-step walkthrough of common workflows in `CasualPlots.jl`.

## 1. Getting Started & Demo Data

To start the application and populate your environment with sample data:

```julia
using CasualPlots

# Inject demo vectors, arrays, and DataFrames into Main namespace
CasualPlots.@populate

# Launch application instance
app = casualplots_app()

# Serve GUI in Electron window
Ele.serve_app(app)
```

The GUI consists of three main areas:
1. **Control Panel**: Tabbed sidebar containing **Source**, **Format**, **Open**, and **Save** tabs.
2. **Plot Pane**: Floating window displaying the generated plot powered by `WGLMakie.jl`.
3. **Table Pane**: Floating window displaying the active data subset in tabular form.

---

## 2. Data Selection Modes

When using `CasualPlots.jl`, the source selection dropdowns automatically populate with compatible variables found in the Julia `Main` environment.

### a). X, Y Array Mode

1. In the **Source** tab, select **X, Y Arrays** as the Source Type.
2. Choose an X variable (e.g., `caspl_x_10`).
   - *Note: X variables from `Main` must be 1-dimensional arrays (vectors) containing `Real` numbers or `Unitful` quantities.*
3. Select a Y variable of matching length.
   - *Note: Y variables from `Main` can be 1D vectors or 2D matrices containing `Real` numbers or `Unitful` quantities. The first dimension (rows) must match the length of X.*
4. Optionally adjust the row index range (`Range From` / `Range To`).
5. Click **(Re-)Plot** to generate the plot and populate the table.

!!! details "📸 Screenshot: Array X,Y Selection"
    *🔍 [Click to view full resolution](Screenshots/xy_source_selection.png)*
    [![Array X,Y Selection](Screenshots/xy_source_selection.png)](Screenshots/xy_source_selection.png)

---

### b). DataFrame Mode

DataFrames in `Main` (as well as 2D `Matrix` variables) are detected automatically. DataFrames are expected to follow the ["wide" format](https://aog.makie.org/stable/examples/data-manipulations/wide-data#Long-vs-Wide-Data-Formats).

1. In the **Source** tab, select **File/DataFrame/Matrix** as the Source Type.
2. Choose a DataFrame or Matrix from the dropdown (e.g., `caspl_df_simple`).
3. Select columns using the column checkboxes. The first checked column is assigned to the X-axis, and subsequent checked columns are plotted on the Y-axis.
4. Optionally adjust the row index range (`Range From` / `Range To`).
5. Click **(Re-)Plot**. The DataTable will be filled in, and the data plotted.

!!! details "📸 Screenshot: DataFrame Selection, every third column selected, a sub-range selected"
    *🔍 [Click to view full resolution](Screenshots/dataframe_source_selection.png)*
    [![DataFrame Column Selection](Screenshots/dataframe_source_selection.png)](Screenshots/dataframe_source_selection.png)

---

### c). File Import (CSV & XLSX)

Supported disk formats are **CSV/TSV** and **XLSX** (Excel). The GUI provides a subset of the file reading options available in the respective packages. If you have a file with complex formatting, you can load it into a `DataFrame` manually in the REPL; the data will then be available as a standard variable.

To load external files from disk:

1. Import [CSV.jl](https://github.com/JuliaData/CSV.jl) or [XLSX.jl](https://github.com/felipenoris/XLSX.jl) *before* starting the GUI, as file reading capabilities are implemented as package extensions for `CasualPlots.jl`.
2. Navigate to the **Open** tab.
3. Configure optional file reading parameters:
   - Header row index (0 for no header).
   - Rows to skip after header.
   - Option to skip empty rows.
   - Delimiter and decimal separator formats for CSV/TSV files.
4. Click **Open File** and select a file.
   - For **CSV** files, data is parsed immediately.
   - For **Excel (XLSX)** files with multiple tables, the first worksheet is opened initially. You can select a different sheet from the dropdown.
   - Use the **Reload** button to re-parse the data if you adjust any reading options after the initial load.
5. Loaded file data becomes available under `"opened file"` in the DataFrame source selection dropdown.
6. Proceed in DataFrame Mode.

!!! details "📸 Screenshot: Open Tab & File Reading Options"
    *🔍 [Click to view full resolution](Screenshots/open_file_tab.png)*
    [![Open File Tab](Screenshots/open_file_tab.png)](Screenshots/open_file_tab.png)

---

### d). Data Cleansing and Normalization

Before plotting, the application automatically cleanses and normalizes selected data:

- **Non-numeric values**: If a column contains fewer than 10% non-numeric values, `CasualPlots` replaces them with `missing` (displaying a warning modal) so the remaining valid data can be plotted. If non-numeric values exceed 10%, the column is left as-is: an X-axis column is treated as categorical, while a Y-axis column may result in a downstream plotting error.
- **Unitful quantities**:
  - **Within a column**: Compatible units (e.g., `m` and `cm`) are converted to a single common unit. Incompatible physical dimensions (e.g., `m` and `m^2`) or a mix of units and plain numbers raise an error.
  - **Across multiple Y columns**: If multiple Y columns have compatible units, they are unified to a single common unit on the Y-axis. If multiple Y columns have incompatible physical dimensions (e.g., plotting voltage and current on the same axis), `CasualPlots` displays a warning and strips the units so the values can still be plotted together.

---

## 3. Plot Formatting & Themes

Navigate to the **Format** tab to customize visual parameters.

### a). Lines and Scatter Plots

Select **Lines** or **Scatter** plot type. Options include:
- **Theme Selection**: Choose from predefined themes such as Makie Default, AoG, Dark, Light, Minimal, or ggplot2.
- **Group Differentiation**: Group datasets by **Color** or **Geometry** (linestyle/marker).
- **Titles & Labels**: Custom axis labels and plot titles.
- **Legend Controls**: Toggle legend visibility and edit legend title.

!!! details "📸 Screenshot: Format Tab & Lines Plot, Customized attributes"
    *🔍 [Click to view full resolution](Screenshots/format_tab_lines.png)*
    [![Format Tab Lines](Screenshots/format_tab_lines.png)](Screenshots/format_tab_lines.png)

!!! details "📸 Screenshot: Scatter Plot, Differentiated by Geometry"
    *🔍 [Click to view full resolution](Screenshots/Scatter_by_geometry.png)*
    [![Scatter Plot Geometry](Screenshots/Scatter_by_geometry.png)](Screenshots/Scatter_by_geometry.png)

---

### b). Bar Plots (Dodged vs Stacked with Categorical Data)

When **BarPlot** is selected with a categorical X column (e.g., categories `Group A`, `Group B`, `Group C`):

- **Bar Mode**: Choose between **Dodged** (bars grouped side-by-side) and **Stacked** (bars stacked vertically).
- **Direction**: Render bars **Vertical** or **Horizontal**.

#### Dodged Mode
!!! details "📸 Screenshot: BarPlot Dodged Mode (Categorical X)"
    *🔍 [Click to view full resolution](Screenshots/format_tab_barplot_dodged.png)*
    [![BarPlot Dodged Mode](Screenshots/format_tab_barplot_dodged.png)](Screenshots/format_tab_barplot_dodged.png)

#### Stacked Mode
!!! details "📸 Screenshot: BarPlot Stacked Mode, Horizontal (Categorical X)"
    *🔍 [Click to view full resolution](Screenshots/format_tab_barplot_stacked.png)*
    [![BarPlot Stacked Mode](Screenshots/format_tab_barplot_stacked.png)](Screenshots/format_tab_barplot_stacked.png)

---

### c). Axis Limits, Log Scale & Axis Reversal

In the **Format** tab:
- **Axis Limits (`X lim:`, `Y lim:`)**: Set explicit numerical bounds (lower and upper, separated by an en-dash). Placeholders display the current automatic data bounds.
- **Log Scale (`log:`)**: Toggle the `log:` checkbox on the X or Y axis to display data on a logarithmic ($\log_{10}$) scale.
- **Axis Reversal (`rev.:`)**: Toggle the `rev.:` checkbox to invert axis directions (i.e., displaying values from high to low).
- **Categorical Data**: If an axis contains categorical data (e.g., strings), custom limits, log scale, and reversal controls are automatically disabled for that axis.
- **Interactive Synchronization**: Zooming and panning in the Plot pane automatically synchronizes the current view limits back to the input fields.

!!! details "📸 Screenshot: Axis Limits Controls, customized X-axis"
    *🔍 [Click to view full resolution](Screenshots/format_tab_limits.png)*
    [![Axis Limits Controls](Screenshots/format_tab_limits.png)](Screenshots/format_tab_limits.png)

---

## 4. Resizing Panes

The GUI utilizes a flexible windowing system. The **Plot Pane** and **Table Pane** feature window controls in their top-right corners:

- **Maximize**: Expands the pane to fill the entire available workspace. Maximizing the Plot pane automatically resizes the interactive figure to fit the new dimensions perfectly.
- **Restore**: Returns the layout to its default split view.
- **Minimize**: Collapses the pane.

!!! details "📸 Screenshot: Maximized Plot Pane"
    *🔍 [Click to view full resolution](Screenshots/plot_pane_maximized.png)*
    [![Maximized Plot Pane](Screenshots/plot_pane_maximized.png)](Screenshots/plot_pane_maximized.png)

---

## 5. Data Table & Header Coloring

The **Table Pane** updates dynamically whenever data is plotted.

Column header colors indicate data types:
- 🟩 **Green**: Numeric data (`Float64`, `Int64`).
- 🟦 **Blue**: `Unitful` quantity data (e.g., `10.5u"m"`, `3.2u"s"`).
- 🟨 **Yellow**: String and other non-numeric types; Mixed types (e.g. `Union{String, Int64}`).

!!! details "📸 Screenshot: Maximized Data Table"
    *🔍 [Click to view full resolution](Screenshots/table_view.png)*
    [![Maximized Data Table](Screenshots/table_view.png)](Screenshots/table_view.png)

---

## 6. REPL Access to the Live Plot

The active plot's `Makie.Figure` and `Axis` objects are exported directly to the `Main` REPL environment as `cp_figure` and `cp_figure_ax`. You can inspect or modify them from the REPL; changes update the interactive GUI display immediately:

```julia-repl
# Directly modify the axis in the REPL; changes reflect in the GUI immediately
julia> hidespines!(cp_figure_ax, :r, :t)
```

!!! note
    Modifications made directly to `cp_figure` or `cp_figure_ax` are included when saving image files (`PNG`, `SVG`, `PDF`), but are **not** reflected in scripts generated by **Create Script**.

---

## 7. Exporting Plots & Script Generation

Navigate to the **Save** tab:

### Saving Image Files
- Specify a file path (or click **Select File...**) with a `.png`, `.svg`, or `.pdf` extension, then click **Save Plot** to save static vector or raster outputs. If the destination file already exists, a confirmation prompt prevents accidental overwriting.

### Script Generation
- Click **Create Script** to generate a standalone Julia `.jl` script. If the target file already exists, a confirmation prompt appears.
- The generated code uses `AlgebraOfGraphics.jl` and `WGLMakie.jl`/`CairoMakie.jl` to reproduce the plot without requiring the CasualPlots GUI. See **[Script Generation](script_generation.md)** for a detailed walkthrough.

!!! details "📸 Screenshot: Save Tab & Code Generation"
    *🔍 [Click to view full resolution](Screenshots/save_tab_script.png)*
    [![Save Tab](Screenshots/save_tab_script.png)](Screenshots/save_tab_script.png)

