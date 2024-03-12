using Aqua
using JET
using JuliaFormatter
using Test

using ParallelGraphs
using Graphs

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
        @test return_true() == true
        @test return_false() == false

        @testset "Empty graph" begin
            graph = SimpleGraph(0)
            @test bfs_seq(graph, 0) == []
            @test bfs_par(graph, 0) == []
        end

        @testset "BFS sequential" begin
            @testset "Undirected graph" begin
                # Empty graph
                graph = SimpleGraph(0)
                @test bfs_seq(graph, 0) == []

                # Basic undirected graph
                adjacency_matrix = [
                    0 1 1 0
                    1 0 0 1
                    1 0 0 1
                    0 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                expected_parents_1 = [1, 1, 1, 2]
                expected_parents_2 = [1, 1, 1, 3]
                res = bfs_seq(graph, 1)
                @test res == expected_parents_1 || res == expected_parents_2

                expected_parents_1 = [2, 2, 1, 2]
                expected_parents_2 = [2, 2, 4, 2]
                res = bfs_seq(graph, 2)
                @test res == expected_parents_1 || res == expected_parents_2

                # Not-connected graph
                adjacency_matrix = [
                    0 1 0 0 0 0
                    1 0 1 0 0 0
                    0 1 0 0 0 0
                    0 0 0 0 1 0
                    0 0 0 1 0 1
                    0 0 0 0 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                expected_parents_1 = [1, 1, 2, 0, 0, 0]
                res = bfs_seq(graph, 1)
                @test res == expected_parents_1

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
            @testset "Undirected graph" begin
                # Empty graph
                graph = SimpleGraph(0)
                @test bfs_par(graph, 0) == []

                # Basic undirected graph
                adjacency_matrix = [
                    0 1 1 0
                    1 0 0 1
                    1 0 0 1
                    0 1 1 0
                ]
                graph = SimpleGraph(adjacency_matrix)

                expected_parents_1 = [1, 1, 1, 2]
                expected_parents_2 = [1, 1, 1, 3]
                res = bfs_par(graph, 1)
                @test res == expected_parents_1 || res == expected_parents_2

                expected_parents_1 = [2, 2, 1, 2]
                expected_parents_2 = [2, 2, 4, 2]
                res = bfs_par(graph, 2)
                @test res == expected_parents_1 || res == expected_parents_2

                # Not-connected graph
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

                expected_parents_1 = [1, 1, 2, 0, 0, 0, 0, 0]
                res = bfs_seq(graph, 1)
                @test res == expected_parents_1

                expected_parents_1 = [0, 0, 0, 4, 4, 5, 5, 7]
                expected_parents_2 = [0, 0, 0, 4, 4, 5, 5, 6]

                res = bfs_par(graph, 4)
                @test (res == expected_parents_1) ⊻ (res == expected_parents_2) # XOR to check that only one is true

                # Complicated undirected graph
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
                #println(histogram) the results varies depending on execution, so multithreading is working
                @test counter == 100
                if equality
                    @warn "Some results that should be unpredictable are always identical. Test environnement is probably not configured correctly for multi-threading"
                end
            end

            @testset "Directed Graphs" begin
                # Empty graph
                graph = SimpleDiGraph(0)
                @test bfs_par(graph, 0) == []

                # Simple directed graph
                adjacency_matrix = [
                    0 1 0 0
                    0 0 1 0
                    0 0 0 1
                    0 1 0 0
                ]
                graph = SimpleDiGraph(adjacency_matrix)

                expected_parents_1 = [1, 1, 2, 3]
                res = bfs_par(graph, 1)
                @test res == expected_parents_1

                expected_parents_1 = [0, 2, 2, 3]
                res = bfs_par(graph, 2)
                @test res == expected_parents_1

                # More complicated directed graph
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
                res = bfs_par(graph, 1)

                expected_parents_1 = [1, 1, 2, 3, 4, 5, 6, 4, 8, 9, 7, 10, 0, 7]
                expected_parents_2 = [1, 1, 2, 3, 4, 5, 6, 4, 8, 9, 10, 10, 0, 7]
                @test (res == expected_parents_1) ⊻ (res == expected_parents_2)
            end
        end
    end
end
