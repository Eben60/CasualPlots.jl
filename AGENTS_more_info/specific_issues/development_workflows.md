# Development Workflows

Extracted from `AGENTS.md`.

- Review the **Development Workflow Guidelines** Knowledge Item (KI) for general workflow rules (file staging, GitKraken, ShareAdd, Kaimon MCP).

## Modifying UI Components

1. **Control panel**: Edit `create_control_panel_ui.jl`
2. **Tabs**: Modify `gui_tabs.jl`
3. **Layout**: Adjust `assemble_layout` in `gui_layout.jl`
4. **Styles**: Edit `css_styles.css` (prefer CSS classes over inline styles)

## Adding New Observables

1. Initialize in `initialize_app_state()` (`app_state.jl`)
2. Add to state NamedTuple unpacking where needed
3. Connect to callbacks in relevant `setup_*_callback` function

## Debugging Observable Updates

- Use `on(obs) do val; @info "Observable changed" val; end` pattern
- Check `block_format_update[]` state to verify race prevention
- Verify callback execution order in REPL output

## Testing

- Review the **Testing Guidelines** Knowledge Item (KI) before running or modifying tests.
- Manual testing via `src/scripts/casualplots_test.jl`
    - see also [extended manual testing protocol](manual_testing_plan.md)
- **Interactive Agentic Workflow**: When capturing screenshots or testing specific UI states interactively with the user, follow this cooperative workflow:
    1. **Launch**: Agent starts the GUI locally (e.g., using `Kaimon` `ex` tool to run `Bonito.Server(app, "127.0.0.1", 8000)`).
    2. **Navigate**: User navigates to `http://localhost:8000` in their local browser and interacts with the GUI to reach the desired state.
    3. **Capture/Read**: Agent uses `browser_subagent` to capture a screenshot of `http://localhost:8000` (without modifying the state) OR the agent reads the necessary backend variables.
- GUI agentic testing was not successful. See attempts and more info in Branch `v0.6.0-refactoring`
- Additional testing tools are in [AgenticTesting.jl](../../test/AgenticTesting) subpackage.
    - **Note for Documentation**: The JS hooks inside this package (e.g., `set_radio_value`, `click_button` in `gui_testing_utils.jl`) can be executed via `Bonito.evaljs` to visually drive the UI. This is highly useful for automating documentation screenshots.
- Test suite is using SafeTestsets.jl package. Each `@safetestset` is in an included file. It can contain one more level of `@testset` if necessary, but not more.
