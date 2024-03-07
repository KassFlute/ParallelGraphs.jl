"""
    bfs_seq(graph::AbstractGraph, source::Integer)

Perform a breadth-first search on `graph` starting from vertex `source`.
Return a vector of vertices in the order they were visited.

# Example
```julia
g = SimpleGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 1)
bfs_seq(g, 1) # returns [1, 2, 4, 3]
```
"""
function bfs_seq(graph::AbstractGraph, source::T) where {T<:Integer}
    queue::Vector{T} = Vector{T}(undef, 0) # FIFO of vertices to visit
    visited = Set([source]) # Set of visited vertices
    visited_order = [source] # Order of visited vertices
    push!(queue, source)

    while !isempty(queue)
        v = popfirst!(queue)
        ns = neighbors(graph, v)
        for n in ns
            if !(n in visited)
                push!(queue, n)
                push!(visited_order, n)
                push!(visited, n)
            end
        end
    end

    return visited_order
end
## Parents should be filled with zeros
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

function bfs_seq_tree(graph::AbstractGraph, source::T) where {T<:Integer}
    #parents = Array{T} # Set of Parent vertices
    parents = fill(0, nv(graph))
    bfs_seq_tree!(graph, source, parents)
    return parents
end
