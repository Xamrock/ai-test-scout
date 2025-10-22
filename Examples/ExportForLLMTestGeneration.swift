import XCTest
import AITestScout

/// Example: Export comprehensive exploration data for LLM test generation
///
/// This example shows how to use the new export features to capture ALL data needed
/// for LLMs to generate high-quality XCUITests, including:
/// - Element queries (how to find elements in code)
/// - Element state (frame, visibility, enabled)
/// - Environment context (device, OS, screen size)
/// - Navigation graph (screens and transitions)
/// - Exploration steps with detailed reasoning
///
/// The exported JSON can be fed to Claude/GPT-4 to automatically generate test code.
@available(iOS 26.0, *)
@MainActor
final class ExportForLLMTestGeneration: XCTestCase {

    var app: XCUIApplication!
    var analyzer: HierarchyAnalyzer!
    var crawler: AICrawler!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        analyzer = HierarchyAnalyzer()

        let expectation = XCTestExpectation(description: "Initialize Crawler")
        Task {
            crawler = try await AICrawler()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    /// Complete example: Explore app and export comprehensive data for LLM test generation
    func testExploreAndExportForLLMTestGeneration() throws {
        app.launch()

        print("\n" + String(repeating: "=", count: 80))
        print("🚀 AI EXPLORATION WITH COMPREHENSIVE EXPORT")
        print(String(repeating: "=", count: 80) + "\n")

        // PHASE 1: Explore the app
        let maxSteps = 10
        for stepCount in 1...maxSteps {
            print("Step \(stepCount)/\(maxSteps)...")

            // Capture hierarchy with rich context
            let hierarchy = analyzer.capture(from: app)

            // Get AI decision
            let expectation = XCTestExpectation(description: "AI Decision")
            var decision: CrawlerDecision?
            Task {
                decision = try await crawler.decideNextActionWithChoices(
                    hierarchy: hierarchy,
                    goal: "Explore the app and test core features"
                )
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30.0)

            guard let decision = decision else { break }
            if decision.action == "done" {
                print("✅ Exploration complete")
                break
            }

            // Execute action
            _ = try? executeAction(decision)
            sleep(1)
        }

        // PHASE 2: Build comprehensive export
        print("\n📦 Building comprehensive export...")

        // Capture environment
        let environment = EnvironmentCapture.capture()
        print("   - Environment: \(environment.platform) \(environment.osVersion)")
        print("   - Device: \(environment.deviceModel)")
        print("   - Resolution: \(Int(environment.screenResolution.width))×\(Int(environment.screenResolution.height))")

        // Get captured element contexts from analyzer
        let elementContexts = analyzer.capturedElementContexts
        print("   - Element contexts captured: \(elementContexts.count)")

        // Build app context
        let appContext = AppContext(
            bundleId: "com.example.app",
            appVersion: "1.0.0",
            buildNumber: "100",
            launchArguments: [],
            launchEnvironment: [:]
        )

        // Create metadata package
        let metadata = ExplorationMetadata(
            environment: environment,
            elementContexts: elementContexts,
            appContext: appContext
        )

        // Attach metadata to exploration path
        _ = crawler.explorationPath.attachMetadata(metadata)

        // PHASE 3: Export to JSON
        print("\n💾 Exporting data...")

        let exporter = ExplorationExporter()

        // Export comprehensive JSON
        let jsonData = try exporter.exportComprehensive(
            explorationPath: crawler.explorationPath,
            navigationGraph: crawler.navigationGraph,
            metadata: metadata
        )

        // Save to file
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("exploration_export_\(Date().timeIntervalSince1970).json")

        try jsonData.write(to: fileURL)
        print("   ✅ JSON exported to: \(fileURL.path)")
        print("   📊 Size: \(jsonData.count / 1024) KB")

        // PHASE 4: Export markdown report (human-readable)
        let markdown = exporter.exportMarkdown(
            explorationPath: crawler.explorationPath,
            navigationGraph: crawler.navigationGraph,
            metadata: metadata
        )

        let markdownURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("exploration_report_\(Date().timeIntervalSince1970).md")

        try markdown.write(to: markdownURL, atomically: true, encoding: .utf8)
        print("   ✅ Markdown report: \(markdownURL.path)")

        // PHASE 5: Show sample of exported data
        print("\n📋 Sample exported data structure:")
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            printSampleStructure(json, indent: 0, maxDepth: 3)
        }

        print("\n" + String(repeating: "=", count: 80))
        print("✅ EXPORT COMPLETE - Ready for LLM test generation!")
        print(String(repeating: "=", count: 80) + "\n")

        // Now this JSON can be fed to Claude/GPT-4 with a prompt like:
        // "Generate XCUITests from this exploration data..."
    }

    /// Example: Access element contexts during exploration
    func testAccessElementContextsDuringExploration() throws {
        app.launch()

        // Capture hierarchy
        let hierarchy = analyzer.capture(from: app)

        // Access captured element contexts
        let contexts = analyzer.capturedElementContexts

        print("\n📊 Element Contexts Captured:")
        for (key, context) in contexts.prefix(5) {
            print("\n   Element: \(key)")
            print("   Type: \(context.xcuiElementType)")
            print("   Frame: \(context.frame)")
            print("   Hittable: \(context.isHittable)")
            print("   Primary Query: \(context.queries.primary)")
            if let alternatives = context.queries.byLabel {
                print("   Alt Query: \(alternatives)")
            }
        }
    }

    // MARK: - Helper Methods

    private func executeAction(_ decision: CrawlerDecision) throws -> Bool {
        switch decision.action {
        case "tap":
            guard let target = decision.targetElement else { return false }
            let element = app.descendants(matching: .any).matching(identifier: target).firstMatch
            guard element.exists else { return false }
            element.tap()
            return true
        case "swipe":
            app.swipeUp()
            return true
        case "type":
            guard let target = decision.targetElement,
                  let text = decision.textToType else { return false }
            let element = app.descendants(matching: .any).matching(identifier: target).firstMatch
            guard element.exists else { return false }
            element.tap()
            element.typeText(text)
            return true
        default:
            return false
        }
    }

    private func printSampleStructure(_ json: [String: Any], indent: Int, maxDepth: Int) {
        guard indent < maxDepth else { return }

        let indentString = String(repeating: "   ", count: indent)

        for (key, value) in json.sorted(by: { $0.key < $1.key }) {
            if let dict = value as? [String: Any] {
                print("\(indentString)• \(key):")
                printSampleStructure(dict, indent: indent + 1, maxDepth: maxDepth)
            } else if let array = value as? [Any] {
                print("\(indentString)• \(key): [\(array.count) items]")
            } else {
                let valueString = "\(value)".prefix(50)
                print("\(indentString)• \(key): \(valueString)")
            }
        }
    }
}
