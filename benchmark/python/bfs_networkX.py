import networkx as nx
import csv
import time

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
    start_time = time.time()
    bfs_tree = nx.bfs_tree(graph, start_node)
    end_time = time.time()
    return end_time - start_time


if __name__ == "__main__":

    # roads.csv
    filepath = "benchmark/data/roads.csv" # "../data/roads.csv" if run from python folder
    print(f"Loading graph from {filepath}...")
    graph = load_graph_from_csv(filepath)
    start_node = "140000"
    if start_node not in graph.nodes():
        print(f"Node {start_node} not found in the graph.")
        exit()
    print(f"Running BFS on {filepath} with {graph.number_of_nodes()} nodes from node {start_node}...")
    bfs_time = bfs_benchmark(graph, start_node)
    print(f"BFS benchmark completed, execution time: {bfs_time}  seconds")

    # twitch user
    filepath = "benchmark/data/large_twitch_edges.csv" # "../data/roads.csv" if run from python folder
    print(f"Loading graph from {filepath}...")
    graph = load_graph_from_csv(filepath)
    start_node = "0"
    if start_node not in graph.nodes():
        print(f"Node {start_node} not found in the graph.")
        exit()
    print(f"Running BFS on {filepath} with {graph.number_of_nodes()} nodes from node {start_node}...")
    bfs_time = bfs_benchmark(graph, start_node)
    print(f"BFS benchmark completed, execution time: {bfs_time}  seconds")
