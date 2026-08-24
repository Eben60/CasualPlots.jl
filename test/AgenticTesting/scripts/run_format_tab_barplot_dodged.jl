using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for format_tab_barplot_dodged.png...")
screenshot_path = generate_format_tab_barplot_dodged_screenshot("format_tab_barplot_dodged.png")
println("Done. Screenshot saved at: ", screenshot_path)
