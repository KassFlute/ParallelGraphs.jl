var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = ParallelGraphs","category":"page"},{"location":"#ParallelGraphs","page":"Home","title":"ParallelGraphs","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for ParallelGraphs.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [ParallelGraphs]","category":"page"},{"location":"#ParallelGraphs.Coloring","page":"Home","title":"ParallelGraphs.Coloring","text":"Struct to store the coloring of a graph.\n\nnum_colors: Number of colors used in the coloring.\ncolors: Vector of length `n` where `n` is the number of vertices in the graph.\n        The `i`-th element of the vector is the color assigned to the `i`-th vertex.\n\n\n\n\n\n","category":"type"},{"location":"#ParallelGraphs.ThreadQueue","page":"Home","title":"ParallelGraphs.ThreadQueue","text":"ThreadQueue\n\nA thread safe queue implementation for using as the queue for BFS.\n\n\n\n\n\n","category":"type"},{"location":"#ParallelGraphs.BLAS_coloring_degree-Tuple{Graphs.AbstractGraph}","page":"Home","title":"ParallelGraphs.BLAS_coloring_degree","text":"Function to perform a greedy coloring of a graph using GraphBLAS. This method will color the graph using the Largest Degree First euristic.\n\ng: Graph to be colored.\n\nReturns a `Coloring` struct with the coloring of the graph.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.BLAS_coloring_maxIS-Tuple{Graphs.AbstractGraph, Vector{Int64}}","page":"Home","title":"ParallelGraphs.BLAS_coloring_maxIS","text":"Function to perform a greedy coloring of a graph using GraphBLAS. The vertices are colored in the order given by the `order` vector.\nThis will color the vertices in parallel using maximum independant sets.\n\ng: Graph to be colored.\norder: Order in which the vertices will be colored.\n\nReturns a `Coloring` struct with the coloring of the graph.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.bfs_BLAS!-Union{Tuple{T}, Tuple{SuiteSparseGraphBLAS.GBMatrix{Bool}, T, SuiteSparseGraphBLAS.GBVector{T}}} where T<:Integer","page":"Home","title":"ParallelGraphs.bfs_BLAS!","text":"bfs_BLAS!(A_T::GBMatrix{Bool}, source::T, p::GBVector{T}, f::GBVector{Bool}) where {T<:Integer}\n\nPerform a BFS traversal on a graph represented by its transpose adjacency matrix A_T starting from vertex source using GraphBLAS operations.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.bfs_BLAS-Union{Tuple{T}, Tuple{Graphs.AbstractGraph, T}} where T<:Integer","page":"Home","title":"ParallelGraphs.bfs_BLAS","text":"bfs_BLAS(graph::AbstractGraph, source::T) where {T<:Integer}\n\nPerform a BFS traversal on a graph graph starting from vertex source using GraphBLAS operations.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.bfs_par!-Union{Tuple{T}, Tuple{Graphs.AbstractGraph, T, Array{Base.Threads.Atomic{T}}}} where T<:Integer","page":"Home","title":"ParallelGraphs.bfs_par!","text":"bfs_par_tree!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}})\n\nRun a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.\n\nSee also: bfs_par\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.bfs_par-Union{Tuple{T}, Tuple{Graphs.AbstractGraph, T}} where T<:Integer","page":"Home","title":"ParallelGraphs.bfs_par","text":"bfs_par(graph::AbstractGraph, source::T)\n\nRun a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.\n\nSee also: bfs_par!\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.bfs_seq!-Union{Tuple{T}, Tuple{Graphs.AbstractGraph, T, Array{T}}} where T<:Integer","page":"Home","title":"ParallelGraphs.bfs_seq!","text":"bfs_seq_tree!(graph::AbstractGraph, source::T, parents::Array{T})\n\nRun a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array. For correct results, the 'parents' Array should be initialized with zeros.\n\nSee also: bfs_seq\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.bfs_seq-Union{Tuple{T}, Tuple{Graphs.AbstractGraph, T}} where T<:Integer","page":"Home","title":"ParallelGraphs.bfs_seq","text":"bfs_seq(graph::AbstractGraph, source::T)\n\nRun a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.\n\nSee also: bfs_seq!\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.degree_order_and_color-Tuple{Graphs.AbstractGraph}","page":"Home","title":"ParallelGraphs.degree_order_and_color","text":"Function to order the vertices of a graph by degree and perform a greedy coloring.\n\ng: Graph to be colored.\n\nReturns a `Coloring` struct with the coloring of the graph.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.degree_order_and_color_n_times-Tuple{Graphs.AbstractGraph, Int64}","page":"Home","title":"ParallelGraphs.degree_order_and_color_n_times","text":"Function to order the vertices of a graph by degree and perform a greedy coloring `n` times.\n\ng: Graph to be colored.\nn: Number of times the graph will be colored.\n\nReturns a `Coloring` struct with the best coloring found.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.greedy_coloring-Tuple{Graphs.AbstractGraph, Vector{Int64}}","page":"Home","title":"ParallelGraphs.greedy_coloring","text":"Function to perform a greedy coloring of a graph.\n\ng: Graph to be colored.\norder: Order in which the vertices will be colored. The `i`-th element of the vector\n       is the index of the vertex that will be colored in the `i`-th iteration.\n\nReturns a `Coloring` struct with the coloring of the graph.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.max_IS_inner!-Tuple{SuiteSparseGraphBLAS.GBMatrix{Bool}, SuiteSparseGraphBLAS.GBVector{Int64}, SuiteSparseGraphBLAS.GBVector{Bool}, SuiteSparseGraphBLAS.GBVector{Bool}, SuiteSparseGraphBLAS.GBVector{Int64}}","page":"Home","title":"ParallelGraphs.max_IS_inner!","text":"Helper function to find a maximum independent set of a graph using GraphBLAS.\n\n    A_T : Transposed adjacency matrix of the graph.\n    randomized_weights : Randomized weights of the vertices. The weights will be overwritten.\n    independant_set : Independant set to be filled.\n    ignore : Vertices to ignore (already colored).\n    max_W_in_neighbors : pre-constructed vector to store the maximum weight in the neighbors of each vertex.\n\nReturns a `Coloring` struct with the coloring of the graph.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.shuffle_and_color-Tuple{Graphs.AbstractGraph}","page":"Home","title":"ParallelGraphs.shuffle_and_color","text":"Function to shuffle the vertices of a graph and perform a greedy coloring.\n\ng: Graph to be colored.\n\nReturns a `Coloring` struct with the coloring of the graph.\n\n\n\n\n\n","category":"method"},{"location":"#ParallelGraphs.shuffle_and_color_n_times-Tuple{Graphs.AbstractGraph, Int64}","page":"Home","title":"ParallelGraphs.shuffle_and_color_n_times","text":"Function to shuffle the vertices of a graph and perform a greedy coloring `n` times.\n\ng: Graph to be colored.\nn: Number of times the graph will be colored.\n\nReturns a `Coloring` struct with the best coloring found.\n\n\n\n\n\n","category":"method"}]
}