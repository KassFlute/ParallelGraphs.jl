"""
    bfs_seq_tree!(graph::AbstractGraph, source::T, parents::Array{T})

Run a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.
For correct results, the 'parents' Array should be initialized with zeros.

See also: [bfs_seq](@ref)
"""
function bfs_seq!(graph::AbstractGraph, source::T, parents::Array{T}) where {T<:Integer}
    queue::Queue{T} = Queue{T}() # FIFO of vertices to visit
    push!(queue, source)

    parents[source] = source

    while !isempty(queue)
        src_v = popfirst!(queue)
        ns = neighbors(graph, src_v)
        for n in ns
            if parents[n] == 0
                parents[n] = src_v
                push!(queue, n)
            end
        end
    end
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
