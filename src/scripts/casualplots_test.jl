include("setup_test.jl")

app = casualplots_app()

Ele.serve_app(app)


# the current plot is exported and accessible as `cp_figure`
# and can be displayed in your environment by 
# julia> cp_figure
#
# Its Axis object is accessible as `cp_figure_ax`, thus you can modify the plot, e.g.
# julia> cp_figure_ax.title = "New Title"

# To close the app, please call:
# close(app)
