function var_to_string(t)
    s = t |> Symbol |> string
    parts = split(s, '.')
    return parts[end]
end

function create_plot(x_data, y_data, x_name, y_name; art=Scatter)
    if size(x_data, 1) != size(y_data, 1)
        println("Error: Dimension mismatch. X has length $(length(x_data)) but Y has $(size(y_data, 1)) rows.")
        return nothing
    end
    
    n_cols = size(y_data, 2)
    x_long = repeat(x_data, n_cols)
    y_long = vec(y_data)
    group = repeat(1:n_cols, inner=size(x_data, 1))
    
    df = (; x=x_long, y=y_long, group=string.(group))
    plt = data(df) * mapping(:x, :y, color=:group) *  visual(art)

    fig = Figure(size = (800, 600))
    ax = Axis(fig[1, 1], xlabel=x_name, ylabel=y_name, title="$(var_to_string(art)) Plot of $y_name vs $x_name")
    draw!(ax, plt)
    show(IOBuffer(), MIME"text/html"(), fig) # Force render to complete without needing a display
    global cp_figure = fig
    global cp_figure_ax = ax
    return fig
end

function check_data_create_plot(x_name, y_name; art=Scatter) # x, y AbstractString or Symbol
    try
        x_data = getfield(Main, Symbol(x_name))
        y_data = getfield(Main, Symbol(y_name))

        if y_data isa AbstractVector
            y_data = reshape(y_data, :, 1)
        end

        if y_data isa AbstractMatrix && x_data isa AbstractVector
            return create_plot(x_data, y_data, x_name, y_name; art)
        else
            println("Error: Unsupported data types for plotting. x must be a vector, and y can be a vector or a matrix.")
            return nothing
        end
    catch e
        println("An error occurred during plotting: ", e)
        return nothing
    end
end