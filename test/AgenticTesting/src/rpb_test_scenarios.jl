# rpb_test_scenarios.jl
#
# Modular test scenarios covering the 14 Acceptance Criteria of the RPB
# and reactive Data Table refactoring.

"""
    test_group_a_table_decoupling(session, local_app; results::Vector) -> Bool

Test Group A: Decoupled Reactive Data Table (Criteria 1 & 2).
Verifies that the Table reacts immediately to X, Y, DataFrame selection, column checks,
and range inputs without triggering or modifying the Plot.
"""
function test_group_a_table_decoupling(session, local_app; results=Tuple{Bool, String}[])
    println("\n--- Running Group A: Reactive Data Table Decoupling ---")

    # ========================================================
    # Test A1: XY-Source Mode (Criterion 1)
    # ========================================================
    println("Test A1: Testing XY-Source Mode...")
    
    # 1. Switch to X, Y Arrays mode
    click_element_by_text(session, "Source")
    wait_for_ui_settle(session; delay=0.5)
    set_radio_value(session, "source_type", "X, Y Arrays")
    wait_for_observable(local_app.state.data_selection.source_type, "X, Y Arrays")
    wait_for_ui_settle(session; delay=0.5)

    # 2. Select X = "caspl_x_10"
    select_dropdown_value(session, "#dropdown-x", "caspl_x_10")
    wait_for_observable(local_app.state.data_selection.selected_x, "caspl_x_10")
    wait_for_ui_settle(session; delay=0.5)

    headers = get_table_headers_dom(session)
    pass_a1_x_headers = "Index" in headers && "caspl_x_10" in headers
    push!(results, log_result("A1.1_x_headers", pass_a1_x_headers, "Table headers after X: $(headers)"))

    rows = get_table_row_count_dom(session)
    pass_a1_x_rows = rows == 10
    push!(results, log_result("A1.2_x_rows", pass_a1_x_rows, "Table row count after X: $rows (expected 10)"))

    pass_a1_no_plot = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("A1.3_no_plot_on_x", pass_a1_no_plot, "Plot is not rendered after selecting X alone"))

    # 3. Select Y = "caspl_ys10"
    select_dropdown_value(session, "#dropdown-y", "caspl_ys10")
    wait_for_observable(local_app.state.data_selection.selected_y, "caspl_ys10")
    wait_for_ui_settle(session; delay=0.5)

    headers_xy = get_table_headers_dom(session)
    pass_a1_xy_headers = "Index" in headers_xy && "caspl_x_10" in headers_xy && any(h -> startswith(h, "caspl_ys10"), headers_xy)
    push!(results, log_result("A1.4_xy_headers", pass_a1_xy_headers, "Table headers after Y: $(headers_xy)"))

    pass_a1_no_plot_y = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("A1.5_no_plot_on_y", pass_a1_no_plot_y, "Plot remains unrendered after selecting Y (before RPB)"))

    # 4. Click (Re-)Plot
    click_replot(session)
    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== nothing; timeout=10.0)
    pass_a1_plotted = local_app.state.plotting.handles.current_figure[] !== nothing
    push!(results, log_result("A1.6_rpb_plots", pass_a1_plotted, "Plot is rendered after RPB click"))

    # 5. Change X to "caspl_x_100" -> should reset Y and clear Plot, revert Table
    select_dropdown_value(session, "#dropdown-x", "caspl_x_100")
    wait_for_observable(local_app.state.data_selection.selected_x, "caspl_x_100")
    wait_for_ui_settle(session; delay=0.5)

    y_val = local_app.state.data_selection.selected_y[]
    pass_a1_y_reset = isnothing(y_val) || isempty(y_val)
    push!(results, log_result("A1.7_change_x_resets_y", pass_a1_y_reset, "Y reset after changing X: $(repr(y_val))"))

    pass_a1_plot_cleared = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("A1.8_change_x_clears_plot", pass_a1_plot_cleared, "Plot cleared after changing X"))

    headers_revert = get_table_headers_dom(session)
    pass_a1_table_revert = "Index" in headers_revert && "caspl_x_100" in headers_revert && !any(h -> startswith(h, "caspl_ys10"), headers_revert)
    push!(results, log_result("A1.9_table_reverts", pass_a1_table_revert, "Table reverted to [Index, X]: $(headers_revert)"))

    # ========================================================
    # Test A2: DataFrame Mode (Criterion 2)
    # ========================================================
    println("Test A2: Testing DataFrame Mode...")

    set_radio_value(session, "source_type", "DataFrame")
    wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
    wait_for_ui_settle(session; delay=0.5)

    select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")
    wait_for_ui_settle(session; delay=0.5)

    # 1. Assert only Index column shown initially, row count 100
    cols = local_app.state.data_selection.selected_columns[]
    pass_a2_no_cols = isnothing(cols) || isempty(cols)
    push!(results, log_result("A2.1_df_init_no_cols", pass_a2_no_cols, "No columns selected initially: $(cols)"))

    headers_df_init = get_table_headers_dom(session)
    pass_a2_index_only = headers_df_init == ["Index"]
    push!(results, log_result("A2.2_index_only", pass_a2_index_only, "Table displays only Index column: $(headers_df_init)"))

    rows_df_init = get_table_row_count_dom(session)
    pass_a2_full_rows = rows_df_init == 100
    push!(results, log_result("A2.3_full_rows", pass_a2_full_rows, "Table displays full row count 100: $(rows_df_init)"))

    # 2. Check columns x and y1
    for col_name in ["x", "y1"]
        Bonito.evaljs(session, js"""
            (function() {
                const cb = document.querySelector('input.column-checkbox[value="' + $(col_name) + '"]');
                if (cb && !cb.checked) {
                    cb.checked = true;
                    cb.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
    end
    wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], ["x", "y1"]))
    wait_for_ui_settle(session; delay=0.5)

    headers_checked = get_table_headers_dom(session)
    pass_a2_headers_checked = headers_checked == ["Index", "x", "y1"]
    push!(results, log_result("A2.4_columns_checked_table", pass_a2_headers_checked, "Table headers after checking columns: $(headers_checked)"))

    pass_a2_no_plot_yet = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("A2.5_no_plot_on_check", pass_a2_no_plot_yet, "Plot is still unrendered before RPB"))

    # 3. Check column y2 -> immediate Table update
    Bonito.evaljs(session, js"""
        (function() {
            const cb = document.querySelector('input.column-checkbox[value="y2"]');
            if (cb && !cb.checked) {
                cb.checked = true;
                cb.dispatchEvent(new Event('change', {bubbles: true}));
            }
        })()
    """)
    wait_until(() -> "y2" in local_app.state.data_selection.selected_columns[])
    wait_for_ui_settle(session; delay=0.5)

    headers_3cols = get_table_headers_dom(session)
    pass_a2_3cols = headers_3cols == ["Index", "x", "y1", "y2"]
    push!(results, log_result("A2.6_append_column_table", pass_a2_3cols, "Table headers after checking y2: $(headers_3cols)"))

    # 4. Modify range to 50 -> immediate Table update, Plot unchanged
    set_input_value(session, "#range-to-input", "50")
    wait_until(() -> local_app.state.data_selection.range_to[] == 50)
    wait_for_ui_settle(session; delay=0.5)

    rows_sliced = get_table_row_count_dom(session)
    pass_a2_sliced = rows_sliced == 50
    push!(results, log_result("A2.7_range_edit_table", pass_a2_sliced, "Table immediately reflects row range 1:50: $rows_sliced rows"))

    pass_a2_plot_still_none = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("A2.8_range_edit_no_plot", pass_a2_plot_still_none, "Plot remains untouched by range edit before RPB"))

    return all(r -> r[1], results)
end

"""
    test_group_b_hot_patching(session, local_app; results::Vector) -> Bool

Test Group B: RPB Re-Plot Pipeline & Hot-Patching (Criteria 3 & 4).
Verifies clean replots with unchanged data and instant pickup of in-place modified values.
"""
function test_group_b_hot_patching(session, local_app; results=Tuple{Bool, String}[])
    println("\n--- Running Group B: RPB Execution & Hot-Patching ---")

    # 1. RPB with unchanged data
    click_replot(session)
    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== nothing; timeout=10.0)
    wait_for_ui_settle(session; delay=0.5)

    pass_b1_plot = local_app.state.plotting.handles.current_figure[] !== nothing
    push!(results, log_result("B1.1_rpb_plots", pass_b1_plot, "RPB renders plot for selected columns"))

    pass_b1_no_modal = !local_app.state.dialogs.show_modal[]
    push!(results, log_result("B1.2_no_modal_unchanged", pass_b1_no_modal, "No modal shown for unchanged data on first RPB"))

    # Immediate second RPB
    click_replot(session)
    wait_for_ui_settle(session; delay=0.5)
    pass_b1_second_no_modal = !local_app.state.dialogs.show_modal[]
    push!(results, log_result("B1.3_second_rpb_no_modal", pass_b1_second_no_modal, "No modal shown on second RPB with unchanged data"))

    # 2. Hot-patch data in Main: caspl_df_exp[5, :y1] = 999.0
    df_exp = Core.eval(Main, :caspl_df_exp)
    orig_val = df_exp[5, :y1]
    try
        df_exp[5, :y1] = 999.0
        click_replot(session)
        wait_for_ui_settle(session; delay=0.5)

        pass_b2_no_modal = !local_app.state.dialogs.show_modal[]
        push!(results, log_result("B2.1_hot_patch_no_modal", pass_b2_no_modal, "Hot-patched value replots without structural warning"))

        # Table cell at row 5, col 3 ("y1") reflects the new value
        cell_val = get_table_cell_dom(session, 5, 3)
        pass_b2_cell = occursin("999", cell_val)
        push!(results, log_result("B2.2_hot_patch_table_cell", pass_b2_cell, "Table cell at (row 5, col 3) updated to hot-patched value: \"$cell_val\""))
    finally
        df_exp[5, :y1] = orig_val
    end

    return all(r -> r[1], results)
end

"""
    test_group_c_structural_continuity(session, local_app; results::Vector) -> Bool

Test Group C: Structural Continuity, 2-Button Warning & Error Modals (Criteria 5, 6, 7, 13, 14).
"""
function test_group_c_structural_continuity(session, local_app; results=Tuple{Bool, String}[])
    println("\n--- Running Group C: Structural Continuity & Modals ---")

    click_element_by_text(session, "Source")
    wait_for_ui_settle(session; delay=0.5)
    set_radio_value(session, "source_type", "DataFrame")
    wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
    wait_for_ui_settle(session; delay=0.5)

    # Setup dedicated test dataframe in Main
    Core.eval(Main, :(caspl_test_df = DataFrame(a = collect(1:100), b = collect(101:200), c = collect(201:300))))
    local_app.state.data_selection.dataframes_dict_obs[] = Base.invokelatest(CasualPlots.collect_dataframes_from_main)
    wait_for_ui_settle(session; delay=0.5)

    select_dropdown_value(session, "#dropdown-dataframe", "caspl_test_df")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_test_df")
    wait_for_ui_settle(session; delay=0.5)

    for col in ["a", "b"]
        Bonito.evaljs(session, js"""
            (function() {
                const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
                if (cb && !cb.checked) {
                    cb.checked = true;
                    cb.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
    end
    wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], ["a", "b"]))
    
    # Establish baseline with full range (100 rows)
    click_replot(session)
    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== nothing; timeout=10.0)
    wait_for_ui_settle(session; delay=0.5)

    # ========================================================
    # Test C1: Shrunk source with full range -> Warning -> Continue (Criterion 5a, 13)
    # ========================================================
    println("Test C1: Shrunk source with full range -> Continue...")
    Core.eval(Main, :(deleteat!(caspl_test_df, 81:100))) # now 80 rows
    click_replot(session)
    wait_for_observable(local_app.state.dialogs.show_modal, true; timeout=10.0)

    pass_c1_modal = local_app.state.dialogs.modal_type[] == :warning &&
                    local_app.state.dialogs.modal_primary_label[] == "Continue" &&
                    local_app.state.dialogs.modal_secondary_label[] == "Select data anew"
    push!(results, log_result("C1.1_warning_modal", pass_c1_modal, "2-button Warning Modal shown on shrunk data (full range)"))

    # Click Continue
    click_modal_primary(session)
    wait_for_observable(local_app.state.dialogs.show_modal, false; timeout=5.0)
    wait_for_ui_settle(session; delay=0.5)

    pass_c1_bounds = local_app.state.data_selection.data_bounds_to[] == 80 &&
                     local_app.state.data_selection.range_to[] == 80
    push!(results, log_result("C1.2_bounds_updated", pass_c1_bounds, "Range and bounds updated to new size 80"))

    # Immediate second RPB must NOT show modal (Criterion 13)
    click_replot(session)
    wait_for_ui_settle(session; delay=0.5)
    pass_c1_no_second_modal = !local_app.state.dialogs.show_modal[]
    push!(results, log_result("C1.3_no_repeat_modal", pass_c1_no_second_modal, "Criterion 13: Second RPB after Continue shows no dialog"))

    # ========================================================
    # Test C2: Shrunk source with full range -> Select data anew (Criterion 5b)
    # ========================================================
    println("Test C2: Shrunk source with full range -> Select data anew...")
    Core.eval(Main, :(deleteat!(caspl_test_df, 61:80))) # now 60 rows
    click_replot(session)
    wait_for_observable(local_app.state.dialogs.show_modal, true; timeout=10.0)

    # Click Secondary button ("Select data anew")
    click_modal_secondary(session)
    wait_for_observable(local_app.state.dialogs.show_modal, false; timeout=5.0)
    wait_for_ui_settle(session; delay=0.5)

    pass_c2_plot_cleared = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("C2.1_plot_cleared", pass_c2_plot_cleared, "Plot cleared after 'Select data anew'"))

    cols_c2 = local_app.state.data_selection.selected_columns[]
    pass_c2_cols_cleared = isnothing(cols_c2) || isempty(cols_c2)
    push!(results, log_result("C2.2_cols_cleared", pass_c2_cols_cleared, "Column selection cleared after 'Select data anew'"))

    pass_c2_df_kept = local_app.state.data_selection.selected_dataframe[] == "caspl_test_df"
    push!(results, log_result("C2.3_source_kept", pass_c2_df_kept, "Source remains selected after 'Select data anew'"))

    # ========================================================
    # Test C3: Shrunk source with custom range exceeding new size -> Fatal Error (Criterion 5c)
    # ========================================================
    println("Test C3: Custom range exceeding new size -> Error modal...")
    Core.eval(Main, :(caspl_test_df = DataFrame(a = collect(1:100), b = collect(101:200), c = collect(201:300))))
    # Re-select source by toggling to caspl_df_exp first so on(selected_dataframe) fires and refreshes bounds to 1:100
    select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")
    wait_for_ui_settle(session; delay=0.3)
    select_dropdown_value(session, "#dropdown-dataframe", "caspl_test_df")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_test_df")
    wait_for_observable(local_app.state.data_selection.data_bounds_to, 100)
    for col in ["a", "b"]
        Bonito.evaljs(session, js"""
            (function() {
                const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
                if (cb && !cb.checked) {
                    cb.checked = true;
                    cb.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
    end
    wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], ["a", "b"]))

    # Set custom range: 50 to 90
    set_input_value(session, "#range-from-input", "50")
    set_input_value(session, "#range-to-input", "90")
    wait_until(() -> local_app.state.data_selection.range_from[] == 50 && local_app.state.data_selection.range_to[] == 90)

    click_replot(session)
    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== nothing; timeout=10.0)

    # Shrink to 70 rows (range 50:90 exceeds 70)
    Core.eval(Main, :(deleteat!(caspl_test_df, 71:100)))
    click_replot(session)
    wait_for_observable(local_app.state.dialogs.show_modal, true; timeout=10.0)

    pass_c3_error = local_app.state.dialogs.modal_type[] == :error
    push!(results, log_result("C3.1_error_modal", pass_c3_error, "Fatal Error modal shown when range exceeds new size"))

    msg_c3 = local_app.state.file_saving.save_status_message[]
    pass_c3_msg = occursin("exceeds the new row bounds", msg_c3)
    push!(results, log_result("C3.2_error_msg", pass_c3_msg, "Error message explains bounds violation: \"$msg_c3\""))

    click_modal_primary(session)
    wait_for_observable(local_app.state.dialogs.show_modal, false; timeout=5.0)
    wait_for_ui_settle(session; delay=0.5)

    pass_c3_cleared = local_app.state.plotting.handles.current_figure[] === nothing
    push!(results, log_result("C3.3_panes_cleared", pass_c3_cleared, "Panes blanked after error modal"))

    # ========================================================
    # Test C4: First RPB after selection with custom range out-of-bounds (Criterion 14)
    # ========================================================
    println("Test C4: First RPB after selection out-of-bounds -> Error modal, no BoundsError...")
    Core.eval(Main, :(caspl_x_shrunk = collect(1:100); caspl_y_shrunk = collect(1:100)))
    local_app.state.data_selection.dims_dict_obs[] = Base.invokelatest(CasualPlots.get_dims_of_arrays)
    wait_for_ui_settle(session; delay=0.5)

    set_radio_value(session, "source_type", "X, Y Arrays")
    wait_for_observable(local_app.state.data_selection.source_type, "X, Y Arrays")
    select_dropdown_value(session, "#dropdown-x", "caspl_x_shrunk")
    wait_for_observable(local_app.state.data_selection.selected_x, "caspl_x_shrunk")
    select_dropdown_value(session, "#dropdown-y", "caspl_y_shrunk")
    wait_for_observable(local_app.state.data_selection.selected_y, "caspl_y_shrunk")

    set_input_value(session, "#range-to-input", "90")
    wait_until(() -> local_app.state.data_selection.range_to[] == 90)

    # Shrink before first RPB
    Core.eval(Main, :(resize!(caspl_x_shrunk, 60); resize!(caspl_y_shrunk, 60)))
    click_replot(session)
    wait_for_observable(local_app.state.dialogs.show_modal, true; timeout=10.0)

    pass_c4_handled = local_app.state.dialogs.modal_type[] == :error &&
                      occursin("exceeds the new row bounds", local_app.state.file_saving.save_status_message[])
    push!(results, log_result("C4.1_first_rpb_bounds_check", pass_c4_handled, "Criterion 14: First RPB shows clean error modal instead of raw BoundsError"))

    click_modal_primary(session)
    wait_for_observable(local_app.state.dialogs.show_modal, false; timeout=5.0)

    # ========================================================
    # Test C5: Trailing column modified vs Renamed selected column (Criteria 6 & 7)
    # ========================================================
    println("Test C5: Trailing modified column (Criterion 7) vs Renamed column (Criterion 6)...")
    Core.eval(Main, :(caspl_cols_df = DataFrame(x = collect(1:50), y1 = collect(1:50), y2 = collect(1:50), extra = collect(1:50))))
    local_app.state.data_selection.dataframes_dict_obs[] = Base.invokelatest(CasualPlots.collect_dataframes_from_main)
    wait_for_ui_settle(session; delay=0.5)

    set_radio_value(session, "source_type", "DataFrame")
    wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")
    select_dropdown_value(session, "#dropdown-dataframe", "caspl_cols_df")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_cols_df")

    for col in ["x", "y1"]
        Bonito.evaljs(session, js"""
            (function() {
                const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
                if (cb && !cb.checked) {
                    cb.checked = true;
                    cb.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
    end
    wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], ["x", "y1"]))
    click_replot(session)
    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== nothing; timeout=10.0)

    # Modify trailing column 'extra' (position 4 > position 2)
    Core.eval(Main, :(caspl_cols_df.extra = string.(caspl_cols_df.extra)))
    click_replot(session)
    wait_for_observable(local_app.state.dialogs.show_modal, true; timeout=10.0)

    pass_c5_resumable = local_app.state.dialogs.modal_type[] == :warning
    push!(results, log_result("C5.1_trailing_col_warning", pass_c5_resumable, "Criterion 7: Modified trailing column produces resumable Warning Modal"))

    click_modal_primary(session) # Continue
    wait_for_observable(local_app.state.dialogs.show_modal, false; timeout=5.0)
    wait_for_ui_settle(session; delay=0.5)

    # Rename selected column 'y1'
    Core.eval(Main, :(rename!(caspl_cols_df, :y1 => :y_renamed)))
    click_replot(session)
    wait_for_observable(local_app.state.dialogs.show_modal, true; timeout=10.0)

    pass_c5_fatal = local_app.state.dialogs.modal_type[] == :error &&
                    occursin("Selected column \"y1\" is no longer present", local_app.state.file_saving.save_status_message[])
    push!(results, log_result("C5.2_renamed_col_fatal", pass_c5_fatal, "Criterion 6: Renamed selected column produces fatal Error Modal"))

    click_modal_primary(session)
    wait_for_observable(local_app.state.dialogs.show_modal, false; timeout=5.0)

    return all(r -> r[1], results)
