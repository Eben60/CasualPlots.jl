"""
    create_tabs_component(tab_configs::Vector; default_active=1)

Create a tabbed interface component.

# Arguments
- `tab_configs`: Vector of NamedTuples with `name` and `content` fields
  - `name`: String name for the tab button
  - `content`: DOM node to display when tab is active
- `default_active`: Index of the tab to show by default (1-indexed)

# Returns
A DOM node containing the complete tabs interface

# Example
```julia
tabs = create_tabs_component([
    (name="Settings", content=DOM.div("Settings content")),
    (name="Data", content=DOM.div("Data content")),
    (name="Help", content=DOM.div("Help content"))
]; default_active=2)
```
"""
function create_tabs_component(tab_configs::Vector; default_active=1)
    # Observable to track which tab is active (1-indexed)
    active_tab = Observable(default_active)
    
    # Create tab buttons
    tab_buttons = map(enumerate(tab_configs)) do (idx, config)
        is_active = Observable(idx == active_tab[])
        
        # Update is_active when active_tab changes
        on(active_tab) do active_idx
            is_active[] = (idx == active_idx)
        end
        
        # Create button with dynamic class
        button_class = map(is_active) do active
            active ? "tab-button active" : "tab-button"
        end
        
        DOM.button(
            config.name;
            class=button_class,
            onclick=js"() => window.CasualPlots.setObservableValue($(active_tab), $idx)"
        )
    end
    
    # Create tab content panels
    tab_panels = map(enumerate(tab_configs)) do (idx, config)
        is_active = Observable(idx == active_tab[])
        
        # Update is_active when active_tab changes
        on(active_tab) do active_idx
            is_active[] = (idx == active_idx)
        end
        
        # Create panel with dynamic class
        panel_class = map(is_active) do active
            active ? "tab-panel active" : "tab-panel"
        end
        
        DOM.div(config.content; class=panel_class)
    end
    
    # Assemble the complete tabs component
    tabs_html = DOM.div(
        DOM.div(tab_buttons...; class="tab-buttons"),
        DOM.div(tab_panels...; class="tab-content");
        class="tabs-container"
    )
    
    return (; dom=tabs_html, active_tab)
end

"""
    create_tab_content(control_panel, state, outputs)

Organize control panel elements into tabbed interface.

# Arguments
- `control_panel`: NamedTuple with x_source, y_source, plot_kind, legend_control
- `state`: Application state NamedTuple with save-related observables
- `outputs`: Output observables NamedTuple with table observable

# Returns
NamedTuple with:
- `tabs`: Tabbed component DOM element with Open, Source, Format, and Save tabs (Source is default active)
- `overwrite_trigger`: Observable for overwrite button (passed to modal)
- `cancel_trigger`: Observable for cancel button (passed to modal)
"""
function create_tab_content(control_panel, state, outputs)
    # Create a refresh trigger for the Open tab that fires when it becomes active
    open_tab_refresh = Observable(0)
    
    # Open tab - shows extension availability status (reactive) with file loading
    open_tab_content = create_open_tab_content(open_tab_refresh, outputs.table, state)
    
    t1_source_content = DOM.div(control_panel.source_type_selector, control_panel.source_content)
    t2_format_content = DOM.div(
        control_panel.plot_kind,
        control_panel.theme_selector,
        control_panel.group_by_selector,
        control_panel.legend_control,
        control_panel.xlabel_input,
        control_panel.ylabel_input,
        control_panel.title_input,
        control_panel.axis_limits_section,
    )
    save_tab_result = create_save_tab_content(state)
    
    tab_configs = [
        (name="Open", content=open_tab_content),
        (name="Source", content=t1_source_content),
        (name="Format", content=t2_format_content),
        (name="Save", content=save_tab_result.content),
    ]
    
    # default_active=2 keeps "Source" tab as the default (Open is now index 1)
    tabs_result = create_tabs_component(tab_configs; default_active=2)
    
    # Wire up the Open tab refresh: trigger when Open tab (index 1) becomes active
    on(tabs_result.active_tab) do tab_idx
        if tab_idx == 1  # Open tab
            open_tab_refresh[] = open_tab_refresh[] + 1
        end
    end
    
    return (; tabs=tabs_result.dom, overwrite_trigger=save_tab_result.overwrite_trigger, 
              cancel_trigger=save_tab_result.cancel_trigger)
end
