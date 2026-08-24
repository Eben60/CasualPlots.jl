using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for plot_pane_maximized.png...")
screenshot_path = generate_plot_pane_maximized_screenshot("plot_pane_maximized.png")
println("Done. Screenshot saved at: ", screenshot_path)
