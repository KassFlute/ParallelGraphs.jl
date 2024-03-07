using ParallelGraphs
using BenchmarkTools
using Graphs: SimpleGraph, add_edge!, dorogovtsev_mendes

SUITE = BenchmarkGroup()
SUITE["rand"] = @benchmarkable rand(10)

SUITE["BFS"] = BenchmarkGroup()

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

# Generate a random graph with 10,000 vertices and 50,000 edges
const NUM_VERTICES = 10_000
const NUM_EDGES = 50_000
#graph = generate_random_graph(NUM_VERTICES, NUM_EDGES)
graph = dorogovtsev_mendes(NUM_VERTICES)

# Benchmark BFS
const START_VERTEX = 1
SUITE["BFS"]["bfs_seq"] = @benchmarkable bfs_seq(graph, START_VERTEX)
SUITE["BFS"]["bfs_par"] = @benchmarkable bfs_par(graph, START_VERTEX)

# If a cache of tuned parameters already exists, use it, otherwise, tune and cache
# the benchmark parameters. Reusing cached parameters is faster and more reliable
# than re-tuning `suite` every time the file is included.
paramspath = joinpath(dirname(@__FILE__), "params.json")

if isfile(paramspath)
    loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals)
else
    tune!(SUITE)
    BenchmarkTools.save(paramspath, params(SUITE))
end
