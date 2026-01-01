"""
Setup callbacks to update plot labels when text fields are edited.

This function creates reactive callbacks that update the Makie axis properties
(xlabel, ylabel, title) when the user edits the text fields and presses Enter.

Uses update_plot_format!() for incremental updates without rebuilding the plot.
Also marks the format option as changed in state.misc.format_changed.
"""
function setup_label_update_callbacks(state, outputs)
    (; xlabel_text, ylabel_text, title_text, current_axis, current_figure) = state.plotting.handles
    (; block_format_update, format_changed) = state.misc

    # Create callbacks for each label property
    setup_label_callback(xlabel_text, :xlabel, current_axis, current_figure, block_format_update, format_changed)
    setup_label_callback(ylabel_text, :ylabel, current_axis, current_figure, block_format_update, format_changed)
    setup_label_callback(title_text, :title, current_axis, current_figure, block_format_update, format_changed)
end

"""
    setup_label_callback(text_observable, prop_name, current_axis, current_figure, block_format_update, format_changed)

Set up a single label update callback that updates axis property when text changes.
Also marks the property as changed in format_changed dict.

# Arguments
- `text_observable`: The Observable containing the text value
- `prop_name`: Symbol for the axis property (:xlabel, :ylabel, or :title)
- `current_axis`: Observable holding the current Makie Axis
- `current_figure`: Observable holding the current Makie Figure
- `block_format_update`: Observable flag to block updates during format changes
- `format_changed`: DefaultDict tracking which format options have been changed
"""
function setup_label_callback(text_observable, prop_name::Symbol, 
                               current_axis, current_figure, block_format_update, format_changed)
    on(text_observable) do new_value
        # Skip if format update is in progress to prevent interference
        block_format_update[] && return
        
        ax = current_axis[]
        fig = current_figure[]
        
        # Mark this property as changed by user
        format_changed[prop_name] = true
        
        # Only update if we have valid plot and non-empty value
        if !isnothing(ax) && !isnothing(fig) && new_value != ""
            update_plot_format!(fig, ax; (prop_name => new_value,)...)
        end
    end
end
