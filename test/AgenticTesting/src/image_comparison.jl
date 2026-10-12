# image_comparison.jl

"""
    _extract_canonical_name(path::AbstractString) -> String

Extract the canonical image filename (e.g. `"foo.png"`) by stripping directory paths
and any trailing numeric suffix (such as `_01`, `_02`).
"""
function _extract_canonical_name(path::AbstractString)
    fname = basename(path)
    m = match(r"^(.*?)(?:_(\d+))?\.png$"i, fname)
    return m !== nothing ? String(m.captures[1]) * ".png" : fname
end

"""
    _canonical_name_for_pair(path1::AbstractString, path2::AbstractString) -> String

Determine canonical name for an image pair. Returns the shared canonical filename
if both paths share the same stem, or `"<name1> vs <name2>"` if they differ.
"""
function _canonical_name_for_pair(path1::AbstractString, path2::AbstractString)
    c1 = _extract_canonical_name(path1)
    c2 = _extract_canonical_name(path2)
    return c1 == c2 ? c1 : "$c1 vs $c2"
end

"""
    compare_images_ssim(path1::AbstractString, path2::AbstractString; threshold::Real = Sys.isapple() ? 0.98 : 0.9, crop::Bool = false) -> (; passed::Bool, score::Union{Real, Missing})

Loads two images using FileIO, strips any alpha channel, and computes their 
Structural Similarity Index (SSIM). If `crop` is `true` and the images have different 
dimensions, both images are cropped from the top-left to their common maximal size 
(intersection) before comparison. Returns a NamedTuple with `passed::Bool` 
(true if `score >= threshold`) and `score` (Float64, or `missing` on failure).
"""
function compare_images_ssim(path1, path2; threshold = Sys.isapple() ? 0.98 : 0.9, crop = false)
   
    if !isfile(path1)
        @warn "File not found: $path1"
        return (; passed = false, score = missing)
    end
    if !isfile(path2)
        @warn "File not found: $path2"
        return (; passed = false, score = missing)
    end

    canonical_name = _canonical_name_for_pair(path1, path2)

    # Load images and strip alpha channel by converting to RGB
    img1 = RGB.(FileIO.load(path1))
    img2 = RGB.(FileIO.load(path2))

    if size(img1) != size(img2)
        if crop
            h = min(size(img1, 1), size(img2, 1))
            w = min(size(img1, 2), size(img2, 2))
            @info "$(canonical_name): Images have different dimensions: $(size(img1)) vs $(size(img2)). Cropping to common maximal size: ($h, $w)"
            img1 = @view img1[1:h, 1:w]
            img2 = @view img2[1:h, 1:w]
        else
            @info "$(canonical_name): Images have different dimensions: $(size(img1)) vs $(size(img2))"
            return (; passed = false, score = missing)
        end
    end

    score = Float64(assess_ssim(img1, img2))
    passed = score >= threshold

    if !passed
        @info "$(canonical_name): SSIM score $(round(score, digits=4)) is below threshold $threshold"
    end

    return (; passed, score)
end

"""
    _find_screenshot_candidates(dir::AbstractString) -> Dict{String, String}

Scans `dir` non-recursively for PNG images. For each logical image base name,
selects the file without appended numbers if present; otherwise, selects the
highest-numbered file. Returns a dictionary mapping canonical filename
(e.g., `"foo.png"`) to the actual filename in `dir`.
"""
function _find_screenshot_candidates(dir)
    isdir(dir) || return Dict{String, String}()
    files = filter(f -> endswith(lowercase(f), ".png"), readdir(dir))
    groups = Dict{String, Vector{Tuple{Union{Int, Nothing}, String}}}()

    for f in files
        m = match(r"^(.*?)(?:_(\d+))?\.png$"i, f)
        m === nothing && continue
        stem = String(m.captures[1])
        num = m.captures[2] === nothing ? nothing : parse(Int, m.captures[2])
        push!(get!(groups, stem, Tuple{Union{Int, Nothing}, String}[]), (num, f))
    end

    candidates = Dict{String, String}()
    for (stem, file_list) in groups
        unversioned = filter(x -> x[1] === nothing, file_list)
        if !isempty(unversioned)
            candidates[stem * ".png"] = unversioned[1][2]
        else
            sort!(file_list, by = x -> x[1], rev = true)
            candidates[stem * ".png"] = file_list[1][2]
        end
    end

    return candidates
end

