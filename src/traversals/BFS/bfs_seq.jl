"""
    bfs_seq_tree!(graph::AbstractGraph, source::T, parents::Array{T})

Run a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.

See also: [bfs_seq_tree](@ref)
"""
function bfs_seq_tree!(
    graph::AbstractGraph, source::T, parents::Array{T}
) where {T<:Integer}
    queue::Vector{T} = Vector{T}(undef, 0) # FIFO of vertices to visit
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

    return parents
end

"""
    bfs_seq_tree(graph::AbstractGraph, source::T)

Run a sequential BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.

See also: [bfs_seq_tree!](@ref)
"""
function bfs_seq_tree(graph::AbstractGraph, source::T) where {T<:Integer}
    #parents = Array{T} # Set of Parent vertices
    parents = fill(0, nv(graph))
    bfs_seq_tree!(graph, source, parents)
    println("after call : ", parents)
    return parents
end
