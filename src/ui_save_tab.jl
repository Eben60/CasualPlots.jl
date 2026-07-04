"""
    create_file_dialog_button(dialog_trigger)

Create a button that triggers the OS file save dialog.
"""
function create_file_dialog_button(dialog_trigger)
    DOM.button(
        "Select File...";
        onclick=js"() => window.CasualPlots.incrementObservable($(dialog_trigger))",
        class="btn btn-primary mb-2"
    )
end

"""
    create_path_textarea(save_file_path)

Create a multi-line textarea for displaying/editing the save path.
"""
function create_path_textarea(save_file_path)
    DOM.div(
        DOM.label("File Path:"; class="form-label"),
        DOM.textarea(
            id="save-path-input",
            value=save_file_path,
            placeholder="/path/to/save/plot.png",
            onchange=js"event => window.CasualPlots.updateObservableValue(event, $(save_file_path))",
            onblur=js"event => window.CasualPlots.updateObservableValue(event, $(save_file_path))",
            class="input-textarea",
            style=Styles("height" => "60px") # Height is specific enough to keep inline or add .h-60? Inline is fine for specific dims.
        );
        class="mb-2"
    )
end

"""
    create_button_save_plot(save_trigger, button_enabled)

Create the main Save button that triggers saving.
"""
function create_button_save_plot(save_trigger, button_enabled)
    # Re-render button when enabled state changes to update interactions/styles
    map(button_enabled) do enabled
        DOM.button(
            "Save Plot";
            onclick=enabled ? js"() => window.CasualPlots.incrementObservable($(save_trigger))" : js"() => {}",
            disabled=!enabled,
            class=enabled ? "btn btn-success mb-2" : "btn btn-disabled mb-2"
        )
    end
end

"""
    create_button_create_script(script_trigger, button_enabled)

Create the button that triggers code generation.
"""
function create_button_create_script(script_trigger, button_enabled)
    map(button_enabled) do enabled
        DOM.button(
            "Create Script";
            onclick=enabled ? js"() => window.CasualPlots.incrementObservable($(script_trigger))" : js"() => {}",
            disabled=!enabled,
            class=enabled ? "btn btn-primary mb-2" : "btn btn-disabled mb-2"
        )
    end
end

"""
    setup_save_callbacks!(state, dialog_trigger, save_trigger, script_trigger, overwrite_trigger, cancel_trigger)

Setup Julia-side callbacks for save functionality.
Callbacks now show popup modals instead of inline status displays.
"""
function setup_save_callbacks!(state, dialog_trigger, save_trigger, script_trigger, overwrite_trigger, cancel_trigger)
    (; save_file_path, save_status_message, save_status_type) = state.file_saving
    (; show_modal, modal_type) = state.dialogs
    (; current_figure) = state.plotting.handles
    
    save_type = Ref(:plot)
    
    # Callback for file dialog button
    on(dialog_trigger) do _
        # Use current path's directory as starting point if available
        current_path = save_file_path[]
        start_path = ""
        if !isempty(current_path)
            dir = dirname(current_path)
            if isdir(dir)
                start_path = dir
            end
        end
        
        result = save_file(start_path)
        if !isnothing(result) && !isempty(result)
            save_file_path[] = result
        end
    end
    
    # Callback for save button
    on(save_trigger) do _
        save_type[] = :plot
        path = strip(save_file_path[])
        
        # Check if there's a plot to save
        if isnothing(current_figure[])
            save_status_message[] = "No plot to save. Create a plot first."
            modal_type[] = :error
            show_modal[] = true
            return
        end
        
        # Validate path
        val = validate_save_path(path)
        if !val.valid
            save_status_message[] = val.error_message
            modal_type[] = :error
            show_modal[] = true
            return
        end
        
        # Check if file exists - show confirmation modal
        if isfile(path)
            save_status_message[] = "File already exists. Do you want to overwrite it?"
            modal_type[] = :confirm
            show_modal[] = true
            return
        end
        
        # Save the file
        do_save(path, state, save_type[])
    end

    # Callback for create script button
    on(script_trigger) do _
        save_type[] = :script
        path = strip(save_file_path[])
        
        # Check if there's a plot to save script for
        if isnothing(current_figure[])
            save_status_message[] = "No plot to create script for."
            modal_type[] = :error
            show_modal[] = true
            return
        end
        
        # For overwrite check, we must know the final file path
        valid, path, err_msg = validate_script_path(path)
        if !valid
            save_status_message[] = err_msg
            modal_type[] = :error
            show_modal[] = true
            return
        end
        
        if isfile(path)
            save_status_message[] = "File already exists. Do you want to overwrite it?"
            modal_type[] = :confirm
            show_modal[] = true
            return
        end
        
        do_save(path, state, save_type[])
    end
    
    # Callback for overwrite confirmation
    on(overwrite_trigger) do _
        show_modal[] = false
        path = strip(save_file_path[])
        if save_type[] == :script
             _, path, _ = validate_script_path(path)
        end
        
        fig = current_figure[]
        if !isnothing(fig)
            do_save(path, state, save_type[])
        end
    end
    
    # Callback for cancel button
    on(cancel_trigger) do _
        show_modal[] = false
        save_status_message[] = ""
        modal_type[] = :none
    end
end

"""
    do_save(path, state, type)

Actually perform the save operation and show result in modal popup.
"""
function do_save(path, state, type)
    (; save_status_message, save_status_type) = state.file_saving
    (; show_modal, modal_type) = state.dialogs
    (; current_figure) = state.plotting.handles
    
    if type == :plot
        (success, message) = save_current_plot(path, current_figure[])
    else
        res = generate_julia_code(state; file=path)
        success = res.success
        message = res.message
    end
    
    save_status_message[] = message
    save_status_type[] = success ? :success : :error
    modal_type[] = success ? :success : :error
    show_modal[] = true
end

"""
    create_save_tab_content(state)

Create the complete Save tab UI content.

Returns a NamedTuple with:
- `content`: The DOM element for the save tab
- `overwrite_trigger`: Observable for overwrite button (used by modal)
- `cancel_trigger`: Observable for cancel button (used by modal)
"""
function create_save_tab_content(state)
    (; save_file_path) = state.file_saving
    (; current_figure) = state.plotting.handles
    
    # Create trigger observables for button clicks
    dialog_trigger = Observable(0)
    save_trigger = Observable(0)
    script_trigger = Observable(0)
    overwrite_trigger = Observable(0)
    cancel_trigger = Observable(0)
    
    # Button enabled state
    button_enabled = map(current_figure) do fig
        !isnothing(fig)
    end
    
    # Setup callbacks
    setup_save_callbacks!(state, dialog_trigger, save_trigger, script_trigger, overwrite_trigger, cancel_trigger)
    
    # Create UI elements (status is now shown in modal popup)
    file_dialog_button = create_file_dialog_button(dialog_trigger)
    path_input = create_path_textarea(save_file_path)
    save_button = create_button_save_plot(save_trigger, button_enabled)
    script_button = create_button_create_script(script_trigger, button_enabled)
    
    buttons_row = DOM.div(
        save_button,
        script_button;
        class="d-flex justify-content-between",
        style=Styles("display" => "flex", "justify-content" => "space-between")
    )
    
    content = DOM.div(
        file_dialog_button,
        path_input,
        buttons_row;
        class="p-1"
    )
    
    return (; content, overwrite_trigger, cancel_trigger)
end