"""
    compare_directories_ssim(;
        ref_dir::AbstractString = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots")),
        target_dir::AbstractString = joinpath(ref_dir, "tmp"),
        threshold::Real = Sys.isapple() ? 0.98 : 0.9,
        crop::Bool = false,
    ) -> (; passed::Bool, scores::Dict{String, Union{Real, Missing}})

Compares screenshots between `ref_dir` and `target_dir` pairwise using SSIM.
By default, `ref_dir` is the golden reference screenshot directory, and `target_dir`
is the `tmp/` subdirectory within it.

Selects PNG files without appended numbers if available, or the highest-numbered PNG
file otherwise. Sets the score to `missing` if the counterpart in `target_dir` is missing.
Returns a NamedTuple with `passed::Bool` (true if all scores are >= `threshold` and none
are missing) and `scores` mapping canonical filenames to their scores.
"""
function compare_directories_ssim(;
    ref_dir = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots")),
    target_dir = joinpath(ref_dir, "tmp"),
    threshold = Sys.isapple() ? 0.98 : 0.9,
    crop = false,
)
    source_candidates = _find_screenshot_candidates(ref_dir)
    target_candidates = _find_screenshot_candidates(target_dir)

    scores = Dict{String, Union{Float64, Missing}}()

    for (canonical_name, ref_file) in source_candidates
        if !haskey(target_candidates, canonical_name)
            scores[canonical_name] = missing
        else
            tgt_file = target_candidates[canonical_name]
            ref_path = joinpath(ref_dir, ref_file)
            tgt_path = joinpath(target_dir, tgt_file)
            (; passed, score) = compare_images_ssim(ref_path, tgt_path; threshold, crop)

            scores[canonical_name] = score
        end
    end

    passed = !isempty(scores) && !any(ismissing, values(scores)) && all(s >= threshold for s in values(scores))

    return (; passed = passed, scores = scores)
end

"""
    crop_screenshot_plot(screenshot::AbstractArray; rows = 40:649, cols = 362:1169) -> AbstractArray
    crop_screenshot_plot(screenshot_path::AbstractString; rows = 40:649, cols = 362:1169) -> Matrix{RGB}

Crop the plot canvas area from a full CasualPlots GUI screenshot.
Defaults to `rows = 40:649` and `cols = 362:1169` (the 808×610 plot canvas within a 1200×960 window).
"""
function crop_screenshot_plot(screenshot::AbstractArray; rows = 40:649, cols = 362:1169)
    return screenshot[rows, cols]
end

function crop_screenshot_plot(screenshot_path::AbstractString; rows = 40:649, cols = 362:1169)
    isfile(screenshot_path) || error("Screenshot file not found: $screenshot_path")
    img = RGB.(FileIO.load(screenshot_path))
    return crop_screenshot_plot(img; rows = rows, cols = cols)
end

"""
    compare_screenshot_plot_ssim(
        screenshot_path::AbstractString,
        plot_path::AbstractString;
        threshold::Real = Sys.isapple() ? 0.98 : 0.9,
        crop_rows = 40:649,
        crop_cols = 362:1169,
    ) -> (; passed::Bool, score::Union{Real, Missing})

Crops the plot canvas from `screenshot_path` and computes its SSIM comparison against
the standalone rendered figure in `plot_path`. Returns a NamedTuple with `passed::Bool`
and `score` (Float64 or `missing` if either file is not found).
"""
function compare_screenshot_plot_ssim(
    screenshot_path,
    plot_path;
    threshold = Sys.isapple() ? 0.98 : 0.9,
    crop_rows = 40:649,
    crop_cols = 362:1169,
)
    if !isfile(screenshot_path)
        @warn "Screenshot file not found: $screenshot_path"
        return (; passed = false, score = missing)
    end
    if !isfile(plot_path)
        @warn "Plot file not found: $plot_path"
        return (; passed = false, score = missing)
    end

    img_shot = RGB.(FileIO.load(screenshot_path))
    img_plot = RGB.(FileIO.load(plot_path))

    cropped = crop_screenshot_plot(img_shot; rows = crop_rows, cols = crop_cols)

    if size(cropped) != size(img_plot)
        h = min(size(cropped, 1), size(img_plot, 1))
        w = min(size(cropped, 2), size(img_plot, 2))
        cropped = @view cropped[1:h, 1:w]
        img_plot = @view img_plot[1:h, 1:w]
    end

    score = Float64(assess_ssim(cropped, img_plot))
    passed = score >= threshold

    return (; passed = passed, score = score)
end

