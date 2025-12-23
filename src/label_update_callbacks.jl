"""
Setup callbacks to update plot labels when text fields are edited.

This function creates reactive callbacks that update the Makie axis properties
(xlabel, ylabel, title) when the user edits the text fields and presses Enter.
"""
function setup_label_update_callbacks(state, outputs)
    (; xlabel_text, ylabel_text, title_text, current_axis, current_figure) = state.plotting.handles
    plot_observable = outputs.plot

    # Update X-axis label when text field changes
    on(xlabel_text) do new_label
        # Skip if format update is in progress to prevent interference
        if state.misc.block_format_update[]
            return
        end
        ax = current_axis[]
        fig = current_figure[]
        if !isnothing(ax) && !isnothing(fig) && new_label != ""
            if ax.xlabel[] != new_label
                ax.xlabel = new_label
                force_plot_refresh(plot_observable, fig)
            end
        end
    end
    
    # Update Y-axis label when text field changes  
    on(ylabel_text) do new_label
        # Skip if format update is in progress to prevent interference
        if state.misc.block_format_update[]
            return
        end
        ax = current_axis[]
        fig = current_figure[]
        if !isnothing(ax) && !isnothing(fig) && new_label != ""
            if ax.ylabel[] != new_label
                ax.ylabel = new_label
                force_plot_refresh(plot_observable, fig)
            end
        end
    end
    
    # Update title when text field changes
    on(title_text) do new_title
        # Skip if format update is in progress to prevent interference
        if state.misc.block_format_update[]
            return
        end
        ax = current_axis[]
        fig = current_figure[]
        if !isnothing(ax) && !isnothing(fig) && new_title != ""
            if ax.title[] != new_title
                ax.title = new_title
                force_plot_refresh(plot_observable, fig)
            end
        end
    end
end
