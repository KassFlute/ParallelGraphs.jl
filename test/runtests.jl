using Aqua
using JET
using JuliaFormatter
using ParallelGraphs
using Test

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

        @testset "BFS sequential" begin
            adjacency_matrix = [
                0 1 1 0
                1 0 0 1
                1 0 0 1
                0 1 1 0
            ]
            graph = SimpleGraph(adjacency_matrix)

            expected_order = [1, 2, 3, 4]
            @test bfs(graph, 1) == expected_order
            expected_order = [2, 1, 4, 3]
            @test bfs(graph, 2) == expected_order
            expected_order = [3, 1, 4, 2]
            @test bfs(graph, 3) == expected_order
            expected_order = [4, 2, 3, 1]
            @test bfs(graph, 4) == expected_order
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
            @test bfs_par(graph, 1) == expected_order
            expected_order = [2, 1, 4, 3]
            @test bfs_par(graph, 2) == expected_order
            expected_order = [3, 1, 4, 2]
            @test bfs_par(graph, 3) == expected_order
            expected_order = [4, 2, 3, 1]
            @test bfs_par(graph, 4) == expected_order
        end
    end
end
