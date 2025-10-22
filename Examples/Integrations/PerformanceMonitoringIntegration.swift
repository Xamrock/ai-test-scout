import XCTest
import AITestScout

/// Example: Monitor performance during AI exploration
///
/// Tracks transition times, memory usage, and slow screens.
/// Useful for identifying performance bottlenecks during automated testing.
@available(iOS 26.0, *)
@MainActor
final class PerformanceMonitoringIntegration: XCTestCase {

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

    func testExplorationWithPerformanceMonitoring() throws {
        app.launch()

        let perfDelegate = PerformanceMonitorDelegate()
        crawler.delegate = perfDelegate

        print("\n⚡️ Starting Performance-Monitored Exploration")
        print(String(repeating: "━", count: 60))

        for stepCount in 1...10 {
            print("\n📍 Step \(stepCount)/10")

            let hierarchy = analyzer.capture(from: app)

            let expectation = XCTestExpectation(description: "AI Decision")
            var decision: CrawlerDecision?
            Task {
                decision = try await crawler.decideNextActionWithChoices(hierarchy: hierarchy)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30.0)

            guard let decision = decision else { break }
            if decision.action == "done" { break }

            let succeeded = try executeAction(decision)
            if !succeeded { continue }

            sleep(1)
        }

        print("\n" + String(repeating: "━", count: 60))
        perfDelegate.printReport()
        print(String(repeating: "━", count: 60))

        // Assert performance constraints
        XCTAssertLessThan(perfDelegate.maxTransitionTime, 5.0, "Transitions should be under 5s")
    }

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
        case "done":
            return true
        default:
            return false
        }
    }
}

// MARK: - Performance Monitor Delegate

@available(iOS 26.0, *)
private class PerformanceMonitorDelegate: AICrawlerDelegate {
    private var transitionTimes: [TimeInterval] = []
    var maxTransitionTime: TimeInterval = 0

    func didRecordTransition(
        from fromFingerprint: String,
        to toFingerprint: String,
        action: Action,
        duration: TimeInterval
    ) {
        transitionTimes.append(duration)
        maxTransitionTime = max(maxTransitionTime, duration)

        let durationMs = Int(duration * 1000)
        print("🔄 Transition: \(fromFingerprint.prefix(6))... → \(toFingerprint.prefix(6))...")
        print("   Duration: \(durationMs)ms")

        if duration > 3.0 {
            print("   ⚠️  SLOW TRANSITION!")
        }
    }

    func printReport() {
        guard !transitionTimes.isEmpty else {
            print("No transitions recorded")
            return
        }

        let avg = transitionTimes.reduce(0, +) / Double(transitionTimes.count)
        let max = transitionTimes.max() ?? 0
        let min = transitionTimes.min() ?? 0

        print("\n⚡️ PERFORMANCE REPORT")
        print("Transitions: \(transitionTimes.count)")
        print("Average: \(Int(avg * 1000))ms")
        print("Min: \(Int(min * 1000))ms")
        print("Max: \(Int(max * 1000))ms")
    }
}