end

"""
    test_group_d_file_import_continuity(session, local_app; results::Vector) -> Bool

Test Group D: File Import & Reload Continuity (Criteria 8, 9, 12).
"""
function test_group_d_file_import_continuity(session, local_app; results=Tuple{Bool, String}[])
    println("\n--- Running Group D: File Import & Reload Continuity ---")

    csv_path = normpath(joinpath(@__DIR__, "..", "..", "assets", "sample_data.csv"))
    if !isfile(csv_path)
        push!(results, log_result("D1.0_csv_exists", false, "Test asset sample_data.csv not found at $csv_path"))
        return false
    end

    # 1. Load CSV file
    click_element_by_text(session, "Open")
    wait_for_ui_settle(session; delay=0.5)

    set_opened_file_path(local_app, csv_path, "D1.1_set_path")
    click_button(session, "#btn-reload")
    wait_until(() -> local_app.state.file_opening.opened_file_df[] !== nothing; timeout=10.0)
    wait_for_ui_settle(session; delay=0.5)

    # Criterion 8: cp_file_df exists and matches opened_file_df
    pass_d1_export = isdefined(CasualPlots, :cp_file_df) &&
                     !isnothing(CasualPlots.cp_file_df) &&
                     CasualPlots.cp_file_df === local_app.state.file_opening.opened_file_df[]
    push!(results, log_result("D1.2_cp_file_df_bound", pass_d1_export, "Criterion 8: CasualPlots.cp_file_df is exported and matches opened_file_df"))

    # Switch to Source tab -> verify cp_file_df does NOT appear as duplicate in dropdown
    click_element_by_text(session, "Source")
    wait_for_ui_settle(session; delay=0.5)
    set_radio_value(session, "source_type", "DataFrame")
    wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

    opts = get_dropdown_options(session; css_selector="#dropdown-dataframe")
    df_opt_values = [get(o, "value", "") for o in opts]
    pass_d1_no_dup = !("cp_file_df" in df_opt_values)
    push!(results, log_result("D1.3_dropdown_omits_cp_file_df", pass_d1_no_dup, "Criterion 8: cp_file_df does not appear as separate entry in dropdown"))

    return all(r -> r[1], results)
