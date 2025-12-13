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
    
    # CSS styling for the tabs
    tab_styles = """
    <style>
        .tabs-container {
            display: flex;
            flex-direction: column;
            width: 100%;
            height: 100%;
        }
        
        .tab-buttons {
            display: flex;
            gap: 2px;
            background-color: #e0e0e0;
            padding: 5px 5px 0 5px;
            border-bottom: 2px solid #999;
        }
        
        .tab-button {
            padding: 8px 16px;
            background-color: #d0d0d0;
            border: 1px solid #999;
            border-bottom: none;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.2s;
            border-radius: 4px 4px 0 0;
        }
        
        .tab-button:hover {
            background-color: #e8e8e8;
        }
        
        .tab-button.active {
            background-color: whitesmoke;
            font-weight: bold;
            border-bottom: 2px solid whitesmoke;
            margin-bottom: -2px;
        }
        
        .tab-content {
            flex: 1;
            padding: 10px;
            overflow: auto;
        }
        
        .tab-panel {
            display: none;
        }
        
        .tab-panel.active {
            display: block;
        }
    </style>
    """
    
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
            onclick=js"() => $(active_tab).notify($idx)"
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
        DOM.style(tab_styles),
        DOM.div(
            DOM.div(tab_buttons...; class="tab-buttons"),
            DOM.div(tab_panels...; class="tab-content");
            class="tabs-container"
        )
    )
    
    return (; dom=tabs_html, active_tab)
end
