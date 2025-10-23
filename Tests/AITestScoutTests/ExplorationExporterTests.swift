import Testing
import Foundation
@testable import AITestScout

@Suite("ExplorationExporter Tests")
struct ExplorationExporterTests {

    // MARK: - Test Fixtures

    /// Creates a sample exploration path for testing
    private func makeSamplePath(
        goal: String = "Test exploration",
        stepCount: Int = 0,
        successfulSteps: Int = 0
    ) -> ExplorationPath {
        let path = ExplorationPath(goal: goal, sessionId: UUID())

        for i in 0..<stepCount {
            let isSuccessful = i < successfulSteps
            let step = ExplorationStep(
                action: i % 3 == 0 ? "tap" : (i % 3 == 1 ? "type" : "swipe"),
                targetElement: i % 3 == 2 ? nil : "element\(i)",
                textTyped: i % 3 == 1 ? "test\(i)@example.com" : nil,
                screenDescription: "Screen \(i / 2)",
                interactiveElementCount: 3 + i,
                reasoning: "Step \(i) reasoning",
                confidence: 70 + (i * 5) % 30,
                wasSuccessful: isSuccessful
            )
            path.addStep(step)
        }

        return path
    }

    /// Creates a sample navigation graph for testing
    private func makeSampleGraph(screenCount: Int = 0) -> NavigationGraph {
        let graph = NavigationGraph()

        for i in 0..<screenCount {
            let node = ScreenNode(
                fingerprint: "screen\(i)",
                screenType: i == 0 ? .login : .content,
                elements: [],
                screenshot: Data(),
                depth: i,
                parentFingerprint: i > 0 ? "screen\(i-1)" : nil
            )
            graph.addNode(node)
        }

        return graph
    }

    // MARK: - Initialization

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationExporter initializes successfully")
    func initialization() {
        _ = ExplorationExporter()
        // If we get here, initialization succeeded
    }

    // MARK: - Comprehensive JSON Export

    @Suite("Comprehensive JSON Export")
    struct ComprehensiveExportTests {

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Exports valid JSON structure")
        func validJSONStructure() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(stepCount: 2)
            let graph = ExplorationExporterTests().makeSampleGraph(screenCount: 1)

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            #expect(data.count > 0)

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )

