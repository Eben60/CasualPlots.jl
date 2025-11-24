using CasualPlots
using WGLMakie
using Bonito

# Creating a few vectors and matrices for the tests
# Prefix all var names by caspl_ to avoid name conflicts

isdefined(Main, :caspl_x_10) || (caspl_x_10 = 1:10)
isdefined(Main, :caspl_ys10) || (caspl_ys10 = hcat(caspl_x_10.^2, caspl_x_10.^1.5))
isdefined(Main, :caspl_z10) || (caspl_z10 = 1.0:0.5:5.5)
isdefined(Main, :caspl_x_to_3by2) || (caspl_x_to_3by2 = caspl_x_10.^(3//2))
isdefined(Main, :caspl_x_100) || (caspl_x_100 = 0:0.1:10)
isdefined(Main, :caspl_z100) || (caspl_z100 = caspl_x_100 .|> sqrt)
isdefined(Main, :caspl_tbl100x10) || (caspl_tbl100x10 = create_data_matrix(caspl_x_100, 10))

app = casualplots_app()

# Electron or Browser
ele_serve = true

if ele_serve
    Ele.serve_app(app)
else
    # this opens the GUI in browser for debugging
    server = Bonito.Server(app, "127.0.0.1", 8000)
    println("Server running at http://127.0.0.1:8000")
    println("Press Ctrl+C to stop the server")
    wait(server)
end


# the current plot is exported and accessible as `cp_figure`
# and can be displayed in your environment by 
# julia> cp_figure
#
# It's Axis object is accessible as `cp_figure_ax`, thus you can modify the plot, e.g.
# julia> cp_figure_ax.title = "New Title"

# To close the app, you can call:
# close(app)
