# Modal dialog component for popup notifications and confirmations
# Uses reactive CSS to control visibility

"""
    create_modal_overlay_style(show_modal)

Create reactive style for the modal overlay (full-screen semi-transparent background).
"""
function create_modal_overlay_style(show_modal)
    map(show_modal) do is_visible
        Styles(
            "display" => is_visible ? "flex" : "none",
            "position" => "fixed",
            "top" => "0",
            "left" => "0",
            "width" => "100%",
            "height" => "100%",
            "background-color" => "rgba(0, 0, 0, 0.5)",
            "justify-content" => "center",
            "align-items" => "center",
            "z-index" => "1000"
        )
    end
end

"""
    create_modal_box_style(modal_type)

Create style for the modal box based on dialog type.
Returns appropriate border color for success/error/warning/confirm.
"""
function create_modal_box_style(modal_type)
    map(modal_type) do mtype
        border_color = if mtype == :success
            "#28A745"
        elseif mtype == :error
            "#DC3545"
        elseif mtype == :warning || mtype == :confirm
            "#FFC107"
        else
            "#ccc"
        end
        
        Styles(
            "background" => "white",
            "padding" => "20px",
            "border-radius" => "8px",
            "min-width" => "300px",
            "max-width" => "500px",
            "box-shadow" => "0 4px 20px rgba(0,0,0,0.3)",
            "border-top" => "4px solid $border_color"
        )
    end
end

"""
    create_modal_icon(modal_type)

Create icon element based on modal type.
"""
function create_modal_icon(modal_type)
    map(modal_type) do mtype
        (icon, color) = if mtype == :success
            ("✓", "#28A745")
        elseif mtype == :error
            ("✗", "#DC3545")
        elseif mtype == :warning || mtype == :confirm
            ("⚠", "#FFC107")
        else
            ("", "#000")
        end
        
        DOM.span(icon; style=Styles(
            "font-size" => "24px",
            "margin-right" => "10px",
            "color" => color
        ))
    end
end

"""
    create_modal_title(modal_type)

Create title element based on modal type.
"""
function create_modal_title(modal_type)
    map(modal_type) do mtype
        title = if mtype == :success
            "Success"
        elseif mtype == :error
            "Error"
        elseif mtype == :warning
            "Warning"
        elseif mtype == :confirm
            "Confirm Action"
        else
            ""
        end
        
        DOM.span(title; style=Styles(
            "font-size" => "18px",
            "font-weight" => "bold"
        ))
    end
end

"""
    create_ok_button(dismiss_trigger)

Create an "OK" button for dismissing the modal.
"""
function create_ok_button(dismiss_trigger)
    DOM.button(
        "OK";
        onclick=js"() => window.CasualPlots.incrementObservable($(dismiss_trigger))",
        style=Styles(
            "padding" => "8px 24px",
            "background-color" => "#007BFF",
            "color" => "white",
            "border" => "none",
            "border-radius" => "4px",
            "cursor" => "pointer",
            "font-size" => "14px"
        )
    )
end

"""
    create_confirm_buttons(overwrite_trigger, cancel_trigger)

Create "Overwrite" and "Cancel" buttons for confirmation dialogs.
"""
function create_confirm_buttons(overwrite_trigger, cancel_trigger)
    DOM.div(
        DOM.button(
            "Overwrite";
            onclick=js"() => window.CasualPlots.incrementObservable($(overwrite_trigger))",
            style=Styles(
                "padding" => "8px 20px",
                "background-color" => "#DC3545",
                "color" => "white",
                "border" => "none",
                "border-radius" => "4px",
                "cursor" => "pointer",
                "font-size" => "14px",
                "margin-right" => "10px"
            )
        ),
        DOM.button(
            "Cancel";
            onclick=js"() => window.CasualPlots.incrementObservable($(cancel_trigger))",
            style=Styles(
                "padding" => "8px 20px",
                "background-color" => "#6C757D",
                "color" => "white",
                "border" => "none",
                "border-radius" => "4px",
                "cursor" => "pointer",
                "font-size" => "14px"
            )
        );
        style=Styles("display" => "flex", "gap" => "10px")
    )
end

"""
    create_modal_buttons(modal_type, dismiss_trigger, overwrite_trigger, cancel_trigger)

Create appropriate buttons based on modal type.
"""
function create_modal_buttons(modal_type, dismiss_trigger, overwrite_trigger, cancel_trigger)
    map(modal_type) do mtype
        if mtype == :confirm
            create_confirm_buttons(overwrite_trigger, cancel_trigger)
        else
            create_ok_button(dismiss_trigger)
        end
    end
end

"""
    create_modal_container(state, overwrite_trigger, cancel_trigger)

Create the complete modal dialog container.

The modal visibility is controlled by `state.show_modal`.
The modal type (success/error/warning/confirm) is determined by `state.modal_type`.
The message content comes from `state.save_status_message`.
"""
function create_modal_container(state, overwrite_trigger, cancel_trigger)
    (; show_modal, modal_type) = state.dialogs
    (; save_status_message) = state.file_saving
    
    # Create trigger for OK button (dismisses modal)
    dismiss_trigger = Observable(0)
    
    # Setup dismiss callback
    on(dismiss_trigger) do _
        show_modal[] = false
    end
    
    # Create reactive styles
    overlay_style = create_modal_overlay_style(show_modal)
    box_style = create_modal_box_style(modal_type)
    
    # Create modal content
    icon = create_modal_icon(modal_type)
    title = create_modal_title(modal_type)
    buttons = create_modal_buttons(modal_type, dismiss_trigger, overwrite_trigger, cancel_trigger)
    
    # Build the modal structure
    map(overlay_style, box_style, icon, title, save_status_message, buttons) do ostyle, bstyle, icn, ttl, msg, btns
        DOM.div(
            DOM.div(
                # Header row with icon and title
                DOM.div(
                    icn,
                    ttl;
                    style=Styles(
                        "display" => "flex",
                        "align-items" => "center",
                        "margin-bottom" => "15px"
                    )
                ),
                # Message content
                DOM.p(msg; style=Styles(
                    "margin" => "0 0 20px 0",
                    "color" => "#333",
                    "line-height" => "1.5"
                )),
                # Buttons
                DOM.div(
                    btns;
                    style=Styles(
                        "display" => "flex",
                        "justify-content" => "flex-end"
                    )
                );
                style=bstyle
            );
            style=ostyle
        )
    end
end
