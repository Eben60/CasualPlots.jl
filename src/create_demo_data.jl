"""
    create_data_matrix(x::AbstractVector, n::Integer)

Generates a matrix with n columns based on the input vector x.
The i-th column is calculated as x.^(0.3 + i * 0.2).

Function used for demo purposes only.
"""
function create_data_matrix(x::AbstractVector, n::Integer)
   
    len_x = length(x)
    result_matrix = Matrix{Float64}(undef, len_x, n)
    
    for i in 1:n
        exponent = 0.4 + i * 0.1
        result_matrix[:, i] = x .^ exponent
    end
    
    return result_matrix
end

function make_y(v, n)
    m = Matrix{Float64}(undef, length(v), n)
    r = range(; start=0.2, stop=1.2, length=n)
    for (i, x) in pairs(r)
        m[:, i] = v .^ x
    end
    return m
end

# Creating a few vectors and matrices for the tests
# Prefix all var names by caspl_ to avoid name conflicts

function variable_examples()
    caspl_x_10 = 1:10
    caspl_ys10 = hcat(caspl_x_10.^2, caspl_x_10.^1.5)
    caspl_z10 = 1.0:0.5:5.5
    caspl_x_to_3by2 = caspl_x_10.^(3//2)
    caspl_x_100 = 0:0.1:10
    caspl_z100 = caspl_x_100 .|> sqrt
    caspl_tbl100x10 = create_data_matrix(caspl_x_100, 10)
    caspl_u_10 = (1:10).*u"mm^2"
    caspl_u_25 = (1:25).*u"mm^2"
    caspl_cm_25 = (1:25).*u"cm^2"

    caspl_mmcm_25 = Vector{Any}(((1.0:25.0).*u"cm^2") |> collect)
    caspl_mmcm_25[3] = (2.9*u"cm^2" |> u"mm^2")

    caspl_3d = 
    let
        m = create_data_matrix(caspl_x_10, 12)
        t = reshape(m, 10, 3, 4)
    end

    # Create test DataFrames from existing arrays
    caspl_df_simple = DataFrame(
        x = caspl_x_10,
        y1 = caspl_x_10.^2,
        y2 = caspl_x_10.^1.5,
    )

    caspl_df_large = DataFrame(
        time = caspl_x_100,
        sqrt_val = caspl_z100,
        col1 = caspl_tbl100x10[:, 1],
        col2 = caspl_tbl100x10[:, 2],
        col3 = caspl_tbl100x10[:, 3],
    )

    caspl_df_unitful = DataFrame(
        index = 1:10,
        area = caspl_u_10,
        linear = (1:10).*u"mm",
    )

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

    caspl_df_exp = 
    let
        xs = 0.0:10
        n_cols = 40
        m = hcat(xs, make_y(xs, n_cols))
        nms = vcat("x", ["y$n" for n in 1:n_cols])
        DataFrame(m, nms)
    end

    return (; 
        caspl_x_10, 
        caspl_ys10, 
        caspl_z10, 
        caspl_x_to_3by2, 
        caspl_x_100, 
        caspl_z100, 
        caspl_tbl100x10, 
        caspl_u_10, 
        caspl_u_25, 
        caspl_cm_25, 
        caspl_mmcm_25, 
        caspl_3d, 
        caspl_df_simple, 
        caspl_df_large, 
        caspl_df_unitful, 
        caspl_df_unitmix, 
        caspl_df_exp,
    )
end

"""
    @populate()

Injects several demo variables into the caller's scope. 
These variables (prefixed with `caspl_`) include arrays, matrices, Unitful vectors, and DataFrames of varying complexity. They are primarily used for testing and demonstrating CasualPlots functionality.

Variables created include:
- `caspl_x_10`, `caspl_ys10`, `caspl_z10`, etc. (Vectors and Matrices)
- `caspl_u_10`, `caspl_cm_25`, etc. (Unitful arrays)
- `caspl_df_simple`, `caspl_df_large`, `caspl_df_unitful`, etc. (DataFrames)
"""
macro populate()
    return esc(quote
        (; 
            caspl_x_10, 
            caspl_ys10, 
            caspl_z10, 
            caspl_x_to_3by2, 
            caspl_x_100, 
            caspl_z100, 
            caspl_tbl100x10, 
            caspl_u_10, 
            caspl_u_25, 
            caspl_cm_25, 
            caspl_mmcm_25, 
            caspl_3d, 
            caspl_df_simple, 
            caspl_df_large, 
            caspl_df_unitful, 
            caspl_df_unitmix, 
            caspl_df_exp,
        ) = CasualPlots.variable_examples();
    end)
end
