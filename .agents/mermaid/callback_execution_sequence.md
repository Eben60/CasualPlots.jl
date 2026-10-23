# Callback Execution Sequence

This sequence diagram shows how Observable changes trigger callbacks and how race conditions are prevented.

```mermaid
sequenceDiagram
    participant User
    participant UI as UI Controls
    participant Obs as Observables
    participant SourceCB as Source & RPB Callbacks
    participant TableCB as Table Callback
    participant FormatCB as Format Callback
    participant Plot as Plot Engine
    participant Table as Table View
    participant SaveCB as Save & Modal Callbacks
    participant Cairo as CairoMakie
    
    %% Initial Data Selection (Decoupled Table)
    Note over User,Table: Array Mode: User Selects Data (Table Updates Immediately)
    User->>UI: Select X variable
    UI->>Obs: selected_x[] = "var_x"
    Obs->>TableCB: Triggered (setup_table_refresh_callback)
    TableCB->>Table: refresh_table! -> [Index, X]
    
    User->>UI: Select Y variable
    UI->>Obs: selected_y[] = "var_y"
    Obs->>SourceCB: Triggered (setup_source_callback)
    SourceCB->>Obs: source_signature[] = capture_signature(:array, x, y)
    Obs->>TableCB: Triggered (setup_table_refresh_callback)
    TableCB->>Table: refresh_table! -> [Index, X, Y...]
    
    %% (Re-)Plot Button Action
    Note over User,Table: Unified (Re-)Plot Button Action (run_rpb!)
    User->>UI: Click "(Re-)Plot" (#btn-replot)
    UI->>Obs: plot_trigger[] += 1
    Obs->>SourceCB: run_rpb!(state, outputs)
    activate SourceCB
    
    SourceCB->>Plot: show_loading_indicator(outputs)
    SourceCB->>SourceCB: fresh_sig = capture_signature(state)
    SourceCB->>SourceCB: check_continuity(baseline, fresh_sig, selection)
    
    alt status == :fatal
        SourceCB->>Obs: show_modal!(type=:error, exception=DataContinuityError)
        SourceCB->>SourceCB: reset_selection! & blank Plot/Table
    else status == :resumable
        SourceCB->>Obs: show_modal!(type=:warning, "Continue" / "Select data anew")
        Note over User,SourceCB: On "Continue": finish_rpb!(adopt_baseline=true)<br/>On "Select data anew": reset_selection!
    else status == :identical
        SourceCB->>SourceCB: acquire_source(state) (fresh read from Main or cp_file_df)
        SourceCB->>SourceCB: prepare_plot_data! (slice, clean_plot_data!, detect categorical, update cached_cleaned_df[])
        SourceCB->>Plot: replot_from_cache! -> do_replot(is_new_data=is_new_source, reset_semipersistent=true)
        Note over Plot: Sets block_format_update[] = true during render,<br/>resets axis limits to defaults, applies custom formatting
        Plot-->>SourceCB: fig_result
        SourceCB->>Obs: plot[] = new figure
        SourceCB->>Table: refresh_table!(state, outputs)
        SourceCB->>Obs: Update last_plotted_*[]
    end
    deactivate SourceCB
    
    %% Format Change (Uses Cached Data)
    Note over User,Table: User Changes Format (Uses Cached Data Only)
    User->>UI: Change plot type to "Scatter"
    UI->>Obs: selected_plottype[] = "Scatter"
    
    Obs->>FormatCB: Triggered (selected_plottype changed)
    activate FormatCB
    
    FormatCB->>Obs: Check block_format_update[]
    alt block_format_update == true
        FormatCB->>FormatCB: Return early (blocked)
    else block_format_update == false
        FormatCB->>Obs: format_is_default[:plottype] = false
        FormatCB->>Plot: replot_from_cache!(state, outputs)
        Note over Plot: Reads cached_cleaned_df[] (does NOT re-read Main)<br/>Merges get_current_axis_limits(state)<br/>Calls do_replot & apply_custom_formatting!
        Plot-->>FormatCB: fig_result
        FormatCB->>Obs: plot[] = new figure
        Note over FormatCB: Table NOT updated
    end
    deactivate FormatCB
    
    %% Axis Limits & Scales Change
    Note over User,Table: User Changes Axis Limits, Reversal, or Log Scale
    User->>UI: Toggle Log scale / Edit Limit / Toggle Reversed
    UI->>Obs: xlog[] / ylog[] / x_min[] / ... updated
    Obs->>FormatCB: Triggered (setup_axis_limits_callbacks)
    activate FormatCB
    FormatCB->>Plot: trigger_axis_replot() -> replot_from_cache! -> do_replot
    Plot-->>FormatCB: fig_result
    FormatCB->>Obs: plot[] = new figure
    deactivate FormatCB
    
    %% Theme Change
    Note over User,Table: User Changes Theme
    User->>UI: Select theme "theme_dark"
    UI->>Obs: selected_theme[] = "theme_dark"
    
    Obs->>FormatCB: Triggered (selected_theme changed)
    activate FormatCB
    FormatCB->>FormatCB: apply_theme!("theme_dark")
    Note over FormatCB: set_theme!(theme_dark())
    FormatCB->>Obs: format_is_default[:theme] = false
    FormatCB->>Plot: replot_from_cache! -> do_replot
    Plot-->>FormatCB: fig_result (with new theme)
    FormatCB->>Obs: plot[] = new figure
    deactivate FormatCB
    
    %% Group By Change
    Note over User,Table: User Changes Group Differentiation
    User->>UI: Select "Geometry" in group_by dropdown
    UI->>Obs: dynamic_attributes[:group_by][] = "Geometry"
    
    Obs->>FormatCB: Triggered (dynamic_attributes callback)
    activate FormatCB
    Note over FormatCB: Lines: linestyle mapping<br/>Scatter: marker mapping
    FormatCB->>Plot: replot_from_cache! -> do_replot
    Plot-->>FormatCB: fig_result (groups by line style/marker)
    FormatCB->>Obs: plot[] = new figure
    deactivate FormatCB
    
    %% DataFrame Mode
    Note over User,Table: DataFrame or Matrix Mode: Selection vs (Re-)Plot
    User->>UI: Select DataFrame/Matrix "df1" (or "opened file")
    UI->>Obs: selected_dataframe[] = "df1"
    Obs->>SourceCB: setup_dataframe_callbacks
    SourceCB->>Obs: selected_columns[] = []
    SourceCB->>Obs: source_signature[] = capture_signature(:table, "df1", opened_file_df[])
    Obs->>TableCB: refresh_table! -> [Index]
    
    User->>UI: Check columns [col1, col2, col3] / Edit Range
    UI->>Obs: selected_columns[] = [col1, col2, col3]
    Obs->>TableCB: refresh_table! -> [Index, col1, col2, col3]
    Note over TableCB: Plot Pane remains unchanged until (Re-)Plot is clicked
    
    User->>UI: Click "(Re-)Plot" (#btn-replot)
    UI->>Obs: plot_trigger[] += 1
    Obs->>SourceCB: Executes unified run_rpb!(state, outputs) (same pipeline as above)
    
    %% Save Flow
    Note over User,Cairo: Save Tab: User Saves Plot
    User->>UI: Click "Select File..." button
    UI->>Obs: dialog_trigger[] += 1
    
    Obs->>SaveCB: Triggered (dialog_trigger changed)
    activate SaveCB
    SaveCB->>SaveCB: Open OS file dialog (save_file)
    SaveCB-->>Obs: save_file_path[] = selected_path
    deactivate SaveCB
    
    User->>UI: Click "Save Plot" button
    UI->>Obs: save_trigger[] += 1
    
    Obs->>SaveCB: Triggered (save_trigger changed)
    activate SaveCB
    
    SaveCB->>Obs: Check current_figure[]
    alt current_figure == nothing
        SaveCB->>Obs: show_modal!(state, "No plot to save"; type=:error, exception=...)
    else valid figure
        SaveCB->>SaveCB: validate_save_path(path)
        alt invalid path or extension
            SaveCB->>Obs: show_modal!(state, error_msg; type=:error, exception=...)
        else valid path
            alt file exists
                SaveCB->>Obs: show_modal!(state, msg; type=:confirm, on_primary=do_save)
                Note over SaveCB: 2-button modal ("Overwrite" / "Cancel")
            else file doesn't exist
                SaveCB->>Cairo: CairoMakie.activate!() & CairoMakie.save(path, fig)
                SaveCB->>Plot: WGLMakie.activate!()
                SaveCB->>Obs: show_modal!(state, "Saved"; type=:success)
            end
        end
    end
    deactivate SaveCB
    
    %% Modal Primary / Secondary Action (Unified Modal Callbacks)
    Note over User,SaveCB: Modal Dialog Button Click (#btn-modal-ok / #btn-modal-cancel)
    User->>UI: Click primary ("OK" / "Continue" / "Overwrite") or secondary ("Select data anew" / "Cancel")
    UI->>Obs: modal_action_primary[] += 1 (or modal_action_secondary[] += 1)
    Obs->>SaveCB: Triggered in create_modal_container
    activate SaveCB
    SaveCB->>Obs: show_modal[] = false
    SaveCB->>SaveCB: Clear modal_callbacks[] & invoke on_primary() / on_secondary() inside try/catch
    deactivate SaveCB
    
    %% Resize Flow
    Note over User,Plot: Window Management: User Resizes Plot
    User->>UI: Drag Plot window border / Maximize
    UI->>Obs: ResizeObserver triggers plot_size[] update
    Obs->>FormatCB: Triggered (setup_plot_resize_callback)
    activate FormatCB
    FormatCB->>Plot: Makie.resize!(fig, w, h)
    Note over FormatCB: In-place resize (no re-render)
    deactivate FormatCB
```
