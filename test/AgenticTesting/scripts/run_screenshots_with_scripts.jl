using Pkg

initial_env = Base.active_project()
target_env = normpath(joinpath(@__DIR__, ".."))
target_project = normpath(joinpath(target_env, "Project.toml"))
already_target = initial_env !== nothing && normpath(initial_env) == target_project

"""
    run_screenshots_with_scripts(; verify_against::Symbol = :golden) -> (; passed::Bool, results::Vector{Pair{String, NamedTuple}})

Run screenshot generators with script generation, execute the generated scripts
to produce standalone figure PNGs (808×610), and verify them using SSIM against:
- `:golden` (default): Golden reference screenshots in `docs/src/Screenshots/<name>.png`
- `:produced`: Just-captured screenshots in `docs/src/Screenshots/tmp/<name>_NN.png`
Note: The image size within the Electron GUI currently deviates slightly from the otherwise default (800×600)
"""
function run_screenshots_with_scripts(; verify_against::Symbol = :golden, fig_size = (808, 610))
    @assert verify_against in (:golden, :produced, :both) "verify_against must be :golden, :produced, or :both, got :$verify_against"

    genscripts_dir = normpath(joinpath(pkgdir(CasualPlots), "tmp", "genscripts"))
    genplots_dir = normpath(joinpath(pkgdir(CasualPlots), "tmp", "genplots"))
    golden_dir = normpath(joinpath(pkgdir(CasualPlots), "docs", "src", "Screenshots"))
    mkpath(genscripts_dir)
    mkpath(genplots_dir)

    generators = (
        generate_dataframe_source_screenshot,
        generate_xy_source_screenshot,
        generate_format_tab_barplot_dodged_screenshot,
        generate_format_tab_barplot_stacked_screenshot,
        generate_format_tab_limits_screenshot,
        generate_format_tab_lines_screenshot,
        generate_save_tab_script_screenshot,
        generate_line_symbol_plot_screenshot,
        generate_Scatter_by_geometry_screenshot,
        generate_non_linear_discharge_screenshot,
    )

    produced_screenshots = Dict{String, String}()

    with_screenshot_env(; nofancy = true) do
        println("=== Running screenshot generators with script generation ===")
        for gen in generators
            png_name = gen()
            stem = splitext(png_name)[1]
            script_path = joinpath(genscripts_dir, string(stem, ".jl"))
            shot_path = run_screenshot_generator(
                gen;
                makescript = true,
                scriptfile = script_path,
                fig_size = fig_size,
            )
            produced_screenshots[stem] = shot_path
        end
        println("=== All scripts and screenshots generated successfully ===")
    end

    # Edit scripts to uncomment execution and add saving
    println("=== Editing generated scripts for plot generation ===")
    for f in readdir(genscripts_dir)
        endswith(f, ".jl") || continue
        stem = splitext(f)[1]
        path = joinpath(genscripts_dir, f)
        content = read(path, String)

        # 1. Uncomment the first cp_load_data call
        content = replace(content, r"^# (plot_data = cp_load_data\(.*?)$"m => s"\1"; count = 1)

        # 2. Uncomment the first cp_create_plot call
        content = replace(content, r"^# (fg = cp_create_plot\(plot_data\))$"m => s"\1"; count = 1)

        # 3. Append the save command if not already present
        target_png = joinpath(genplots_dir, stem * "_fig.png")
        if !occursin("save(\"$target_png\"", content)
            save_cmd = string("\n\nmkpath(\"", genplots_dir, "\")\nsave(\"", target_png, "\", fg)\n")
            content *= save_cmd
        end

        write(path, content)
    end

    # Execute scripts to generate the plots
    println("=== Executing scripts to render standalone figures ===")
    Pkg.activate(pkgdir(CasualPlots))
    Core.eval(Main, :(CasualPlots.@populate()))
    for f in sort(readdir(genscripts_dir))
        endswith(f, ".jl") || continue
        include(joinpath(genscripts_dir, f))
    end
    Pkg.activate(target_env)

    # Verification phase
    println("=== Verifying generated plots against $(verify_against) screenshots ===")
    results = Pair{String, Any}[]
    all_passed = true

    for gen in generators
        png_name = gen()
        stem = splitext(png_name)[1]
        plot_path = joinpath(genplots_dir, stem * "_fig.png")
        golden_shot = joinpath(golden_dir, png_name)
        produced_shot = get(produced_screenshots, stem, "")

        if verify_against == :both
            res_golden = compare_screenshot_plot_ssim(golden_shot, plot_path)
            res_prod = isfile(produced_shot) ? compare_screenshot_plot_ssim(produced_shot, plot_path) : (; passed = false, score = missing)
            push!(results, stem => (; golden = res_golden, produced = res_prod))
            if !res_golden.passed || !res_prod.passed
                all_passed = false
            end
            println("✓ $stem: SSIM(golden) = $(round(res_golden.score, digits=4)), SSIM(produced) = $(round(res_prod.score, digits=4))")
        else
            ref_shot = verify_against == :golden ? golden_shot : produced_shot
            res = compare_screenshot_plot_ssim(ref_shot, plot_path)
            push!(results, stem => res)
            if !res.passed
                all_passed = false
                @warn "Verification FAILED for $stem: score = $(res.score)"
            else
                println("✓ $stem: SSIM = $(round(res.score, digits=4)) (passed)")
            end
        end
    end

    return (; passed = all_passed, results = results)
end

try
    already_target || Pkg.activate(target_env)
    using AgenticTesting, CasualPlots
    using CSV, XLSX
    Core.eval(Main, :(CasualPlots.@populate()))

    target_mode = haskey(ENV, "VERIFY_AGAINST") ? Symbol(ENV["VERIFY_AGAINST"]) : :golden
    run_screenshots_with_scripts(; verify_against = target_mode)
finally
    already_target || (initial_env !== nothing ? Pkg.activate(initial_env) : Pkg.activate())
end
