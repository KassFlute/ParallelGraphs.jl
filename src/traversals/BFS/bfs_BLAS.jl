
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
    #A = permutedims(adjacency_matrix(graph), (2, 1))
    A = GBMatrix(adjacency_matrix(graph))

    bfs_BLAS!(A', source, p, f)

    return Array(p)
end

function bfs_BLAS!(
    A::GBArrayOrTranspose{T}, source::T, p::GBVector{T}, f::GBVector{T}
) where {T<:Integer}

    #mask = GBVector{T}(n ; fill = zero(T))

    p[source] = source
    f[source] = source
    z = GBVector{T}(length(p); fill=zero(T))

    for _ in 1:length(p)
        mul!(f, A, f, (any, secondi); mask=~p)
        extract!(f, z, 1:length(p); mask=p)
        extract!(p, f, 1:length(p); mask=~p)
        apply!(rowindex, f, f)
        if reduce(&, f == zero(T))
            return nothing
        end
    end

    return nothing
end
