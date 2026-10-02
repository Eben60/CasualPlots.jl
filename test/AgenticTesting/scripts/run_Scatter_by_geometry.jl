using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for Scatter_by_geometry.png...")
screenshot_path = generate_Scatter_by_geometry_screenshot("Scatter_by_geometry.png")
println("Done. Screenshot saved at: ", screenshot_path)
