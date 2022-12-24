from dijkstar import Graph, find_path

def makeGraph(airports):
    graph = Graph()
    for airport in airports:
        for connection in airport.connections:
            graph.add_edge(airport.id, connection['id'], int(connection['miles']))
    return graph

def shortest_distance(graph, origin, destination):
    return find_path(graph, origin, destination)