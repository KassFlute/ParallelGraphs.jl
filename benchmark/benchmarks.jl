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
    AbstractGraph
using Base.Threads: Atomic
using DataStructures: Queue, enqueue!
using GraphIO.EdgeList
using GraphIO.EdgeList: IntEdgeListFormat, loadgraph
using ParserCombinator
using GraphIO.GML: GMLFormat

# Function to generate a random graph with a given number of vertices and edges
function generate_random_graph(num_vertices::Int, num_edges::Int)
    graph = SimpleGraph(num_vertices)
    for _ in 1:num_edges
        src = rand(1:num_vertices)
        dst = rand(1:num_vertices)
        add_edge!(graph, src, dst)
    end
    return graph
end

function bench(g::AbstractGraph, v::Int, name::String, class::String)
    ## Our implementations
    SUITE["BFS"][class][name]["seq"] = @benchmarkable ParallelGraphs.bfs_seq!(
        $g, $v, parents_prepared
    ) evals = 1 setup = (parents_prepared = fill(0, nv($g)))

    SUITE["BFS"][class][name]["par"] = @benchmarkable ParallelGraphs.bfs_par!(
        $g, $v, parents_atomic_prepared
    ) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)])

    SUITE["BFS"][class][name]["par_local"] = @benchmarkable ParallelGraphs.bfs_par_local!(
        $g, $v, parents_atomic_prepared, queues_prepared, to_visit_prepared
    ) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)];
    queues_prepared = Vector{Queue{Int}}();
    foreach(1:(10 * Threads.nthreads())) do i
        push!(queues_prepared, Queue{Int}())
    end;
    to_visit_prepared = zeros(Int, nv($g)))

    ## Graphs.jl implementation
    return SUITE["BFS"][class][name]["graphs.jl_par"] = @benchmarkable ParallelGraphs.bfs_tree!(
        next_prepared, $g, $v, parents_prepared
    ) evals = 1 setup = (
        next_prepared = ParallelGraphs.ThreadQueue(Int, nv($g));
        parents_prepared = [Atomic{Int}(0) for i in 1:nv($g)]
    )
end

BenchmarkTools.DEFAULT_PARAMETERS.samples = 10
BenchmarkTools.DEFAULT_PARAMETERS.seconds = Inf
SUITE = BenchmarkGroup()
SUITE["rand"] = @benchmarkable rand(10)
SUITE["BFS"] = BenchmarkGroup()

if Threads.nthreads() == 1
    @warn "!!! Julia started with: $(Threads.nthreads()) threads, consider starting Julia with more threads to benchmark parallel code: `julia -t auto`."
else
    @warn "Julia started with: $(Threads.nthreads()) threads."
end

# Benchmark parameters
SIZE = [10_000, 40_000, 100_000, 200_000]
CLASSES = ["10k", "40k", "100k", "200k", "roads", "routers", "routers_bigger"]
# SIZE = [10_000]
# CLASSES = ["10k", "roads", "routers", "routers_bigger"]
#DEGREE = [6]
#SIZE = [200_000]

#####################
### benchmark BFS ###
#####################
generated_graphs = [Vector{AbstractGraph{Int}}() for _ in 1:length(SIZE)]
g_first_vertex = [Vector{Int}() for _ in 1:length(SIZE)]

imported_graphs = Vector{AbstractGraph{Int}}()
i_first_vertex = Vector{Int}()

names = Dict{String,Vector{String}}("Generated" => [], "Imported" => [])

function addgraphtolist(i::Int, g::AbstractGraph{Int}, n::String, v::Int)
    push!(generated_graphs[i], g)
    push!(names["Generated"], n)
    return push!(g_first_vertex[i], v)
end

for i in eachindex(SIZE)
    v = SIZE[i]

    addgraphtolist(i, dorogovtsev_mendes(v), "dorogovtsev_mendes", 1)
    addgraphtolist(i, barabasi_albert(v, 4), "barabasi_albert - 4", 1)
    addgraphtolist(i, barabasi_albert(v, 20), "barabasi_albert - 20", 1)
    addgraphtolist(i, binary_tree(round(Int, log2(v)) + 1), "binary_tree", 1)
    addgraphtolist(i, double_binary_tree(round(Int, log2(v))), "double_binary_tree", 1)
    addgraphtolist(i, star_graph(v), "star_graph - center start", 1)
    addgraphtolist(i, star_graph(v), "star_graph - border start", 2)

    N = round(Int, sqrt(sqrt(v)))
    addgraphtolist(i, grid([N, N, N, N]), "grid 4 dims", 1)
    addgraphtolist(i, path_digraph(v), "path_digraph", round(Int, v / 2))
end

# Load graphs from files
push!(imported_graphs, loadgraph("benchmark/data/roads.csv", "roads", EdgeListFormat()))
push!(names["Imported"], "roads.csv")
push!(i_first_vertex, 1)

push!(imported_graphs, loadgraph("benchmark/data/routers.csv", "routers", EdgeListFormat()))
push!(names["Imported"], "routers.csv")
push!(i_first_vertex, 1)

push!(imported_graphs, loadgraph("benchmark/data/internet_routers_bigger.gml", "graph", GMLFormat()))
push!(names["Imported"], "internet_routers_bigger.gml")
push!(i_first_vertex, 1)

println("Benchmarking BFS on imported graphs : ", length(imported_graphs))
for i in eachindex(imported_graphs)
    graph = imported_graphs[i]
    name = names["Imported"][i]
    vertex = i_first_vertex[i]
    class = CLASSES[length(SIZE) + i]
    bench(graph, vertex, name, class)
end

println(
    "Benchmarking BFS on generated graphs and sizes : ",
    length(generated_graphs[1]),
    " x ",
    length(generated_graphs),
)
for s in eachindex(SIZE)
    for g in eachindex(generated_graphs[s])
        graph = generated_graphs[s][g]
        name = names["Generated"][g]
        vertex = g_first_vertex[s][g]
        class = CLASSES[s]
        bench(graph, vertex, name, class)
    end
end

# for i in eachindex(graphs)
#     g = graphs[i]
#     parents = fill(0, nv(g))
#     parents_atomic = [Atomic{Int}(0) for _ in 1:nv(g)]
#     SUITE["BFS"][names[i]][bfs_seq] = @benchmarkable ParallelGraphs.bfs_seq!(
#         $g, $START_VERTEX, parents_prepared
#     ) evals = 1 setup = (parents_prepared = fill(0, nv($g)))
#     SUITE["BFS"][names[i]][bfs_par] = @benchmarkable ParallelGraphs.bfs_par!(
#         $g, $START_VERTEX, parents_atomic_prepared
#     ) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)])
# end

# If a cache of tuned parameters already exists, use it, otherwise, tune and cache
# the benchmark parameters. Reusing cached parameters is faster and more reliable
# than re-tuning `suite` every time the file is included.

# paramspath = joinpath(dirname(@__FILE__), "params.json")

# if isfile(paramspath)
#     loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals)
# else
#     tune!(SUITE)
#     BenchmarkTools.save(paramspath, params(SUITE))
# end
