# image_comparison.jl

"""
    compare_images_ssim(path1::AbstractString, path2::AbstractString; threshold::Real = Sys.isapple() ? 0.98 : 0.9) -> (; passed::Bool, score::Union{Real, Missing})

Loads two images using FileIO, strips any alpha channel, and computes their 
Structural Similarity Index (SSIM). Returns a NamedTuple with `passed::Bool` 
(true if `score >= threshold`) and `score` (Float64, or `missing` on failure).
"""
function compare_images_ssim(path1, path2; threshold = Sys.isapple() ? 0.98 : 0.9)
    if !isfile(path1)
        @warn "File not found: $path1"
        return (; passed = false, score = missing)
    end
    if !isfile(path2)
        @warn "File not found: $path2"
        return (; passed = false, score = missing)
    end

    # Load images and strip alpha channel by converting to RGB
    img1 = RGB.(FileIO.load(path1))
    img2 = RGB.(FileIO.load(path2))

    if size(img1) != size(img2)
        @info "Images have different dimensions: $(size(img1)) vs $(size(img2))"
        return (; passed = false, score = missing)
    end

    score = Float64(assess_ssim(img1, img2))
    passed = score >= threshold
    if !passed
        @info "SSIM score $(round(score, digits=4)) is below threshold $threshold"
    end

    return (; passed = passed, score = score)
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
    compare_directories_ssim(
        source_dir::AbstractString = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots")),
        target_dir::AbstractString = joinpath(source_dir, "tmp");
        threshold::Real = Sys.isapple() ? 0.98 : 0.9,
    ) -> (; passed::Bool, scores::Dict{String, Union{Real, Missing}})

Compares screenshots between `source_dir` and `target_dir` pairwise using SSIM.
By default, `source_dir` is the golden reference screenshot directory, and `target_dir`
is the `tmp/` subdirectory within it.

Selects PNG files without appended numbers if available, or the highest-numbered PNG
file otherwise. Sets the score to `missing` if the counterpart in `target_dir` is missing.
Returns a NamedTuple with `passed::Bool` (true if all scores are >= `threshold` and none
are missing) and `scores` mapping canonical filenames to their scores.
"""
function compare_directories_ssim(;
    source_dir = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "src", "Screenshots")),
    target_dir = joinpath(source_dir, "tmp"),
    threshold = Sys.isapple() ? 0.98 : 0.9,
)
    source_candidates = _find_screenshot_candidates(source_dir)
    target_candidates = _find_screenshot_candidates(target_dir)

    scores = Dict{String, Union{Float64, Missing}}()

    for (canonical_name, src_file) in source_candidates
        if !haskey(target_candidates, canonical_name)
            scores[canonical_name] = missing
        else
            tgt_file = target_candidates[canonical_name]
            src_path = joinpath(source_dir, src_file)
            tgt_path = joinpath(target_dir, tgt_file)
            res = compare_images_ssim(src_path, tgt_path; threshold = threshold)
            scores[canonical_name] = res.score
        end
    end

    passed = !isempty(scores) && !any(ismissing, values(scores)) && all(s >= threshold for s in values(scores))

    return (; passed = passed, scores = scores)
end

