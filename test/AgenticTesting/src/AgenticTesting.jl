module AgenticTesting

using CasualPlots
using DataFrames
using Dates
using Observables
using Bonito

include("gui_testing_utils.jl")
include("casualplots_agent_test_utils.jl")

export log_result, verify_session_active, set_opened_file_path
export verify_file_loaded, verify_file_row_count, verify_range_selection
export verify_x_selected, verify_y_selected, verify_y_options_filtered_dom, verify_plot_rendered
export verify_observable_value, verify_format_is_custom, verify_format_is_default
export verify_axis_limits, verify_modal_visible, verify_file_on_disk
export verify_script_runs_cleanly

export get_active_session, wait_for_session, get_active_element_info, get_active_element_id, get_active_element_tag, get_active_element_value, get_dropdown_options
export select_dropdown_value, click_button, set_radio_value, toggle_checkbox, get_element_info, get_checkboxes_state
export get_focusable_elements, calculate_tab_distance, calculate_dropdown_keystrokes

end # module
