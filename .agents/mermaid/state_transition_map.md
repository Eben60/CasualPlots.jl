# State Transition Map

This state diagram shows the application's reactive states and what triggers transitions between them.

```mermaid
stateDiagram-v2
    [*] --> Idle: App Launched
    
    Idle --> AwaitingY: X Variable Selected\n(Table shows [Index, X])
    Idle --> AwaitingCols: DataFrame or Matrix Selected\n(SourceSignature captured;\nTable shows [Index])
    
    AwaitingY --> DataReady: Y Variable Selected\n(SourceSignature captured;\nTable shows [Index, X, Y...])
    AwaitingY --> Idle: X Deselected
    
    AwaitingCols --> DataReady: >= 2 Columns Checked\n(Table updates immediately)
    AwaitingCols --> Idle: DataFrame/Matrix Deselected
    
    DataReady --> CheckingContinuity: User Clicks (Re-)Plot\n(or Reload on Plotted File)
    PlotDisplayed --> CheckingContinuity: User Clicks (Re-)Plot\n(or Reload on Plotted File)
    
    CheckingContinuity --> Plotting: Structure Identical
    CheckingContinuity --> ContinuityWarning: Resumable Structural Change\n(2-button Warning Modal)
    CheckingContinuity --> Error: Fatal Structural Change\n(DataContinuityError;\nPanes blanked, Selection reset)
    
    ContinuityWarning --> Plotting: User Clicks "Continue"\n(New baseline adopted)
    ContinuityWarning --> Idle: User Clicks "Select data anew"\n(Array Mode: X & Y cleared)
    ContinuityWarning --> AwaitingCols: User Clicks "Select data anew"\n(DF Mode: Columns cleared)
    
    Plotting --> PlotDisplayed: Plot Generated &\nTable Refreshed
    Plotting --> WarningModal: Data Cleansing Warning\n(e.g. non-numerics -> missing,\nstripped incompatible units)
    
    WarningModal --> PlotDisplayed: User Dismisses ("OK")
    
    PlotDisplayed --> Replotting: Format Changed\n(plottype, theme,\ngroup_by, legend,\nlabels, limits/scales)
    
    Replotting --> PlotDisplayed: Format Applied\n(from cached_cleaned_df;\nlabels & limits preserved)
    
    PlotDisplayed --> AwaitingY: X Changed (Plot cleared)
    PlotDisplayed --> AwaitingCols: New DataFrame/Matrix Selected\n(Plot & columns cleared)
    PlotDisplayed --> Idle: Selection Cleared / Mode Switched
    
    %% Save Flow
    PlotDisplayed --> Saving: Save Triggered\n(valid path)
    PlotDisplayed --> SaveError: Save Triggered\n(invalid path/format)
    PlotDisplayed --> ConfirmOverwrite: Save Triggered\n(file exists)
    
    ConfirmOverwrite --> Saving: Overwrite Confirmed
    ConfirmOverwrite --> PlotDisplayed: Cancel Clicked
    
    Saving --> PlotDisplayed: Save Complete\n(success message)
    Saving --> SaveError: Save Failed\n(IO error)
    
    SaveError --> PlotDisplayed: User Acknowledged
    
    Error --> Idle: User Selects Data Anew (Array Mode)
    Error --> AwaitingCols: User Selects Columns Anew (DF Mode)
    
    note right of Plotting
        acquire_source (fresh read from Main or cp_file_df)
        prepare_plot_data! (clean_plot_data! & cache in cached_cleaned_df)
        is_new_source = (x != last_x || y != last_y) or (df != last_dataframe)
        block_format_update = true
        if is_new_source: reset format_is_default
        reset_semipersistent: reset axis limits & scales
        outputs.plot: shows loading spinner
    end note
    
    note right of Replotting
        replot_from_cache! uses cached_cleaned_df
        (never re-reads Main or unplotted selection)
        get_current_axis_limits() preserves limits & scales
        apply_custom_formatting! re-applies non-default labels
    end note
    
    note right of PlotDisplayed
        Global exports & utilities:
        - cp_figure
        - cp_figure_ax
        - cp_file_df
        - CasualPlots.last_error()
    end note
    
    note right of Saving
        CairoMakie.activate!()
        then WGLMakie.activate!()
    end note
    
    note right of ConfirmOverwrite
        show_modal = true
        modal_type = :confirm
        ("Overwrite" / "Cancel")
    end note

    note right of WarningModal
        show_modal = true
        modal_type = :warning
        Plot generated underneath
    end note
```
