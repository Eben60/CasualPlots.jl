# UI components for the Save tab
# Uses Observable-based communication between JS and Julia

"""
    create_file_dialog_button(dialog_trigger)

Create a button that triggers the OS file save dialog.
"""
function create_file_dialog_button(dialog_trigger)
    DOM.button(
        "Select File...";
        onclick=js"() => $(dialog_trigger).notify($(dialog_trigger).value + 1)",
        style=Styles(
            "padding" => "8px 16px",
            "cursor" => "pointer",
            "background-color" => "#2196F3",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px",
            "margin-bottom" => "10px"
        )
    )
end

"""
    create_path_textarea(save_file_path)

Create a multi-line textarea for displaying/editing the save path.
"""
function create_path_textarea(save_file_path)
    DOM.div(
        DOM.label("File Path:"; style=Styles("font-weight" => "bold", "margin-bottom" => "5px", "display" => "block")),
        DOM.textarea(
            id="save-path-input",
            value=save_file_path,
            placeholder="/path/to/save/plot.png",
            onchange=js"event => $(save_file_path).notify(event.target.value)",
            onblur=js"event => $(save_file_path).notify(event.target.value)",
            style=Styles(
                "width" => "100%",
                "height" => "60px",
                "padding" => "8px",
                "border" => "1px solid #ccc",
                "border-radius" => "4px",
                "resize" => "vertical",
                "font-family" => "monospace",
                "font-size" => "12px",
                "word-wrap" => "break-word",
                "overflow-wrap" => "break-word",
                "box-sizing" => "border-box"
            )
        );
        style=Styles("margin-bottom" => "10px")
    )
end

"""
    create_save_button(save_trigger, button_enabled)

Create the main Save button that triggers saving.
"""
function create_save_button(save_trigger, button_enabled)
    button_style = map(button_enabled) do enabled
        Styles(
            "padding" => "10px 20px",
            "cursor" => enabled ? "pointer" : "not-allowed",
            "background-color" => enabled ? "#4CAF50" : "#cccccc",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px",
            "font-size" => "14px",
            "font-weight" => "bold",
            "margin-bottom" => "10px"
        )
    end
    
    map(button_enabled, button_style) do enabled, style
        DOM.button(
            "Save Plot";
            onclick=enabled ? js"() => $(save_trigger).notify($(save_trigger).value + 1)" : js"() => {}",
            disabled=!enabled,
            style=style
        )
    end
end

"""
    setup_save_callbacks!(state, dialog_trigger, save_trigger, overwrite_trigger, cancel_trigger)

Setup Julia-side callbacks for save functionality.
Callbacks now show popup modals instead of inline status displays.
"""
function setup_save_callbacks!(state, dialog_trigger, save_trigger, overwrite_trigger, cancel_trigger)
    (; save_file_path, save_status_message, save_status_type, 
       show_overwrite_confirm, show_modal, modal_type, plot_handles) = state
    (; current_figure) = plot_handles
    
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
        path = strip(save_file_path[])
        
        # Check if there's a plot to save
        fig = current_figure[]
        if isnothing(fig)
            save_status_message[] = "No plot to save. Create a plot first."
            modal_type[] = :error
            show_modal[] = true
            return
        end
        
        # Validate path
        (valid, err_msg) = validate_save_path(path)
        if !valid
            save_status_message[] = err_msg
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
        do_save(path, fig, state)
    end
    
    # Callback for overwrite confirmation
    on(overwrite_trigger) do _
        show_modal[] = false
        path = strip(save_file_path[])
        fig = current_figure[]
        
        if !isnothing(fig)
            do_save(path, fig, state)
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
    do_save(path, fig, state)

Actually perform the save operation and show result in modal popup.
"""
function do_save(path, fig, state)
    (; save_status_message, save_status_type, show_modal, modal_type) = state
    (success, message) = save_current_plot(path, fig)
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
    (; save_file_path, plot_handles) = state
    (; current_figure) = plot_handles
    
    # Create trigger observables for button clicks
    dialog_trigger = Observable(0)
    save_trigger = Observable(0)
    overwrite_trigger = Observable(0)
    cancel_trigger = Observable(0)
    
    # Button enabled state
    button_enabled = map(current_figure) do fig
        !isnothing(fig)
    end
    
    # Setup callbacks
    setup_save_callbacks!(state, dialog_trigger, save_trigger, overwrite_trigger, cancel_trigger)
    
    # Create UI elements (status is now shown in modal popup)
    file_dialog_button = create_file_dialog_button(dialog_trigger)
    path_input = create_path_textarea(save_file_path)
    save_button = create_save_button(save_trigger, button_enabled)
    
    content = DOM.div(
        file_dialog_button,
        path_input,
        save_button;
        style=Styles("padding" => "5px")
    )
    
    return (; content, overwrite_trigger, cancel_trigger)
end
