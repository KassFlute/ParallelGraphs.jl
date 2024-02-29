using ParallelGraphs
using Documenter

DocMeta.setdocmeta!(ParallelGraphs, :DocTestSetup, :(using ParallelGraphs); recursive=true)

makedocs(;
    modules=[ParallelGraphs],
    authors="KassFlute <cassien.roth@epfl.ch> and contributors",
    sitename="ParallelGraphs.jl",
    format=Documenter.HTML(;
        canonical="https://KassFlute.github.io/ParallelGraphs.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/KassFlute/ParallelGraphs.jl",
    devbranch="main",
)
