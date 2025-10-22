import Foundation

/// Tracks the navigation structure of the app as a graph
/// Nodes are screens, edges are transitions between screens
public class NavigationGraph: Codable, @unchecked Sendable {
    /// All screens in the graph, keyed by fingerprint
    public private(set) var nodes: [String: ScreenNode]

    /// All transitions between screens
    public private(set) var edges: [ScreenEdge]

    /// The fingerprint of the screen shown at app launch
    public private(set) var startNode: String?

    /// The fingerprint of the current screen
    public private(set) var currentNode: String?

    /// Adjacency list for O(1) edge lookups (outgoing edges by source)
    private var outgoingEdges: [String: [ScreenEdge]] = [:]

    /// Adjacency list for O(1) edge lookups (incoming edges by destination)
    private var incomingEdges: [String: [ScreenEdge]] = [:]

    public init() {
        self.nodes = [:]
        self.edges = []
        self.startNode = nil
        self.currentNode = nil
        self.outgoingEdges = [:]
        self.incomingEdges = [:]
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case nodes, edges, startNode, currentNode
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.nodes = try container.decode([String: ScreenNode].self, forKey: .nodes)
        self.edges = try container.decode([ScreenEdge].self, forKey: .edges)
        self.startNode = try container.decodeIfPresent(String.self, forKey: .startNode)
        self.currentNode = try container.decodeIfPresent(String.self, forKey: .currentNode)

        // Rebuild adjacency lists from edges
        self.outgoingEdges = [:]
        self.incomingEdges = [:]
        rebuildAdjacencyLists()
    }

    /// Rebuilds the adjacency lists from the edges array
    private func rebuildAdjacencyLists() {
        outgoingEdges.removeAll()
        incomingEdges.removeAll()

        for edge in edges {
            outgoingEdges[edge.from, default: []].append(edge)
            incomingEdges[edge.to, default: []].append(edge)
        }
    }

    // MARK: - Adding Nodes and Edges

    /// Add a screen to the graph or update visit count if it already exists
    /// - Parameter node: The screen node to add
    /// - Returns: True if this is a new screen, false if we've seen it before
    @discardableResult
    public func addNode(_ node: ScreenNode) -> Bool {
        if var existingNode = nodes[node.fingerprint] {
            // Update visit count and last visited
            existingNode.visitCount += 1
            existingNode.lastVisited = Date()
            nodes[node.fingerprint] = existingNode
            return false
        } else {
            nodes[node.fingerprint] = node

            // If this is the first node, mark it as the start
            if startNode == nil {
                startNode = node.fingerprint
            }

            return true
        }
    }

    /// Add a transition between two screens
    /// - Parameters:
    ///   - from: Source screen fingerprint
    ///   - to: Destination screen fingerprint
    ///   - action: The action that caused the transition
    ///   - duration: How long the transition took
    public func addTransition(
        from: String,
        to: String,
        action: Action,
        duration: TimeInterval
    ) {
        let edge = ScreenEdge(
            from: from,
            to: to,
            action: action,
            duration: duration
        )
        edges.append(edge)

        // Update adjacency lists for O(1) lookups
        outgoingEdges[from, default: []].append(edge)
        incomingEdges[to, default: []].append(edge)

        // Update current node
        currentNode = to
    }

    // MARK: - Querying the Graph

    /// Get a screen by its fingerprint
    public func getNode(_ fingerprint: String) -> ScreenNode? {
        return nodes[fingerprint]
    }

    /// Get all edges originating from a screen (O(1) lookup)
    public func getOutgoingEdges(from fingerprint: String) -> [ScreenEdge] {
        return outgoingEdges[fingerprint] ?? []
    }

    /// Get all edges leading to a screen (O(1) lookup)
    public func getIncomingEdges(to fingerprint: String) -> [ScreenEdge] {
        return incomingEdges[fingerprint] ?? []
    }

    /// Check if we've already visited a screen
    public func hasVisited(_ fingerprint: String) -> Bool {
        return nodes[fingerprint] != nil
    }

    /// Get the visit count for a screen
    public func getVisitCount(for fingerprint: String) -> Int {
        return nodes[fingerprint]?.visitCount ?? 0
    }

    // MARK: - Cycle Detection

    /// Find all cycles in the graph using DFS
    /// - Returns: Array of cycles, where each cycle is an array of screen fingerprints
    public func findCycles() -> [[String]] {
        var cycles: [[String]] = []
        var visited: Set<String> = []
        var recursionStack: Set<String> = []

        func dfs(_ nodeId: String, path: [String]) {
            if recursionStack.contains(nodeId) {
                // Found a cycle - extract it from the path
                if let startIndex = path.firstIndex(of: nodeId) {
                    let cycle = Array(path[startIndex...])
                    cycles.append(cycle)
                }
                return
            }

            if visited.contains(nodeId) {
                return
            }

            visited.insert(nodeId)
            recursionStack.insert(nodeId)

            var newPath = path
            newPath.append(nodeId)

            // Visit all neighbors (O(1) lookup)
            for edge in outgoingEdges[nodeId] ?? [] {
                dfs(edge.to, path: newPath)
            }

            recursionStack.remove(nodeId)
        }

        // Run DFS from all nodes
        for nodeId in nodes.keys {
            if !visited.contains(nodeId) {
                dfs(nodeId, path: [])
            }
        }

        return cycles
    }

