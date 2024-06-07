"""
    Function to perform a greedy coloring of a graph using GraphBLAS. This method will color the graph using the Largest Degree First euristic.

    g: Graph to be colored.
    
    Returns a `Coloring` struct with the coloring of the graph.
"""
function BLAS_coloring_degree(graph::AbstractGraph)
    order = sortperm(degree(graph))

    weights = GBVector{Int}(range(1, nv(graph))[invperm(order)])
    return BLAS_coloring_maxIS(graph, weights)
end

"""
    Function to perform a greedy coloring of a graph using GraphBLAS. The vertices are colored in the order given by the `order` vector.
    This will color the vertices in parallel using maximum independant sets.

    g: Graph to be colored.
    order: Order in which the vertices will be colored.
    
    Returns a `Coloring` struct with the coloring of the graph.
"""
function BLAS_coloring_maxIS(graph::AbstractGraph, weights::GBVector{Int})
    if nv(graph) == 0
        return []
    end
    A_T = GBMatrix{Bool}((adjacency_matrix(graph, Bool; dir=:both)))
    C = GBVector{Int}(nv(graph); fill=0)
    max_W_in_neighbors = GBVector{Int}(nv(graph); fill=0)
    independant_set = GBVector{Bool}(nv(graph); fill=false)

    color = 1
    randomized_weights_ow = GBVector{Int}(nv(graph); fill=0)
    while true
        ignore = GBVector{Bool}(C .> 0; fill=false)
        empty!(independant_set)

        assign!(
            randomized_weights_ow,
            weights,
            range(1, nv(graph));
            mask=ignore,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=true,
                structural_mask=true,
                complement_mask=true,
            ),
        )
        # Compute the maximal independant set
        max_IS_inner!(
            A_T, randomized_weights_ow, independant_set, ignore, max_W_in_neighbors
        )
        #println("independant_set : ", independant_set)

        # Color the maximal independant set we just found with the current color
        not_done = reduce(∨, independant_set)
        if (isnothing(not_done) || !not_done)
            return Coloring(color - 1, (C))
        end
        apply!(
            *,
            C,
            color,
            independant_set;
            mask=independant_set,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=false,
                structural_mask=false,
                complement_mask=false,
            ),
        )
        #println("C : ", C)
        apply!(
            *,
            weights,
            0,
            weights;
            mask=independant_set,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=false,
                structural_mask=false,
                complement_mask=false,
            ),
        )
        color += 1
    end
end

"""
    Helper function to find a maximum independent set of a graph using GraphBLAS.

        A_T : Transposed adjacency matrix of the graph.
        randomized_weights : Randomized weights of the vertices. The weights will be overwritten.
        independant_set : Independant set to be filled.
        ignore : Vertices to ignore (already colored).
        max_W_in_neighbors : pre-constructed vector to store the maximum weight in the neighbors of each vertex.
    
    Returns a `Coloring` struct with the coloring of the graph.
"""
function max_IS_inner!(
    A_T::GBMatrix{Bool},
    randomized_weights::GBVector{Int},
    independant_set::GBVector{Bool},
    ignore::GBVector{Bool},
    max_W_in_neighbors::GBVector{Int},
)
    n = size(A_T, 1)
    frontier = GBVector{Bool}(n; fill=false)
    empty!(frontier)

    while true # While there are still vertices to add to the independant set
        # Find the vertex with the maximum weight in the neighborhood
        #println("0 : ", A_T)
        #println("0 : ", randomized_weights)
        mul!(
            max_W_in_neighbors,
            A_T,
            randomized_weights,
            (max, second);
            mask=ignore,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=true,
                structural_mask=false,
                complement_mask=true,
            ),
        )
        #println("1 : ", max_W_in_neighbors)
        # Add the vertices with the maximum weight to the independant sets
        eadd!(
            frontier,
            randomized_weights,
            max_W_in_neighbors,
            >;
            mask=ignore,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=true,
                structural_mask=false,
                complement_mask=true,
            ),
        )
        #println("2 : ", frontier)
        #println("size new : ", reduce(+, Int.(frontier)))
        inner_not_done = reduce(∨, frontier)
        if (isnothing(inner_not_done) || !inner_not_done) # If there are no more vertices to add,
            return nothing
        end
        # Add the vertices we just found to the independant set
        eadd!(
            independant_set,
            frontier,
            independant_set,
            ∨;
            mask=ignore,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=false,
                structural_mask=false,
                complement_mask=true,
            ),
        )
        #println("3 : ", independant_set)
        #println("size acc : ", reduce(+, Int.(independant_set)))
        # Remove neighbors of the vertices we just added to the independant set
        mul!(
            ignore,
            A_T,
            frontier,
            (∨, second);
            mask=ignore,
            accum=∨,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=false,
                structural_mask=false,
                complement_mask=true,
            ),
        )
        #println("4 : ", ignore)

        # Remove the vertices we just added to the independant set from candidates
        eadd!(
            ignore,
            independant_set,
            ignore,
            ∨;
            mask=ignore,
            desc=Descriptor(;
                nthreads=Threads.nthreads(), structural_mask=false, complement_mask=true
            ),
        )
        #println("5 : ", ignore)

        # Set weights of the vertices we just added to 0
        apply!(
            *,
            randomized_weights,
            0,
            randomized_weights;
            mask=ignore,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=false,
                structural_mask=false,
                complement_mask=false,
            ),
        )
        #println("6 : ", randomized_weights)
    end
    # Return the independant set
    return nothing
end
