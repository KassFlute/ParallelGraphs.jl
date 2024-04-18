module ParallelGraphs

using Graphs:
    vertices,
    edges,
    AbstractGraph,
    SimpleGraph,
    SimpleDiGraph,
    neighbors,
    add_edge!,
    has_vertex,
    nv,
    dorogovtsev_mendes,
    adjacency_matrix

using Base.Threads: @threads, @spawn, @atomicreplace, Atomic, atomic_add!, atomic_cas!
using DataStructures: Queue, isempty, enqueue!, dequeue!, push!
using OhMyThreads: tforeach

using SuiteSparseGraphBLAS:
    GBVector,
    GBMatrix,
    GBArrayOrTranspose,
    first,
    second,
    min,
    *,
    any,
    secondi,
    mask!,
    mul!,
    eadd!,
    apply,
    apply!,
    rowindex,
    colindex,
    assign!,
    extract!

include("utils.jl")
include("traversals/BFS/bfs_seq.jl")
include("traversals/BFS/bfs_par.jl")

export bfs_seq,
    bfs_par,
    bfs_BLAS,
    bfs_seq!,
    bfs_par!,
    bfs_par_local!,
    bfs_BLAS!
    bfs_par_local_unsafe!,
    bfs_par_local_probably_slower!,
    ThreadQueue,
    t_push!

end
