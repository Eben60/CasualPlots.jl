using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for dataframe_source_selection.png...")
screenshot_path = generate_dataframe_source_screenshot("dataframe_source_selection.png")
println("Done. Screenshot saved at: ", screenshot_path)
