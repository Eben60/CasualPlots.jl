"""
    inject_window_controls(; xObs, yObs, wObs, hObs, orig_x, orig_y, orig_w, orig_h,
                             other_xObs, other_yObs, other_wObs, other_hObs,
                             other_orig_x, other_orig_y, other_orig_w, other_orig_h,
                             other_fw_class, size_obs=nothing)

Inject minimize/restore/maximize window control buttons into a BonitoWidgets FloatingWindow.

On **maximize**, this window fills the viewport and hides the grid + other window.
On **restore**, BOTH windows are fully reset to their initial geometry (position, size,
body visibility, minHeight), and the grid is shown again.
"""
function inject_window_controls(; xObs, yObs, wObs, hObs, orig_x, orig_y, orig_w, orig_h,
                                  other_xObs, other_yObs, other_wObs, other_hObs,
                                  other_orig_x, other_orig_y, other_orig_w, other_orig_h,
                                  other_fw_class, size_obs=nothing)
    marker = DOM.div(; style=Styles("display" => "none"))
    
    actual_size_obs = isnothing(size_obs) ? Observable{Any}((0,0)) : size_obs
    has_size_obs = !isnothing(size_obs)

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
        
        // Helper: fully reset a .bw-float element's CSS overrides
        function resetFwCss(el) {
            if (!el) return;
            el.style.minHeight = '';
            const body = el.querySelector('.bw-float-body');
            if (body) body.style.display = '';
        }
        
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
        
        // Maximize: hide grid + other window, fill viewport
        const btnMax = document.createElement('button');
        btnMax.className = 'bw-icon-btn';
        btnMax.innerHTML = '\u26f6';
        btnMax.title = 'Maximize';
        btnMax.style.fontSize = '14px';
        btnMax.onclick = () => {
            resetFwCss(fw);
            const grid = document.querySelector('.cp-main-grid');
            if (grid) grid.style.display = 'none';
            const other = document.querySelector('.' + $(other_fw_class));
            if (other) other.style.display = 'none';
            $(xObs).notify(0);
            $(yObs).notify(0);
            $(wObs).notify(document.documentElement.clientWidth);
            $(hObs).notify(document.documentElement.clientHeight);
        };
        
        // Restore: fully reset BOTH windows to initial layout
        const btnRes = document.createElement('button');
        btnRes.className = 'bw-icon-btn';
        btnRes.innerHTML = '\u21ba';
        btnRes.title = 'Restore';
        btnRes.style.fontSize = '16px';
        btnRes.onclick = () => {
            // Show everything
            const grid = document.querySelector('.cp-main-grid');
            if (grid) grid.style.display = '';
            const otherWrapper = document.querySelector('.' + $(other_fw_class));
            if (otherWrapper) otherWrapper.style.display = '';
            
            // Reset THIS window's CSS and geometry
            resetFwCss(fw);
            $(xObs).notify($(orig_x));
            $(yObs).notify($(orig_y));
            $(wObs).notify($(orig_w));
            $(hObs).notify($(orig_h));
            
            // Reset OTHER window's CSS and geometry
            if (otherWrapper) {
                const otherFw = otherWrapper.querySelector('.bw-float');
                resetFwCss(otherFw);
            }
            $(other_xObs).notify($(other_orig_x));
            $(other_yObs).notify($(other_orig_y));
            $(other_wObs).notify($(other_orig_w));
            $(other_hObs).notify($(other_orig_h));
        };
        
        controls.appendChild(btnMin);
        controls.appendChild(btnRes);
        controls.appendChild(btnMax);
        titleBar.insertBefore(controls, closeBtn);
        
        // Attach ResizeObserver for plot canvas scaling
        if ($(has_size_obs)) {
            setTimeout(() => {
                const body = fw.querySelector('.bw-float-body');
                if (body) {
                    const ro = new ResizeObserver(entries => {
                        for (let entry of entries) {
                            let w = entry.contentRect.width;
                            let h = entry.contentRect.height;
                            if (w > 0 && h > 0) {
                                $(actual_size_obs).notify([Math.round(w), Math.round(h)]);
                            }
                        }
                    });
                    ro.observe(body);
                }
            }, 100);
        }
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
    
    ctrlpane = Card(ctrlpane_split; class="pane-card pane-card-ctrl")
    
    # Grid layout (only contains ctrlpane)
    container = Grid(ctrlpane; columns="350px", rows="645px", gap="5px", class="cp-main-grid", style=Styles("height"=>"645px"))
    
    # --- Geometry constants ---
    # Plot: right of the grid
    plot_orig = (; x=360, y=5, w=810, h=645)
    # Table: below the grid
    table_orig = (; x=5, y=655, w=1165, h=270)
    
    # --- Observables for both windows ---
    fw_plot_x = Observable(plot_orig.x)
    fw_plot_y = Observable(plot_orig.y)
    fw_plot_w = Observable(plot_orig.w)
    fw_plot_h = Observable(plot_orig.h)
    
    fw_table_x = Observable(table_orig.x)
    fw_table_y = Observable(table_orig.y)
    fw_table_w = Observable(table_orig.w)
    fw_table_h = Observable(table_orig.h)
    
    # --- Plot FloatingWindow ---
    plot_controls = inject_window_controls(;
        xObs=fw_plot_x, yObs=fw_plot_y, wObs=fw_plot_w, hObs=fw_plot_h,
        orig_x=plot_orig.x, orig_y=plot_orig.y, orig_w=plot_orig.w, orig_h=plot_orig.h,
        other_xObs=fw_table_x, other_yObs=fw_table_y, other_wObs=fw_table_w, other_hObs=fw_table_h,
        other_orig_x=table_orig.x, other_orig_y=table_orig.y, other_orig_w=table_orig.w, other_orig_h=table_orig.h,
        other_fw_class="cp-table-fw",
        size_obs=state.plotting.handles.plot_size)
    
    plot_content = DOM.div(plot_observable, plot_controls;
                           class="plot-float-content",
                           style=Styles("width"=>"100%", "height"=>"100%", "overflow"=>"hidden"))
    
    fw_plot = FloatingWindow(
        plot_content; title="Plot",
        x=fw_plot_x, y=fw_plot_y, width=fw_plot_w, height=fw_plot_h
    )
    
    # --- Table FloatingWindow ---
    table_controls = inject_window_controls(;
        xObs=fw_table_x, yObs=fw_table_y, wObs=fw_table_w, hObs=fw_table_h,
        orig_x=table_orig.x, orig_y=table_orig.y, orig_w=table_orig.w, orig_h=table_orig.h,
        other_xObs=fw_plot_x, other_yObs=fw_plot_y, other_wObs=fw_plot_w, other_hObs=fw_plot_h,
        other_orig_x=plot_orig.x, other_orig_y=plot_orig.y, other_orig_w=plot_orig.w, other_orig_h=plot_orig.h,
        other_fw_class="cp-plot-fw")
    
    table_content = DOM.div(table_observable, table_controls; class="table-float-content")
    
    fw_table = FloatingWindow(
        table_content; title=table_title,
        x=fw_table_x, y=fw_table_y, width=fw_table_w, height=fw_table_h
    )
    
    # --- Modal dialog ---
    modal = create_modal_container(state, overwrite_trigger, cancel_trigger)
    
    # --- Global CSS ---
    global_style = DOM.style(GLOBAL_CSS)
    
    return DOM.div(
        global_style,
        container,
        DOM.div(fw_plot; class="cp-plot-fw"),
        DOM.div(fw_table; class="cp-table-fw"),
        modal;
        class="main-layout-container",
        style=Styles("height" => "100vh", "position" => "relative", "box-sizing"=>"border-box")
    )
end

