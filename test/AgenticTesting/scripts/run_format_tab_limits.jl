using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for format_tab_limits.png...")
screenshot_path = generate_format_tab_limits_screenshot("format_tab_limits.png")
println("Done. Screenshot saved at: ", screenshot_path)
