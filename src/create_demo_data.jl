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

export create_data_matrix
