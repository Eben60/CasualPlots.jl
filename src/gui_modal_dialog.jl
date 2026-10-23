# Uses reactive CSS to control visibility

const _LAST_ERROR_INFO = Ref{Any}(nothing)

"""
    last_error() -> Nothing

Prints the full stacktrace of the most recent GUI error caught by the application.
"""
function last_error()
    if isnothing(_LAST_ERROR_INFO[])
        println("No recent GUI error recorded.")
        return nothing
    end
    e, bt = _LAST_ERROR_INFO[]
    showerror(stdout, e, bt)
    return nothing
end

"""
    show_modal!(
        state::CasualPlotsState,
        msg::AbstractString;
        type::Symbol,
        exception=nothing,
        primary_label::AbstractString="OK",
        secondary_label::Union{Nothing, AbstractString}=nothing,
        on_primary=nothing,
        on_secondary=nothing,
    ) -> Nothing

Trigger a modal dialog with the given message and type. Type can be `:error`, `:warning`, `:info`, `:success`, or `:confirm`.

Automatically logs the message to the REPL based on the `type`, except for 
`:confirm` case, which is an interactive UI prompt in GUI only.
"""
function show_modal!(
    state,
    msg;
    type,
    exception=nothing,
    primary_label="OK",
    secondary_label=nothing,
    on_primary=nothing,
    on_secondary=nothing,
)
    if type == :error && isnothing(exception)
        throw(ArgumentError("An exception must be provided when type is :error"))
    end

    if !isnothing(exception)
        _LAST_ERROR_INFO[] = exception
    end

    if type == :error || type == :warning
        if type == :error && !isnothing(exception)
            @warn msg * "\nTip: Run `CasualPlots.last_error()` to see the full stacktrace."
        else
            @warn msg
        end
    elseif type == :success || type == :info
        @info msg
    end

    actual_primary = primary_label
    actual_secondary = secondary_label
    if type == :confirm
        if actual_primary == "OK"
            actual_primary = "Overwrite"
        end
        if isnothing(actual_secondary)
            actual_secondary = "Cancel"
        end
    end

    state.file_saving.save_status_message[] = msg
    state.dialogs.modal_type[] = type
    state.dialogs.modal_primary_label[] = String(actual_primary)
    state.dialogs.modal_secondary_label[] = isnothing(actual_secondary) ? nothing : String(actual_secondary)
    state.dialogs.modal_callbacks[] = (; on_primary = on_primary, on_secondary = on_secondary)
    state.dialogs.show_modal[] = true
    return nothing
end

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
            "z-index" => "1100"
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
    create_modal_buttons(state)

Create appropriate buttons based on modal type and labels.
"""
function create_modal_buttons(state)
    (; modal_type, modal_primary_label, modal_secondary_label, modal_action_primary, modal_action_secondary) = state.dialogs

    return map(modal_type, modal_primary_label, modal_secondary_label) do mtype, p_label, s_label
        primary_bg = mtype == :confirm ? "#DC3545" : "#007BFF"

        primary_btn = DOM.button(
            p_label;
            id="btn-modal-ok",
            onclick=js"() => window.CasualPlots.incrementObservable($(modal_action_primary))",
            style=Styles(
                "padding" => "8px 24px",
                "background-color" => primary_bg,
                "color" => "white",
                "border" => "none",
                "border-radius" => "4px",
                "cursor" => "pointer",
                "font-size" => "14px",
            ),
        )

        if isnothing(s_label)
            return DOM.div(primary_btn)
        else
            secondary_btn = DOM.button(
                s_label;
                id="btn-modal-cancel",
                onclick=js"() => window.CasualPlots.incrementObservable($(modal_action_secondary))",
                style=Styles(
                    "padding" => "8px 20px",
                    "background-color" => "#6C757D",
                    "color" => "white",
                    "border" => "none",
                    "border-radius" => "4px",
                    "cursor" => "pointer",
                    "font-size" => "14px",
                ),
            )
            return DOM.div(
                primary_btn,
                secondary_btn;
                style=Styles("display" => "flex", "gap" => "10px"),
            )
        end
    end
end

"""
    create_modal_container(state)

Create the complete modal dialog container.

The modal visibility is controlled by `state.dialogs.show_modal`.
The modal type (success/error/warning/confirm) is determined by `state.dialogs.modal_type`.
The message content comes from `state.file_saving.save_status_message`.
"""
function create_modal_container(state; plot_observable=nothing, table_observable=nothing)
    (; show_modal, modal_type, modal_action_primary, modal_action_secondary, modal_callbacks) = state.dialogs
    (; save_status_message) = state.file_saving

    # Setup dismiss / action callbacks
    on(modal_action_primary) do _
        show_modal[] = false
        cbs = modal_callbacks[]
        modal_callbacks[] = nothing
        if !isnothing(cbs) && !isnothing(cbs.on_primary)
            try
                cbs.on_primary()
            catch e
                show_modal!(
                    state,
                    "Error executing modal action: $(e)";
                    type=:error,
                    exception=(e, catch_backtrace()),
                )
                !isnothing(plot_observable) && (plot_observable[] = DOM.div(""))
                !isnothing(table_observable) && (table_observable[] = DOM.div(""))
            end
        end
    end

    on(modal_action_secondary) do _
        show_modal[] = false
        cbs = modal_callbacks[]
        modal_callbacks[] = nothing
        if !isnothing(cbs) && !isnothing(cbs.on_secondary)
            try
                cbs.on_secondary()
            catch e
                show_modal!(
                    state,
                    "Error executing modal action: $(e)";
                    type=:error,
                    exception=(e, catch_backtrace()),
                )
                !isnothing(plot_observable) && (plot_observable[] = DOM.div(""))
                !isnothing(table_observable) && (table_observable[] = DOM.div(""))
            end
        end
    end

    # Create reactive styles
    overlay_style = create_modal_overlay_style(show_modal)
    box_style = create_modal_box_style(modal_type)

    # Create modal content
    icon = create_modal_icon(modal_type)
    title = create_modal_title(modal_type)
    buttons = create_modal_buttons(state)

    # Build the modal structure
    return map(overlay_style, box_style, icon, title, save_status_message, buttons) do ostyle, bstyle, icn, ttl, msg, btns
        DOM.div(
            DOM.div(
                # Header row with icon and title
                DOM.div(
                    icn,
                    ttl;
                    style=Styles(
                        "display" => "flex",
                        "align-items" => "center",
                        "margin-bottom" => "15px",
                    ),
                ),
                # Message content
                DOM.p(
                    msg;
                    style=Styles(
                        "margin" => "0 0 20px 0",
                        "color" => "#333",
                        "line-height" => "1.5",
                        "white-space" => "pre-line",
                    ),
                ),
                # Buttons
                DOM.div(
                    btns;
                    style=Styles(
                        "display" => "flex",
                        "justify-content" => "flex-end",
                    ),
                );
                style=bstyle,
            );
            style=ostyle,
        )
    end
end
