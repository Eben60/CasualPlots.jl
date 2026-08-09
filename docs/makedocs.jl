using Documenter, CasualPlots

DocMeta.setdocmeta!(CasualPlots, :DocTestSetup, :(using CasualPlots); recursive=true)

makedocs(;
    modules=[CasualPlots],
    authors="Ben Elkin (github: Eben60)",
    sitename="CasualPlots.jl",
    format=Documenter.HTML(;
        edit_link="main",
        assets=String[],
        prettyurls = (get(ENV, "CI", nothing) == "true")
    ),
    pages=[
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Script Generation" => "script_generation.md",
        "API Reference" => "api.md",
        "Changelog" => "changelog.md",
    ],
    checkdocs = :exports,
    warnonly = [:missing_docs],
)
