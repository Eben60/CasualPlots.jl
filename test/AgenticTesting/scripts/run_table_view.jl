using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for table_view.png...")
screenshot_path = generate_table_view_screenshot("table_view.png")
println("Done. Screenshot saved at: ", screenshot_path)
