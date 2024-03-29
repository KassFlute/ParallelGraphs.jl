module ParallelGraphs

using Graphs:
    vertices,
    edges,
    AbstractGraph,
    SimpleGraph,
    SimpleDiGraph,
    neighbors,
    add_edge!,
    nv,
    dorogovtsev_mendes

using Base.Threads: @threads, @spawn, @atomicreplace, Atomic, atomic_add!, atomic_cas!
using DataStructures: Queue, isempty, enqueue!, dequeue!, push!
using OhMyThreads: tforeach

include("utils.jl")
include("traversals/BFS/bfs_seq.jl")
include("traversals/BFS/bfs_par.jl")

export bfs_seq,
    bfs_par,
    bfs_seq!,
    bfs_par!,
    bfs_par_local!,
    bfs_par_local_unsafe!,
    bfs_par_local_probably_slower!

end
