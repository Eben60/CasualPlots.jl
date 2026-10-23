using Test
using DataFrames

@testset "DataContinuityError" begin
    using CasualPlots: DataContinuityError

    err = DataContinuityError("custom continuity error")
    @test err isa Exception
    @test sprint(showerror, err) == "custom continuity error"
end

@testset "SourceSignature Construction and Equality" begin
    using CasualPlots: SourceSignature

    sig1 = SourceSignature(:array, "y vs x", 1, 100, ["x", "y"], [Float64, Float64], false, 1, 100)
    sig2 = SourceSignature(:array, "y vs x", 1, 100, ["x", "y"], [Float64, Float64], false, 1, 100)
    sig3 = SourceSignature(:table, "df", 1, 100, ["x", "y"], [Float64, Float64], false, 1, 100)
    sig4 = SourceSignature(:array, "y vs x", 1, 100, ["x", "y"], [Float64, Int], false, 1, 100)

    @test sig1 == sig2
    @test sig1 != sig3
    @test sig1 != sig4
    @test sig1.coltypes isa Vector{Type}
end

@testset "capture_signature for Array Mode" begin
    using CasualPlots: capture_signature, DataContinuityError

    # Set up variables in Main for testing
    Main.eval(:(test_x = [1.0, 2.0, 3.0, 4.0]))
    Main.eval(:(test_y = [10.0, 20.0, 30.0, 40.0]))
    Main.eval(:(test_y_mat = [10.0 100.0; 20.0 200.0; 30.0 300.0; 40.0 400.0]))
    Main.eval(:(test_non_array = "hello"))

    sig = capture_signature(:array, "test_x", "test_y")
    @test sig.kind == :array
    @test sig.first_index == 1
    @test sig.last_index == 4
    @test sig.colnames == ["test_x", "test_y"]
    @test sig.coltypes == Type[Float64, Float64]
    @test !sig.is_matrix

    sig_mat = capture_signature(:array, "test_x", "test_y_mat")
    @test sig_mat.kind == :array
    @test sig_mat.is_matrix
    @test sig_mat.colnames == ["test_x", "test_y_mat_1", "test_y_mat_2"]
    @test sig_mat.coltypes == Type[Float64, Float64, Float64]

    # Error conditions
    Main.eval(:(test_string_vec = ["a", "b", "c", "d"]))
    @test_throws DataContinuityError capture_signature(:array, "nonexistent_x", "test_y")
    @test_throws DataContinuityError capture_signature(:array, "test_x", "nonexistent_y")
    @test_throws DataContinuityError capture_signature(:array, "test_non_array", "test_y")
    @test_throws DataContinuityError capture_signature(:array, "test_string_vec", "test_y")
    @test_throws DataContinuityError capture_signature(:table, "test_x", "test_y")
end

@testset "capture_signature for Table Mode" begin
    using CasualPlots: capture_signature, DataContinuityError

    Main.eval(:(test_df = DataFrame(; a = [1, 2, 3], b = [4.0, 5.0, 6.0])))
    Main.eval(:(test_mat = [1 2; 3 4; 5 6]))

    sig = capture_signature(:table, "test_df")
    @test sig.kind == :table
    @test !sig.is_matrix
    @test sig.first_index == 1
    @test sig.last_index == 3
    @test sig.colnames == ["a", "b"]
    @test sig.coltypes == Type[Int, Float64]

    sig_mat = capture_signature(:table, "test_mat")
    @test sig_mat.kind == :table
    @test sig_mat.is_matrix
    @test sig_mat.colnames == ["test_mat_1", "test_mat_2"]
    @test sig_mat.coltypes == Type[Int, Int]

    # __opened_file__
    opened_df = DataFrame(; col1 = ["x", "y"], col2 = [10, 20])
    sig_opened = capture_signature(:table, "__opened_file__", opened_df)
    @test sig_opened.kind == :table
    @test sig_opened.colnames == ["col1", "col2"]
    @test sig_opened.last_index == 2

    # Error conditions
    @test_throws DataContinuityError capture_signature(:table, "nonexistent_df")
    @test_throws DataContinuityError capture_signature(:table, "__opened_file__", nothing)
