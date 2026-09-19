# Data Cleansing and Normalization

Extracted from `AGENTS.md`.

Centralized via `clean_plot_data!` (in `preprocess_dataframes.jl`) to ensure all data passed to the plotting backend is valid and properly typed.

- **Unitful Unification (Within Column)**: Checks each column for mixed compatible units (e.g., `m` and `cm`). If found, it unifies all elements to the largest metric unit present in that column (`unify_internal_column_units!`). Mixed incompatible units or a mix of units and plain numbers will throw an error.
- **Numeric Normalization**: Checks column types and contents (`normalize_numeric_columns!`). If an `Any` or `AbstractString` column has `> 90%` numeric values (i.e., less than 10% non-numerics), it replaces the invalid elements with `missing` so the rest of the data can be plotted. A warning popup is shown.
- **Unitful Unification (Cross-Column)**: If multiple Y-columns contain `Unitful` quantities, it attempts to unify them to a common target unit (`unify_units!`). If dimensions are incompatible (e.g., `s` and `m`), it issues a warning and strips the units entirely to allow plotting on the same axis.
