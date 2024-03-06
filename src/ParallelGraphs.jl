module ParallelGraphs

using Graphs: vertices, edges, AbstractGraph, SimpleGraph, neighbors, add_edge!, nv
#using OhMyThreads
using Base.Threads: @threads, @atomicreplace, Atomic, atomic_add!

include("fichier_bidon.jl")
include("traversals/BFS/bfs_seq.jl")
include("traversals/BFS/bfs_par.jl")

export return_true,
    return_false, bfs_seq, bfs_par, bfs_seq_tree, bfs_par_tree, SimpleGraph, add_edge!

end
