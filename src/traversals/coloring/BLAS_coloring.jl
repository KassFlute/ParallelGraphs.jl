function BLAS_coloring(graph::AbstractGraph)
    if nv(graph) == 0
        return []
    end
    A_T = GBMatrix{Int}((adjacency_matrix(graph; dir=:in)))
    C = GBVector{Int}(nv(graph); fill=0)
    max_W_in_neighbors = GBVector{Float64}(nv(graph); fill=0.0)
    frontier = GBVector{Int}(nv(graph); fill=0)

    # Descriptors
    normal_mask_desc = Descriptor(; nthreads=Threads.nthreads(), replace_output=true, structural_mask=true) 
    complement_mask_desc = Descriptor(; nthreads=Threads.nthreads(), replace_output=true, structural_mask=true, complement_mask=true)
    value_mask_desc = Descriptor(; nthreads=Threads.nthreads())

    # Assign weights to vertices based on their degree
    W = GBVector{Float64}(nv(graph); fill=0.0)
    W = reduce(+, A_T, dims=2)

    # Break ties with random weights
    W .+ rand(Float64)

    done = false
    color = 1
    while !done 
        mul!(max_W_in_neighbors, A_T, W, (max, *); mask=C, desc=complement_mask_desc)
        eadd!(frontier, W, max_W_in_neighbors, > ; mask=C, desc=complement_mask_desc)
        succ = reduce(+, frontier)
        if succ == 0
            done = true
        else
            apply!(*, C, color, frontier; mask=frontier , desc=value_mask_desc)
            apply!(*, W, 0, W; mask=frontier, desc=value_mask_desc)
            color += 1
        end
        
    end

    return C

    
end