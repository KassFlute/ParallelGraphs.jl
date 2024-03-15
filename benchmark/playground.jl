using Base.Threads
using Graphs
using ParallelGraphs

g = dorogovtsev_mendes(10_000)

using BenchmarkTools


@btime bfs_seq($g, 1);
@btime bfs_par($g, 1);

bfs_par(g, 25);
