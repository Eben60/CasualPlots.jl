using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for line+symbol_plot.png...")
screenshot_path = generate_line_symbol_plot_screenshot("line+symbol_plot.png")
println("Done. Screenshot saved at: ", screenshot_path)
