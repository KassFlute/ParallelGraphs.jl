using Random

"""
    Struct to store the coloring of a graph.

    num_colors: Number of colors used in the coloring.
    colors: Vector of length `n` where `n` is the number of vertices in the graph.
            The `i`-th element of the vector is the color assigned to the `i`-th vertex.
"""
struct Coloring{T<:Integer}
    num_colors::T
    colors::Vector{T}
end

"""
    Function to perform a greedy coloring of a graph.

    g: Graph to be colored.
    order: Order in which the vertices will be colored. The `i`-th element of the vector
           is the index of the vertex that will be colored in the `i`-th iteration.

    Returns a `Coloring` struct with the coloring of the graph.
"""
function greedy_coloring(g::AbstractGraph, order::Vector{Int})
    n = nv(g)
    colors = fill(0, n)
    max_color = 0

    # Loop through the vertices in the given order
    for v in order
        available = fill(true, max_color)
        for neighbor in all_neighbors(g, v)
            if colors[neighbor] != 0
                available[colors[neighbor]] = false
            end
        end
        color = findfirst(available)
        if color === nothing
            max_color += 1
            colors[v] = max_color
        else
            colors[v] = color
        end
    end

    num_colors = max_color
    return Coloring(num_colors, colors)
end

"""
    Function to shuffle the vertices of a graph and perform a greedy coloring.

    g: Graph to be colored.

    Returns a `Coloring` struct with the coloring of the graph.
"""
function shuffle_and_color(g::AbstractGraph)
    order = shuffle(1:nv(g))
    return greedy_coloring(g, order)
end

"""
    Function to shuffle the vertices of a graph and perform a greedy coloring `n` times.

    g: Graph to be colored.
    n: Number of times the graph will be colored.

    Returns a `Coloring` struct with the best coloring found.
"""
function shuffle_and_color_n_times(g::AbstractGraph, n::Int)
    best_coloring = shuffle_and_color(g)
    for i in 2:n
        coloring = shuffle_and_color(g)
        if coloring.num_colors < best_coloring.num_colors
            best_coloring = coloring
        end
    end
    return best_coloring
end

"""
    Function to order the vertices of a graph by degree and perform a greedy coloring.

    g: Graph to be colored.

    Returns a `Coloring` struct with the coloring of the graph.
"""
function degree_order_and_color(g::AbstractGraph)
    order = sortperm(degree(g); rev=true)
    return greedy_coloring(g, order)
end

"""
    Function to order the vertices of a graph by degree and perform a greedy coloring `n` times.

    g: Graph to be colored.
    n: Number of times the graph will be colored.

    Returns a `Coloring` struct with the best coloring found.
"""
function degree_order_and_color_n_times(g::AbstractGraph, n::Int)
    best_coloring = degree_order_and_color(g)
    for i in 2:n
        coloring = degree_order_and_color(g)
        if coloring.num_colors < best_coloring.num_colors
            best_coloring = coloring
        end
    end
    return best_coloring
end
