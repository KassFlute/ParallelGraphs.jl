using ParallelGraphs
using BenchmarkTools
using Graphs:
    SimpleGraph,
    add_edge!,
    dorogovtsev_mendes,
    barabasi_albert,
    nv,
    binary_tree,
    double_binary_tree,
    star_graph,
    grid,
    path_digraph,
    AbstractGraph,
    adjacency_matrix
using SuiteSparseGraphBLAS:
    GBVector, GBMatrix, setstorageorder!, RowMajor, mul!, extract!, gbset, format, Monoid
import Graphs.Parallel as GP
using Base.Threads: Atomic
using DataStructures: Queue, enqueue!
using GraphIO.EdgeList
using GraphIO.EdgeList: IntEdgeListFormat, loadgraph
using ParserCombinator
using GraphIO.GML: GMLFormat
using DataFrames
using CSV
using Plots
using Statistics: mean

#######################
### Benchmark setup ###
#######################

SIZES_TO_GENERATE = [10, 100, 1000, 10000] # sizes in number of vertices

# BenchmarkTools parameters
BenchmarkTools.DEFAULT_PARAMETERS.samples = 10
BenchmarkTools.DEFAULT_PARAMETERS.seconds = Inf
SUITE = BenchmarkGroup()
SUITE["BFS"] = BenchmarkGroup()
gbset(:nthreads, Threads.nthreads())

# Check if Julia was started with more than one thread
if Threads.nthreads() == 1
    @warn "!!! Julia started with: $(Threads.nthreads()) threads, consider starting Julia with more threads to benchmark parallel code: `julia -t auto`."
else
    @warn "Julia started with: $(Threads.nthreads()) threads."
end

##################
### Add Graphs ###
##################

# Struct to store the graphs to benchmark
@enum GraphType begin
    GEN
    IMPORT
end

struct BenchGraphs
    graph::AbstractGraph
    size::Int
    name::String
    type::GraphType
    start_vertex::Int
end

# Generate bench graphs
SIZES = SIZES_TO_GENERATE # sizes in number of vertices
bench_graphs = Vector{BenchGraphs}()
print("Generate graphs...")
for i in eachindex(SIZES)
    v = SIZES[i]
    push!(bench_graphs, BenchGraphs(dorogovtsev_mendes(v), v, "dorogovtsev_mendes", GEN, 1))
    push!(
        bench_graphs, BenchGraphs(barabasi_albert(v, 2), v, "barabasi_albert - 2", GEN, 1)
    )
    push!(
        bench_graphs, BenchGraphs(barabasi_albert(v, 8), v, "barabasi_albert - 8", GEN, 1)
    )
    push!(
        bench_graphs,
        BenchGraphs(binary_tree(round(Int, log2(v)) + 1), v, "binary_tree", GEN, 1),
    )
    #push!(generated_graphs, BenchGraphs(double_binary_tree(round(Int, log2(v))), "double_binary_tree", GENERATED, 1))
    push!(bench_graphs, BenchGraphs(star_graph(v), v, "star_graph - center start", GEN, 1))
    push!(bench_graphs, BenchGraphs(star_graph(v), v, "star_graph - border start", GEN, 2))
    N = round(Int, sqrt(sqrt(v)))
    push!(bench_graphs, BenchGraphs(grid([N, N, N, N]), v, "grid 4 dims", GEN, 1))
    #push!(generated_graphs, BenchGraphs(path_digraph(v), "path_digraph", GENERATED, round(Int, v / 2)))
end
println("OK")

# Add imported graphs
print("Import graphs...")
# g = loadgraph(
#     "benchmark/data/large_twitch_edges.csv", "twitch user network", EdgeListFormat()
# )
# push!(bench_graphs, BenchGraphs(g, nv(g), "large_twitch_edges.csv", IMPORT, 1))
println("OK")

#push!(
#    imported_graphs,
#    loadgraph("benchmark/data/LiveJournal.txt", "live journal", EdgeListFormat()),
#)
#push!(names["Imported"], "live journal.txt")
#push!(i_first_vertex, 1)