end

@testset "check_continuity: Rule 1 (XY Lengths)" begin
    using CasualPlots: SourceSignature, check_continuity

    old = SourceSignature(:array, "y vs x", 1, 10, ["x", "y"], [Float64, Float64], false, 1, 10)
    selection = (;
        selected_columns = ["x", "y"],
        range_from = 1,
        range_to = 10,
        full_range = true,
        all_columns = true,
    )

    # XY length mismatch in new
    new_mismatch = SourceSignature(:array, "y vs x", 1, 10, ["x", "y"], [Float64, Float64], false, 1, 8)
    res = check_continuity(old, new_mismatch, selection)
    @test res.status == :fatal
    @test occursin("does not match", res.reason)
end

@testset "check_continuity: Rule 2 (Row Range & Offset Arrays)" begin
    using CasualPlots: SourceSignature, check_continuity

    old = SourceSignature(:array, "y vs x", 1, 100, ["x", "y"], [Float64, Float64], false, 1, 100)

    # Full range with shrunk rows: resumable
    new_shrunk = SourceSignature(:array, "y vs x", 1, 80, ["x", "y"], [Float64, Float64], false, 1, 80)
    sel_full = (;
        selected_columns = ["x", "y"],
        range_from = 1,
        range_to = 100,
        full_range = true,
        all_columns = true,
    )
    res = check_continuity(old, new_shrunk, sel_full)
    @test res.status == :resumable
    @test any(c -> occursin("Row count changed from 100 to 80", c), res.changes)

    # Custom range exceeding new bounds: fatal
    sel_custom = (;
        selected_columns = ["x", "y"],
        range_from = 1,
        range_to = 90,
        full_range = false,
        all_columns = true,
    )
    res_fatal = check_continuity(old, new_shrunk, sel_custom)
    @test res_fatal.status == :fatal
    @test occursin("exceeds the new row bounds", res_fatal.reason)

    # Invalid range: from > to
    sel_invalid = (;
        selected_columns = ["x", "y"],
        range_from = 50,
        range_to = 20,
        full_range = false,
        all_columns = true,
    )
    res_inv = check_continuity(old, new_shrunk, sel_invalid)
    @test res_inv.status == :fatal
    @test occursin("cannot be greater than", res_inv.reason)

    # Offset array simulation: bounds -50:50 shrunk to -50:40
    old_offset = SourceSignature(:array, "y vs x", -50, 50, ["x", "y"], [Float64, Float64], false, -50, 50)
    new_offset = SourceSignature(:array, "y vs x", -50, 40, ["x", "y"], [Float64, Float64], false, -50, 40)
    sel_offset_fatal = (;
        selected_columns = ["x", "y"],
        range_from = -10,
        range_to = 45,
        full_range = false,
        all_columns = true,
    )
    res_offset = check_continuity(old_offset, new_offset, sel_offset_fatal)
    @test res_offset.status == :fatal
    @test occursin("exceeds the new row bounds", res_offset.reason)
end

@testset "check_continuity: Rule 3 (Matrix Columns)" begin
    using CasualPlots: SourceSignature, check_continuity

    old_mat = SourceSignature(
        :table,
        "mat",
        1,
        50,
        ["mat_1", "mat_2", "mat_3", "mat_4"],
        [Float64, Float64, Float64, Float64],
        true,
        1,
        50,
    )

    # All columns selected: shrunk column count is resumable
    new_mat_shrunk = SourceSignature(
        :table,
        "mat",
        1,
        50,
        ["mat_1", "mat_2"],
        [Float64, Float64],
        true,
        1,
        50,
    )
    sel_all = (;
        selected_columns = ["mat_1", "mat_2", "mat_3", "mat_4"],
        range_from = 1,
        range_to = 50,
        full_range = true,
        all_columns = true,
    )
    res = check_continuity(old_mat, new_mat_shrunk, sel_all)
    @test res.status == :resumable
    @test any(c -> occursin("Matrix column count changed from 4 to 2", c), res.changes)

    # Specific columns selected: position 4 missing in 2-column matrix is fatal
    sel_subset = (;
        selected_columns = ["mat_1", "mat_4"],
        range_from = 1,
        range_to = 50,
        full_range = true,
        all_columns = false,
    )
    res_fatal = check_continuity(old_mat, new_mat_shrunk, sel_subset)
    @test res_fatal.status == :fatal
    @test occursin("less than highest selected column position", res_fatal.reason)
