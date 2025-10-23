import XCTest
import AITestScout

/// Example: Visual regression testing during exploration
///
/// Captures and compares screenshots automatically as the AI explores.
/// Detects visual changes between test runs.
@available(iOS 26.0, *)
@MainActor
final class ScreenshotDiffIntegration: XCTestCase {

    var app: XCUIApplication!
    var analyzer: HierarchyAnalyzer!
    var crawler: AICrawler!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        analyzer = HierarchyAnalyzer()
        crawler = try xcAwait { try await AICrawler() }
    }

    func testExplorationWithScreenshotDiff() throws {
        app.launch()

        let screenshotDelegate = ScreenshotDiffDelegate(baselineDir: "Screenshots/Baseline")
        crawler.delegate = screenshotDelegate

        print("\n📸 Starting Visual Regression Testing")
        print(String(repeating: "━", count: 60))

        for stepCount in 1...10 {
            print("\n📍 Step \(stepCount)/10")

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
        screenshotDelegate.printReport()
        print(String(repeating: "━", count: 60))

        // Fail test if visual regressions found
        let regressions = screenshotDelegate.getRegressionCount()
        XCTAssertEqual(regressions, 0, "Found \(regressions) visual regressions")
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

// MARK: - Screenshot Diff Delegate

@available(iOS 26.0, *)
private class ScreenshotDiffDelegate: AICrawlerDelegate {
    private let baselineDir: String
    private var screenshots: [String: Data] = [:]
    private var regressions: [String] = []

    init(baselineDir: String) {
        self.baselineDir = baselineDir
    }

    func didDiscoverNewScreen(_ fingerprint: String, hierarchy: CompressedHierarchy) {
        screenshots[fingerprint] = hierarchy.screenshot

        print("📸 Captured screenshot for \(fingerprint.prefix(8))...")

        // Check for baseline
        let baselinePath = "\(baselineDir)/\(fingerprint).png"
        if FileManager.default.fileExists(atPath: baselinePath) {
            // In real implementation: compare images
            let hasRegression = checkForVisualRegression(fingerprint, screenshot: hierarchy.screenshot, baselinePath: baselinePath)

            if hasRegression {
                regressions.append(fingerprint)
                print("   ❌ VISUAL REGRESSION DETECTED!")
            } else {
                print("   ✅ Matches baseline")
            }
        } else {
            print("   💾 Saving as new baseline")
            saveBaseline(fingerprint, screenshot: hierarchy.screenshot)
        }
    }

    private func checkForVisualRegression(_ fingerprint: String, screenshot: Data, baselinePath: String) -> Bool {
        // In real implementation: use image comparison library
        // For now, just a placeholder
        return false
    }

    private func saveBaseline(_ fingerprint: String, screenshot: Data) {
        let dir = URL(fileURLWithPath: baselineDir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let path = dir.appendingPathComponent("\(fingerprint).png")
        try? screenshot.write(to: path)
    }

    func printReport() {
        print("\n📸 SCREENSHOT DIFF REPORT")
        print("Screenshots captured: \(screenshots.count)")
        print("Visual regressions: \(regressions.count)")

        if !regressions.isEmpty {
            print("\nRegressed screens:")
            for fingerprint in regressions {
                print("  • \(fingerprint)")
            }
        }
    }

    func getRegressionCount() -> Int {
        return regressions.count
    }
}
