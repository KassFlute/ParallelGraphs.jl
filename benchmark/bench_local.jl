include("benchmarks.jl")

print("Run benchmarks...")
results = run(SUITE, verbose=true)
println("OK")

print("Parse results...")
data = parse_results(results)
colors = parse_colors()
println("OK")

println("Plot results...")
plot_BFS_results(data)
plot_coloring_results(data, colors)
println("FINISH")
