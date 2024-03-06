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


## Version with a ThreadQueue stolen from Graphs.jl

"""
    ThreadQueue

A thread safe queue implementation for using as the queue for BFS.
"""
struct ThreadQueue{T,N<:Integer}
    data::Vector{T}
    head::Atomic{N} # Index of the head
    tail::Atomic{N} # Index of the tail
end

function ThreadQueue(T::Type, maxlength::N) where {N<:Integer}
    q = ThreadQueue(Vector{T}(undef, maxlength), Atomic{N}(1), Atomic{N}(1))
    return q
end

function push!(q::ThreadQueue{T,N}, val::T) where {T} where {N}
    # TODO: check that head > tail
    offset = atomic_add!(q.tail, one(N))
    q.data[offset] = val
    return offset
end

function popfirst!(q::ThreadQueue{T,N}) where {T} where {N}
    # TODO: check that head < tail
    offset = atomic_add!(q.head, one(N))
    return q.data[offset]
end

function isempty(q::ThreadQueue{T,N}) where {T} where {N}
    return (q.head[] == q.tail[]) && q.head != one(N)
end

function getindex(q::ThreadQueue{T}, iter) where {T}
    return q.data[iter]
end

function bfs_par_tree(graph::AbstractGraph, source::Integer)
    queue = ThreadQueue{source}(nv(graph))
    push!(queue, source)

    parents[source] = source


    while !isempty(queue)
        sources = queue.data[queue.head[]:queue.tail[]-1]
        @Threads for src in sources
            for n in neighbors(graph, src)
                @atomicreplace parents[n] 0 => src && push!(queue, n) # If the parent is 0, replace it with src vertex and push to queue
            end
        end
    end

    return parents
end

function bfs_par_tree(graph::AbstractGraph, source :: Integer)
    parents = zeros([source], nv(graph)) # Set of Parent vertices
    return bfs_par_tree!(graph, source, parents)
end