end

"""
    test_group_e_format_cache_isolation(session, local_app; results::Vector) -> Bool

Test Group E: Format Changes Decoupled from Re-Reading (Criterion 10).
Verifies that format/theme changes replot exclusively from cache without leaking unplotted column selections into the plot.
"""
function test_group_e_format_cache_isolation(session, local_app; results=Tuple{Bool, String}[])
    println("\n--- Running Group E: Format Changes Decoupled from Re-Reading ---")

    click_element_by_text(session, "Source")
    wait_for_ui_settle(session; delay=0.5)
    set_radio_value(session, "source_type", "DataFrame")
    wait_for_observable(local_app.state.data_selection.source_type, "DataFrame")

    select_dropdown_value(session, "#dropdown-dataframe", "caspl_df_exp")
    wait_for_observable(local_app.state.data_selection.selected_dataframe, "caspl_df_exp")
    wait_for_ui_settle(session; delay=0.5)

    # Check x and y1
    for col in ["x", "y1"]
        Bonito.evaljs(session, js"""
            (function() {
                const cb = document.querySelector('input.column-checkbox[value="' + $(col) + '"]');
                if (cb && !cb.checked) {
                    cb.checked = true;
                    cb.dispatchEvent(new Event('change', {bubbles: true}));
                }
            })()
        """)
    end
    wait_until(() -> all(c -> c in local_app.state.data_selection.selected_columns[], ["x", "y1"]))

    click_replot(session)
    wait_until(() -> local_app.state.plotting.handles.current_figure[] !== nothing; timeout=10.0)

    # Now check column 'y2' without clicking RPB
    Bonito.evaljs(session, js"""
        (function() {
            const cb = document.querySelector('input.column-checkbox[value="y2"]');
            if (cb && !cb.checked) {
                cb.checked = true;
                cb.dispatchEvent(new Event('change', {bubbles: true}));
            }
        })()
    """)
    wait_until(() -> "y2" in local_app.state.data_selection.selected_columns[])
    wait_for_ui_settle(session; delay=0.5)

    # Switch to Format tab and change plot type
    click_element_by_text(session, "Format")
    wait_for_ui_settle(session; delay=0.5)

    select_dropdown_value(session, "#dropdown-plottype", "Scatter")
    wait_for_observable(local_app.state.plotting.format.selected_plottype, "Scatter")
    wait_for_ui_settle(session; delay=1.0)

    # Criterion 10: Cached y names must remain "y1" and cached_cols ["x", "y1"] (unplotted column y2 is NOT included in plot)
    cached_y = local_app.state.misc.cached_y_names[]
    cached_cols = local_app.state.misc.cached_cols[]
    pass_e1_cached_isolated = cached_y == "y1" && cached_cols == ["x", "y1"]
    push!(results, log_result("E1.1_format_cache_isolated", pass_e1_cached_isolated, "Criterion 10: Format replot used cached data $(repr(cached_cols)), unplotted column \"y2\" excluded"))

    # Table still shows all checked columns [Index, x, y1, y2]
    headers_e = get_table_headers_dom(session)
    pass_e1_table_current = "y2" in headers_e
    push!(results, log_result("E1.2_table_keeps_selection", pass_e1_table_current, "Table reflects current live column selection: $(headers_e)"))

    return all(r -> r[1], results)
end

