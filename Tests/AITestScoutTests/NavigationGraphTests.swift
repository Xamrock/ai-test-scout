import Testing
import Foundation
@testable import AITestScout

@Suite("NavigationGraph Tests")
struct NavigationGraphTests {

    // MARK: - Basic Graph Operations

    @Test("Empty graph initialization")
    func testEmptyGraph() {
        let graph = NavigationGraph()

        #expect(graph.nodes.isEmpty)
        #expect(graph.edges.isEmpty)
        #expect(graph.startNode == nil)
        #expect(graph.currentNode == nil)
    }

    @Test("Add first node sets it as start node")
    func testAddFirstNode() {
        let graph = NavigationGraph()
        let node = createTestNode(fingerprint: "screen1", depth: 0)

        let isNew = graph.addNode(node)

        #expect(isNew == true)
        #expect(graph.startNode == "screen1")
        #expect(graph.nodes.count == 1)
        #expect(graph.getNode("screen1") != nil)
    }

    @Test("Add duplicate node increments visit count")
    func testAddDuplicateNode() {
        let graph = NavigationGraph()
        let node = createTestNode(fingerprint: "screen1", depth: 0)

        let isNew1 = graph.addNode(node)
        let isNew2 = graph.addNode(node)

        #expect(isNew1 == true)
        #expect(isNew2 == false)
        #expect(graph.nodes.count == 1)
        #expect(graph.getVisitCount(for: "screen1") == 2)
    }

    @Test("Add transition between screens")
    func testAddTransition() {
        let graph = NavigationGraph()
        let node1 = createTestNode(fingerprint: "screen1", depth: 0)
        let node2 = createTestNode(fingerprint: "screen2", depth: 1)

        graph.addNode(node1)
        graph.addNode(node2)

        let action = Action(type: .tap, targetElement: "button1", reasoning: "Test tap")
        graph.addTransition(from: "screen1", to: "screen2", action: action, duration: 0.5)

        #expect(graph.edges.count == 1)
        #expect(graph.currentNode == "screen2")
        #expect(graph.edges[0].from == "screen1")
        #expect(graph.edges[0].to == "screen2")
        #expect(graph.edges[0].duration == 0.5)
    }

    @Test("Get outgoing edges from a node")
    func testGetOutgoingEdges() {
        let graph = NavigationGraph()
        let node1 = createTestNode(fingerprint: "screen1", depth: 0)
        let node2 = createTestNode(fingerprint: "screen2", depth: 1)
        let node3 = createTestNode(fingerprint: "screen3", depth: 1)

        graph.addNode(node1)
        graph.addNode(node2)
        graph.addNode(node3)

        let action1 = Action(type: .tap, targetElement: "button1", reasoning: "Go to screen2")
        let action2 = Action(type: .tap, targetElement: "button2", reasoning: "Go to screen3")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 0.5)
        graph.addTransition(from: "screen1", to: "screen3", action: action2, duration: 0.5)

        let outgoing = graph.getOutgoingEdges(from: "screen1")

