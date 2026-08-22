# run_open_tab_screenshot.jl

using ShareAdd

# Load CSV and XLSX to trigger CasualPlots' package extensions
@usingany CasualPlots, CSV, XLSX

# Include and use the local AgenticTesting module
@usingany AgenticTesting

println("Starting automated UI interaction...")
# Generates the screenshot and saves it to docs/src/Screenshots/tmp/open_file_tab_1.png
generate_open_tab_screenshot("open_file_tab_3.png")

println("Screenshot generation complete.")
