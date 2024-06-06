
"""
    bfs_BLAS(graph::AbstractGraph, source::T) where {T<:Integer}

Perform a BFS traversal on a graph `graph` starting from vertex `source` using GraphBLAS operations.
"""
function bfs_BLAS(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end

    if !has_vertex(graph, source)
        throw(ArgumentError("source vertex is not in the graph"))
    end

    n = nv(graph)
    p = GBVector{T}(n; fill=zero(T))
    A_T = GBMatrix{Bool}((adjacency_matrix(graph, Bool; dir=:in)))
    bfs_BLAS!(A_T, source, p)

    return Array(p)
end

"""
    bfs_BLAS!(A_T::GBMatrix{Bool}, source::T, p::GBVector{T}, f::GBVector{Bool}) where {T<:Integer}

Perform a BFS traversal on a graph represented by its transpose adjacency matrix `A_T` starting from vertex `source` using GraphBLAS operations.
"""
function bfs_BLAS!(
    A_T::GBMatrix{Bool}, source::T, p::GBVector{T}
) where {T<:Integer}
    p[source] = source

    temp1 = GBVector{Bool}(length(p); fill=false)
    temp2 = GBVector{Bool}(length(p); fill=false)
    temp1[source] = true
    while true
        mul!(
            temp2,
            A_T,
            temp1,
            (any, pair);
            mask=p,
            desc=Descriptor(;
                nthreads=Threads.nthreads(),
                replace_output=true,
                complement_mask=true,
                structural_mask=true,
            ),
        )
        if reduce(∨, temp2) == false
    f[source] = true
    desc = Descriptor(; nthreads=Threads.nthreads())
    temp = GBVector{T}(length(p); fill=zero(T))
    for _ in 1:length(p)
        empty!(temp)
        mul!(temp, A_T, f, (any, secondi); mask=~p)
        extract!(p, temp, 1:length(p); mask=temp)
        empty!(f)
        apply!(identity, f, temp; mask=temp)
        if !reduce(∨, f)
            return nothing
        end
    end
    return nothing

    #p[source] = source
    #f[source] = source
    #z = GBVector{T}(length(p); fill=zero(T))
    #temp = GBMatrix{T}(1 , length(p); fill=zero(T))
    #
    #depth = 0
    #for _ in 1:length(p)
    #    depth += 1
    #    empty!(temp)
    #    mul!(temp, f', A, (any, secondi); mask=~p')
    #    #extract!(f, z, 1:length(p); mask=p)
    #    extract!(p, temp, 1:length(p); mask=temp)
    #    apply(rowindex, f, temp')
    #    if reduce(max, f) == 0
    #        return nothing
    #    end
    #end
    #return nothing
end
