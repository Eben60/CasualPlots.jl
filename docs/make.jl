using CasualPlots
using Documenter

DocMeta.setdocmeta!(CasualPlots, :DocTestSetup, :(using CasualPlots); recursive=true)

makedocs(;
    modules=[CasualPlots],
    authors="Eben60 <nomail@nowhere.me>",
    sitename="CasualPlots.jl",
    format=Documenter.HTML(;
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
