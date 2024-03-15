"""
    bfs_seq_tree!(graph::AbstractGraph, source::T, parents::Array{T})

Run a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.
For correct results, the 'parents' Array should be initialized with zeros.

See also: [bfs_seq](@ref)
"""
function bfs_seq!(graph::AbstractGraph, source::T, parents::Array{T}) where {T<:Integer}
    if nv(graph) == 0
        return parents
    end
    if source > nv(graph) || source < 1
        throw(ArgumentError("source vertex is not in the graph"))
    end
    queue = Queue{T}() # FIFO of vertices to visit
    enqueue!(queue, source)

    parents[source] = source

    while !isempty(queue)
        src_v = dequeue!(queue)
        for n in neighbors(graph, src_v)
            if parents[n] == 0
                parents[n] = src_v
                enqueue!(queue, n)
            end
        end
    end
    return nothing
end

"""
    bfs_seq(graph::AbstractGraph, source::T)

Run a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.

See also: [bfs_seq!](@ref)
"""
function bfs_seq(graph::AbstractGraph, source::T) where {T<:Integer}
    #parents = Array{T} # Set of Parent vertices

    parents = fill(0, nv(graph))
    bfs_seq!(graph, source, parents)
    return parents
end
