import XCTest
import AITestScout

/// Example: Log exploration data to analytics
///
/// Tracks AI decisions, screen discoveries, and user flows.
/// Useful for understanding app coverage and AI behavior.
@available(iOS 26.0, *)
@MainActor
final class AnalyticsIntegration: XCTestCase {

    var app: XCUIApplication!
    var analyzer: HierarchyAnalyzer!
    var crawler: AICrawler!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        analyzer = HierarchyAnalyzer()
        crawler = try xcAwait { try await AICrawler() }
    }

    func testExplorationWithAnalytics() throws {
        app.launch()

        let analyticsDelegate = AnalyticsDelegate()
        crawler.delegate = analyticsDelegate

        print("\n📊 Starting Analytics-Tracked Exploration")
        print(String(repeating: "━", count: 60))

        for stepCount in 1...10 {
            let hierarchy = analyzer.capture(from: app)

            let decision = try xcAwait {
                try await crawler.decideNextActionWithChoices(hierarchy: hierarchy)
            }
            if decision.action == "done" { break }

            let succeeded = try executeAction(decision)
            if !succeeded { continue }

            sleep(1)
        }

        print("\n" + String(repeating: "━", count: 60))
        analyticsDelegate.printReport()
        analyticsDelegate.exportToJSON()
        print(String(repeating: "━", count: 60))
    }

    private func executeAction(_ decision: ExplorationDecision) throws -> Bool {
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
        case "done":
            return true
        default:
            return false
        }
    }
}

// MARK: - Analytics Delegate

@available(iOS 26.0, *)
private class AnalyticsDelegate: AICrawlerDelegate {
    private var events: [AnalyticsEvent] = []
    private var screensDiscovered = 0
    private var decisionCount = 0

    func didDiscoverNewScreen(_ fingerprint: String, hierarchy: CompressedHierarchy) {
        screensDiscovered += 1
        events.append(AnalyticsEvent(
            type: "screen_discovered",
            timestamp: Date(),
            data: ["fingerprint": fingerprint, "elementCount": hierarchy.elements.count]
        ))
        print("📱 Screen #\(screensDiscovered) discovered")
    }

    func didMakeDecision(_ decision: ExplorationDecision, hierarchy: CompressedHierarchy) {
        decisionCount += 1
        events.append(AnalyticsEvent(
            type: "ai_decision",
            timestamp: Date(),
            data: [
                "action": decision.action,
                "confidence": decision.confidence,
                "target": decision.targetElement ?? "none"
            ]
        ))
    }

    func didDetectStuck(attemptCount: Int, screenFingerprint: String) {
        events.append(AnalyticsEvent(
            type: "stuck_detected",
            timestamp: Date(),
            data: ["attempts": attemptCount, "screen": screenFingerprint]
        ))
        print("🚨 Stuck detected after \(attemptCount) attempts")
    }

    func printReport() {
        print("\n📊 ANALYTICS REPORT")
        print("Events logged: \(events.count)")
        print("Screens discovered: \(screensDiscovered)")
        print("Decisions made: \(decisionCount)")
    }

    func exportToJSON() {
        let jsonPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("analytics_\(Date().timeIntervalSince1970).json")

        // In real implementation, encode events to JSON and save
        print("💾 Analytics exported to: \(jsonPath.path)")
    }
}

// MARK: - Models

private struct AnalyticsEvent {
    let type: String
    let timestamp: Date
    let data: [String: Any]
}