#####################
### benchmark BFS ###
#####################
"""
    bench_BFS(g::AbstractGraph, v::Int, name::String, class::String)

Create a benchmark for BFS on a graph `g` with a starting vertex `v` and store it in the global `SUITE` variable.
"""
function bench_BFS(bg::BenchGraphs)
    # Our sequential
    SUITE["BFS"][string(bg.type) * ": " * bg.name][bg.size]["seq"] = @benchmarkable ParallelGraphs.bfs_seq!(
        $bg.graph, $bg.start_vertex, parents_prepared
    ) evals = 1 setup = (parents_prepared = fill(0, nv($bg.graph)))

    ## Our parallel similar to Graphs.jl
    #SUITE["BFS"][class][name]["par"] = @benchmarkable ParallelGraphs.bfs_par!(
    #    $g, $v, parents_atomic_prepared
    #) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)])

    # Our parallel with local queues
    SUITE["BFS"][string(bg.type) * ": " * bg.name][bg.size]["par_local"] = @benchmarkable ParallelGraphs.bfs_par_local!(
        $bg.graph,
        $bg.start_vertex,
        parents_atomic_prepared,
        queues_prepared,
        to_visit_prepared,
    ) evals = 1 setup = (
        parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($bg.graph)];
        queues_prepared = Vector{Queue{Int}}();
        foreach(1:(10 * Threads.nthreads())) do i
            push!(queues_prepared, Queue{Int}())
        end;
        to_visit_prepared = zeros(Int, nv($bg.graph))
    )

    ## Our GraphBLAS based implementation
    A_T = GBMatrix{Bool}((adjacency_matrix(bg.graph, Bool; dir=:in)))
    SUITE["BFS"][string(bg.type) * ": " * bg.name][bg.size]["BLAS"] = @benchmarkable ParallelGraphs.bfs_BLAS!(
        $A_T, $bg.start_vertex, p, f
    ) evals = 1 setup = (p = GBVector{Int}(nv($bg.graph); fill=zero(Int));
    f = GBVector{Bool}(nv($bg.graph); fill=false))

    ## Graphs.jl implementation
    SUITE["BFS"][string(bg.type) * ": " * bg.name][bg.size]["graphs.jl_par"] = @benchmarkable GP.bfs_tree!(
        next_prepared, $bg.graph, $bg.start_vertex, parents_prepared
    ) evals = 1 setup = (next_prepared = GP.ThreadQueue(Int, nv($bg.graph));
    parents_prepared = [Atomic{Int}(0) for i in 1:nv($bg.graph)])

    return SUITE
end

print("Add BFS benchmarks...")
for i in eachindex(bench_graphs)
    bench_BFS(bench_graphs[i])
end
println("OK (", length(bench_graphs), " added)")

##########################
### benchmark Coloring ###
##########################
"""
    bench_Coloring(g::AbstractGraph, v::Int, name::String, class::String)

Create a benchmark for Coloring on a graph `g` and store it in the global `SUITE` variable.
"""
function bench_Coloring(bg::BenchGraphs)
    # Our sequential
    SUITE["Coloring"][string(bg.type) * ": " * bg.name][bg.size]["seq"] = @benchmarkable ParallelGraphs.degree_order_and_color(
        $bg.graph
    ) evals = 1

    return SUITE
end

print("Add Coloring benchmarks...")
for i in eachindex(bench_graphs)
    bench_Coloring(bench_graphs[i])
end
println("OK (", length(bench_graphs), " added)")

# Run coloring and save color number
coloring_sample = 10
data_colors = DataFrame(; graph=[], size=[], algo_implem=[], color_numbers=[])

for graph in bench_graphs
    color_runs = []
    for _ in 1:coloring_sample
        num_colors = ParallelGraphs.degree_order_and_color(graph.graph).num_colors
        push!(color_runs, num_colors)
    end
    graph_name = string(graph.type) * ": " * graph.name
    push!(data_colors, (graph_name, graph.size, "seq_degree", color_runs))
