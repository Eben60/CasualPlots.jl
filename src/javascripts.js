window.CasualPlots = window.CasualPlots || {};

/**
 * Updates an observable with the target value from an event (for input/select).
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to update
 */
window.CasualPlots.updateObservableValue = (event, observable) => {
    observable.notify(event.target.value);
}

/**
 * Updates an observable with the checked state from an event (for checkbox).
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to update
 */
window.CasualPlots.updateObservableChecked = (event, observable) => {
    observable.notify(event.target.checked);
}

/**
 * Increments an observable's value by 1.
 * @param {Observable} observable - The observable to increment
 */
window.CasualPlots.incrementObservable = (observable) => {
    observable.notify(observable.value + 1);
}

/**
 * Sets an observable to a specific value.
 * @param {Observable} observable - The observable to set
 * @param {any} value - The value to set
 */
window.CasualPlots.setObservableValue = (observable, value) => {
    observable.notify(value);
}

/**
 * Handles 'Enter' key press on inputs to notify an observable.
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to notify
 */
window.CasualPlots.handleEnterKey = (event, observable) => {
    if (event.key === 'Enter') {
        event.preventDefault();
        observable.notify(event.target.value);
    }
}

/**
 * Handles changes on dataframe column checkboxes.
 * Adds/removes the value from the selected columns list.
 * @param {Event} event - The DOM event
 * @param {Observable} selectedColumnsObs - Observable holding the list of selected columns
 */
window.CasualPlots.handleColumnCheckboxChange = (event, selectedColumnsObs) => {
    const checked = event.target.checked;
    const value = event.target.value;
    let current = selectedColumnsObs.value;
    if (checked) {
        if (!current.includes(value)) {
            // We assume 'current' is an array we can mutate, or we should copy it.
            // Original code mutated the value directly obtained from .value
            current.push(value);
        }
    } else {
        const index = current.indexOf(value);
        if (index > -1) {
            current.splice(index, 1);
        }
    }
    selectedColumnsObs.notify(current);
}

/**
 * Selects all available columns.
 * @param {Array} allCols - List of all column names
 * @param {Observable} selectedColumnsObs - Observable holding the list of selected columns
 */
window.CasualPlots.selectAllColumns = (allCols, selectedColumnsObs) => {
    // 1. Update Julia state
    selectedColumnsObs.notify(allCols);
    // 2. Manually sync UI (since checkboxes aren't reactive on selected_columns)
    document.querySelectorAll('.column-checkbox').forEach(cb => {
        cb.checked = true;
    });
}

/**
 * Deselects all columns.
 * @param {Observable} selectedColumnsObs - Observable holding the list of selected columns
 */
window.CasualPlots.deselectAllColumns = (selectedColumnsObs) => {
    // 1. Update Julia state
    selectedColumnsObs.notify([]);
    // 2. Manually sync UI (since checkboxes aren't reactive on selected_columns)
    document.querySelectorAll('.column-checkbox').forEach(cb => {
        cb.checked = false;
    });
}
