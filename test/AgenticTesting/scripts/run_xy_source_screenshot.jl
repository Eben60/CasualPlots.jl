using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for xy_source_selection.png...")
screenshot_path = generate_xy_source_screenshot("xy_source_selection.png")
println("Done. Screenshot saved at: ", screenshot_path)
