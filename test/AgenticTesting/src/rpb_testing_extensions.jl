# rpb_testing_extensions.jl
#
# Extensions for agentic testing of the (Re-)Plot Button (RPB) refactoring
# and decoupled reactive Data Table.

"""
    get_table_headers_dom(session::Bonito.Session) -> Vector{String}

Retrieve column header titles from the active Data Table rendered in the browser DOM.
"""
function get_table_headers_dom(session)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const ths = document.querySelectorAll('.cp-table-fw th, .table-pane-container th');
            return Array.from(ths).map(th => th.innerText.trim());
        })()
    """)
end

"""
    get_table_row_count_dom(session::Bonito.Session) -> Int

Retrieve the count of data rows rendered in the active Data Table DOM.
"""
function get_table_row_count_dom(session)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const trs = document.querySelectorAll('.cp-table-fw tbody tr, .table-pane-container tbody tr');
            return trs.length;
        })()
    """)
end

"""
    get_table_cell_dom(session::Bonito.Session, row::Int, col::Int) -> String

Retrieve the text of a cell at 1-based `row` and `col` coordinates from the rendered table.
"""
function get_table_cell_dom(session, row, col)
    return Bonito.evaljs_value(session, js"""
        (function() {
            const rows = document.querySelectorAll('.cp-table-fw tbody tr, .table-pane-container tbody tr');
            if ($(row) < 1 || $(row) > rows.length) return "";
            const cells = rows[$(row) - 1].querySelectorAll('td');
            if ($(col) < 1 || $(col) > cells.length) return "";
            return cells[$(col) - 1].innerText.trim();
        })()
    """)
end

"""
    get_modal_info_dom(session::Bonito.Session) -> NamedTuple

Inspect the modal dialog elements in the DOM and return its visual state.
"""
function get_modal_info_dom(session)
    res = Bonito.evaljs_value(session, js"""
        (function() {
            const okBtn = document.querySelector('#btn-modal-ok');
            const cancelBtn = document.querySelector('#btn-modal-cancel');
            
            // Check visibility by looking for the visible overlay containing okBtn
            let visible = false;
            let overlay = null;
            if (okBtn) {
                overlay = okBtn.closest('div[style*="position: fixed"]');
                if (overlay && overlay.style.display !== 'none') {
                    visible = true;
                }
            }
            
            let message = "";
            let title = "";
            if (overlay) {
                const msgEl = overlay.querySelector('p');
                if (msgEl) message = msgEl.innerText.trim();
                const titleSpan = overlay.querySelector('div > span:nth-child(2)');
                if (titleSpan) title = titleSpan.innerText.trim();
            }

            return {
                visible: visible,
                title: title,
                message: message,
                ok_label: okBtn ? okBtn.innerText.trim() : "",
                has_cancel: !!cancelBtn,
                cancel_label: cancelBtn ? cancelBtn.innerText.trim() : ""
            };
        })()
    """)

    return (;
        visible = Bool(get(res, "visible", false)),
        title = String(get(res, "title", "")),
        message = String(get(res, "message", "")),
        ok_label = String(get(res, "ok_label", "")),
        has_cancel = Bool(get(res, "has_cancel", false)),
        cancel_label = String(get(res, "cancel_label", "")),
    )
end

"""
    click_replot(session::Bonito.Session) -> Nothing

Click the (Re-)Plot button (`#btn-replot`).
"""
function click_replot(session)
    click_button(session, "#btn-replot")
    return nothing
end

"""
    click_modal_primary(session::Bonito.Session) -> Nothing

Click the primary modal button (`#btn-modal-ok`, e.g. "OK" or "Continue").
"""
function click_modal_primary(session)
    click_button(session, "#btn-modal-ok")
    return nothing
end

"""
    click_modal_secondary(session::Bonito.Session) -> Nothing

Click the secondary modal button (`#btn-modal-cancel`, e.g. "Select data anew" or "Cancel").
"""
function click_modal_secondary(session)
    click_button(session, "#btn-modal-cancel")
    return nothing
end

