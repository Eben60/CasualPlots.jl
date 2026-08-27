using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("=== Running all screenshot generators ===")

include("run_dataframe_source_screenshot.jl")
include("run_xy_source_screenshot.jl")
include("run_open_tab_screenshot.jl")
include("run_format_tab_barplot_dodged.jl")
include("run_format_tab_barplot_stacked.jl")
include("run_format_tab_limits.jl")
include("run_format_tab_lines.jl")
include("run_plot_pane_maximized.jl")
include("run_save_tab_script.jl")
include("run_table_view.jl")
include("run_line_symbol_plot.jl")

println("=== All screenshots generated successfully ===")
