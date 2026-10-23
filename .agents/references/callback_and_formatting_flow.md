# Callback & Formatting Flow

Extracted from `AGENTS.md`. See also the [Mermaid diagrams](../mermaid/) for visual flows.

## 1. Source Selection & Plotting Flow

Both **X,Y Source**, **DataFrame Source**, and **Open File** modes feed into the plotting pipeline.

### A. X,Y Source Selection

1.  **Step 1: X Selection** (`setup_x_callback`)
    - User selects X variable.
    - Triggers population of congruent Y-variable options.
    - Clears current Y selection.
    - Sets `data_bounds_from`/`data_bounds_to` from the X array's first/last indices.
    - Initializes `range_from`/`range_to` to match bounds.
    - **Immediately updates Table Pane** to show `[Index, X]` over the active range. Clears Plot Pane.
2.  **Step 2: Y Selection** (`setup_source_callback`)
    - User selects Y variable.
    - Captures baseline `SourceSignature` snapshot.
    - Updates `current_plot_x`, `current_plot_y` for tracking.
    - **Immediately updates Table Pane** to append Y columns: `[Index, X, Y...]`.
    - **Does NOT auto-plot** - waits for user to click "(Re-)Plot" button.
    - *On invalid selection*: Clears plot, resets table to `[Index, X]`, and resets state.
3.  **Step 3: (Re-)Plot** (`run_rpb!`)
    - User clicks "(Re-)Plot" button.
    - Fresh read of X and Y from `Main`.
    - Validates structural continuity against baseline `SourceSignature` (`check_continuity`):
      - If fatal changes (length mismatch, range out of bounds): shows error modal, blanks panes, resets selection.
      - If resumable changes (row count changed): shows 2-button warning modal ("Continue" or "Select data anew").
      - If identical or accepted: proceeds with replot.
    - Cleanses data via `clean_plot_data!`, caches cleaned data in `cached_cleaned_df`.
    - Calls `do_replot` with range parameters.
    - Refreshes Table Pane.
    - Applies non-default formatting options via `apply_custom_formatting!`.

### B. DataFrame / Matrix Source Selection (Main or Opened File)

1.  **Step 1: Source Selection**
    - User selects a DataFrame or 2D Matrix from `Main` OR selects "opened file" (if file loaded via Open tab).
    - Captures baseline `SourceSignature` snapshot.
    - If needed (opened file), strings are normalized (`normalize_strings!`) at load time.
    - Triggers population of column checkboxes (or generated column names `Col1`, `Col2`, etc. for matrices).
    - Clears current column selection.
    - **Immediately updates Table Pane** to display only the `Index` column over the full row range.
2.  **Step 2: Column Selection & Table Decoupling** (`setup_table_refresh_callback` -> `refresh_table!`)
    - Checking or unchecking columns updates the Table Pane **immediately**: `[Index, Col_1, Col_2, ...]`.
    - Columns maintain their natural DataFrame order regardless of the checking sequence.
    - Range field adjustments immediately update the row slice in the Table Pane.
3.  **Step 3: (Re-)Plot** (`run_rpb!`)
    - **Plotting is triggered manually**: User must click "(Re-)Plot" button.
    - Fresh read from `Main` (by variable name) or `cp_file_df` (`acquire_source`).
    - Validates structural continuity against `SourceSignature` (`check_continuity`).
    - Cleanses data via `clean_plot_data!` and caches in `cached_cleaned_df` (`prepare_plot_data!`).
    - Calls `finish_rpb!` -> `replot_from_cache!` -> `do_replot`.
    - Generates plot with default labels on first plot from that source, or preserves user labels.
    - Refreshes Table Pane (`refresh_table!`).

### C. File Import with Reading Options (Open Tab)

The Open tab provides configurable file reading options before/after loading:
1.  **Reading Options** (configured via UI controls):
    - `header_row`: Row number containing headers (0 = no headers)
    - `skip_after_header`: Rows to skip after header (subheaders)
    - `skip_empty_rows`: Remove rows where all elements are missing
    - `delimiter`: CSV delimiter (Auto, Comma, Tab, Space, Semicolon, Pipe)
    - `decimal_separator`: Decimal/thousands separator format
2.  **File Loading**:
    - CSV/TSV: Options passed to `CSV.read()` via `collect_csv_options()`
    - XLSX: Options passed to `XLSX.readtable()` via `collect_xlsx_options()`. The first sheet is auto-selected and loaded by default.
    - Both call `skip_rows!()` for post-load row processing
    - Loaded `DataFrame` is stored internally in `opened_file_df` and exported globally to the REPL as `cp_file_df`.
    - Shows whole-file preview in the Table Pane until a source is selected.
3.  **Reload Button**:
    - Enabled when a file is loaded (CSV) or sheet selected (XLSX)
    - Re-reads the file from disk with current options and updates `cp_file_df`.
    - Preserves active column selection if `"opened file"` is selected.
    - If a plot from the opened file already exists, automatically executes the `run_rpb!` pipeline (including change detection).
    - If no plot exists yet, refreshes the Table Pane only and updates the baseline `SourceSignature`.

---

## 2. Formatting & Updates

Formatting changes (Plot Type, Legend, Labels) are handled differently to preserve user customizations and optimize performance.

### A. Format Callback Logic

