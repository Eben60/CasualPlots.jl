# gui_testing_utils.jl
# 
# Utility functions for querying the browser DOM state from Julia. 
# These functions are intended for development, testing, and debugging purposes only.
# They use `Bonito.evaljs_value` to execute JavaScript in the connected browser session
# and return the results back to the Julia REPL.
# 
# ### How to use:
# All functions require an active `Bonito.Session` object. 
# Since `Session`s contain Tasks and cannot be safely cached in global package variables 
# (it breaks precompilation), you should fetch the session dynamically from your active server.
# 
# Use the provided `get_active_session()` helper function in your REPL/tests:
# ```julia
# # 1. Start your app and server
# # 2. Get the session:
# my_session = get_active_session()
# 
# # 3. Query the GUI:
# info = get_active_element_info(my_session)
# ```
"""
    get_active_session()

Dynamically retrieves the active Bonito Session from `Main.app` or `Main.app.app`.
"""
function get_active_session()
    if !isdefined(Main, :app)
        error("No active app found. Please define 'app = casualplots_app()' or 'app = ...' in Main.")
    end
    
    app_obj = Main.app
    # Unwrap CasualPlotApp if needed
    if isdefined(Main, :CasualPlotApp) && app_obj isa Main.CasualPlotApp
        app_obj = app_obj.app
    elseif hasfield(typeof(app_obj), :app) && app_obj.app isa Bonito.App
        app_obj = app_obj.app
    end
    
    if !(app_obj isa Bonito.App)
        error("Main.app is not a Bonito.App or CasualPlotApp.")
    end
    
    session = app_obj.session[]
    if isnothing(session)
        error("No active session found in the app. Make sure a browser is connected.")
    end
    
    return session
end

"""
    wait_for_session(; timeout::Real=10) -> Bonito.Session

Poll `get_active_session()` every 0.5 s until a session is available or `timeout`
seconds have elapsed. Throws if no session connects within the deadline.
"""
function wait_for_session(; timeout::Real=10)
    deadline = time() + timeout
    while time() < deadline
        try
            return get_active_session()
        catch
            sleep(0.5)
        end
    end
    error("No active Bonito session after $(timeout) s.")
end


"""
    get_active_element_info(session::Bonito.Session)

Returns a Dict containing the 'id', 'tag', 'class', and 'value' of the currently focused 
HTML element in the browser. Useful for verifying Tab navigation during keyboard testing.
"""
function get_active_element_info(session::Bonito.Session)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const el = document.activeElement;
            if (!el) return {id: "", tag: "", className: "", value: ""};
            return {
                id: el.id || "",
                tag: el.tagName || "",
                className: el.className || "",
                value: el.value || ""
            };
        })()
    """)
end

"""
    get_active_element_id(session::Bonito.Session)

Returns the ID of the currently focused HTML element.
"""
function get_active_element_id(session::Bonito.Session)
    return Bonito.evaljs_value(session, js"document.activeElement ? document.activeElement.id : ''")
end

"""
    get_active_element_tag(session::Bonito.Session)

Returns the HTML tag name (e.g., 'SELECT', 'INPUT') of the currently focused element.
"""
function get_active_element_tag(session::Bonito.Session)
    return Bonito.evaljs_value(session, js"document.activeElement ? document.activeElement.tagName : ''")
end

"""
    get_active_element_value(session::Bonito.Session)

Returns the value of the currently focused HTML element.
"""
function get_active_element_value(session::Bonito.Session)
    return Bonito.evaljs_value(session, js"document.activeElement ? document.activeElement.value : ''")
end

"""
    get_dropdown_options(session::Bonito.Session; id::Union{String, Nothing}=nothing, css_selector::Union{String, Nothing}=nothing)

Returns a Vector of Dicts representing options (text, value, selected) for a `<select>` dropdown.
If neither `id` nor `css_selector` is provided, it queries the currently focused/active element.
"""
function get_dropdown_options(session::Bonito.Session; id::Union{String, Nothing}=nothing, css_selector::Union{String, Nothing}=nothing)
    el_js = if !isnothing(css_selector)
        js"document.querySelector($(css_selector))"
    elseif !isnothing(id)
        js"document.getElementById($(id))"
    else
        js"document.activeElement"
    end

    return Bonito.evaljs_value(session, js"""
        (function() {
            const select = $(el_js);
            if (!select || select.tagName !== 'SELECT') return [];
            return Array.from(select.options).map(opt => {
                return {
                    text: opt.text || "",
                    value: opt.value || "",
                    selected: opt.selected || false
                };
            });
        })()
    """)
end

"""
    select_dropdown_value(session, css_selector, value)

Sets a `<select>` dropdown's value and dispatches a `change` event so WGLMakie/Bonito updates the Observable.
"""
function select_dropdown_value(session::Bonito.Session, css_selector::String, value::String)
    Bonito.evaljs(session, js"""
        (function() {
            const sel = document.querySelector($(css_selector));
            if (!sel) { console.error('Element not found:', $(css_selector)); return; }
            sel.value = $(value);
            sel.dispatchEvent(new Event('change', {bubbles: true}));
        })()
    """)
end

"""
    click_button(session, css_selector)

Clicks a button element matching the CSS selector.
"""
function click_button(session::Bonito.Session, css_selector::String)
    Bonito.evaljs(session, js"""
        (function() {
            const btn = document.querySelector($(css_selector));
            if (!btn) { console.error('Button not found:', $(css_selector)); return; }
            btn.click();
        })()
    """)
end

"""
    set_radio_value(session, name, value)