    /// Check if adding an edge would create a cycle
    public func wouldCreateCycle(from: String, to: String) -> Bool {
        // If 'to' can reach 'from', then adding 'from' -> 'to' creates a cycle
        return canReach(from: to, to: from)
    }

    /// Check if there's a path from one screen to another
    private func canReach(from: String, to: String) -> Bool {
        var visited: Set<String> = []
        var queue: [String] = [from]

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if current == to {
                return true
            }

            if visited.contains(current) {
                continue
            }

            visited.insert(current)

            // Add all neighbors to queue (O(1) lookup)
            for edge in outgoingEdges[current] ?? [] {
                queue.append(edge.to)
            }
        }

        return false
    }

    // MARK: - Shortest Path (Dijkstra's Algorithm)

    /// Find the shortest path between two screens
    /// - Parameters:
    ///   - from: Starting screen fingerprint
    ///   - to: Destination screen fingerprint
    /// - Returns: Array of actions to reach the destination, or nil if no path exists
    public func shortestPath(from: String, to: String) -> [Action]? {
        var distances: [String: TimeInterval] = [:]
        var previous: [String: (String, Action)] = [:]
        var unvisited: Set<String> = Set(nodes.keys)

        distances[from] = 0

        while !unvisited.isEmpty {
            // Find unvisited node with minimum distance
            guard let current = unvisited.min(by: { distances[$0] ?? .infinity < distances[$1] ?? .infinity }) else {
                break
            }

            if current == to {
                break  // Found shortest path
            }

            unvisited.remove(current)

            let currentDistance = distances[current] ?? .infinity

            // Check all neighbors (O(1) lookup)
            for edge in outgoingEdges[current] ?? [] {
                let alt = currentDistance + edge.duration

                if alt < (distances[edge.to] ?? .infinity) {
                    distances[edge.to] = alt
                    previous[edge.to] = (current, edge.action)
                }
            }
        }

        // Reconstruct path
        guard previous[to] != nil else {
            return nil  // No path found
        }

        var path: [Action] = []
        var current = to

        while let (prev, action) = previous[current] {
            path.insert(action, at: 0)
            current = prev

            if current == from {
                break
            }
        }

        return path
    }

    // MARK: - Coverage Statistics

    /// Get coverage statistics for the exploration
    public func coverageStats() -> CoverageStats {
        let totalScreens = nodes.count
        let exploredScreens = nodes.values.filter { $0.visitCount > 0 }.count
        let averageDepth = nodes.values.isEmpty ? 0.0 :
            Double(nodes.values.map { $0.depth }.reduce(0, +)) / Double(nodes.count)

        return CoverageStats(
            totalScreens: totalScreens,
            exploredScreens: exploredScreens,
            coveragePercentage: totalScreens > 0 ? (Double(exploredScreens) / Double(totalScreens)) * 100 : 0,
            totalEdges: edges.count,
            averageDepth: averageDepth
        )
    }

    // MARK: - Export

    /// Export graph as Mermaid diagram
    public func exportAsMermaid() -> String {
        var mermaid = "graph TD\n"

        for edge in edges {
            guard let fromNode = nodes[edge.from],
                  let toNode = nodes[edge.to] else {
                continue
            }

            let fromLabel = fromNode.screenType?.rawValue ?? "Screen"
            let toLabel = toNode.screenType?.rawValue ?? "Screen"
            let actionLabel = edge.action.type.rawValue

            let fromId = edge.from.prefix(6)
            let toId = edge.to.prefix(6)

            if let target = edge.action.targetElement {
                mermaid += "    \(fromId)[\(fromLabel)] -->|\(actionLabel): \(target)| \(toId)[\(toLabel)]\n"
            } else {
                mermaid += "    \(fromId)[\(fromLabel)] -->|\(actionLabel)| \(toId)[\(toLabel)]\n"
            }
        }

        return mermaid
    }

    /// Export graph as JSON
    public func exportAsJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

/// Coverage statistics for the navigation graph
public struct CoverageStats: Codable, Sendable {
    public let totalScreens: Int
    public let exploredScreens: Int
    public let coveragePercentage: Double
    public let totalEdges: Int
    public let averageDepth: Double

    public init(
        totalScreens: Int,
        exploredScreens: Int,
        coveragePercentage: Double,
        totalEdges: Int,
        averageDepth: Double
    ) {
        self.totalScreens = totalScreens
        self.exploredScreens = exploredScreens
        self.coveragePercentage = coveragePercentage
        self.totalEdges = totalEdges
        self.averageDepth = averageDepth
    }
}
