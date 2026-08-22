# Callback & Formatting Flow

Extracted from `AGENTS.md`. See also the [Mermaid diagrams](../Mermaid/) for visual flows.

## 1. Source Selection & Plotting Flow

Both **X,Y Source**, **DataFrame Source**, and **Open File** modes feed into the plotting pipeline.

### A. X,Y Source Selection

1.  **Step 1: X Selection** (`setup_x_callback`)
    - User selects X variable.
    - Triggers population of congruent Y-variable options.
    - Clears current Y selection.
    - Sets `data_bounds_from`/`data_bounds_to` from the X array's first/last indices.
    - Initializes `range_from`/`range_to` to match bounds.
2.  **Step 2: Y Selection** (`setup_source_callback`)
    - User selects Y variable.
    - Updates `current_plot_x`, `current_plot_y` for tracking.
    - **Does NOT auto-plot** - waits for user to click "(Re-)Plot" button.
    - *On invalid selection*: Clears plot, table, and state.
3.  **Step 3: (Re-)Plot** (`setup_array_plot_trigger_callback`)
    - User clicks "(Re-)Plot" button.
    - Validates range values (uses bounds as defaults if empty).
    - Calls `do_replot` with range parameters.
    - Updates table view with range-filtered data.
    - Applies non-default formatting options via `apply_custom_formatting!`.

### B. DataFrame Source Selection (Main or Opened File)

1.  **Step 1: DataFrame Selection**
    - User selects a DataFrame from `Main` OR selects "opened file" (if file loaded via Open tab).
    - If needed (opened file), strings are normalized (`normalize_strings!`) at load time.
    - Triggers population of column checkboxes.
    - Clears current column selection.
2.  **Step 2: Column Selection & Plotting** (`setup_dataframe_callbacks`)
    - User selects columns (checkboxes).
    - **Plotting is triggered manually**: User must click "(Re-)Plot" button.
    - `plot_trigger` observable fires:
        - Validates selection (at least 2 columns).
        - **Data Cleansing and Normalization**: Calls `clean_plot_data!` to manage unit conversions and normalize non-numeric values (see [data_cleansing.md](data_cleansing.md)).
        - Calls `update_dataframe_plot` helper.
        - Generates plot with **default labels** (resets legend title).
        - Updates table view.

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
    - XLSX: Options passed to `XLSX.readtable()` via `collect_xlsx_options()`
    - Both call `skip_rows!()` for post-load row processing
3.  **Reload Button**:
    - Enabled when a file is loaded (CSV) or sheet selected (XLSX)
    - Re-reads the same file (`opened_file_path`) with current options
    - Useful for adjusting options after seeing initial import results

---

## 2. Formatting & Updates

Formatting changes (Plot Type, Legend, Labels) are handled differently to preserve user customizations and optimize performance.

### A. Format Callback Logic

- **Triggered by**: `selected_plottype`, `selected_theme`, `show_legend`, `legend_title_text`, axis limit observables, and any dynamically registered attribute in `dynamic_attributes`.
- **Implementations**:
    - X,Y Mode: `setup_format_change_callbacks` (triggers `do_replot`)
    - DataFrame Mode: Format callbacks within `setup_dataframe_callbacks` (triggers `update_dataframe_plot` -> `do_replot`)
    - Theme: `setup_theme_callback` (applies theme globally, triggers replot)
    - Dynamic Attributes: Callbacks automatically generated for all `AbstractPlotAttribute` configurations (triggers replot).
    - Axis Limits: `setup_axis_limits_callbacks` (triggers immediate replot with current limits)
- **Shared Behavior**:
    - **All format changes trigger full replot** using the unified `do_replot` function.
    - **Preserves user labels and axis limits**: `format_is_default` dict tracks which options are customized. After replot, `apply_custom_formatting!` re-applies non-default values.
    - **Axis limits preserved during format changes**: `get_current_axis_limits(state)` helper merges current limits into `plot_format`.
    - **Does NOT update table**: Table update is skipped as data has not changed.
    - **Race Condition Prevention**: Returns early if `block_format_update[]` is true.
    - **Legend title optimization**: Skip replot if legend is not visible (title is saved for when legend becomes visible).

### B. Format Persistence Strategy (`format_is_default` and `RESET_FORMAT_OPTION`)

A `DefaultDict{Symbol, Bool}` tracks which format options are still at their default values.

Reset behavior is driven by `RESET_FORMAT_OPTION` Dict (dynamically populated at startup from `AbstractPlotAttribute` registries):
- `"never"` -> Options that persist across all changes: `:plottype`, `:theme`
- `"source"` -> Options reset when data source changes: `:title`, `:xlabel`, `:ylabel`, `:show_legend`, `:legend_title`, dynamic attributes (e.g. `:group_by`, `:bar_mode`) with `reset_policy="source"`, axis limits.
- `"range"` -> Options reset when (Re-)Plot button is clicked: `:x_min`, `:x_max`, `:y_min`, `:y_max`, `:xreversed`, `:yreversed`

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
