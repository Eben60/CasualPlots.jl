"""
    create_tab_content(control_panel, state, outputs)

Organize control panel elements into tabbed interface using BonitoWidgets.Tabs.

# Returns
NamedTuple with:
- `tabs`: BonitoWidgets.Tabs component (Source tab active by default)
- `overwrite_trigger`: Observable for overwrite button (passed to modal)
- `cancel_trigger`: Observable for cancel button (passed to modal)
"""
function create_tab_content(control_panel, state, outputs)
    # Open tab - shows extension availability status (reactive) with file loading
    open_tab_content = create_open_tab_content(outputs, state)
    
    t1_source_content = DOM.div(control_panel.source_type_selector, control_panel.source_content)
    permanent_controls = Card(DOM.div(
        control_panel.theme_selector,
        control_panel.legend_control,
        control_panel.xlabel_input,
        control_panel.ylabel_input,
        control_panel.title_input,
        control_panel.axis_limits_section;
        class="flex-col"
    ); class="pane-card")

    t2_format_content = DOM.div(
        DOM.div(
            control_panel.plot_kind,
            control_panel.dynamic_attributes_section
        ),
        permanent_controls;
        style=Styles("display"=>"flex", "flex-direction"=>"column", "justify-content"=>"space-between", "height"=>"100%")
    )

    save_tab_result = create_save_tab_content(state)
    
    # Use BonitoWidgets.Tabs instead of custom create_tabs_component
    tabs_widget = Tabs(
        "Open"   => open_tab_content,
        "Source"  => t1_source_content,
        "Format"  => t2_format_content,
        "Save"   => save_tab_result.content;
        active=2  # Default to "Source" tab
    )
    
    return (; tabs=tabs_widget, overwrite_trigger=save_tab_result.overwrite_trigger, 
              cancel_trigger=save_tab_result.cancel_trigger)
end
