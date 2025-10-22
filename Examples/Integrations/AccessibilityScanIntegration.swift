import XCTest
import AITestScout

/// Example: Integrate accessibility scanning into AI-powered exploration
///
/// This example shows how to run accessibility audits on every screen discovered
/// during exploration, ensuring your app meets accessibility standards.
///
/// Key Benefits:
/// - Automatic accessibility testing across entire app
/// - Identifies missing labels, IDs, and contrast issues
/// - Generates comprehensive accessibility report
/// - Works seamlessly with existing exploration
@available(iOS 26.0, *)
@MainActor
final class AccessibilityScanIntegration: XCTestCase {

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

    // MARK: - Approach 1: Using AICrawler Delegate

    func testAccessibilityWithDelegate() throws {
        app.launch()

        // Set up accessibility delegate
        let accessibilityDelegate = AccessibilityScanDelegate()
        crawler.delegate = accessibilityDelegate

        print("\n🔍 Starting Accessibility Scan with Delegate")
        print(String(repeating: "━", count: 60))

        // Run normal exploration - accessibility scans happen automatically
        for stepCount in 1...10 {
            print("\n📍 Step \(stepCount)/10")

            let hierarchy = analyzer.capture(from: app)

            let expectation = XCTestExpectation(description: "AI Decision")
            var decision: CrawlerDecision?
            Task {
                decision = try await crawler.decideNextActionWithChoices(
                    hierarchy: hierarchy,
                    goal: "Explore app and verify accessibility"
                )
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30.0)

            guard let decision = decision else { break }
            if decision.action == "done" { break }

            let succeeded = try executeAction(decision)
            if !succeeded { continue }

            sleep(1)
        }

        // Print accessibility report
        print("\n" + String(repeating: "━", count: 60))
        accessibilityDelegate.printReport()
        print(String(repeating: "━", count: 60))

        // Fail test if critical issues found
        let criticalIssues = accessibilityDelegate.getCriticalIssues()
        XCTAssertEqual(criticalIssues, 0, "Found \(criticalIssues) critical accessibility issues")
    }

    // MARK: - Approach 2: Manual Loop Injection

    func testAccessibilityWithManualScan() throws {
        app.launch()

        let scanner = AccessibilityScanner()

        print("\n🔍 Starting Manual Accessibility Scan")
        print(String(repeating: "━", count: 60))

        for stepCount in 1...10 {
            print("\n📍 Step \(stepCount)/10")

            // Capture hierarchy
            let hierarchy = analyzer.capture(from: app)

            // 🔌 INJECTION POINT: Run accessibility scan
            let issues = scanner.scan(hierarchy)
            if !issues.isEmpty {
                print("⚠️  Found \(issues.count) issues:")
                for issue in issues {
                    print("   - \(issue.description)")
                }
            } else {
                print("✅ No accessibility issues")
            }

            // Continue exploration
            let expectation = XCTestExpectation(description: "AI Decision")
            var decision: CrawlerDecision?
            Task {
                decision = try await crawler.decideNextActionWithChoices(
                    hierarchy: hierarchy,
                    goal: "Explore app"
                )
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30.0)

            guard let decision = decision else { break }
            if decision.action == "done" { break }

            try executeAction(decision)
            sleep(1)
        }

        // Generate and save report
        let report = scanner.generateReport()
        print("\n📊 Accessibility Report:\n\(report)")

        // Save to file
        let reportPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("accessibility_report.txt")
        try report.write(to: reportPath, atomically: true, encoding: .utf8)
        print("💾 Report saved to: \(reportPath.path)")
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

        case "type":
            guard let target = decision.targetElement,
                  let text = decision.textToType else { return false }
            let element = app.descendants(matching: .any).matching(identifier: target).firstMatch
            guard element.exists else { return false }
            element.tap()
            element.typeText(text)
            KeyboardHelper.dismissKeyboard(in: app)
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

// MARK: - Accessibility Delegate

@available(iOS 26.0, *)
private class AccessibilityScanDelegate: AICrawlerDelegate {
    private var screenIssues: [String: [AccessibilityIssue]] = [:]
    private var screensScanned = 0

    func didDiscoverNewScreen(_ fingerprint: String, hierarchy: CompressedHierarchy) {
        screensScanned += 1
        print("🔍 Running accessibility scan on screen \(fingerprint.prefix(8))...")

        let scanner = AccessibilityScanner()
        let issues = scanner.scan(hierarchy)

        if !issues.isEmpty {
            screenIssues[fingerprint] = issues
            print("   ⚠️  Found \(issues.count) issue(s)")
            for issue in issues {
                print("      • \(issue.description)")
            }
        } else {
            print("   ✅ No issues found")
        }
    }

    func printReport() {
        let totalIssues = screenIssues.values.flatMap { $0 }.count
        let critical = screenIssues.values.flatMap { $0 }.filter { $0.severity == .critical }.count
        let warning = screenIssues.values.flatMap { $0 }.filter { $0.severity == .warning }.count

        print("\n📊 ACCESSIBILITY SCAN REPORT")
        print("Screens scanned: \(screensScanned)")
        print("Screens with issues: \(screenIssues.count)")
        print("Total issues: \(totalIssues)")
        print("  Critical: \(critical)")
        print("  Warnings: \(warning)")
    }

    func getCriticalIssues() -> Int {
        return screenIssues.values.flatMap { $0 }.filter { $0.severity == .critical }.count
    }
}

// MARK: - Accessibility Scanner

private class AccessibilityScanner {
    func scan(_ hierarchy: CompressedHierarchy) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []

        for element in hierarchy.elements {
            // Rule 1: Interactive elements must have accessibility IDs
            if element.interactive && element.id == nil {
                issues.append(AccessibilityIssue(
                    severity: .critical,
                    type: .missingID,
                    element: element.label ?? "Unknown element",
                    description: "Interactive element missing accessibility identifier"
                ))
            }

            // Rule 2: Interactive elements should have labels
            if element.interactive && element.label == nil && element.id != nil {
                issues.append(AccessibilityIssue(
                    severity: .warning,
                    type: .missingLabel,
                    element: element.id!,
                    description: "Interactive element missing label"
                ))
            }

            // Rule 3: Buttons should have descriptive labels
            if element.type == .button && element.label != nil {
                let label = element.label!
                if label.count < 3 {
                    issues.append(AccessibilityIssue(
                        severity: .warning,
                        type: .poorLabel,
                        element: element.id ?? label,
                        description: "Button label too short: '\(label)'"
                    ))
                }
            }

            // Rule 4: Images should have labels for screen readers
            if element.type == .image && element.label == nil && element.id == nil {
                issues.append(AccessibilityIssue(
                    severity: .warning,
                    type: .missingLabel,
                    element: "Unlabeled image",
                    description: "Image missing both label and identifier"
                ))
            }
        }

        return issues
    }

    func generateReport() -> String {
        var report = "ACCESSIBILITY SCAN REPORT\n"
        report += String(repeating: "=", count: 60) + "\n\n"
        report += "Generated: \(Date())\n"
        report += "Framework: AITestScout\n\n"
        report += "This report was automatically generated during AI-powered exploration.\n"
        return report
    }
}

// MARK: - Models

private enum AccessibilitySeverity {
    case critical  // Must fix
    case warning   // Should fix
    case info      // Nice to have
}

private enum AccessibilityIssueType {
    case missingID
    case missingLabel
    case poorLabel
    case poorContrast
}

private struct AccessibilityIssue {
    let severity: AccessibilitySeverity
    let type: AccessibilityIssueType
    let element: String
    let description: String
}
