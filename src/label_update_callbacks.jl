"""
Setup callbacks to update plot labels when text fields are edited.

This function creates reactive callbacks that update the Makie axis properties
(xlabel, ylabel, title) when the user edits the text fields and presses Enter or Tab.
"""
function setup_label_update_callbacks(state, outputs)
    (; xlabel_text, ylabel_text, title_text, current_axis) = state
    plot_observable = outputs.plot

    # Update X-axis label when text field changes
    on(xlabel_text) do new_label
        ax = current_axis[]
        if !isnothing(ax) && new_label != ""
            ax.xlabel = new_label
            # Force plot refresh by notifying with same value
            plot_observable[] = plot_observable[]
        end
    end
    
    # Update Y-axis label when text field changes  
    on(ylabel_text) do new_label
        ax = current_axis[]
        if !isnothing(ax) && new_label != ""
            ax.ylabel = new_label
            plot_observable[] = plot_observable[]
        end
    end
    
    # Update title when text field changes
    on(title_text) do new_title
        ax = current_axis[]
        if !isnothing(ax) && new_title != ""
            ax.title = new_title
            plot_observable[] = plot_observable[]
        end
    end
end
