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
function bfs_par(graph::AbstractGraph, source::T) where {T<:Integer}
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

function bfs_par_tree!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}}) where {T<:Integer}
    queue = ThreadQueue(T, nv(graph))
    t_push!(queue, source)

    parents[source] = Atomic{Int}(source)

    while !t_isempty(queue)
        sources = queue.data[queue.head[]:(queue.tail[] - 1)]
        @threads for src in sources
            for n in neighbors(graph, src)
                #@atomicreplace parents[n].Val 0 => src && t_push!(queue, n) # If the parent is 0, replace it with src vertex and push to queue
            end
        end
    end

    return parents
end

function bfs_par_tree(graph::AbstractGraph, source::T) where {T<:Integer}
    parents = Array{Atomic{T}}(undef, nv(graph))
    bfs_par_tree!(graph, source, parents)
    return parents
end