using ShareAdd
@usingany CasualPlots, AgenticTesting
CasualPlots.@populate()

println("Starting screenshot generation for save_tab_script.png...")
screenshot_path = generate_save_tab_script_screenshot("save_tab_script.png")
println("Done. Screenshot saved at: ", screenshot_path)
