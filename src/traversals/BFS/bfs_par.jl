"""
    bfs_par_tree!(graph::AbstractGraph, source::T, parents::Array{Atomic{T}})

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in the given 'parents' Array.

See also: [bfs_par_tree](@ref)
"""
function bfs_par!(
    graph::AbstractGraph, source::T, parents::Array{Atomic{T}}
) where {T<:Integer}
    queue = ThreadQueue(T, nv(graph))
    t_push!(queue, source)

    parents[source] = Atomic{Int}(source)

    while !t_isempty(queue)
        sources = queue.data[queue.head[]:(queue.tail[] - 1)]
        queue.head[] = queue.tail[]
        @threads for src in sources
            @threads for n in neighbors(graph, src)

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
    return parents
end

"""
    bfs_par_tree(graph::AbstractGraph, source::T)

Run a parallel BFS traversal on a graph and return the parent vertices of each vertex in the BFS tree in a new Array.

See also: [bfs_par_tree!](@ref)
"""
function bfs_par(graph::AbstractGraph, source::T) where {T<:Integer}
    #parents = Array{Atomic{T}}(0, nv(graph))
    parents_atomic = [Atomic{T}(0) for _ in 1:nv(graph)]
    bfs_par!(graph, source, parents_atomic)
    parents = [x[] for x in parents_atomic]
    return parents
end
