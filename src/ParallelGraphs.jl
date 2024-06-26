module ParallelGraphs

using Graphs:
    vertices,
    edges,
    AbstractGraph,
    SimpleGraph,
    SimpleDiGraph,
    neighbors,
    all_neighbors,
    add_edge!,
    has_vertex,
    nv,
    degree,
    dorogovtsev_mendes,
    adjacency_matrix

using Base.Threads: @threads, @spawn, @atomicreplace, Atomic, atomic_add!, atomic_cas!
using DataStructures: Queue, isempty, enqueue!, dequeue!, push!
using OhMyThreads: tforeach

using SuiteSparseGraphBLAS:
    GBVector,
    GBMatrix,
    GBArrayOrTranspose,
    GBVecOrMat,
    setstorageorder!,
    RowMajor,
    ColMajor,
    permutedims,
    transpose!,
    transpose,
    first,
    second,
    min,
    pair,
    *,
    +,
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
    extract!,
    Monoid,
    Descriptor,
    gbset

using SuiteSparseGraphBLAS.BinaryOps: ∨

include("utils.jl")
include("traversals/BFS/bfs_seq.jl")
include("traversals/BFS/bfs_par.jl")
include("traversals/BFS/bfs_BLAS.jl")
include("traversals/coloring/greedy_coloring_seq.jl")
include("traversals/coloring/BLAS_coloring.jl")

export bfs_seq,
    bfs_par,
    bfs_par_local,
    bfs_BLAS,
    bfs_seq!,
    bfs_par!,
    bfs_par_local!,
    bfs_BLAS!,
    shuffle_and_color,
    shuffle_and_color_n_times,
    degree_order_and_color,
    degree_order_and_color_n_times,
    max_is_coloring,
    BLAS_coloring_degree,
    BLAS_coloring_maxIS,
    Coloring

end
