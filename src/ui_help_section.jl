"""
    setup_help_section(plot_observable)

Create reactive help section that shows/hides based on plot presence.

Returns Observable controlling help section visibility
"""
function setup_help_section(plot_observable)
    return map(plot_observable) do plot_content
        plot_content isa Figure ? "visible" : "hidden"
    end
end

"""
    mouse_helptext(help_visibility)

Create the mouse controls help text with reactive visibility.

# Arguments
- `help_visibility`: Observable controlling CSS visibility property

# Returns
DOM.div containing formatted help text for mouse controls
"""
mouse_helptext(help_visibility) = map(help_visibility) do visibility_style
    DOM.div(
        DOM.div("Mouse Controls", class="help-title"),
        DOM.div(
            DOM.div("Pan: Right-click + Drag", class="help-item"),
            DOM.div("Zoom: Mouse Wheel", class="help-item"),
            DOM.div("Zoom in: Select rectangle by left button", class="help-item"),
            DOM.div("Reset: Ctrl + Left-click", class="help-item")
        );
        class="help-container",
        style=Styles("visibility" => visibility_style)
    )
end

"""
    help_section(help_visibility)

Create the complete help section with separator line and help text.

# Arguments
- `help_visibility`: Observable controlling help text visibility

# Returns
DOM.div containing separator line and conditionally visible help text
"""
help_section(help_visibility) = DOM.div(
    DOM.div(class="separator-line"),  # Permanent separator line
    mouse_helptext(help_visibility);  # Conditionally visible help text
    class="no-shrink"
)
