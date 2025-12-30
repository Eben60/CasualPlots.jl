"""
Setup callbacks for label text field observables.

Note: Previously, this function set up automatic plot updates when labels/title were edited.
This automatic behavior has been removed in favor of the explicit "Replot" button in the Format tab,
which gives users control over when format changes (including labels) are applied.

The text field values are still stored in observables (xlabel_text, ylabel_text, title_text),
and they are applied when the user clicks the Replot button.
"""
function setup_label_update_callbacks(state, outputs)
    # Label changes are now applied via the Replot button in the Format tab
    # No automatic callbacks needed - the observables are read when Replot is triggered
    return nothing
end
