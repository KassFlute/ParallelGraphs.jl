"""
    bfs_par_tree!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}})

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
        # explores vertices in parallel
        if last_elem > granularity
            split_chunks!(to_visit, granularity, last_elem, chunks)
            @sync for i in 1:granularity
                @spawn local_exploration!(chunks[i], queues[i])
            end
        else
            local_exploration!(Vector[view(to_visit, 1:last_elem)][1], queues[1])
        end

        # Store the lenghts of the queues in the accumulator to parallelize the copying
        last_elem = 0
        accumulator = [0 for _ in 1:(granularity + 1)]
        for i in 2:granularity
            accumulator[i] = accumulator[i - 1] + length(queues[i - 1])
            last_elem += length(queues[i - 1])
        end
        accumulator[granularity + 1] =
            accumulator[granularity] + length(queues[granularity])
        last_elem += length(queues[granularity])

        # Empty the to_visit array and fill it with the elements of the queues
        fill!(to_visit, zero(T))
        @sync for i in 1:granularity
            @spawn begin
                q = queues[i]

                #last = length(q) + last_elem
                ##println("splicing : ", length(q), " from ", last_elem, " to ", last)
                #splice!(to_visit, (last_elem + 1):last, collect(q))
                #last_elem = last
                #empty!(q)

                for j in (accumulator[i] + 1):accumulator[i + 1]
                    to_visit[j] = dequeue!(q)
                end
            end
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
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    bfs_par!(graph, source, parents_atomic)

    parents = Array{T}(undef, length(parents_atomic))
    parents = [x[] for x in parents_atomic]
    return parents
end

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
