include("benchmarks.jl")

print("Run benchmarks...")
results = run(SUITE)
println("OK")

print("Parse results...")
data = parse_results(results)
println("OK")

println("Plot results...")
plot_results(data)
println("FINISH")
