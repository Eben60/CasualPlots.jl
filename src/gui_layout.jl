"""
    assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, state, overwrite_trigger, cancel_trigger)

Assemble the application layout using BonitoWidgets.Workspace.

Default arrangement: Controls (left) + Plot (right) docked side-by-side.
Data Table starts as a floating window.

# Returns
Complete DOM structure for the application including modal overlay
"""
function inject_window_controls(xObs, yObs, wObs, hObs; orig_x, orig_y, orig_w, orig_h)
    # Marker element: placed inside the FloatingWindow body so we can
    # traverse up to .bw-float via Bonito's $() interpolation.
    marker = DOM.div(; style=Styles("display" => "none"))

    setup = js"""
    (() => {
        const marker = $(marker);
        const fw = marker.closest('.bw-float');
        if (!fw) return;
        const titleBar = fw.querySelector('.bw-float-title');
        if (!titleBar) return;
        const closeBtn = titleBar.querySelector('.bw-float-close');
        
        const controls = document.createElement('div');
        controls.style.display = 'flex';
        
        // Minimize
        const btnMin = document.createElement('button');
        btnMin.className = 'bw-icon-btn';
        btnMin.innerHTML = '\u2212';
        btnMin.title = 'Minimize';
        btnMin.style.fontSize = '18px';
        btnMin.style.paddingBottom = '4px';
        btnMin.onclick = () => {
            fw.style.minHeight = '32px';
            const body = fw.querySelector('.bw-float-body');
            if (body) body.style.display = 'none';
            $(wObs).notify(350);
            $(hObs).notify(32);
        };
        
        // Maximize: hide other panes, fill viewport
        const btnMax = document.createElement('button');
        btnMax.className = 'bw-icon-btn';
        btnMax.innerHTML = '\u26f6';
        btnMax.title = 'Maximize';
        btnMax.style.fontSize = '14px';
        btnMax.onclick = () => {
            fw.style.minHeight = '';
            const body = fw.querySelector('.bw-float-body');
            if (body) body.style.display = '';
            const grid = document.querySelector('.cp-main-grid');
            if (grid) grid.style.display = 'none';
            $(xObs).notify(0);
            $(yObs).notify(0);
            $(wObs).notify(document.documentElement.clientWidth);
            $(hObs).notify(document.documentElement.clientHeight);
        };
        
        // Restore: show other panes, restore original geometry
        const btnRes = document.createElement('button');
        btnRes.className = 'bw-icon-btn';
        btnRes.innerHTML = '\u21ba';
        btnRes.title = 'Restore';
        btnRes.style.fontSize = '16px';
        btnRes.onclick = () => {
            fw.style.minHeight = '';
            const body = fw.querySelector('.bw-float-body');
            if (body) body.style.display = '';
            const grid = document.querySelector('.cp-main-grid');
            if (grid) grid.style.display = '';
            $(xObs).notify($(orig_x));
            $(yObs).notify($(orig_y));
            $(wObs).notify($(orig_w));
            $(hObs).notify($(orig_h));
        };
        
        controls.appendChild(btnMin);
        controls.appendChild(btnRes);
        controls.appendChild(btnMax);
        titleBar.insertBefore(controls, closeBtn);
    })();
    """

    return DOM.div(marker, DOM.script(setup); style=Styles("display" => "none"))
end

function assemble_layout(ctrlpane_content, help_visibility, plot_observable, table_observable, table_title, state, overwrite_trigger, cancel_trigger)
    # Control pane: tabs on top, help section at bottom
    ctrlpane_split = DOM.div(
        DOM.div(ctrlpane_content; class="ctrl-pane-content"),
        help_section(help_visibility);
        class="ctrl-pane-split"
    )
    
    # --- Define Grid Cells (Top Row Only) ---
    ctrlpane = Card(ctrlpane_split; class="pane-card pane-card-ctrl")
    pltpane = Card(plot_observable; class="pane-card pane-card-plot")
    
    # Grid layout (only top row needed)
    # cp-main-grid class is used by window controls to hide/show the grid on maximize/restore
    container = Grid(ctrlpane, pltpane; columns="350px 810px", rows="610px", gap="5px", class="cp-main-grid", style=Styles("height"=>"610px"))
    
    # --- Floating Window ---
    # Create observables so we can pass them to the window controls script
    fw_x = Observable(5)
    fw_y = Observable(655)
    fw_w = Observable(1165)
    fw_h = Observable(270)
    
    controls_script = inject_window_controls(fw_x, fw_y, fw_w, fw_h; orig_x=5, orig_y=655, orig_w=1165, orig_h=270)
    
    # Wrap table_observable in a div with auto overflow to allow internal scrolling
    table_content = DOM.div(table_observable, controls_script; class="table-float-content")
    
    fw = FloatingWindow(
        table_content;
        title=table_title,
        # Positioned right below the 610px high grid + future plot titlebar
        x=fw_x, y=fw_y, width=fw_w, height=fw_h
    )
    
    # --- Modal dialog (must sit ABOVE BonitoWidgets floating layer) ---
    modal = create_modal_container(state, overwrite_trigger, cancel_trigger)
    
    # --- Global CSS (our custom styles for inputs, buttons, format tab, etc.) ---
    global_style = DOM.style(GLOBAL_CSS)
    
    return DOM.div(
        global_style,
        container,
        fw,
        modal;
        class="main-layout-container",
        style=Styles("height" => "100vh", "position" => "relative", "box-sizing"=>"border-box")
    )
end
