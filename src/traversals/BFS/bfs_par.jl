"""
    bfs_par_tree!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}})

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.

See also: [bfs_par](@ref)
"""
function bfs_par!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}
) where {T<:Integer}
    if source > nv(graph) || source < 1
        throw(ArgumentError("source vertex is not in the graph"))
    end
    queue = ThreadQueue(T, nv(graph))
    t_push!(queue, source)

    parents[source] = Atomic{Int}(source)

    while !t_isempty(queue)
        sources = queue.data[queue.head[]:(queue.tail[] - 1)]
        queue.head[] = queue.tail[]
        @threads for src in sources
            for n in neighbors(graph, src)

                #(@atomicreplace parents[n] 0 => src).success && t_push!(queue, n) 
                # If the parent is 0, replace it with src vertex and push to queue
                old_val = atomic_cas!(parents[n], 0, src)
                if old_val == 0
                    t_push!(queue, n)
                end
            end
        end
    end

    #return Array{T}(parents) TODO : find a way to efficiently convert Array{Atomic{T}} to Array{T}
    return nothing
end

function bfs_par_local!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}
) where {T<:Integer}
    if source > nv(graph) || source < 1
        throw(ArgumentError("source vertex is not in the graph"))
    end
    buckets = Vector{Queue{T}}(undef, Threads.nthreads())
    for i in 1:Threads.nthreads()
        buckets[i] = Queue{T}()
    end

    to_visit = Vector{T}()
    push!(to_visit, source)

    parents[source] = Atomic{Int}(source)

    while !isempty(to_visit)
        @threads for src in to_visit
            @threads for n in neighbors(graph, src)
                tid = Threads.threadid()

                # If the parent is 0, replace it with src vertex and push to queue
                old_val = atomic_cas!(parents[n], 0, src)
                if old_val == 0
                    enqueue!(buckets[tid], n)
                end
            end
        end
        to_visit = Vector{T}()
        for i in 1:Threads.nthreads()
            while !isempty(buckets[i])
                push!(to_visit, dequeue!(buckets[i]))
            end
        end
    end

    #return Array{T}(parents) TODO : find a way to efficiently convert Array{Atomic{T}} to Array{T}
    return nothing
end

"""
    bfs_par_tree(graph::AbstractGraph, source::T)

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.

See also: [bfs_par!](@ref)
"""
function bfs_par(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end

    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    parents_atomic = bfs_par!(graph, source, parents_atomic)
    #parents = Array{T}(parents_atomic)
    #parents = [x[] for x in parents_atomic]
    return parents_atomic
end