end

##############################
### benchmarks run methods ###
##############################

function parse_results(results; path="benchmark/out/benchmarks.csv")
    data = DataFrame(; tested_algo=[], graph=[], size=[], algo_implem=[], minimum_time=[])
    for tested_algo in identity.(keys(results))
        for graph in identity.(keys(results[tested_algo]))
            for size in identity.(keys(results[tested_algo][graph]))
                for algo_implem in identity.(keys(results[tested_algo][graph][size]))
                    perf = results[tested_algo][graph][size][algo_implem]
                    #println(tested_algo, " ", graph, " ", size, " ", algo_implem, " ", perf)
                    push!(
                        data, (tested_algo, graph, size, algo_implem, minimum(perf.times))
                    )
                end
            end
        end
    end

    if !isnothing(path)
        dir = dirname(path)
        mkpath(dir)
        open(path, "w") do file
            CSV.write(file, data)
        end
    end
    return data
end

function parse_colors()
    return data_colors
end

function plot_BFS_results(data::DataFrame)
    markers = [
        :circle, :cross, :diamond, :dtriangle, :heptagon, :hexagon, :hline, :ltriangle
    ]
    data = filter(row -> row.tested_algo == "BFS", data)
    grouped_by_graph = groupby(data, :graph)
    for (i, graph_group) in enumerate(grouped_by_graph)
        p = plot(;
            title=string(graph_group.graph[1]),
            xlabel="Size",
            ylabel="Time (ns)",
            xscale=:log10,
        )
        algo_grouped = groupby(graph_group, :algo_implem)

        for (j, algo_group) in enumerate(algo_grouped)
            sorted_group = sort(algo_group, :size)
            plot!(
                p,
                sorted_group.size,
                sorted_group.minimum_time;
                label=string(sorted_group.algo_implem[1]),
                seriestype=:line,
                marker=markers[j],
            )
        end
        filename = "benchmark/out/plot_BFS_$(graph_group.graph[1])_$(i).png"
        savefig(p, filename)
        println("Saved plot to $filename")
    end
end

function plot_coloring_results(data::DataFrame, colors::DataFrame)
    markers = [
        :circle, :cross, :diamond, :dtriangle, :heptagon, :hexagon, :hline, :ltriangle
    ]
    data = filter(row -> row.tested_algo == "Coloring", data)
    grouped_by_graph = groupby(data, :graph)
    for (i, graph_group) in enumerate(grouped_by_graph)
        p = plot(;
            title=string(graph_group.graph[1]),
            xlabel="Size",
            ylabel="Time (ns)",
            xscale=:log10,
        )
        algo_grouped = groupby(graph_group, :algo_implem)

        for (j, algo_group) in enumerate(algo_grouped)
            sorted_group = sort(algo_group, :size)
            plot!(
                p,
                sorted_group.size,
                sorted_group.minimum_time;
                label=string(sorted_group.algo_implem[1]),
                seriestype=:line,
                marker=markers[j],
            )
        end
        filename = "benchmark/out/plot_Coloring_$(graph_group.graph[1])_$(i)_times.png"
        savefig(p, filename)
        println("Saved plot to $filename")
    end

    data = colors
    grouped_by_graph = groupby(data, :graph)
    for (i, graph_group) in enumerate(grouped_by_graph)
        p = plot(;
            title=string(graph_group.graph[1]),
            xlabel="Size",
            ylabel="Color number",
            xscale=:log10,
        )
        algo_grouped = groupby(graph_group, :algo_implem)

        for (j, algo_group) in enumerate(algo_grouped)
            sorted_group = sort(algo_group, :size)
            plot!(
                p,
                sorted_group.size,
                mean.(sorted_group.color_numbers);
                label=string(sorted_group.algo_implem[1]),
                seriestype=:line,
                marker=markers[j],
            )
        end
        filename = "benchmark/out/plot_Coloring_$(graph_group.graph[1])_$(i)_colors.png"
        savefig(p, filename)
        println("Saved plot to $filename")
    end
end
