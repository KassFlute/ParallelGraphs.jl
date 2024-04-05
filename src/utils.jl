## Version of a thread-safe queue stolen from Graphs.jl
## TODO : implement a better queue using a binary heap for the priority queue

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

function t_push!(q::ThreadQueue{T,N}, val::T) where {T} where {N}
    # TODO: check that head > tail
    offset = atomic_add!(q.tail, one(N))
    q.data[offset] = val
    return offset
end

function t_popfirst!(q::ThreadQueue{T,N}) where {T} where {N}
    # TODO: check that head < tail
    offset = atomic_add!(q.head, one(N))
    return q.data[offset]
end

function t_isempty(q::ThreadQueue{T,N}) where {T} where {N}
    return (q.head[] == q.tail[]) && q.head != one(N)
end

function t_getindex(q::ThreadQueue{T}, iter) where {T}
    return q.data[iter]
end

function split_chunks!(
    v::Vector{T}, nb_chunks::Int, size::Int, res::Vector{Vector{T}}
) where {T}
    if size % nb_chunks == 0
        chunk_size = div(size, nb_chunks)
    else
        chunk_size = div(size, nb_chunks - 1)
    end

    for i in 1:(nb_chunks - 1)
        res[i] = view(v, ((i - 1) * chunk_size + 1):(i * chunk_size))
    end
    res[nb_chunks] = view(v, ((nb_chunks - 1) * chunk_size + 1):size)
    return nothing
end
