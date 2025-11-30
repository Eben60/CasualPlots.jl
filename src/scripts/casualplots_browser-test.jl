using CasualPlots
using WGLMakie
using Bonito
using Unitful
using DataFrames

# Creating a few vectors and matrices for the tests
# Prefix all var names by caspl_ to avoid name conflicts

isdefined(Main, :caspl_x_10) || (caspl_x_10 = 1:10)
isdefined(Main, :caspl_ys10) || (caspl_ys10 = hcat(caspl_x_10.^2, caspl_x_10.^1.5))
isdefined(Main, :caspl_z10) || (caspl_z10 = 1.0:0.5:5.5)
isdefined(Main, :caspl_x_to_3by2) || (caspl_x_to_3by2 = caspl_x_10.^(3//2))
isdefined(Main, :caspl_x_100) || (caspl_x_100 = 0:0.1:10)
isdefined(Main, :caspl_z100) || (caspl_z100 = caspl_x_100 .|> sqrt)
isdefined(Main, :caspl_tbl100x10) || (caspl_tbl100x10 = create_data_matrix(caspl_x_100, 10))
isdefined(Main, :caspl_u_10) || (caspl_u_10 = (1:10).*u"mm^2")

# Create test DataFrames from existing arrays
isdefined(Main, :caspl_df_simple) || (caspl_df_simple = DataFrame(
    x = caspl_x_10,
    y1 = caspl_x_10.^2,
    y2 = caspl_x_10.^1.5
))

isdefined(Main, :caspl_df_large) || (caspl_df_large = DataFrame(
    time = caspl_x_100,
    sqrt_val = caspl_z100,
    col1 = caspl_tbl100x10[:, 1],
    col2 = caspl_tbl100x10[:, 2],
    col3 = caspl_tbl100x10[:, 3]
))

isdefined(Main, :caspl_df_unitful) || (caspl_df_unitful = DataFrame(
    index = 1:10,
    area = caspl_u_10,
    linear = (1:10).*u"mm"
))

if !isdefined(Main, :caspl_df_exp) 
    xs = 0.0:10
    n_cols = 40
    m = hcat(xs, make_y(xs, n_cols))
    nms = vcat("x", ["y$n" for n in 1:n_cols])
    caspl_df_exp = DataFrame(m, nms)
end

app = casualplots_app()

# this opens the GUI in browser for debugging
server = Bonito.Server(app, "127.0.0.1", 8000)
println("Server running at http://127.0.0.1:8000")
println("Press Ctrl+C to stop the server")
wait(server)


# To close the app, you can call:
# close(app)