        #expect(outgoing.count == 2)
        #expect(outgoing.contains { $0.to == "screen2" })
        #expect(outgoing.contains { $0.to == "screen3" })
    }

    @Test("Get incoming edges to a node")
    func testGetIncomingEdges() {
        let graph = NavigationGraph()
        let node1 = createTestNode(fingerprint: "screen1", depth: 0)
        let node2 = createTestNode(fingerprint: "screen2", depth: 1)
        let node3 = createTestNode(fingerprint: "screen3", depth: 1)

        graph.addNode(node1)
        graph.addNode(node2)
        graph.addNode(node3)

        let action1 = Action(type: .tap, targetElement: "button1", reasoning: "Go to screen3")
        let action2 = Action(type: .tap, targetElement: "button2", reasoning: "Go to screen3")

        graph.addTransition(from: "screen1", to: "screen3", action: action1, duration: 0.5)
        graph.addTransition(from: "screen2", to: "screen3", action: action2, duration: 0.5)

        let incoming = graph.getIncomingEdges(to: "screen3")

        #expect(incoming.count == 2)
        #expect(incoming.contains { $0.from == "screen1" })
        #expect(incoming.contains { $0.from == "screen2" })
    }

    @Test("Has visited screen")
    func testHasVisited() {
        let graph = NavigationGraph()
        let node1 = createTestNode(fingerprint: "screen1", depth: 0)

        #expect(graph.hasVisited("screen1") == false)

        graph.addNode(node1)

        #expect(graph.hasVisited("screen1") == true)
        #expect(graph.hasVisited("screen2") == false)
    }

    // MARK: - Cycle Detection

    @Test("Detect simple cycle")
    func testDetectSimpleCycle() {
        let graph = NavigationGraph()

        // Create cycle: screen1 -> screen2 -> screen1
        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))

        let action1 = Action(type: .tap, targetElement: "button1", reasoning: "Go to screen2")
        let action2 = Action(type: .tap, targetElement: "button2", reasoning: "Back to screen1")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 0.5)
        graph.addTransition(from: "screen2", to: "screen1", action: action2, duration: 0.5)

        let cycles = graph.findCycles()

        #expect(cycles.count >= 1)
        #expect(cycles.contains { $0.contains("screen1") && $0.contains("screen2") })
    }

    @Test("Detect complex cycle")
    func testDetectComplexCycle() {
        let graph = NavigationGraph()

        // Create cycle: screen1 -> screen2 -> screen3 -> screen1
        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen3", depth: 2))

        let action1 = Action(type: .tap, reasoning: "Go to screen2")
        let action2 = Action(type: .tap, reasoning: "Go to screen3")
        let action3 = Action(type: .tap, reasoning: "Back to screen1")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 0.5)
        graph.addTransition(from: "screen2", to: "screen3", action: action2, duration: 0.5)
        graph.addTransition(from: "screen3", to: "screen1", action: action3, duration: 0.5)

        let cycles = graph.findCycles()

        #expect(cycles.count >= 1)
        let hasCycle = cycles.contains { cycle in
            cycle.contains("screen1") && cycle.contains("screen2") && cycle.contains("screen3")
        }
        #expect(hasCycle)
    }

    @Test("No cycles in linear graph")
    func testNoCyclesInLinearGraph() {
        let graph = NavigationGraph()

        // Create linear path: screen1 -> screen2 -> screen3
        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen3", depth: 2))

        let action1 = Action(type: .tap, reasoning: "Go to screen2")
        let action2 = Action(type: .tap, reasoning: "Go to screen3")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 0.5)
        graph.addTransition(from: "screen2", to: "screen3", action: action2, duration: 0.5)

        let cycles = graph.findCycles()

        #expect(cycles.isEmpty)
    }

    @Test("Would create cycle check")
    func testWouldCreateCycle() {
        let graph = NavigationGraph()

        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))

        let action = Action(type: .tap, reasoning: "Go to screen2")
        graph.addTransition(from: "screen1", to: "screen2", action: action, duration: 0.5)

        // Adding screen2 -> screen1 would create a cycle
        #expect(graph.wouldCreateCycle(from: "screen2", to: "screen1") == true)

        // Adding screen2 -> screen3 would not create a cycle
        #expect(graph.wouldCreateCycle(from: "screen2", to: "screen3") == false)
    }

    // MARK: - Shortest Path

    @Test("Find shortest path in linear graph")
    func testShortestPathLinear() {
        let graph = NavigationGraph()

        // Create linear path: screen1 -> screen2 -> screen3
        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen3", depth: 2))

        let action1 = Action(type: .tap, targetElement: "button1", reasoning: "Go to screen2")
        let action2 = Action(type: .tap, targetElement: "button2", reasoning: "Go to screen3")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 0.5)
        graph.addTransition(from: "screen2", to: "screen3", action: action2, duration: 0.5)

        let path = graph.shortestPath(from: "screen1", to: "screen3")

        #expect(path != nil)
        #expect(path?.count == 2)
        #expect(path?[0].targetElement == "button1")
        #expect(path?[1].targetElement == "button2")
    }

    @Test("Find shortest path with multiple routes")
    func testShortestPathMultipleRoutes() {
        let graph = NavigationGraph()

        // Create graph:
        // screen1 -> screen2 -> screen4 (total: 2.0)
        // screen1 -> screen3 -> screen4 (total: 1.0) - shorter!
        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen3", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen4", depth: 2))

        let action1 = Action(type: .tap, reasoning: "Route 1 to screen2")
        let action2 = Action(type: .tap, reasoning: "Route 1 to screen4")
        let action3 = Action(type: .tap, reasoning: "Route 2 to screen3")
        let action4 = Action(type: .tap, reasoning: "Route 2 to screen4")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 1.0)
        graph.addTransition(from: "screen2", to: "screen4", action: action2, duration: 1.0)
        graph.addTransition(from: "screen1", to: "screen3", action: action3, duration: 0.3)
        graph.addTransition(from: "screen3", to: "screen4", action: action4, duration: 0.3)

        let path = graph.shortestPath(from: "screen1", to: "screen4")

        #expect(path != nil)
        #expect(path?.count == 2)
        // Should take the shorter route through screen3
        #expect(path?[0].reasoning.contains("screen3") == true)
    }

    @Test("No path exists")
    func testNoPathExists() {
        let graph = NavigationGraph()

        // Create disconnected graph
        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen3", depth: 0))

        let action = Action(type: .tap, reasoning: "Go to screen2")
        graph.addTransition(from: "screen1", to: "screen2", action: action, duration: 0.5)

        // screen3 is disconnected
        let path = graph.shortestPath(from: "screen1", to: "screen3")

        #expect(path == nil)
    }

    // MARK: - Coverage Statistics

    @Test("Coverage statistics for empty graph")
    func testCoverageStatsEmpty() {
        let graph = NavigationGraph()
        let stats = graph.coverageStats()

        #expect(stats.totalScreens == 0)
        #expect(stats.exploredScreens == 0)
        #expect(stats.coveragePercentage == 0.0)
        #expect(stats.totalEdges == 0)
        #expect(stats.averageDepth == 0.0)
    }

    @Test("Coverage statistics with screens")
    func testCoverageStatsWithScreens() {
        let graph = NavigationGraph()

        graph.addNode(createTestNode(fingerprint: "screen1", depth: 0))
        graph.addNode(createTestNode(fingerprint: "screen2", depth: 1))
        graph.addNode(createTestNode(fingerprint: "screen3", depth: 2))

        let action1 = Action(type: .tap, reasoning: "Go to screen2")
        let action2 = Action(type: .tap, reasoning: "Go to screen3")

        graph.addTransition(from: "screen1", to: "screen2", action: action1, duration: 0.5)
        graph.addTransition(from: "screen2", to: "screen3", action: action2, duration: 0.5)

        let stats = graph.coverageStats()

        #expect(stats.totalScreens == 3)
        #expect(stats.exploredScreens == 3)
        #expect(stats.coveragePercentage == 100.0)
        #expect(stats.totalEdges == 2)
        #expect(stats.averageDepth == 1.0) // (0 + 1 + 2) / 3
    }

    // MARK: - Export

    @Test("Export as Mermaid diagram")
    func testExportAsMermaid() {
        let graph = NavigationGraph()

        let node1 = createTestNode(fingerprint: "screen1", screenType: .login, depth: 0)
        let node2 = createTestNode(fingerprint: "screen2", screenType: .list, depth: 1)

        graph.addNode(node1)
        graph.addNode(node2)

        let action = Action(type: .tap, targetElement: "loginButton", reasoning: "Login")
        graph.addTransition(from: "screen1", to: "screen2", action: action, duration: 0.5)

        let mermaid = graph.exportAsMermaid()

        #expect(mermaid.contains("graph TD"))
        #expect(mermaid.contains("login"))
        #expect(mermaid.contains("list"))
        #expect(mermaid.contains("tap"))
        #expect(mermaid.contains("loginButton"))
    }

    @Test("Export as JSON")
    func testExportAsJSON() throws {
        let graph = NavigationGraph()

        let node1 = createTestNode(fingerprint: "screen1", depth: 0)
        graph.addNode(node1)

        let jsonData = try graph.exportAsJSON()

        #expect(jsonData.count > 0)

        // Verify it can be decoded back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NavigationGraph.self, from: jsonData)

        #expect(decoded.nodes.count == 1)
        #expect(decoded.nodes["screen1"] != nil)
    }

    // MARK: - Helper Functions

    private func createTestNode(
        fingerprint: String,
        screenType: ScreenType? = nil,
        depth: Int
    ) -> ScreenNode {
        let element = MinimalElement(
            type: .button,
            id: "testButton",
            label: "Test",
            interactive: true,
            value: nil,
            intent: nil,
            priority: nil,
            children: []
        )

        return ScreenNode(
            fingerprint: fingerprint,
            screenType: screenType,
            elements: [element],
            screenshot: Data(),
            depth: depth
        )
    }
}
