using ParallelGraphs
using BenchmarkTools
using Graphs: SimpleGraph, add_edge!, dorogovtsev_mendes, barabasi_albert, nv
using Base.Threads: Atomic
using DataStructures: Queue

SUITE = BenchmarkGroup()
SUITE["rand"] = @benchmarkable rand(10)
SUITE["BFS"] = BenchmarkGroup()

if Threads.nthreads() == 1
    @warn "!!! Julia started with: $(Threads.nthreads()) threads, consider starting Julia with more threads to benchmark parallel code: `julia -t auto`."
else
    @warn "Julia started with: $(Threads.nthreads()) threads."
end

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

# Benchmark parameters
const NUM_VERTICES = [100, 500, 1000]
const NUM_EDGES = [500, 2500, 5000]

# Generate random graphs
# graphs = [
#     generate_random_graph(NUM_VERTICES, NUM_EDGES),
#     dorogovtsev_mendes(NUM_VERTICES),
#     barabasi_albert(NUM_VERTICES, 500),
# ]
# names = ["random", "dorogovtsev_mendes", "barabasi_albert"]

#####################
### benchmark BFS ###
const START_VERTEX = 1

for num_vertices in NUM_VERTICES
    for num_edges in NUM_EDGES
        # dorogovtsev_mendes
        g = dorogovtsev_mendes(num_vertices)
        SUITE["BFS"]["Dorogovtsev Mendes"]["$num_vertices,$num_edges"]["seq"] = @benchmarkable ParallelGraphs.bfs_seq!(
            $g, $START_VERTEX, parents_prepared
        ) evals = 1 setup = (parents_prepared = fill(0, nv($g)))
        SUITE["BFS"]["Dorogovtsev Mendes"]["$num_vertices,$num_edges"]["par"] = @benchmarkable ParallelGraphs.bfs_par!(
            $g, $START_VERTEX, parents_atomic_prepared
        ) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)])
        SUITE["BFS"]["Dorogovtsev Mendes"]["$num_vertices,$num_edges"]["par_local_unsafe"] = @benchmarkable ParallelGraphs.bfs_par_local_unsafe!(
            $g, $START_VERTEX, parents_atomic_prepared, queues_prepared
        ) evals = 1 setup = (parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)];
        queues_prepared = [Queue{Int}() for _ in 1:Threads.nthreads()])

        # queues = Channel{Queue{Int}}(Threads.nthreads())
        # for i in 1:Threads.nthreads()
        #     put!(queues, Queue{Int}())
        # end

        SUITE["BFS"]["Dorogovtsev Mendes"]["$num_vertices,$num_edges"]["par_local"] = @benchmarkable ParallelGraphs.bfs_par_local!(
            $g, $START_VERTEX, parents_atomic_prepared, queues_prepared
        ) evals = 1 setup = (
            parents_atomic_prepared = [Atomic{Int}(0) for _ in 1:nv($g)];
            queues_prepared = Channel{Queue{Int}}(Threads.nthreads()) do ch
                for _ in 1:Threads.nthreads()
                    put!(ch, Queue{Int}())
                end
                ch
            end
        )
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