end

@testset "check_continuity: Rule 4 (DataFrame Columns)" begin
    using CasualPlots: SourceSignature, check_continuity

    old_df = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["time", "temp", "pressure", "notes"],
        [Float64, Float64, Float64, String],
        false,
        1,
        100,
    )

    # 1. Selected column deleted in new -> fatal
    new_del = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["time", "pressure", "notes"],
        [Float64, Float64, String],
        false,
        1,
        100,
    )
    sel = (;
        selected_columns = ["time", "temp"],
        range_from = 1,
        range_to = 100,
        full_range = true,
        all_columns = false,
    )
    res = check_continuity(old_df, new_del, sel)
    @test res.status == :fatal
    @test occursin("Selected column \"temp\" is no longer present", res.reason)

    # 2. Column before p renamed -> fatal
    new_renamed = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["timestamp", "temp", "pressure", "notes"],
        [Float64, Float64, Float64, String],
        false,
        1,
        100,
    )
    sel_p3 = (;
        selected_columns = ["temp", "pressure"],
        range_from = 1,
        range_to = 100,
        full_range = true,
        all_columns = false,
    )
    res_ren = check_continuity(old_df, new_renamed, sel_p3)
    @test res_ren.status == :fatal
    @test occursin("Column 1 name changed", res_ren.reason)

    # 3. Column up to p changed type -> fatal (Decision Q2)
    new_type_change = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["time", "temp", "pressure", "notes"],
        [Int, Float64, Float64, String],
        false,
        1,
        100,
    )
    res_type = check_continuity(old_df, new_type_change, sel)
    @test res_type.status == :fatal
    @test occursin("type changed", res_type.reason)

    # 4. Trailing column after p added -> resumable
    new_added = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["time", "temp", "pressure", "notes", "extra"],
        [Float64, Float64, Float64, String, Float64],
        false,
        1,
        100,
    )
    res_add = check_continuity(old_df, new_added, sel)
    @test res_add.status == :resumable
    @test any(c -> occursin("Trailing columns added: extra", c), res_add.changes)

    # 5. Trailing column after p removed -> resumable
    new_removed = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["time", "temp", "pressure"],
        [Float64, Float64, Float64],
        false,
        1,
        100,
    )
    res_rem = check_continuity(old_df, new_removed, sel)
    @test res_rem.status == :resumable
    @test any(c -> occursin("Trailing columns removed: notes", c), res_rem.changes)

    # 6. Trailing column after p renamed -> resumable (Criterion 7)
    new_trail_renamed = SourceSignature(
        :table,
        "df",
        1,
        100,
        ["time", "temp", "pressure", "remarks"],
        [Float64, Float64, Float64, String],
        false,
        1,
        100,
    )
    res_trail_ren = check_continuity(old_df, new_trail_renamed, sel)
    @test res_trail_ren.status == :resumable
    @test any(c -> occursin("Column 4 name changed from \"notes\" to \"remarks\"", c), res_trail_ren.changes)

    # 7. Identical -> identical
    res_ident = check_continuity(old_df, old_df, sel)
    @test res_ident.status == :identical
    @test isempty(res_ident.changes)
end