- **Triggered by**: `selected_plottype`, `selected_theme`, `show_legend`, `legend_title_text`, axis limit/scale observables (`x_min`, `x_max`, `y_min`, `y_max`, `xreversed`, `yreversed`, `xlog`, `ylog`), and any dynamically registered attribute in `dynamic_attributes`.
- **Implementations** (unified across Array and DataFrame modes):
    - Plot Type, Legend, & Dynamic Attributes: `setup_format_change_callbacks` (triggers `replot_from_cache!` -> `do_replot`)
    - Theme: `setup_theme_callback` (applies theme globally via `apply_theme!`, triggers `replot_from_cache!` -> `do_replot`)
    - Axis Limits, Reversal, & Log Scale: `setup_axis_limits_callbacks` (triggers immediate `replot_from_cache!` -> `do_replot` with current limits, reversal, and log scale options)
    - Labels (X, Y, Title): `setup_label_update_callbacks` (updates axis attributes in-place via `update_plot_format!` without full replot)
- **Shared Behavior**:
    - **All format changes replot from cache** via `replot_from_cache!` -> `do_replot`.
    - **Uses Cached Data**: All format callbacks replot using `state.misc.cached_cleaned_df[]` rather than re-reading `Main`. This guarantees that unplotted selection changes in the GUI or variables modified in the REPL are never prematurely plotted during a mere format or theme tweak.
    - **Visual Loading Indicator**: During plot processing / replot (including heavy initial JIT compilation), a loading indicator is displayed in `outputs.plot[]`.
    - **Categorical Axis Disabling**: When axis data is non-numeric (`!(T <: Union{Real, Unitful.Quantity})`), `x_is_categorical` or `y_is_categorical` is set to `true`, disabling the limits inputs, reversal checkbox (`rev.:`), and log scale checkbox (`log:`) for that axis.
    - **Preserves user labels and axis limits**: `format_is_default` dict tracks which options are customized. After replot, `apply_custom_formatting!` re-applies non-default values.
    - **Axis limits preserved during format changes**: `get_current_axis_limits(state)` helper merges current limits, reversals, and log scales into `plot_format`.
    - **Does NOT update table**: Table update is skipped as data has not changed.
    - **Race Condition Prevention**: Returns early if `block_format_update[]` is true.
    - **Legend title optimization**: Skip replot if legend is not visible (title is saved for when legend becomes visible).
    - **Centralized Error Handling**: Errors during callbacks are caught at the outer boundary, displayed via `show_modal!` (mirroring to REPL), and the full stack trace is inspectable in the REPL with `CasualPlots.last_error()`.

### B. Format Persistence Strategy (`format_is_default` and `RESET_FORMAT_OPTION`)

A `DefaultDict{Symbol, Bool}` tracks which format options are still at their default values.

Reset behavior is driven by `RESET_FORMAT_OPTION` Dict (dynamically populated at startup from `AbstractPlotAttribute` registries):
- `"never"` -> Options that persist across all changes: `:plottype`, `:theme`
- `"source"` -> Options reset when data source changes: `:title`, `:xlabel`, `:ylabel`, `:show_legend`, `:legend_title`, dynamic attributes (e.g. `:group_by`, `:bar_mode`) with `reset_policy="source"`, axis limits.
- `"range"` -> Options reset when (Re-)Plot button is clicked: `:x_min`, `:x_max`, `:y_min`, `:y_max`, `:xreversed`, `:yreversed`, `:xlog`, `:ylog` (`AXES_LIMITS_OPTIONS`).

**Data Source Tracking:**
- `last_plotted_x`, `last_plotted_y` - track last X and Y variable names (Array mode)
- `last_plotted_dataframe` - tracks last DataFrame name (DataFrame mode)

**Flow:**
1.  **New Data Source**: `is_new_data=true` -> reset options in `RESET_FORMAT_OPTION["source"]`, initialize text fields from plot defaults.
2.  **(Re-)Plot Button**: `reset_semipersistent=true` -> reset options in `RESET_FORMAT_OPTION["range"]` (axis limits).
3.  **Format Change**: Preserve all format customizations, axis limits passed via `get_current_axis_limits(state)`.
4.  **User Edit**: Mark corresponding flag as `false` (e.g., user changes title -> `format_is_default[:title] = false`).
5.  **Replot**: After creating new plot, `apply_custom_formatting!` iterates over non-default options and re-applies them.

---

## 3. Legend Behavior

- **Default Visibility**: `show_legend` defaults to `true` only if `n_cols > 1`.
- **State Management**:
    - **New Plot**: Legend title is reset to empty.
    - **Format Change**: Legend title and visibility persist.
- **User Override**: Checkbox allows manual toggle, persisting through format updates.

---

## 4. Structural Continuity & Warning Protocol (`source_continuity.jl`)

1. **Baseline Capture (`SourceSignature`)**:
   - Captured when the source is selected (XY: when Y is chosen; DataFrame/Matrix: when source is chosen).
   - Records kind, row index bounds, column names, column element types, and matrix flag.
2. **Fresh Verification on (Re-)Plot / Reload (`check_continuity`)**:
   - Re-reads data from `Main` or `cp_file_df`.
   - **Identical**: Proceeds with replot and table refresh without dialogs.
   - **Resumable Changes** (e.g., row count changed within full range, or trailing columns added/removed after last selected column):
     - Displays 2-button Warning Modal (`show_modal!(...; type=:warning)`).
     - *Continue*: Updates baseline signature to fresh state, adjusts bounds/range inputs, and executes replot.
     - *Select data anew*: Blanks plot and table, clears column selection, resets state.
   - **Fatal Changes** (e.g., custom range out of bounds, selected column deleted/renamed/type changed, length mismatch):
     - Throws `DataContinuityError`, caught at outer callback boundary.
     - Displays Error Modal (`show_modal!(...; type=:error)`), blanks plot and table, and resets data selection.
