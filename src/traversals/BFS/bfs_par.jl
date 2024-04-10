"""
    bfs_par!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}})

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.

See also: [bfs_par](@ref)
"""
function bfs_par!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}
) where {T<:Integer}
    if !has_vertex(graph, source)
        throw(ArgumentError("source vertex is not in the graph"))
    end

    #function local_exploration!(src::T) where {T<:Integer}
    #    for n in neighbors(graph, src)
    #        # If the parent is 0, replace it with src vertex and push to queue
    #        old_val = atomic_cas!(parents[n], 0, src)
    #        if old_val == 0
    #            t_push!(queue, n)
    #        end
    #    end
    #end

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
        #tforeach(local_exploration!, sources) # explores vertices in parallel
    end
    return nothing
end

function bfs_par_local_unsafe!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}, queues::Vector{Queue{T}}
) where {T<:Integer}
    if !has_vertex(graph, source)
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
    end

    #to_visit = Vector{T}()
    #push!(to_visit, source)

    to_visit = zeros(T, nv(graph))
    to_visit[1] = source
    parents[source] = Atomic{Int}(source)
    first_free_index = 2
    while (first_free_index > 1)
        #println(parents)

        tforeach(local_exploration!, view(to_visit, 1:(first_free_index - 1))) # explores vertices in parallel
        first_free_index = 1
        fill!(to_visit, zero(T))

        for i in 1:Threads.nthreads()
            q = queues[i]
            last = length(q) - 1 + first_free_index
            splice!(to_visit, first_free_index:last, collect(q))
            first_free_index = last + 1
            empty!(q)
        end
    end

    #while !isempty(to_visit)
    #    tforeach(local_exploration!, to_visit) # explores vertices in parallel
    #    to_visit = Vector{T}()
    #    for i in 1:Threads.nthreads()
    #        while !isempty(queues[i])
    #            push!(to_visit, dequeue!(queues[i]))
    #        end
    #    end
    #end
    return nothing
end

"""
    bfs_par_local!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}}, queues::Vector{Queue{T}}, to_visit::Vector{T})

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.

See also: [bfs_par_local](@ref)
"""
function bfs_par_local!(
    graph::AbstractGraph,
    source::T,
    parents::Vector{Atomic{T}},
    queues::Vector{Queue{T}},
    to_visit::Vector{T},
) where {T<:Integer}
    if !has_vertex(graph, source)
        throw(ArgumentError("source vertex is not in the graph"))
    end

    function local_exploration!(src_vect::Vector{T}, q::Queue{T}) where {T<:Integer}
        for src in src_vect
            for n in neighbors(graph, src)
                # If the parent is 0, replace it with src vertex and push to queue
                old_val = atomic_cas!(parents[n], 0, src)
                if old_val == 0
                    enqueue!(q, n)
                end
            end
        end
        return nothing
    end

    granularity = length(queues)
    #to_visit = zeros(T, nv(graph))
    to_visit[1] = source
    parents[source] = Atomic{Int}(source)
    last_elem = 1
    chunks = Vector{Vector{T}}(undef, granularity)
    while (last_elem > 0)
        #tforeach(local_exploration!, view(to_visit, 1:(first_free_index - 1))) # explores vertices in parallel
        if last_elem > granularity
            split_chunks!(to_visit, granularity, last_elem, chunks)
            @sync for i in 1:granularity
                @spawn local_exploration!(chunks[i], queues[i])
            end
        else
            local_exploration!(Vector[view(to_visit, 1:last_elem)][1], queues[1])
        end

        last_elem = 0
        fill!(to_visit, zero(T))
        for i in 1:granularity
            q = queues[i]
            last = length(q) + last_elem
            #println("splicing : ", length(q), " from ", last_elem, " to ", last)
            splice!(to_visit, (last_elem + 1):last, collect(q))
            last_elem = last
            empty!(q)

            #l = length(q)
            #for j in (last_elem + 1):(last_elem + l)
            #    to_visit[j] = dequeue!(q)
            #end
            #last_elem += l

            #while !isempty(q)
            #    last_elem += 1
            #    to_visit[last_elem] = dequeue!(q)
            #end
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
    bfs_par(graph::AbstractGraph, source::T)

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.

See also: [bfs_par!](@ref)
"""
function bfs_par(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    bfs_par!(graph, source, parents_atomic)

    parents = Array{T}(undef, length(parents_atomic))
    parents = [x[] for x in parents_atomic]
    return parents
end

function bfs_par_local_unsafe(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end
    queues = Vector{Queue{T}}()
    for i in 1:Threads.nthreads()
        push!(queues, Queue{T}())
    end
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    bfs_par_local_unsafe!(graph, source, parents_atomic, queues)

    parents = Array{T}(undef, length(parents_atomic))
    parents = [x[] for x in parents_atomic]
    return parents
end

"""
    bfs_par_local(graph::AbstractGraph, source::T)

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.
(alternative versino)

See also: [bfs_par_local!](@ref)
"""
function bfs_par_local(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end
    queues = Vector{Queue{T}}()
    blksize = max((nv(graph) ÷ Threads.nthreads()) + 1, 10)
    for i in 1:Threads.nthreads()
        push!(queues, Queue{T}(blksize))
    end
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    to_visit = zeros(T, nv(graph))
    bfs_par_local!(graph, source, parents_atomic, queues, to_visit)

    parents = Array{T}(undef, length(parents_atomic))
    parents = [x[] for x in parents_atomic]
    return parents
end

function bfs_par_local_probably_slower(graph::AbstractGraph, source::T) where {T<:Integer}
    if nv(graph) == 0
        return T[]
    end
    chnl = Channel{T}(nv(graph))
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    bfs_par_local_probably_slower!(graph, source, parents_atomic, chnl)

    parents = Array{T}(undef, length(parents_atomic))
    parents = [x[] for x in parents_atomic]
    return parents
end
