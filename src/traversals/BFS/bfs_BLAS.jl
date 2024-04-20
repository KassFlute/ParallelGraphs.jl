
function bfs_BLAS(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end

    if !has_vertex(graph, source)
        throw(ArgumentError("source vertex is not in the graph"))
    end

    n = nv(graph)
    p = GBVector{T}(n; fill=zero(T))
    f = GBVector{T}(n; fill=zero(T))
    A_T = GBMatrix{T}(adjacency_matrix(graph; dir=:in))
    bfs_BLAS!(A_T, source, p, f)

    return Array(p)
end

function bfs_BLAS!(
    A_T::GBMatrix{T}, source::T, p::GBVector{T}, f::GBVector{T}
) where {T<:Integer}
    p[source] = source
    f[source] = source
    temp = GBVector{T}(length(p); fill=zero(T))
    for _ in 1:length(p)
        empty!(temp)
        mul!(temp, A_T, f, (any, secondi); mask=~p)
        extract!(p, temp, 1:length(p); mask=temp)
        empty!(f)
        apply!(rowindex, f, temp; mask=temp)
        if reduce(max, f) == 0
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
