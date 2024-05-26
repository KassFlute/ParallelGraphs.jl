# Descriptors
const normal_mask_desc = Descriptor(;
    nthreads=Threads.nthreads(), replace_output=true, structural_mask=true
)
const complement_mask_desc = Descriptor(;
    nthreads=Threads.nthreads(),
    replace_output=true,
    structural_mask=true,
    complement_mask=true,
)
const complement_acc_desc = Descriptor(;
    nthreads=Threads.nthreads(), structural_mask=true, complement_mask=true
)
const complement_mask_noStruct_desc = Descriptor(;
    nthreads=Threads.nthreads(),
    replace_output=true,
    structural_mask=false,
    complement_mask=true,
)
const value_mask_desc = Descriptor(; nthreads=Threads.nthreads())

function BLAS_coloring(graph::AbstractGraph)
    if nv(graph) == 0
        return []
    end
    A_T = GBMatrix{Bool}((adjacency_matrix(graph, Bool; dir=:in)))
    A_T_int = GBMatrix{Int}(Int.(A_T))
    C = GBVector{Int}(nv(graph); fill=0)
    max_W_in_neighbors = GBVector{Float64}(nv(graph); fill=Float64(0.0))
    frontier = GBVector{Bool}(nv(graph); fill=false)

    # Descriptors
    normal_mask_desc = Descriptor(;
        nthreads=Threads.nthreads(), replace_output=true, structural_mask=true
    )
    complement_mask_desc = Descriptor(;
        nthreads=Threads.nthreads(),
        replace_output=true,
        structural_mask=true,
        complement_mask=true,
    )
    value_mask_desc = Descriptor(; nthreads=Threads.nthreads())

    # Assign weights to vertices based on their degree
    W_int = reduce(+, A_T_int; dims=2)

    # Break ties with random weights
    randomized_weights = GBVector(rand(Float64, nv(graph)))
    randomized_weights .+= W_int

    color = 1
    while true
        mul!(
            max_W_in_neighbors,
            A_T,
            randomized_weights,
            (max, *);
            mask=C,
            desc=complement_mask_desc,
        )
        eadd!(
            frontier,
            randomized_weights,
            max_W_in_neighbors,
            >;
            mask=C,
            desc=complement_mask_desc,
        )
        succ = reduce(∨, frontier)
        if !succ
            return Coloring(color - 1, C)
        else
            apply!(*, C, color, frontier; mask=frontier, desc=value_mask_desc)
            apply!(
                *,
                randomized_weights,
                0,
                randomized_weights;
                mask=frontier,
                desc=value_mask_desc,
            )
            color += 1
        end
    end
end

function BLAS_coloring_maxIS(graph::AbstractGraph)
    if nv(graph) == 0
        return []
    end
    A_T = GBMatrix{Bool}((adjacency_matrix(graph, Bool; dir=:in)))
    A_T_int = GBMatrix{Int}(Int.(A_T))
    C = GBVector{Int}(nv(graph); fill=0)
    max_W_in_neighbors = GBVector{Float32}(nv(graph); fill=Float32(0.0))
    independant_set = GBVector{Bool}(nv(graph); fill=false)

    # Assign weights to vertices based on their degree
    W = reduce(+, A_T_int; dims=2)
    # Break ties with random weights
    randomized_weights_mat = rand(Float32, nv(graph))
    randomized_weights = GBVector{Float32}(randomized_weights_mat)
    eadd!(
        randomized_weights,
        randomized_weights,
        W;
        mask=C,
        desc=Descriptor(;
            nthreads=Threads.nthreads(),
            replace_output=true,
            structural_mask=false,
            complement_mask=true,
        ),
    )
    randomized_weights .+= W
    color = 1
    randomized_weights_ow = GBVector{Float32}(nv(graph); fill=Float32(0.0))
    while true
        ignore = GBVector{Bool}(C .> 0; fill=false)
        empty!(independant_set)

        assign!(
            randomized_weights_ow,
            randomized_weights,
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
        println("color : ", color)
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
            randomized_weights,
            0,
            randomized_weights;
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

# Ignore = C : the vertices that have already been colored are ignored from start
function max_IS_inner!(
    A_T::GBMatrix{Bool},
    randomized_weights::GBVector{Float32},
    independant_set::GBVector{Bool},
    ignore::GBVector{Bool},
    max_W_in_neighbors::GBVector{Float32},
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
