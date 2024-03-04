"""
    bfs(graph::AbstractGraph, source::Integer)

Perform a breadth-first search on `graph` starting from vertex `source`.
Return a vector of vertices in the order they were visited.

# Example
```julia
g = SimpleGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 1)
bfs(g, 1) # returns [1, 2, 4, 3]
```
"""
function bfs(graph::AbstractGraph, source::Integer)
    queue = [source] # FIFO of vertices to visit
    visited = Set([source]) # Set of visited vertices
    visited_order = [source] # Order of visited vertices

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
