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
    path_digraph
using Base.Threads: Atomic
using DataStructures: Queue, enqueue!
#using GraphIO: EdgeListFormat, loadgraph

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
#DEGREE = [2, 6, 20, 100]
#SIZE = [10_000, 40_000, 100_000, 200_000]
DEGREE = [6]
SIZE = [200_000]

#####################
### benchmark BFS ###
#####################

graphs = []
names = []
first_vertex = []

for v in SIZE
    push!(graphs, dorogovtsev_mendes(v))
    push!(names, "dorogovtsev_mendes($v)")
    push!(first_vertex, 1)

    push!(graphs, barabasi_albert(v, 4))
    push!(names, "barabasi_albert($v, 4)")
    push!(first_vertex, 1)

    push!(graphs, binary_tree(round(Int, log2(v)) + 1))
    push!(names, "binary_tree($(round(Int, log2(v)) + 1))")
    push!(first_vertex, 1)

    push!(graphs, double_binary_tree(round(Int, log2(v))))
    push!(names, "double_binary_tree($(round(Int, log2(v))))")
    push!(first_vertex, 1)

    push!(graphs, star_graph(v))
    push!(names, "star_graph($v) - center start")
    push!(first_vertex, 1)

    push!(graphs, star_graph(v))
    push!(names, "star_graph($v) - border start")
    push!(first_vertex, 2)

    N = round(Int, sqrt(sqrt(v)))
    push!(graphs, grid([N, N, N, N]))
    push!(names, "grid($N^4)")
    push!(first_vertex, 1)

    push!(graphs, path_digraph(v))
    push!(names, "path_digraph($v)")
    push!(first_vertex, round(Int, v / 2))
end

for d in DEGREE
    push!(graphs, barabasi_albert(100_000, d))
    push!(names, "barabasi_albert(100_000, $d)")
    push!(first_vertex, 1)
end

# Load graphs from files
#push!(graphs, loadgraph("data/roads.csv", "roads",  EdgeListFormat()))
#push!(names, "roads.csv")
#push!(first_vertex, 135627)
#
#push!(graphs, loadgraph("data/routers.csv", "routers", EdgeListFormat()))
#push!(names, "routers.csv")
#push!(first_vertex, 8483)


println(length(graphs))
for i in eachindex(graphs)
    graph = graphs[i]
    name = names[i]
    vertex = first_vertex[i]

    SUITE["BFS"][name]["seq"] = @benchmarkable ParallelGraphs.bfs_seq!(
        $graph, $vertex, parents_prepared
    ) evals = 1 setup = (parents_prepared = fill(0, nv($graph)))

    SUITE["BFS"][name]["par"] = @benchmarkable ParallelGraphs.bfs_par!(
        $graph, $vertex, parents_atomic_prepared
    ) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)])

    #SUITE["BFS"][name]["par_local_unsafe"] = @benchmarkable ParallelGraphs.bfs_par_local_unsafe!(
    #    $graph, $vertex, parents_atomic_prepared, queues_prepared
    #) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)];
    #queues_prepared = [Queue{Int}() for _ in 1:Threads.nthreads()])

    SUITE["BFS"][name]["par_local"] = @benchmarkable ParallelGraphs.bfs_par_local!(
        $graph, $vertex, parents_atomic_prepared, queues_prepared, to_visit_prepared
    ) evals = 1 setup = (
        parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)];
        queues_prepared = Vector{Queue{Int}}();
        foreach(1:(10 * Threads.nthreads())) do i
            push!(queues_prepared, Queue{Int}())
        end;
        to_visit_prepared = zeros(Int, nv($graph))
    )
    #SUITE["BFS"][name]["par_local_probably_slower"] = @benchmarkable ParallelGraphs.bfs_par_local_probably_slower!(
    #    $graph, $vertex, parents_atomic_prepared, chnl_prepared
    #) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)];
    #chnl_prepared = Channel{Int}(nv($graph)))
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
