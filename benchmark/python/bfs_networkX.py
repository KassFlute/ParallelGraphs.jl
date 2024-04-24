import networkx as nx
import csv
import timeit

def load_graph_from_csv(filepath):
    """
    Load graph from a CSV file.
    """
    G = nx.Graph()
    with open(filepath, 'r') as file:
        reader = csv.reader(file)
        for row in reader:
            if len(row) == 2:
                node1, node2 = row
                G.add_edge(node1, node2)
    return G

def bfs_benchmark(graph, start_node):
    """
    Benchmark the speed of BFS on the given graph starting from a specified node.
    """
    def bfs():
        return nx.bfs_tree(graph, start_node)
    
    time_taken = timeit.timeit(bfs, number=2)  # run more for more precision
    return time_taken

def run_bfs_benchmark(filepath, start_node):
    """
    Load graph from CSV file and run BFS benchmark.
    """
    print(f"Loading graph from {filepath}...")
    graph = load_graph_from_csv(filepath)
    if start_node not in graph.nodes():
        print(f"Node {start_node} not found in the graph.")
        return
    print(f"Running BFS on {filepath} with {graph.number_of_nodes()} nodes from node {start_node}...")
    bfs_time = bfs_benchmark(graph, start_node)
    print(f"BFS benchmark completed, execution time: {bfs_time} seconds")

if __name__ == "__main__":
    # roads.csv
    run_bfs_benchmark("benchmark/data/roads.csv", "140000")

    # twitch user
    run_bfs_benchmark("benchmark/data/large_twitch_edges.csv", "0")
