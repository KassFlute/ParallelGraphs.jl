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
    end
end
