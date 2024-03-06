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
function bfs_par(graph::AbstractGraph, source::Atomic{Int})
    queue = [source] # FIFO of vertices to visit
    visited = Set([source]) # Set of visited vertices
    visited_order = [source] # Order of visited vertices

    while !isempty(queue)
        v = popfirst!(queue)
        ns = neighbors(graph, v)
        @threads for n in ns
            if !(n in visited)
                push!(queue, n)
                push!(visited_order, n)
                push!(visited, n)
            end
        end
    end

    return visited_order
end




function bfs_par_tree!(graph::AbstractGraph, source::Integer, parents::Array{Atomic{Int}})
    queue = ThreadQueue{source}(nv(graph))
    tpush!(queue, source)

    parents[source] = source


    while !tisempty(queue)
        sources = queue.data[queue.head[]:queue.tail[]-1]
        @Threads for src in sources
            for n in neighbors(graph, src)
                @atomicreplace parents[n] 0 => src && tpush!(queue, n) # If the parent is 0, replace it with src vertex and push to queue
            end
        end
    end

    return parents
end

function bfs_par_tree(graph::AbstractGraph, source :: Atomic{Int})
    parents = zeros([source], nv(graph)) # Set of Parent vertices
    return bfs_par_tree!(graph, source, parents)
end
