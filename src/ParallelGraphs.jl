module ParallelGraphs

using Graphs:
    vertices,
    edges,
    AbstractGraph,
    SimpleGraph,
    neighbors,
    add_edge!,
    nv,
    dorogovtsev_mendes

#using OhMyThreads
using Base.Threads: @threads, @atomicreplace, Atomic, atomic_add!, atomic_cas!
using DataStructures: Queue, push!, popfirst!, isempty

include("fichier_bidon.jl")
include("utils.jl")
include("traversals/BFS/bfs_seq.jl")
include("traversals/BFS/bfs_par.jl")

export return_true, return_false, bfs_seq, bfs_par

end