            #expect(json["exportFormat"] as? String == "aitestscout-exploration-v1")
            #expect(json["exportedAt"] != nil)
            #expect(json["session"] != nil)
            #expect(json["explorationSteps"] != nil)
            #expect(json["navigationGraph"] != nil)
            #expect(json["insights"] != nil)
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Session info contains correct data", arguments: [
            ("Simple goal", 0, 0),
            ("Complex exploration", 5, 3),
            ("All failures", 10, 0),
            ("Perfect run", 8, 8)
        ])
        func sessionInfo(goal: String, totalSteps: Int, successfulSteps: Int) throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(
                goal: goal,
                stepCount: totalSteps,
                successfulSteps: successfulSteps
            )
            let graph = NavigationGraph()

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let session = try #require(json["session"] as? [String: Any])

            #expect(session["goal"] as? String == goal)
            #expect(session["totalSteps"] as? Int == totalSteps)
            #expect(session["successfulSteps"] as? Int == successfulSteps)
            #expect(session["failedSteps"] as? Int == totalSteps - successfulSteps)
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Exploration steps are exported correctly", arguments: [0, 1, 5, 10])
        func explorationSteps(stepCount: Int) throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(stepCount: stepCount)
            let graph = NavigationGraph()

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let steps = try #require(json["explorationSteps"] as? [[String: Any]])

            #expect(steps.count == stepCount)

            if stepCount > 0 {
                let firstStep = steps[0]
                #expect(firstStep["action"] != nil)
                #expect(firstStep["reasoning"] != nil)
                #expect(firstStep["confidence"] != nil)
                #expect(firstStep["wasSuccessful"] != nil)
            }
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Navigation graph stats are included", arguments: [0, 1, 3, 5])
        func navigationGraphStats(screenCount: Int) throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = ExplorationExporterTests().makeSampleGraph(screenCount: screenCount)

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let navGraph = try #require(json["navigationGraph"] as? [String: Any])

            #expect(navGraph["totalScreens"] as? Int == screenCount)
            #expect(navGraph["totalTransitions"] as? Int == 0)
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Insights include performance and coverage")
        func insights() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(stepCount: 10, successfulSteps: 7)
            let graph = ExplorationExporterTests().makeSampleGraph(screenCount: 3)

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let insights = try #require(json["insights"] as? [String: Any])
            let performance = try #require(insights["performance"] as? [String: Any])
            let coverage = try #require(insights["coverage"] as? [String: Any])

            #expect(performance["totalSteps"] as? Int == 10)
            #expect(performance["successfulSteps"] as? Int == 7)
            #expect(performance["failedSteps"] as? Int == 3)

            #expect(coverage["totalScreens"] as? Int == 3)
            #expect(coverage["totalTransitions"] as? Int == 0)
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Metadata is included when provided")
        func metadata() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = NavigationGraph()

            let env = EnvironmentInfo(
                platform: "iOS",
                osVersion: "18.0",
                deviceModel: "iPhone 15 Pro",
                screenResolution: CGSize(width: 393, height: 852),
                orientation: "portrait",
                locale: "en_US"
            )
            let appContext = AppContext(
                bundleId: "com.test.app",
                appVersion: "1.0",
                buildNumber: "1"
            )
            let metadata = ExplorationMetadata(
                environment: env,
                elementContexts: [:],
                appContext: appContext
            )

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph,
                metadata: metadata
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let environment = try #require(json["environment"] as? [String: Any])
            let context = try #require(json["appContext"] as? [String: Any])

            #expect(environment["platform"] as? String == "iOS")
            #expect(environment["osVersion"] as? String == "18.0")
            #expect(environment["deviceModel"] as? String == "iPhone 15 Pro")

            #expect(context["bundleId"] as? String == "com.test.app")
            #expect(context["appVersion"] as? String == "1.0")
        }
    }

    // MARK: - Markdown Export

    @Suite("Markdown Export")
    struct MarkdownExportTests {

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Exports basic markdown structure")
        func basicStructure() {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(goal: "Test markdown")
            let graph = NavigationGraph()

            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph
            )

            #expect(markdown.contains("# Exploration Report"))
            #expect(markdown.contains("## Session Overview"))
            #expect(markdown.contains("## Coverage"))
            #expect(markdown.contains("## Exploration Steps"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Session overview contains goal", arguments: [
            "Simple test",
            "Complete registration flow",
            "Navigate through checkout"
        ])
        func sessionOverview(goal: String) {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(goal: goal)
            let graph = NavigationGraph()

            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph
            )

            #expect(markdown.contains("**Goal**: \(goal)"))
            #expect(markdown.contains("**Total Steps**:"))
            #expect(markdown.contains("**Success Rate**:"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Coverage stats are displayed", arguments: [0, 1, 3, 10])
        func coverageStats(screenCount: Int) {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = ExplorationExporterTests().makeSampleGraph(screenCount: screenCount)

            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph
            )

            #expect(markdown.contains("**Screens Discovered**: \(screenCount)"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Steps are listed with details", arguments: [
            ("tap", "loginButton", nil, true),
            ("type", "emailField", "test@example.com", true),
            ("swipe", nil, nil, false),
            ("tap", "submitBtn", nil, false)
        ])
        func stepListing(action: String, target: String?, text: String?, success: Bool) {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationPath(goal: "Test steps")

            let step = ExplorationStep(
                action: action,
                targetElement: target,
                textTyped: text,
                screenDescription: "Test screen",
                interactiveElementCount: 5,
                reasoning: "Test reasoning",
                confidence: 85,
                wasSuccessful: success
            )
            path.addStep(step)

            let graph = NavigationGraph()
            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph
            )

            // Check for success/failure indicator
            #expect(markdown.contains(success ? "✅" : "❌"))

            // Check for action
            #expect(markdown.contains("**\(action)**"))

            // Check for target if present
            if let target = target {
                #expect(markdown.contains("`\(target)`"))
            }

            // Check for text if present
            if let text = text {
                #expect(markdown.contains("`\(text)`"))
            }

            // Check for reasoning
            #expect(markdown.contains("Test reasoning"))

            // Check for confidence
            #expect(markdown.contains("Confidence: 85%"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Environment section is included when metadata provided")
        func environmentSection() {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = NavigationGraph()

            let env = EnvironmentInfo(
                platform: "iOS",
                osVersion: "18.0",
                deviceModel: "iPhone 15 Pro",
                screenResolution: CGSize(width: 393, height: 852),
                orientation: "portrait",
                locale: "en_US"
            )
            let appContext = AppContext(
                bundleId: "com.test.app",
                appVersion: "1.0",
                buildNumber: "1"
            )
            let metadata = ExplorationMetadata(
                environment: env,
                elementContexts: [:],
                appContext: appContext
            )

            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph,
                metadata: metadata
            )

            #expect(markdown.contains("## Environment"))
            #expect(markdown.contains("**Platform**: iOS"))
            #expect(markdown.contains("**OS Version**: 18.0"))
            #expect(markdown.contains("**Device**: iPhone 15 Pro"))
            #expect(markdown.contains("**Resolution**: 393×852"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Environment section is omitted when no metadata")
        func noEnvironmentWithoutMetadata() {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = NavigationGraph()

            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph,
                metadata: nil
            )

            #expect(!markdown.contains("## Environment"))
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Handles empty exploration path")
        func emptyPath() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationPath(goal: "Empty path")
            let graph = NavigationGraph()

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let steps = try #require(json["explorationSteps"] as? [[String: Any]])

            #expect(steps.isEmpty)
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Handles empty navigation graph")
        func emptyGraph() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = NavigationGraph()

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let navGraph = try #require(json["navigationGraph"] as? [String: Any])

            #expect(navGraph["totalScreens"] as? Int == 0)
            #expect(navGraph["totalTransitions"] as? Int == 0)
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Produces valid parseable JSON")
        func validJSON() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath(stepCount: 3)
            let graph = ExplorationExporterTests().makeSampleGraph(screenCount: 2)

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            // Should parse without throwing
            let json = try JSONSerialization.jsonObject(with: data)
            #expect(json is [String: Any])

            // Should be pretty-printed (contains newlines)
            let jsonString = try #require(String(data: data, encoding: .utf8))
            #expect(jsonString.contains("\n"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Markdown handles no steps gracefully")
        func markdownNoSteps() {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationPath(goal: "No steps")
            let graph = NavigationGraph()

            let markdown = exporter.exportMarkdown(
                explorationPath: path,
                navigationGraph: graph
            )

            #expect(markdown.contains("# Exploration Report"))
            #expect(markdown.contains("**Total Steps**: 0"))
        }

        @available(macOS 26.0, iOS 26.0, *)
        @Test("Export format version is consistent")
        func formatVersion() throws {
            let exporter = ExplorationExporterTests().makeSampleExporter()
            let path = ExplorationExporterTests().makeSamplePath()
            let graph = NavigationGraph()

            let data = try exporter.exportComprehensive(
                explorationPath: path,
                navigationGraph: graph
            )

            let json = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )

            #expect(json["exportFormat"] as? String == "aitestscout-exploration-v1")
        }
    }

    // MARK: - Helper

    private func makeSampleExporter() -> ExplorationExporter {
        ExplorationExporter()
    }
}
