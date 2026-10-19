using CasualPlots
using Test
using DataFrames
using Unitful

# Inject test data into Main scope since CasualPlots looks for DataFrames there
@eval Main import DataFrames: DataFrame
@eval Main import Unitful: @u_str
@eval Main _casualplots_cat_test_df = DataFrame(
    num_col = [1.0, 2.0, 3.0],
    unit_col_x = [1.0u"m", 2.0u"m", 3.0u"m"],
    unit_col_y = [1.0u"s", 2.0u"s", 3.0u"s"],
    str_col = ["A", "B", "C"]
)

using CasualPlots: initialize_app_state, initialize_output_observables, update_unified_plot!

state = initialize_app_state()
outputs = initialize_output_observables()

state.data_selection.source_type[] = "DataFrame"
state.data_selection.selected_dataframe[] = "_casualplots_cat_test_df"

# Test Case 1: Number vs Number
state.data_selection.selected_columns[] = ["num_col", "num_col"]
update_unified_plot!(state, outputs; is_new_data=true)
@test state.plotting.format.x_is_categorical[] == false
@test state.plotting.format.y_is_categorical[] == false

# Test Case 2: Number vs String
state.data_selection.selected_columns[] = ["num_col", "str_col"]
update_unified_plot!(state, outputs; is_new_data=true)
@test state.plotting.format.x_is_categorical[] == false
@test state.plotting.format.y_is_categorical[] == true

# Test Case 3: Unitful vs Unitful
state.data_selection.selected_columns[] = ["unit_col_x", "unit_col_y"]
update_unified_plot!(state, outputs; is_new_data=true)
@test state.plotting.format.x_is_categorical[] == false
@test state.plotting.format.y_is_categorical[] == false

# Test Case 4: String vs Unitful
state.data_selection.selected_columns[] = ["str_col", "unit_col_x"]
update_unified_plot!(state, outputs; is_new_data=true)
@test state.plotting.format.x_is_categorical[] == true
@test state.plotting.format.y_is_categorical[] == false

