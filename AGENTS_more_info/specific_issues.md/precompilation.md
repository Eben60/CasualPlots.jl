# Precompilation

CasualPlots uses **PrecompileTools.jl** to reduce Time-To-First-Plot (TTFP). The precompilation workload is defined in `src/precompile.jl`.

## What's Precompiled

1. **DataFrame Preprocessing**:
   - `normalize_strings!()` - InlineString → String conversion
   - `normalize_numeric_columns!()` - Type normalization for plotting
   - `skip_rows!()` - Row filtering

2. **Plotting Pipeline** (via hidden Electron window):
   - Full `casualplots_app()` creation and serving
   - `create_plot()` calls for all three plot types: `Lines`, `Scatter`, `BarPlot`
   - WGLMakie rendering pipeline

## Electron Hidden Window

The `Ele.serve_app()` function accepts a `show` keyword argument:
```julia
Ele.serve_app(app; show=false)  # Hidden window (for precompilation/testing)
Ele.serve_app(app; show=true)   # Visible window (default, normal use)
```

This allows precompilation to run the full Electron/Bonito/WGLMakie stack without displaying a window.

## Known Limitations

- **WGLMakie Task Serialization**: WGLMakie creates internal tasks for WebGL communication that cannot be serialized into the precompile cache. Aggressive cleanup is required:
  - Clear global plot references (`cp_figure`, `cp_figure_ax`)
  - Close app and Electron display
  - Multiple `GC.gc()` + `yield()` cycles
  
- **Cleanup Sensitivity**: The cleanup sequence is critical. Improper cleanup leads to "Waiting for background task / IO / timer" errors during precompilation.

- **No Extension Precompilation**: CSV.jl and XLSX.jl extension code is NOT precompiled (weak dependencies may not be loaded).
