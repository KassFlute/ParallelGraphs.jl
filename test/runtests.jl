using Aqua
using JET
using JuliaFormatter
using Test

using ParallelGraphs
using Graphs

using GraphIO.EdgeList
using GraphIO.EdgeList: IntEdgeListFormat, loadgraph
using ParserCombinator
using GraphIO.GML: GMLFormat

@testset verbose = true "ParallelGraphs.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(ParallelGraphs; ambiguities=false)
    end
    @testset "JET" begin
        JET.test_package(ParallelGraphs; target_defined_modules=true)
    end
    @testset "JuliaFormatter" begin
        @test JuliaFormatter.format(ParallelGraphs; overwrite=false)
    end
    @testset "Actual tests" begin
        @testset "BFS sequential" begin
            @testset "Undirected graph" begin
                ### Empty graph ###
                graph = SimpleGraph(0)
                @test bfs_seq(graph, 0) == []

                ### Basic undirected graph ###
                adjacency_matrix = [
                    0 1 1 0
                    1 0 0 1
                    1 0 0 1
                    0 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                # correct from source 1
                expected_parents_1 = [1, 1, 1, 2]
                expected_parents_2 = [1, 1, 1, 3]
                res = bfs_seq(graph, 1)
                @test res == expected_parents_1 || res == expected_parents_2

                # correct from source 2
                expected_parents_1 = [2, 2, 1, 2]
                expected_parents_2 = [2, 2, 4, 2]
                res = bfs_seq(graph, 2)
                @test res == expected_parents_1 || res == expected_parents_2

                # invalid source
                @test_throws ArgumentError bfs_seq(graph, 0)
                @test_throws ArgumentError bfs_seq(graph, -1)
                @test_throws ArgumentError bfs_seq(graph, 5)

                ### Not-connected graph ###
                adjacency_matrix = [
                    0 1 0 0 0 0
                    1 0 1 0 0 0
                    0 1 0 0 0 0
                    0 0 0 0 1 0
                    0 0 0 1 0 1
                    0 0 0 0 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                # correct from source 1
                expected_parents_1 = [1, 1, 2, 0, 0, 0]
                res = bfs_seq(graph, 1)
                @test res == expected_parents_1

                # correct from source 5
                expected_parents_1 = [0, 0, 0, 5, 5, 5]
                res = bfs_seq(graph, 5)
                @test res == expected_parents_1
            end

            @testset "Directed Graphs" begin
                # Empty graph
                graph = SimpleDiGraph(0)
                @test bfs_seq(graph, 0) == []

                # Basic directed graph
                adjacency_matrix = [
                    0 1 0 0
                    0 0 1 0
                    0 0 0 1
                    0 1 0 0
                ]
                graph = SimpleDiGraph(adjacency_matrix)

                expected_parents_1 = [1, 1, 2, 3]
                res = bfs_seq(graph, 1)
                @test res == expected_parents_1

                expected_parents_1 = [0, 2, 2, 3]
                res = bfs_seq(graph, 2)
                @test res == expected_parents_1
            end
        end

        @testset "BFS Parallel" begin
            ### TESTED PARALLEL BFS CANDIDATES ###
            bfs_parallel_algorithms = [
                bfs_par,
                ParallelGraphs.bfs_par_local_unsafe,
                ParallelGraphs.bfs_par_local,
                ParallelGraphs.bfs_par_local_probably_slower,
            ]

            @testset "Undirected graph" begin
                ### Empty graph ###
                graph = SimpleGraph(0)
                for bfs_par in bfs_parallel_algorithms
                    @test bfs_par(graph, 0) == []
                end

                ### Basic undirected graph ###
                adjacency_matrix = [
                    0 1 1 0
                    1 0 0 1
                    1 0 0 1
                    0 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                # correct from source 1
                expected_parents_1 = [1, 1, 1, 2]
                expected_parents_2 = [1, 1, 1, 3]
                for bfs_par in bfs_parallel_algorithms
                    res = bfs_par(graph, 1)
                    @test res == expected_parents_1 || res == expected_parents_2
                end

                # correct from source 2
                expected_parents_1 = [2, 2, 1, 2]
                expected_parents_2 = [2, 2, 4, 2]
                for bfs_par in bfs_parallel_algorithms
                    res = bfs_par(graph, 2)
                    @test res == expected_parents_1 || res == expected_parents_2
                end

                # invalid source
                @test_throws ArgumentError bfs_par(graph, 0)
                @test_throws ArgumentError bfs_par(graph, -1)
                @test_throws ArgumentError bfs_par(graph, 5)

                ### Not-connected graph ###
                adjacency_matrix = [
                    0 1 0 0 0 0 0 0
                    1 0 1 0 0 0 0 0
                    0 1 0 0 0 0 0 0
                    0 0 0 0 1 0 0 0
                    0 0 0 1 0 1 1 0
                    0 0 0 0 1 0 1 1
                    0 0 0 0 1 1 0 1
                    0 0 0 0 0 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                # correct from source 1
                expected_parents_1 = [1, 1, 2, 0, 0, 0, 0, 0]
                for bfs_par in bfs_parallel_algorithms
                    res = bfs_par(graph, 1)
                    @test res == expected_parents_1
                end

                # correct from source 4
                expected_parents_1 = [0, 0, 0, 4, 4, 5, 5, 7]
                expected_parents_2 = [0, 0, 0, 4, 4, 5, 5, 6]
                for bfs_par in bfs_parallel_algorithms
                    res = bfs_par(graph, 4)
                    @test (res == expected_parents_1) ⊻ (res == expected_parents_2) # XOR to check that only one is true
                end

                ### Complicated undirected graph ###
                adjacency_matrix = [
                    0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0
                    0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0
                    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0
                    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0
                    0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0
                    0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0
                    0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 1 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                for bfs_par in bfs_parallel_algorithms
                    # correct and effectively parallel from source 1
                    histogram = zeros(Int, 30)
                    correct = Set(14:29)
                    counter = 0
                    equality = true
                    base_res = bfs_par(graph, 1)[30]

                    for i in 1:100
                        res = bfs_par(graph, 1)[30]
                        histogram[res] += 1
                        if res in correct
                            counter += 1
                        end
                        equality = equality && res == base_res
                    end
                    # The results varies depending on execution, so multithreading is working
                    @test counter == 100
                    if equality
                        @warn "Some results that should be unpredictable are always identical. Test environnement is probably not configured correctly for multi-threading. Method used : $bfs_par"
                    end
                end
            end

            @testset "Directed Graphs" begin
                ###  Empty graph ###
                graph = SimpleDiGraph(0)
                for bfs_par in bfs_parallel_algorithms
                    @test bfs_par(graph, 0) == []
                end

                ### Simple directed graph ###
                adjacency_matrix = [
                    0 1 0 0
                    0 0 1 0
                    0 0 0 1
                    0 1 0 0
                ]
                graph = SimpleDiGraph(adjacency_matrix)

                # correct from source 1
                expected_parents_1 = [1, 1, 2, 3]
                for bfs_par in bfs_parallel_algorithms
                    res = bfs_par(graph, 1)
                    @test res == expected_parents_1
                end

                # correct from source 2
                expected_parents_1 = [0, 2, 2, 3]
                for bfs_par in bfs_parallel_algorithms
                    res = bfs_par(graph, 2)
                    @test res == expected_parents_1
                end

                ### More complicated directed graph ###
                adjacency_matrix = [
                    0 1 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 1 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 1 0 0 0 0 0 0 0 0 0 0
                    0 1 0 0 1 0 0 1 0 0 0 0 0 0
                    0 0 0 0 0 1 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 1 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 1 0 0 1
                    0 0 0 0 0 0 0 0 1 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 1 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 1 1 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 1
                    1 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0
                ]
                graph = SimpleDiGraph(adjacency_matrix)

                for bfs_par in bfs_parallel_algorithms
                    # correct from source 1
                    expected_parents_1 = [1, 1, 2, 3, 4, 5, 6, 4, 8, 9, 7, 10, 0, 7]
                    expected_parents_2 = [1, 1, 2, 3, 4, 5, 6, 4, 8, 9, 10, 10, 0, 7]
                    res = bfs_par(graph, 1)
                    @test (res == expected_parents_1) ⊻ (res == expected_parents_2)
                end
            end
            @testset "Stress tests" begin
                graph = barabasi_albert(100_005, 10)
                for bfs_par in bfs_parallel_algorithms
                    bfs_par(graph, 1)
                end

                graph = loadgraph("../benchmark/data/roads.csv", "roads", EdgeListFormat())
                #print("roads : ", nv(graph), " vertices, ", ne(graph), " edges\n")
                for bfs_par in bfs_parallel_algorithms
                    bfs_par(graph, 1)
                end

                graph = loadgraph(
                    "../benchmark/data/routers.csv", "routers", EdgeListFormat()
                )
                #print("routers : ", nv(graph), " vertices, ", ne(graph), " edges\n")
                for bfs_par in bfs_parallel_algorithms
                    bfs_par(graph, 1)
                end

                graph = loadgraph(
                    "../benchmark/data/internet_routers_bigger.gml", "graph", GMLFormat()
                )
                # print(
                #     "internet_routers_bigger.gml : ",
                #     nv(graph),
                #     " vertices, ",
                #     ne(graph),
                #     " edges\n",
                # )
            end
        end

        @testset "Greedy coloring sequential" begin
            @testset "Basic undirected graph" begin
                adjacency_matrix = [
                    0 1 1 0
                    1 0 0 1
                    1 0 0 1
                    0 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                # Test coloring with different orders
                order1 = [1, 2, 3, 4]
                order2 = [4, 3, 2, 1]

                # Color the graph with different orders
                coloring1 = ParallelGraphs.greedy_coloring(graph, order1)
                coloring2 = ParallelGraphs.greedy_coloring(graph, order2)

                # Ensure all vertices are colored
                @test all(coloring1.colors .!= 0)
                @test all(coloring2.colors .!= 0)

                # Ensure the number of colors used is minimal
                @test coloring1.num_colors == 2
                @test coloring2.num_colors == 2

                # Ensure adjacent vertices have different colors
                for v in 1:nv(graph)
                    for neighbor in neighbors(graph, v)
                        @test coloring1.colors[v] != coloring1.colors[neighbor]
                        @test coloring2.colors[v] != coloring2.colors[neighbor]
                    end
                end
            end

            @testset "Not-connected graph" begin
                adjacency_matrix = [
                    0 1 0 0 0 0
                    1 0 1 0 0 0
                    0 1 0 0 0 0
                    0 0 0 0 1 0
                    0 0 0 1 0 1
                    0 0 0 0 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                # Test coloring with different orders
                order1 = [1, 2, 3, 4, 5, 6]
                order2 = [6, 5, 4, 3, 2, 1]

                # Color the graph with different orders
                coloring1 = ParallelGraphs.greedy_coloring(graph, order1)
                coloring2 = ParallelGraphs.greedy_coloring(graph, order2)

                # Ensure all vertices are colored
                @test all(coloring1.colors .!= 0)
                @test all(coloring2.colors .!= 0)

                # Ensure the number of colors used is minimal
                @test coloring1.num_colors == 2
                @test coloring2.num_colors == 2

                # Ensure adjacent vertices have different colors
                for v in 1:nv(graph)
                    for neighbor in neighbors(graph, v)
                        @test coloring1.colors[v] != coloring1.colors[neighbor]
                        @test coloring2.colors[v] != coloring2.colors[neighbor]
                    end
                end
            end

            @testset "Basic directed graph" begin
                adjacency_matrix = [
                    0 1 0 0
                    0 0 1 0
                    0 0 0 1
                    0 1 0 0
                ]
                graph = SimpleDiGraph(adjacency_matrix)

                # Test coloring with different orders
                order1 = [1, 2, 3, 4]
                order2 = [4, 3, 2, 1]

                # Color the graph with different orders
                coloring1 = ParallelGraphs.greedy_coloring(graph, order1)
                coloring2 = ParallelGraphs.greedy_coloring(graph, order2)

                # Ensure all vertices are colored
                @test all(coloring1.colors .!= 0)
                @test all(coloring2.colors .!= 0)

                # Ensure the number of colors used is minimal
                @test coloring1.num_colors == 3
                @test coloring2.num_colors == 3

                # Ensure adjacent vertices have different colors
                for v in 1:nv(graph)
                    for neighbor in outneighbors(graph, v)
                        @test coloring1.colors[v] != coloring1.colors[neighbor]
                        @test coloring2.colors[v] != coloring2.colors[neighbor]
                    end
                end
            end
        end

        @testset "utils" begin
            # t_push!
            q = ParallelGraphs.ThreadQueue(Int, 5)
            @test ParallelGraphs.t_isempty(q)

            ParallelGraphs.t_push!(q, 1)
            @test !ParallelGraphs.t_isempty(q)
            @test ParallelGraphs.t_getindex(q, 1) == 1

            ParallelGraphs.t_push!(q, 2)
            ParallelGraphs.t_push!(q, 3)
            ParallelGraphs.t_push!(q, 4)
            ParallelGraphs.t_push!(q, 5)

            #TODO in utils.jl: @test_throws MethodError ParallelGraphs.t_push!(q, 6) # Queue is full

            # t_popfirst!
            q = ParallelGraphs.ThreadQueue(Int, 5)
            ParallelGraphs.t_push!(q, 1)
            ParallelGraphs.t_push!(q, 2)
            ParallelGraphs.t_push!(q, 3)

            @test ParallelGraphs.t_popfirst!(q) == 1
            @test ParallelGraphs.t_popfirst!(q) == 2
            @test ParallelGraphs.t_popfirst!(q) == 3

            #TODO in utils.jl: @test_throws BoundsError ParallelGraphs.t_popfirst!(q) # Queue is empty

            # t_isempty
            q = ParallelGraphs.ThreadQueue(Int, 5)
            @test ParallelGraphs.t_isempty(q)

            ParallelGraphs.t_push!(q, 1)
            @test !ParallelGraphs.t_isempty(q)

            ParallelGraphs.t_popfirst!(q)
            @test ParallelGraphs.t_isempty(q)
        end
    end
end