@testset "RPB Pipeline: Validation on first RPB and hot-patching" begin
    using CasualPlots: CasualPlotsState, OutputObservables, run_rpb!, capture_signature,
                       setup_dataframe_callbacks, create_modal_container

    Main.eval(:(rpb_test_df = DataFrame(; a = [1.0, 2.0, 3.0, 4.0, 5.0], b = [10.0, 20.0, 30.0, 40.0, 50.0])))

    state = CasualPlotsState()
    outputs = OutputObservables()
    create_modal_container(state)
    setup_dataframe_callbacks(state, outputs)

    # 1. Select DataFrame and columns
    state.data_selection.source_type[] = "DataFrame"
    state.data_selection.selected_dataframe[] = "rpb_test_df"
    state.data_selection.selected_columns[] = ["a", "b"]

    # Baseline captured at selection time
    baseline = state.misc.source_signature[]
    @test !isnothing(baseline)
    @test baseline.last_index == 5

    # First RPB execution (Q3: validates continuity even on first RPB)
    run_rpb!(state, outputs)
    @test !isnothing(state.plotting.handles.current_figure[])
    @test state.dialogs.show_modal[] == false
    @test state.misc.last_plotted_dataframe[] == "rpb_test_df"

    # Baseline remains unchanged after a plain successful RPB (Q4)
    @test state.misc.source_signature[] == baseline

    # Hot-patching: modify a value in place and RPB
    Main.eval(:(rpb_test_df[3, :b] = 999.0))
    run_rpb!(state, outputs)
    @test state.dialogs.show_modal[] == false

    # Resumable change: shrink with full_range=true shows 2-button warning
    Main.eval(:(deleteat!(rpb_test_df, 4:5)))
    @test_logs (:warn, r"Row count changed") run_rpb!(state, outputs)
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :warning
    @test state.dialogs.modal_primary_label[] == "Continue"
    @test state.dialogs.modal_secondary_label[] == "Select data anew"

    # Clicking Continue triggers modal_action_primary which closes modal and adopts fresh signature (Q4)
    state.dialogs.modal_action_primary[] += 1
    @test state.dialogs.show_modal[] == false
    @test state.misc.source_signature[].last_index == 3

    # Immediate second RPB shows no dialog (Q4)
    run_rpb!(state, outputs)
    @test state.dialogs.show_modal[] == false

    # Fatal change: range exceeding new size throws/shows error modal (Criterion 14)
    state.data_selection.range_from[] = 1
    state.data_selection.range_to[] = 10
    Main.eval(:(deleteat!(rpb_test_df, 2:3))) # only 1 row left
    @test_logs (:warn, r"exceeds the new row bounds") run_rpb!(state, outputs)
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :error
    @test isempty(state.data_selection.selected_columns[]) # selection reset
    @test outputs.table_title[] == "Data Table (Error)"

    # Matrix all_columns selected: Continue adopts new full set of columns (Spec §C.3 & §C.5)
    Main.eval(:(rpb_test_mat = [1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0]))
    state.dialogs.show_modal[] = false
    state.data_selection.selected_dataframe[] = "rpb_test_mat"
    state.data_selection.selected_columns[] = ["rpb_test_mat_1", "rpb_test_mat_2", "rpb_test_mat_3"]
    run_rpb!(state, outputs)
    @test state.dialogs.show_modal[] == false

    # Grow matrix to 4 columns and click RPB -> resumable warning -> Continue selects all 4 columns
    Main.eval(:(rpb_test_mat = [1.0 2.0 3.0 4.0; 5.0 6.0 7.0 8.0; 9.0 10.0 11.0 12.0]))
    @test_logs (:warn, r"Matrix column count changed") run_rpb!(state, outputs)
    @test state.dialogs.show_modal[] == true
    @test state.dialogs.modal_type[] == :warning
    state.dialogs.modal_action_primary[] += 1
    @test state.dialogs.show_modal[] == false
    @test state.data_selection.selected_columns[] == ["rpb_test_mat_1", "rpb_test_mat_2", "rpb_test_mat_3", "rpb_test_mat_4"]
end
