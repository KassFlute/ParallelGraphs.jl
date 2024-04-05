using ParallelGraphs
using BenchmarkTools
using Graphs: SimpleGraph, add_edge!, dorogovtsev_mendes, barabasi_albert, nv
using Base.Threads: Atomic
using DataStructures: Queue, enqueue!

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

# Benchmark parameters
DEGREE = [2, 10, 120]
SIZE = [130_000]

#####################
### benchmark BFS ###
START_VERTEX = 1

for deg in DEGREE
    for num_vertices in SIZE
        # Generate random graphs
        graphs = [
            #generate_random_graph(num_vertices, num_edges),
            #dorogovtsev_mendes(num_vertices),
            barabasi_albert(num_vertices, deg),
        ]
        names = ["random", "Dorogovtsev Mendes", "Barabasi Albert"]

        for i in eachindex(graphs)
            graph = graphs[i]
            name = names[i]
            SUITE["BFS"][name]["$num_vertices,$deg"]["seq"] = @benchmarkable ParallelGraphs.bfs_seq!(
                $graph, $START_VERTEX, parents_prepared
            ) evals = 1 setup = (parents_prepared = fill(0, nv($graph)))
            SUITE["BFS"][name]["$num_vertices,$deg"]["par"] = @benchmarkable ParallelGraphs.bfs_par!(
                $graph, $START_VERTEX, parents_atomic_prepared
            ) evals = 1 setup = (
                parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)]
            )
            SUITE["BFS"][name]["$num_vertices,$deg"]["par_local_unsafe"] = @benchmarkable ParallelGraphs.bfs_par_local_unsafe!(
                $graph, $START_VERTEX, parents_atomic_prepared, queues_prepared
            ) evals = 1 setup = (
                parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)];
                queues_prepared = [Queue{Int}() for _ in 1:Threads.nthreads()]
            )

            # queues = Channel{Queue{Int}}(Threads.nthreads())
            # for i in 1:Threads.nthreads()
            #     put!(queues, Queue{Int}())
            # end
            SUITE["BFS"][name]["$num_vertices,$deg"]["par_local"] = @benchmarkable ParallelGraphs.bfs_par_local!(
                $graph,
                $START_VERTEX,
                parents_atomic_prepared,
                queues_prepared,
                to_visit_prepared,
            ) evals = 1 setup = (
                parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)];
                queues_prepared = Vector{Queue{Int}}();
                foreach(1:Threads.nthreads()) do i
                    push!(queues_prepared, Queue{Int}())
                end;
                to_visit_prepared = zeros(Int, nv($graph))
            )

            # chnl = Channel{Int64}(nv(graph))
            SUITE["BFS"][name]["$num_vertices,$deg"]["par_local_probably_slower"] = @benchmarkable ParallelGraphs.bfs_par_local_probably_slower!(
                $graph, $START_VERTEX, parents_atomic_prepared, chnl_prepared
            ) evals = 1 setup = (
                parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($graph)];
                chnl_prepared = Channel{Int}(nv($graph))
            )
        end
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
