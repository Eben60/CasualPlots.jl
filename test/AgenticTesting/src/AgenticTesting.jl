module AgenticTesting

using CasualPlots
using DataFrames
using Dates
using Observables
using Bonito
using FileIO
using PNGFiles
using ImageQualityIndexes
using ColorTypes

include("gui_testing_utils.jl")
include("casualplots_agent_test_utils.jl")
include("generating_screenshots.jl")
include("image_comparison.jl")

include("screenshot_generators/generate_open_tab_screenshot.jl")
include("screenshot_generators/generate_format_tab_barplot_stacked_screenshot.jl")
include("screenshot_generators/generate_format_tab_limits_screenshot.jl")
include("screenshot_generators/generate_Scatter_by_geometry_screenshot.jl")
include("screenshot_generators/generate_format_tab_lines_screenshot.jl")
include("screenshot_generators/generate_format_tab_barplot_dodged_screenshot.jl")
include("screenshot_generators/generate_plot_pane_maximized_screenshot.jl")
include("screenshot_generators/generate_line_symbol_plot_screenshot.jl")
include("screenshot_generators/generate_xy_source_screenshot.jl")
include("screenshot_generators/generate_table_view_screenshot.jl")
include("screenshot_generators/generate_save_tab_script_screenshot.jl")
include("screenshot_generators/generate_dataframe_source_screenshot.jl")

# ==========================================
# 1. Exported API (Main testing entry points)
# ==========================================
export run_screenshot_generator, with_screenshot_env, capture_gui_screenshot, compare_images_ssim, compare_directories_ssim
export generate_open_tab_screenshot, generate_dataframe_source_screenshot, generate_xy_source_screenshot, 
       generate_format_tab_barplot_dodged_screenshot, generate_format_tab_barplot_stacked_screenshot, 
       generate_format_tab_limits_screenshot, generate_format_tab_lines_screenshot, 
       generate_plot_pane_maximized_screenshot, generate_save_tab_script_screenshot, 
       generate_table_view_screenshot, generate_line_symbol_plot_screenshot, 
       generate_Scatter_by_geometry_screenshot

# ==========================================
# 2. Public API (Used via AgenticTesting.xyz)
# ==========================================
public click_button, select_dropdown_value, set_radio_value, toggle_checkbox, get_dropdown_options, click_element_by_text
public wait_for_session, get_active_session, wait_until, wait_for_observable, wait_for_ui_settle

public set_opened_file_path, verify_session_active, verify_file_loaded, verify_file_row_count, verify_range_selection,
       verify_x_selected, verify_y_selected, verify_y_options_filtered_dom, verify_plot_rendered,
       verify_observable_value, verify_format_is_custom, verify_format_is_default,
       verify_axis_limits, verify_modal_visible, verify_file_on_disk, verify_script_runs_cleanly

# 3. Private Internal Plumbing
# (unexported, non-public helpers)
# get_active_element_info, get_active_element_id, get_active_element_tag, get_active_element_value, 
# get_element_info, get_checkboxes_state, get_focusable_elements, calculate_tab_distance, 
# calculate_dropdown_keystrokes, log_result

end # module
