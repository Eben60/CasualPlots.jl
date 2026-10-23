# High-Level User Flow

This flowchart shows the main user paths through the application, highlighting the two distinct data input modes (Array and DataFrame), file import with configurable reading options (header, skip rows, delimiter), reload functionality, and Save functionality.

```mermaid
flowchart TD
    Start([Launch casualplots_app]) --> TabSelect{Select Data Source Type}
    
    TabSelect -->|Array Tab| ArrayMode[Array Mode]
    TabSelect -->|DataFrame Tab| DFMode[DataFrame Mode]
    TabSelect -->|Open Tab| OpenMode[Open File Tab]

    %% Open File Flow
    OpenMode --> ConfigOptions[Configure Reading Options]
    ConfigOptions --> SelectFile[Click Open File Button]
    SelectFile --> HandleClick[handle_open_file_click]
    HandleClick --> FileType{File Type?}
    FileType -->|CSV/TSV| LoadCSV[load_csv_to_table]
    FileType -->|XLSX| ShowSheets[Auto-load First Sheet & Show Dropdown]
    ShowSheets --> LoadXLSX[load_xlsx_sheet_to_table]
    
    LoadCSV --> ReadError{Read Error?}
    LoadXLSX --> ReadError
    HandleClick -->|File/Sheet Error| ReadError
    ReadError -->|Yes| ErrorModal[Show Error Modal & REPL Warning]
    ErrorModal --> OpenMode
    
    ReadError -->|No| SkipRows[skip_rows!]
    SkipRows --> NormalizeLoad[normalize_strings!]
    NormalizeLoad --> StoreDF["Store in opened_file_df + Export cp_file_df + Preview in Table"]
    StoreDF --> DFMode
    
    %% Reload Flow
    ConfigOptions --> ReloadBtn{Reload Button}
    ReloadBtn -->|File Loaded| ReloadFile["Reload with New Options (Preserves Selection; Auto-Replots if Plotted)"]
    ReloadFile --> FileType
    ReloadBtn -->|No File| ConfigOptions
    
    %% Array Mode Flow
    ArrayMode --> SelectX[Select X Variable from Dropdown]
    SelectX --> UpdateTableX["Update Table with [Index, X]"]
    UpdateTableX --> SelectY[Select Y Variable from Dropdown]
    SelectY --> ValidateArrays{Both X & Y Valid?}
    ValidateArrays -->|No| WaitArrays[Wait for Selection]
    ValidateArrays -->|Yes| UpdateTableXY["Update Table with [Index, X, Y...]"]
    UpdateTableXY --> ClickRPB["User Clicks (Re-)Plot Button"]
    ClickRPB --> CheckContinuity{Structural Continuity?}
    CheckContinuity -->|Fatal Error| ErrorModal[Show Error Modal & Reset]
    CheckContinuity -->|Resumable Change| WarnModal["Show Warning Modal: Continue / Select data anew"]
    WarnModal -->|Continue| FetchData[Fresh Read from Main Module]
    WarnModal -->|Select data anew| ArrayMode
    CheckContinuity -->|Identical / Valid| FetchData
    FetchData --> CleanData[clean_plot_data! & Cache in cached_cleaned_df]
    CleanData --> CreatePlot[Generate Plot with Default or User Labels]
    CreatePlot --> DisplayPlot[Display Plot + Refreshed Table]
    
    %% DataFrame Mode Flow
    DFMode --> SelectDF["Select DataFrame or Matrix (Main or Opened File)"]
    ValidateDF{DataFrame or Matrix Valid?}
    SelectDF --> ValidateDF
    ValidateDF -->|No| WaitDF[Wait for Selection]
    ValidateDF -->|Yes| ShowTableIndex[Update Table with Index Only]
    ShowTableIndex --> ShowCols[Display Column Checkboxes]
    ShowCols --> SelectCols[Toggle Columns via Checkboxes]
    SelectCols --> UpdateTableCols[Update Table Columns Immediately]
    UpdateTableCols --> ClickDFRPB["User Clicks (Re-)Plot Button"]
    ClickDFRPB --> CheckDFContinuity{Structural Continuity?}
    CheckDFContinuity -->|Fatal Error| ErrorModal
    CheckDFContinuity -->|Resumable Change| WarnDFModal["Show Warning Modal: Continue / Select data anew"]
    WarnDFModal -->|Continue| FetchDFData[Fresh Read from Main or cp_file_df]
    WarnDFModal -->|Select data anew| DFMode
    CheckDFContinuity -->|Identical / Valid| FetchDFData
    FetchDFData --> CleanDFData[clean_plot_data! & Cache in cached_cleaned_df]
    CleanDFData --> CreateDFPlot[Generate DataFrame Plot]
    CreateDFPlot --> DisplayDFPlot[Display Plot + Refreshed Table]
    
    %% Format Updates
    DisplayPlot --> FormatControls[Format Controls Available]
    DisplayDFPlot --> FormatControls
    FormatControls --> UserEdit{User Edits Format?}
    UserEdit -->|Plot Type| MarkNonDefault[Mark format_is_default = false]
    UserEdit -->|Theme| ApplyTheme[apply_theme! + Mark non-default]
    UserEdit -->|Group By| GroupByChange[Update group mapping]
    UserEdit -->|Legend Toggle| MarkNonDefault
    UserEdit -->|Legend Title| MarkNonDefault
    UserEdit -->|Axis Limits & Scales| AxisLimitEdit[Update Limits, Reversal, or Log Scale]
    UserEdit -->|Labels| UpdateLabels[Update Axis Labels Directly]
    
    ApplyTheme --> DoReplot["replot_from_cache! -> do_replot"]
    GroupByChange --> DoReplot
    AxisLimitEdit --> DoReplot
    MarkNonDefault --> DoReplot
    DoReplot --> ApplyCustom[apply_custom_formatting!]
    DoReplot -.- NoteLimits["Note: Uses cached_cleaned_df (no source re-read) & preserves limits/scales"]
    ApplyCustom -.- NoteCustom["Note: Re-apply non-default labels"]
    
    UpdateLabels --> RefreshPlot[Refresh Plot Display]
    ApplyCustom --> RefreshPlot
    
    RefreshPlot --> FormatControls
    
    %% Save & Code Flow
    DisplayPlot --> SaveTab[Save / Code Tab Available]
    DisplayDFPlot --> SaveTab
    SaveTab --> SaveAction{User Action}
    SaveAction -->|File Dialog Button| FileDialog[Open OS File Dialog]
    FileDialog --> PathSelected[Path Selected]
    SaveAction -->|Type Path| TypePath[Type Path in Textarea]
    PathSelected --> ValidateAction[User Clicks Save/Generate Button]
    TypePath --> ValidateAction
    SaveAction -->|Save Plot Button| ValidateAction
    SaveAction -->|Create Script Button| ValidateAction
    ValidateAction --> ValidatePath{Path Valid?}
    ValidatePath -->|No| ShowPathError[Show Error Modal]
    ValidatePath -->|Yes| CheckExists{File Exists?}
    CheckExists -->|No| DoSave[Save Plot or Script to File]
    CheckExists -->|Yes| ConfirmOverwrite{Show Confirm Modal}
    ConfirmOverwrite -->|Cancel| SaveTab
    ConfirmOverwrite -->|Overwrite| DoSave
    DoSave --> SaveSuccess[Show Success Modal]
    ShowPathError -->|Click OK| SaveTab
    SaveSuccess -->|Click OK| SaveTab
    
    %% Export
    DisplayPlot -.->|Exported to Main| GlobalVars[cp_figure, cp_figure_ax, cp_file_df]
    DisplayDFPlot -.->|Exported to Main| GlobalVars
    
    style Start fill:#e1f5ff
    style DisplayPlot fill:#d4edda
    style DisplayDFPlot fill:#d4edda
    style Error fill:#f8d7da
    style ErrorModal fill:#f8d7da
    style ShowPathError fill:#f8d7da
    style ConfirmOverwrite fill:#fff3cd
    style GlobalVars fill:#fff3cd
    style SaveSuccess fill:#d4edda
    style ConfigOptions fill:#e8f4fd
    style NoteLimits fill:#ffffde,stroke:#aaaa33
    style NoteCustom fill:#ffffde,stroke:#aaaa33
```
