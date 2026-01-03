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
 * Handles blur (leaving field) on text inputs to notify an observable.
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to notify
 */
window.CasualPlots.handleTextInputBlur = (event, observable) => {
    observable.notify(event.target.value);
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

/**
 * Updates an observable with a non-negative integer from an input field.
 * Validates and sanitizes the input to only accept non-negative integers.
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to update
 */
window.CasualPlots.updateObservableInteger = (event, observable) => {
    const input = event.target;
    // Remove any non-digit characters
    let value = input.value.replace(/[^0-9]/g, '');
    // Parse as integer, default to 0 if empty
    const intValue = value === '' ? 0 : parseInt(value, 10);
    // Update the input display with cleaned value
    input.value = intValue;
    // Notify Julia with the integer value
    observable.notify(intValue);
}

/**
 * Updates an observable with an integer from an input field, allowing null for empty.
 * Used for optional range values where empty means "no limit".
 * Validates against stored bounds and resets to min/max on invalid input.
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to update
 */
window.CasualPlots.updateIntObservable = (event, observable) => {
    const input = event.target;
    const value = input.value.trim();
    const bounds = window.CasualPlots._rangeBounds || { from: null, to: null };
    
    // Helper to ensure a value is a proper integer
    const toInt = (val) => {
        if (val === null || val === undefined) return null;
        if (typeof val === 'number') return Math.round(val);
        if (typeof val === 'string') return parseInt(val, 10);
        return null;
    };
    
    const boundsFrom = toInt(bounds.from);
    const boundsTo = toInt(bounds.to);
    
    if (value === '') {
        // Empty: reset to the appropriate bound
        if (input.id === 'range-from-input' && boundsFrom !== null) {
            input.value = boundsFrom;
            observable.notify(boundsFrom);
        } else if (input.id === 'range-to-input' && boundsTo !== null) {
            input.value = boundsTo;
            observable.notify(boundsTo);
        } else {
            observable.notify(null);
        }
    } else {
        // Parse as integer
        const intValue = parseInt(value, 10);
        if (isNaN(intValue)) {
            // Invalid: reset to bound
            if (input.id === 'range-from-input' && boundsFrom !== null) {
                input.value = boundsFrom;
                observable.notify(boundsFrom);
            } else if (input.id === 'range-to-input' && boundsTo !== null) {
                input.value = boundsTo;
                observable.notify(boundsTo);
            }
        } else {
            // Validate against bounds
            if (boundsFrom !== null && boundsTo !== null) {
                if (input.id === 'range-from-input') {
                    if (intValue < boundsFrom) {
                        input.value = boundsFrom;
                        observable.notify(boundsFrom);
                    } else if (intValue > boundsTo) {
                        input.value = boundsTo;
                        observable.notify(boundsTo);
                    } else {
                        observable.notify(intValue);
                    }
                } else if (input.id === 'range-to-input') {
                    if (intValue > boundsTo) {
                        input.value = boundsTo;
                        observable.notify(boundsTo);
                    } else if (intValue < boundsFrom) {
                        input.value = boundsFrom;
                        observable.notify(boundsFrom);
                    } else {
                        observable.notify(intValue);
                    }
                } else {
                    observable.notify(intValue);
                }
            } else {
                observable.notify(intValue);
            }
        }
    }
}

// Global state for range bounds
window.CasualPlots._rangeBounds = { from: null, to: null };

/**
 * Sets the values of range input fields by their IDs and stores bounds.
 * Called from Julia when data source changes to populate initial range values.
 * @param {number|null} fromValue - Value for range_from input (null clears)
 * @param {number|null} toValue - Value for range_to input (null clears)
 */
window.CasualPlots.setRangeInputValues = (fromValue, toValue) => {
    // Normalize null/undefined/"null" to null, and ensure numbers are numbers
    const normalizeValue = (val) => {
        if (val === null || val === undefined || val === "null") return null;
        if (typeof val === 'string') return parseInt(val, 10);
        return val;
    };
    
    const normalizedFrom = normalizeValue(fromValue);
    const normalizedTo = normalizeValue(toValue);
    
    // Store bounds for validation
    window.CasualPlots._rangeBounds = { from: normalizedFrom, to: normalizedTo };
    
    const fromInput = document.getElementById('range-from-input');
    const toInput = document.getElementById('range-to-input');
    
    if (fromInput) {
        fromInput.value = normalizedFrom !== null ? normalizedFrom : '';
    }
    if (toInput) {
        toInput.value = normalizedTo !== null ? normalizedTo : '';
    }
}

/**
 * Validates that range_from <= range_to before plotting.
 * @param {number} fromValue - Current range_from value
 * @param {number} toValue - Current range_to value
 * @returns {boolean} true if validation passed, false otherwise
 */
window.CasualPlots.validateRangeOrder = (fromValue, toValue) => {
    if (fromValue !== null && toValue !== null && fromValue > toValue) {
        alert('Range Error: "Range from" must be less than or equal to "Range to"');
        return false;
    }
    return true;
}

/**
 * Handles Enter key press for integer input fields.
 * Triggers the same logic as updateIntObservable.
 * @param {Event} event - The DOM keydown event
 * @param {Observable} observable - The observable to update
 */
window.CasualPlots.handleIntEnterKey = (event, observable) => {
    if (event.key === 'Enter') {
        event.preventDefault();
        window.CasualPlots.updateIntObservable(event, observable);
    }
}

// ============================================================
// Axis Limits Functions
// ============================================================

// Global state for axis limit defaults (used for placeholder display and default detection)
window.CasualPlots._axisLimitDefaults = {
    x_min: null, x_max: null, y_min: null, y_max: null
};

/**
 * Updates an axis limit observable with validation.
 * Validates that min < max before allowing the update.
 * @param {Event} event - The DOM event
 * @param {Observable} observable - The observable to update (the one being edited)
 * @param {Observable} pairedObservable - The paired observable (min if editing max, vice versa)
 * @param {string} limitType - 'min' or 'max' indicating which limit is being edited
 */
window.CasualPlots.updateAxisLimitObservable = (event, observable, pairedObservable, limitType) => {
    const input = event.target;
    const value = input.value.trim();
    
    if (value === '') {
        // Empty: set to null (auto/default)
        observable.notify(null);
        return;
    }
    
    const floatValue = parseFloat(value);
    if (isNaN(floatValue)) {
        // Invalid: revert to previous value
        const prevValue = observable.value;
        input.value = prevValue !== null ? prevValue : '';
        return;
    }
    
    // Get paired value for validation
    const pairedValue = pairedObservable.value;
    
    // Validate min < max
    if (pairedValue !== null) {
        if (limitType === 'min' && floatValue >= pairedValue) {
            // min must be < max - revert
            console.warn('Axis limit validation failed: min must be less than max');
            const prevValue = observable.value;
            input.value = prevValue !== null ? prevValue : '';
            return;
        }
        if (limitType === 'max' && floatValue <= pairedValue) {
            // max must be > min - revert
            console.warn('Axis limit validation failed: max must be greater than min');
            const prevValue = observable.value;
            input.value = prevValue !== null ? prevValue : '';
            return;
        }
    }
    
    // Valid: update the observable
    observable.notify(floatValue);
}

/**
 * Handles Enter key press for axis limit input fields.
 * @param {Event} event - The DOM keydown event
 * @param {Observable} observable - The observable to update
 * @param {Observable} pairedObservable - The paired observable for validation
 * @param {string} limitType - 'min' or 'max'
 */
window.CasualPlots.handleAxisLimitEnterKey = (event, observable, pairedObservable, limitType) => {
    if (event.key === 'Enter') {
        event.preventDefault();
        window.CasualPlots.updateAxisLimitObservable(event, observable, pairedObservable, limitType);
        event.target.blur(); // Unfocus after Enter
    }
}

/**
 * Sets the placeholder values for axis limit inputs and stores defaults.
 * Called from Julia when defaults change (e.g., after new plot creation).
 * @param {number|null} xMin - X axis minimum default
 * @param {number|null} xMax - X axis maximum default
 * @param {number|null} yMin - Y axis minimum default
 * @param {number|null} yMax - Y axis maximum default
 */
window.CasualPlots.setAxisLimitPlaceholders = (xMin, xMax, yMin, yMax) => {
    const formatValue = (val) => {
        if (val === null || val === undefined || val === "null") return '';
        const num = parseFloat(val);
        if (isNaN(num)) return '';
        // Use toPrecision for very large/small numbers, otherwise toFixed
        if (Math.abs(num) >= 1e6 || (Math.abs(num) < 1e-3 && num !== 0)) {
            return num.toPrecision(4);
        }
        return num.toFixed(3).replace(/\.?0+$/, ''); // Remove trailing zeros
    };
    
    // Store defaults for later comparison
    window.CasualPlots._axisLimitDefaults = {
        x_min: xMin, x_max: xMax, y_min: yMin, y_max: yMax
    };
    
    const xMinInput = document.getElementById('axis-x-min-input');
    const xMaxInput = document.getElementById('axis-x-max-input');
    const yMinInput = document.getElementById('axis-y-min-input');
    const yMaxInput = document.getElementById('axis-y-max-input');
    
    if (xMinInput) xMinInput.placeholder = formatValue(xMin);
    if (xMaxInput) xMaxInput.placeholder = formatValue(xMax);
    if (yMinInput) yMinInput.placeholder = formatValue(yMin);
    if (yMaxInput) yMaxInput.placeholder = formatValue(yMax);
}

/**
 * Sets the actual values in axis limit input fields (not placeholders).
 * Used when syncing from pan/zoom changes.
 * @param {number|null} xMin - X axis minimum value
 * @param {number|null} xMax - X axis maximum value
 * @param {number|null} yMin - Y axis minimum value
 * @param {number|null} yMax - Y axis maximum value
 */
window.CasualPlots.setAxisLimitInputValues = (xMin, xMax, yMin, yMax) => {
    const formatValue = (val) => {
        if (val === null || val === undefined || val === "null") return '';
        const num = parseFloat(val);
        if (isNaN(num)) return '';
        if (Math.abs(num) >= 1e6 || (Math.abs(num) < 1e-3 && num !== 0)) {
            return num.toPrecision(4);
        }
        return num.toFixed(3).replace(/\.?0+$/, '');
    };
    
    const xMinInput = document.getElementById('axis-x-min-input');
    const xMaxInput = document.getElementById('axis-x-max-input');
    const yMinInput = document.getElementById('axis-y-min-input');
    const yMaxInput = document.getElementById('axis-y-max-input');
    
    if (xMinInput) xMinInput.value = formatValue(xMin);
    if (xMaxInput) xMaxInput.value = formatValue(xMax);
    if (yMinInput) yMinInput.value = formatValue(yMin);
    if (yMaxInput) yMaxInput.value = formatValue(yMax);
}

/**
 * Checks if an axis limit value is approximately at its default.
 * Uses relative tolerance: |current - default| / rangeSpan < 5e-4
 * @param {number|null} currentValue - Current limit value
 * @param {number|null} defaultValue - Default limit value
 * @param {number} rangeSpan - The current range span (max - min)
 * @returns {boolean} true if the value is considered at default
 */
window.CasualPlots.isAxisLimitAtDefault = (currentValue, defaultValue, rangeSpan) => {
    if (currentValue === null || defaultValue === null) {
        return currentValue === defaultValue;
    }
    if (rangeSpan === 0 || isNaN(rangeSpan)) return false;
    
    const relativeError = Math.abs(currentValue - defaultValue) / Math.abs(rangeSpan);
    return relativeError < 5e-4;
}

/**
 * Updates reversal checkbox state from Julia.
 * @param {string} axis - 'x' or 'y'
 * @param {boolean} isReversed - Whether the axis is reversed
 */
window.CasualPlots.updateReversalCheckbox = (axis, isReversed) => {
    const checkbox = document.getElementById(`axis-${axis}-reversed-checkbox`);
    if (checkbox) {
        checkbox.checked = isReversed;
    }
}

/**
 * Clears all axis limit input fields and placeholders.
 * Called when clearing the plot.
 */
window.CasualPlots.clearAxisLimitInputs = () => {
    const inputs = [
        'axis-x-min-input', 'axis-x-max-input',
        'axis-y-min-input', 'axis-y-max-input'
    ];
    inputs.forEach(id => {
        const input = document.getElementById(id);
        if (input) {
            input.value = '';
            input.placeholder = '';
        }
    });
    
    // Reset stored defaults
    window.CasualPlots._axisLimitDefaults = {
        x_min: null, x_max: null, y_min: null, y_max: null
    };
    
    // Uncheck reversal checkboxes
    const xRevCheckbox = document.getElementById('axis-x-reversed-checkbox');
    const yRevCheckbox = document.getElementById('axis-y-reversed-checkbox');
    if (xRevCheckbox) xRevCheckbox.checked = false;
    if (yRevCheckbox) yRevCheckbox.checked = false;
}
