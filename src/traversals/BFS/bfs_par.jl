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
        Threads.@spawn for src in sources
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

function bfs_par_local_unsafe!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}, queues::Vector{Queue{T}}
) where {T<:Integer}
    if source > nv(graph) || source < 1
        throw(ArgumentError("source vertex is not in the graph"))
    end

    function local_exploration!(src::T) where {T<:Integer}
        for n in neighbors(graph, src)
            # If the parent is 0, replace it with src vertex and push to queue
            old_val = atomic_cas!(parents[n], 0, src)
            if old_val == 0
                enqueue!(queues[Threads.threadid()], n)
            end
        end

        to_visit = Vector{T}()
        push!(to_visit, source)

        parents[source] = Atomic{Int}(source)
        while !isempty(to_visit)
            tforeach(local_exploration!, to_visit) # explores vertices in parallel
            to_visit = Vector{T}()
            for i in 1:Threads.nthreads()
                while !isempty(queues[i])
                    push!(to_visit, dequeue!(queues[i]))
                end
            end
        end
        return nothing
    end
end

function bfs_par_local!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}, queues::Channel{Queue{T}}
) where {T<:Integer}
    if source > nv(graph) || source < 1
        throw(ArgumentError("source vertex is not in the graph"))
    end

    function local_exploration!(src::T) where {T<:Integer}
        for n in neighbors(graph, src)
            # If the parent is 0, replace it with src vertex and push to queue
            old_val = atomic_cas!(parents[n], 0, src)
            if old_val == 0
                q = take!(queues)
                enqueue!(q, n)
                put!(queues, q)
                q = take!(queues)
                enqueue!(q, n)
                put!(queues, q)
            end
        end
    end

    to_visit = Vector{T}()
    push!(to_visit, source)

    parents[source] = Atomic{Int}(source)
    while !isempty(to_visit)
        tforeach(local_exploration!, to_visit) # explores vertices in parallel
        to_visit = Vector{T}()
        for i in 1:Threads.nthreads()
            q = take!(queues)
            while !isempty(q)
                push!(to_visit, dequeue!(q))
            end
            put!(queues, q)
        end
    end
    return nothing
end

function bfs_par_local_probably_slower!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}, chnl::Channel{T}
) where {T<:Integer}
    if source > nv(graph) || source < 1
        throw(ArgumentError("source vertex is not in the graph"))
    end

    function local_exploration!(src::T) where {T<:Integer}
        for n in neighbors(graph, src)
            # If the parent is 0, replace it with src vertex and push to queue
            old_val = atomic_cas!(parents[n], 0, src)
            if old_val == 0
                put!(chnl, n)
            end
        end
    end

    to_visit = Vector{T}()
    push!(to_visit, source)
    parents[source] = Atomic{Int}(source)

    while !isempty(to_visit)
        tforeach(local_exploration!, to_visit) # explores vertices in parallel
        to_visit = Vector{T}()
        while isready(chnl)
            push!(to_visit, take!(chnl))
        end
    end
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
    queues = Channel{Queue{T}}(Threads.nthreads())
    for i in 1:Threads.nthreads()
        put!(queues, Queue{T}())
    end
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    bfs_par_local2!(graph, source, parents_atomic, queues)

    parents = Array{T}(undef, length(parents_atomic))
    parents = [x[] for x in parents_atomic]
    return parents
end

#function bfs_par(graph::AbstractGraph, source::T) where {T<:Integer}
#    if nv(graph) == 0
#        return T[]
#    end
#    channel = Channel{T}(nv(graph))
#    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
#    bfs_par_local3!(graph, source, parents_atomic, channel)
#
#    parents = Array{T}(undef, length(parents_atomic))
#    parents = [x[] for x in parents_atomic]
#    return parents
#end
