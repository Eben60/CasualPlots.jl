# AgenticTesting

This package contains browser automation and test verification utilities for `CasualPlots.jl`. 

It is structured as a Julia workspace sub-project. This ensures the testing tools are fully isolated from the main `CasualPlots.jl` package, avoiding dependency bloat and export namespace pollution in the production application.

## Usage

Start your REPL in the `CasualPlots.jl` root directory. The root `Project.toml` automatically loads this workspace.

```julia
using ShareAdd
@usingany CasualPlots
@usingany AgenticTesting
```

Once loaded, you can call GUI testing functions (like `verify_session_active`, `get_dropdown_options`, `click_button`, etc.) directly from the REPL.
