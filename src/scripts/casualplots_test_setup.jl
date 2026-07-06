using CasualPlots
using WGLMakie
using AlgebraOfGraphics
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
isdefined(Main, :caspl_u_25) || (caspl_u_25 = (1:25).*u"mm^2")
isdefined(Main, :caspl_cm_25) || (caspl_cm_25 = (1:25).*u"cm^2")

if !isdefined(Main, :caspl_mmcm_25) 
    caspl_mmcm_25 = Vector{Any}(((1.0:25.0).*u"cm^2") |> collect)
    caspl_mmcm_25[3] = (2.9*u"cm^2" |> u"mm^2")
end


# Create test DataFrames from existing arrays
isdefined(Main, :caspl_df_simple) || (caspl_df_simple = DataFrame(
    x = caspl_x_10,
    y1 = caspl_x_10.^2,
    y2 = caspl_x_10.^1.5,
))

isdefined(Main, :caspl_df_large) || (caspl_df_large = DataFrame(
    time = caspl_x_100,
    sqrt_val = caspl_z100,
    col1 = caspl_tbl100x10[:, 1],
    col2 = caspl_tbl100x10[:, 2],
    col3 = caspl_tbl100x10[:, 3],
))

isdefined(Main, :caspl_df_unitful) || (caspl_df_unitful = DataFrame(
    index = 1:10,
    area = caspl_u_10,
    linear = (1:10).*u"mm",
))

if !isdefined(Main, :caspl_df_unitmix)
    caspl_df_unitmix = let
        unimix = copy(caspl_u_25) |> Vector{Any}
        unimix[3] = missing
        unimix[5] = π
        unimix = collect(unimix)

        unimiss = copy(caspl_u_25) |> Vector{Any}
        unimiss[4] = missing
        unimiss[5] = "Missis"
        unimiss = collect(unimiss)

        DataFrame(
        index = 1:25,
        area = caspl_u_25 .* 1.1,
        linear = ((1:25)./1.1).*u"mm",
        unimix = unimix,
        unimiss = unimiss,
        areacm = caspl_cm_25 .* 0.009,
        areammcm = caspl_mmcm_25 .* 0.008,
        )
    end
end



if !isdefined(Main, :caspl_df_exp) 
    xs = 0.0:10
    n_cols = 40
    m = hcat(xs, make_y(xs, n_cols))
    nms = vcat("x", ["y$n" for n in 1:n_cols])
    caspl_df_exp = DataFrame(m, nms)
end
;