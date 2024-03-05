"""
    bfs_par(graph::AbstractGraph, source::Integer)

Perform a breadth-first search on `graph` starting from vertex `source` in with multiple threads.
Simplest OhMyThreads version -> create a new thread for each neighbot to visit.
Return a vector of vertices in the order they were visited (by all threads!).

# Example
```julia
g = SimpleGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 1)
bfs_par(g, 1) # returns a vector containing all vertices in the order they were visited by all threads
```
"""
function bfs_par(graph::AbstractGraph, source::Integer)
    queue = [source] # FIFO of vertices to visit
    visited = Set([source]) # Set of visited vertices
    visited_order = [source] # Order of visited vertices

    while !isempty(queue)
        v = popfirst!(queue)
        ns = neighbors(graph, v)
        @tasks for n in ns
            if !(n in visited)
                push!(queue, n)
                push!(visited_order, n)
                push!(visited, n)
            end
        end
    end

    return visited_order
end
