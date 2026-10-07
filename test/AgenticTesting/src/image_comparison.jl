# image_comparison.jl

"""
    compare_images_ssim(path1::String, path2::String; threshold::Real = Sys.isapple() ? 0.98 : 0.9) -> Bool

Loads two images using FileIO, strips any alpha channel, and computes their 
Structural Similarity Index (SSIM). Returns true if the SSIM score is greater 
than or equal to the `threshold`.
"""
function compare_images_ssim(path1::String, path2::String; threshold::Real = Sys.isapple() ? 0.98 : 0.9)
    if !isfile(path1)
        @warn "File not found: $path1"
        return false
    end
    if !isfile(path2)
        @warn "File not found: $path2"
        return false
    end

    # Load images and strip alpha channel by converting to RGB
    img1 = RGB.(FileIO.load(path1))
    img2 = RGB.(FileIO.load(path2))

    if size(img1) != size(img2)
        @info "Images have different dimensions: $(size(img1)) vs $(size(img2))"
        return false
    end

    score = assess_ssim(img1, img2)
    if score < threshold
        @info "SSIM score $(round(score, digits=4)) is below threshold $threshold"
        return false
    end

    return true
end