Selects a radio button matching the name and value, dispatching a `change` event.
"""
function set_radio_value(session::Bonito.Session, name::String, value::String)
    selector = "input[type=radio][name=\"$name\"][value=\"$value\"]"
    Bonito.evaljs(session, js"""
        (function() {
            const radio = document.querySelector($(selector));
            if (!radio) { console.error('Radio not found:', $(selector)); return; }
            radio.checked = true;
            radio.dispatchEvent(new Event('change', {bubbles: true}));
        })()
    """)
end

"""
    toggle_checkbox(session, css_selector)

Toggles the checked state of a checkbox and dispatches a `change` event.
"""
function toggle_checkbox(session::Bonito.Session, css_selector::String)
    Bonito.evaljs(session, js"""
        (function() {
            const cb = document.querySelector($(css_selector));
            if (!cb) { console.error('Checkbox not found:', $(css_selector)); return; }
            cb.checked = !cb.checked;
            cb.dispatchEvent(new Event('change', {bubbles: true}));
        })()
    """)
end

"""
    get_element_info(session, css_selector)

Returns a Dict containing tag, id, class, value, disabled, and checked state for the element matching `css_selector`.
"""
function get_element_info(session::Bonito.Session, css_selector::String)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const el = document.querySelector($(css_selector));
            if (!el) return null;
            return {
                tag: el.tagName || "",
                id: el.id || "",
                className: el.className || "",
                value: el.value || "",
                disabled: el.disabled || false,
                checked: el.checked || false
            };
        })()
    """)
end

"""
    get_checkboxes_state(session)

Returns a Vector of Dicts representing all DataFrame column checkboxes (value, checked).
"""
function get_checkboxes_state(session::Bonito.Session)
    return Bonito.evaljs_value(session, js"""
        Array.from(document.querySelectorAll('.column-checkbox')).map(cb => ({
            value: cb.value,
            checked: cb.checked
        }))
    """)
end

"""
    get_focusable_elements(session::Bonito.Session)

Returns a Vector of Dicts representing all currently visible and focusable elements in their natural tab order.
Each Dict contains `id`, `tag`, `className`, and `value`.
"""
function get_focusable_elements(session::Bonito.Session)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const focusable = Array.from(document.querySelectorAll('a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'))
                .filter(el => {
                    if (el.disabled || el.offsetWidth === 0 || el.offsetHeight === 0) return false;
                    // Radio button logic: only checked radio is focusable, or first one if none checked
                    if (el.type === 'radio' && el.name) {
                        if (!el.checked) {
                            const group = document.querySelectorAll(`input[type="radio"][name="${el.name}"]`);
                            const anyChecked = Array.from(group).some(r => r.checked);
                            if (anyChecked) return false;
                            if (group.length > 0 && group[0] !== el) return false;
                        }
                    }
                    return true;
                });
            return focusable.map(el => {
                return {
                    id: el.id || "",
                    tag: el.tagName || "",
                    className: el.className || "",
                    value: el.value || ""
                };
            });
        })()
    """)
end

"""
    calculate_tab_distance(session::Bonito.Session, css_selector::String)

Calculates the number of `TAB` presses needed to navigate from the currently focused element
to the target element identified by `css_selector`.
Returns an integer (positive for `TAB`, negative for `Shift+TAB`), or `nothing` if the active
element or target element cannot be found in the focusable sequence.
"""
function calculate_tab_distance(session::Bonito.Session, css_selector::String)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const focusable = Array.from(document.querySelectorAll('a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'))
                .filter(el => {
                    if (el.disabled || el.offsetWidth === 0 || el.offsetHeight === 0) return false;
                    if (el.type === 'radio' && el.name) {
                        if (!el.checked) {
                            const group = document.querySelectorAll(`input[type="radio"][name="${el.name}"]`);
                            const anyChecked = Array.from(group).some(r => r.checked);
                            if (anyChecked) return false;
                            if (group.length > 0 && group[0] !== el) return false;
                        }
                    }
                    return true;
                });
            
            const active = document.activeElement;
            const target = document.querySelector($(css_selector));
            
            if (!target) return null;
            
            const activeIdx = focusable.indexOf(active);
            const targetIdx = focusable.indexOf(target);
            
            if (targetIdx === -1) return null;
            
            return targetIdx - activeIdx;
        })()
    """)
end

"""
    calculate_dropdown_keystrokes(session::Bonito.Session, css_selector::String, target_value::String)

Calculates the number of `Arrow Down` or `Arrow Up` keystrokes needed to select
`target_value` in the specified `<select>` element from its current selection.
Returns an integer (positive for down, negative for up).
"""
function calculate_dropdown_keystrokes(session::Bonito.Session, css_selector::String, target_value::String)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const select = document.querySelector($(css_selector));
            if (!select || select.tagName !== 'SELECT') return null;
            
            const currentIdx = select.selectedIndex;
            let targetIdx = -1;
            
            for (let i = 0; i < select.options.length; i++) {
                if (select.options[i].value === $(target_value)) {
                    targetIdx = i;
                    break;
                }
            }
            
            if (targetIdx === -1) return null;
            
            return targetIdx - currentIdx;
        })()
    """)
end

