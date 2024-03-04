module ParallelGraphs

using Graphs: vertices, edges, AbstractGraph, SimpleGraph, neighbors, add_edge!

include("fichier_bidon.jl")
include("traversals/sequential/bfs.jl")

export return_true, return_false, bfs, SimpleGraph, add_edge!

end
