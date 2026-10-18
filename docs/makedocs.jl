using Documenter, CasualPlots

DocMeta.setdocmeta!(CasualPlots, :DocTestSetup, :(using CasualPlots); recursive=true)

function is_exported(t)
    t === nothing && return true
    (t === CasualPlots || t === CasualPlots.Ele) && return true
    try
        return Base.isexported(CasualPlots, nameof(t))
    catch
        return false
    end
end

function is_public(t)
    t === nothing && return true
    (t === CasualPlots || t === CasualPlots.Ele) && return true
    try
        s = nameof(t)
        return Base.ispublic(CasualPlots, s) || (isdefined(CasualPlots.Ele, s) && Base.ispublic(CasualPlots.Ele, s))
    catch
        return false
    end
end

makedocs(;
    modules=[CasualPlots],
    meta=Dict(:CollapsedDocStrings => true),
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
        "Intro to AlgebraOfGraphics" => "aog_intro.md",
        "API Reference" => "api.md",
        "Changelog" => "changelog.md",
    ],
    checkdocs = :exports,
    warnonly = [:missing_docs],
)
