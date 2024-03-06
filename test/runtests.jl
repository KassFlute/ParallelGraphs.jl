using Aqua
#using JET
using JuliaFormatter
using ParallelGraphs
using Test

@testset verbose = true "ParallelGraphs.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(ParallelGraphs; ambiguities=false)
    end
    # @testset "JET" begin
    #     JET.test_package(ParallelGraphs; target_defined_modules=true)
    # end
    @testset "JuliaFormatter" begin
        @test JuliaFormatter.format(ParallelGraphs; overwrite=false)
    end
    @testset "Actual tests" begin
        @test return_true() == true
        @test return_false() == false

        @testset "BFS sequential" begin
            adjacency_matrix = [
                0 1 1 0
                1 0 0 1
                1 0 0 1
                0 1 1 0
            ]
            graph = SimpleGraph(adjacency_matrix)

            expected_order = [1, 2, 3, 4]
            #@test bfs_seq(graph, 1) == expected_order
            expected_order = [2, 1, 4, 3]
            #@test bfs_seq(graph, 2) == expected_order
            expected_order = [3, 1, 4, 2]
            #@test bfs_seq(graph, 3) == expected_order
            expected_order = [4, 2, 3, 1]
            #@test bfs_seq(graph, 4) == expected_order
        end

        @testset "BFS parallel" begin
            adjacency_matrix = [
                0 1 1 0
                1 0 0 1
                1 0 0 1
                0 1 1 0
            ]
            graph = SimpleGraph(adjacency_matrix)

            expected_order = [1, 2, 3, 4]
            #@test bfs_par(graph, 1) == expected_order
            expected_order = [2, 1, 4, 3]
            #@test bfs_par(graph, 2) == expected_order
            expected_order = [3, 1, 4, 2]
            #@test bfs_par(graph, 3) == expected_order
            expected_order = [4, 2, 3, 1]
            #@test bfs_par(graph, 4) == expected_order
        end
        @testset "BFS sequential Tree" begin
            adjacency_matrix = [
                0 1 1 0
                1 0 0 1
                1 0 0 1
                0 1 1 0
            ]
            graph = SimpleGraph(adjacency_matrix)

            expected_parents_1 = [1, 1, 1, 2]
            expected_parents_2 = [1, 1, 1, 3]
            res = bfs_seq_tree(graph, 1)
            @test res == expected_parents_1 || res == expected_parents_2

            expected_parents_1 = [2, 2, 1, 2]
            expected_parents_2 = [2, 2, 4, 2]
            res = bfs_seq_tree(graph, 2)
            @test res == expected_parents_1 || res == expected_parents_2
        end
        @testset "BFS Parallel Tree" begin
            adjacency_matrix = [
                0 1 1 0
                1 0 0 1
                1 0 0 1
                0 1 1 0
            ]
            graph = SimpleGraph(adjacency_matrix)

            expected_parents_1 = [1, 1, 1, 2]
            expected_parents_2 = [1, 1, 1, 3]
            res = bfs_par_tree(graph, 1)
            @test res == expected_parents_1 || res == expected_parents_2

            expected_parents_1 = [2, 2, 1, 2]
            expected_parents_2 = [2, 2, 4, 2]
            res = bfs_par_tree(graph, 2)
            @test res == expected_parents_1 || res == expected_parents_2
        end
    end
end
