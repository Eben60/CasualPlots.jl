"""
Setup callbacks to update plot labels when text fields are edited.

This function creates reactive callbacks that update the Makie axis properties
(xlabel, ylabel, title) when the user edits the text fields and presses Enter.

Uses update_plot_format!() for incremental updates without rebuilding the plot.
"""
function setup_label_update_callbacks(state, outputs)
    (; xlabel_text, ylabel_text, title_text, current_axis, current_figure) = state.plotting.handles
    (; block_format_update) = state.misc

    # Create callbacks for each label property
    setup_label_callback(xlabel_text, :xlabel, current_axis, current_figure, block_format_update)
    setup_label_callback(ylabel_text, :ylabel, current_axis, current_figure, block_format_update)
    setup_label_callback(title_text, :title, current_axis, current_figure, block_format_update)
end

"""
    setup_label_callback(text_observable, prop_name, current_axis, current_figure, block_format_update)

Set up a single label update callback that updates axis property when text changes.

# Arguments
- `text_observable`: The Observable containing the text value
- `prop_name`: Symbol for the axis property (:xlabel, :ylabel, or :title)
- `current_axis`: Observable holding the current Makie Axis
- `current_figure`: Observable holding the current Makie Figure
- `block_format_update`: Observable flag to block updates during format changes
"""
function setup_label_callback(text_observable, prop_name::Symbol, 
                               current_axis, current_figure, block_format_update)
    on(text_observable) do new_value
        # Skip if format update is in progress to prevent interference
        block_format_update[] && return
        
        ax = current_axis[]
        fig = current_figure[]
        
        # Only update if we have valid plot and non-empty value
        if !isnothing(ax) && !isnothing(fig) && new_value != ""
            update_plot_format!(fig, ax; (prop_name => new_value,)...)
        end
    end
end
