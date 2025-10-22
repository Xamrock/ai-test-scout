import Foundation

/// Extension to ExplorationPath for generating automated UI test cases
@available(macOS 26.0, iOS 26.0, *)
extension ExplorationPath {

    // MARK: - Failure Analysis

    /// Get all failed steps from the exploration
    public var failedSteps: [ExplorationStep] {
        steps.filter { !$0.wasSuccessful }
    }

    /// Get all successful steps from the exploration
    public var successfulSteps: [ExplorationStep] {
        steps.filter { $0.wasSuccessful }
    }

    /// Get the reproduction path for a specific step
    /// Returns all steps leading up to and including the target step
    public func reproductionPath(for step: ExplorationStep) -> [ExplorationStep] {
        guard let index = steps.firstIndex(where: { $0.id == step.id }) else {
            return []
        }
        return Array(steps[0...index])
    }

    /// Get the successful reproduction path for a specific step
    /// Returns only successful steps leading up to and including the target step
    /// Used for generating success tests that should work without failures
    private func successfulReproductionPath(for step: ExplorationStep) -> [ExplorationStep] {
        guard let index = steps.firstIndex(where: { $0.id == step.id }) else {
            return []
        }
        // Filter to include only successful steps
        return Array(steps[0...index]).filter { $0.wasSuccessful }
    }

    // MARK: - Test Case Generation

    /// Generate a Swift test case for a failed interaction
    /// Documents the failure and includes XCTExpectFailure for the broken step
    public func generateFailureTest(for failedStep: ExplorationStep, className: String = "GeneratedTests") -> String {
        let reproPath = reproductionPath(for: failedStep)
        let testName = sanitizeTestName(failedStep.targetElement ?? "UnknownElement")

        var test = """
        // MARK: - Failure Test: \(failedStep.targetElement ?? "Unknown")
        //
        // This test documents a UI interaction failure found during exploration.
        // The failure occurs at step \(reproPath.count) of the flow.
        //
        // Expected behavior: \(failedStep.action) on '\(failedStep.targetElement ?? "element")' should work
        // Actual behavior: \(failedStep.reasoning)
        //
        // Screen: \(failedStep.screenDescription)
        // Confidence: \(failedStep.confidence)%
        // Timestamp: \(failedStep.timestamp)

        func testFailure_\(testName)() throws {
            let app = XCUIApplication()
            app.launch()

        """

        // Add all reproduction steps
        for (index, step) in reproPath.enumerated() {
            let isFailedStep = step.id == failedStep.id
            test += "    // Step \(index + 1): \(step.reasoning)\n"
            test += generateStepCode(step, indent: "    ", expectFailure: isFailedStep)
            test += "\n"
        }

        test += "}\n"
        return test
    }

    /// Generate a Swift test case for a successful flow
    /// This creates a regression test to ensure the flow continues working
    public func generateSuccessTest(upToStep targetStep: ExplorationStep, testName: String? = nil) -> String {
        // Use filtered path that only includes successful steps
        let reproPath = successfulReproductionPath(for: targetStep)
        let name = testName ?? sanitizeTestName(targetStep.targetElement ?? "Flow")

        // Guard against empty paths (can happen if target step itself failed)
        guard !reproPath.isEmpty else {
            return "// Cannot generate success test for failed step: \(targetStep.targetElement ?? "Unknown")\n"
        }

        var test = """
        // MARK: - Success Test: \(name)
        //
        // This test verifies a successful flow discovered during exploration.
        // It ensures this interaction path continues to work.
        //
        // Final step: \(targetStep.action) on '\(targetStep.targetElement ?? "element")'
        // Screen: \(targetStep.screenDescription)
        // Total steps: \(reproPath.count)

        func testSuccess_\(name)() throws {
            let app = XCUIApplication()
            app.launch()

        """

        // Add all successful steps only
        for (index, step) in reproPath.enumerated() {
            test += "    // Step \(index + 1): \(step.reasoning)\n"
            test += generateStepCode(step, indent: "    ", expectFailure: false)
            test += "\n"
        }

        test += "}\n"
        return test
    }

    /// Generate a complete test suite with all failures and key successful flows
    public func generateComprehensiveTestSuite(className: String = "GeneratedUITests") -> String {
        var suite = """
        import XCTest

        /// Auto-generated UI test suite from AITestScout by Xamrock
        /// Learn more: https://xamrock.com/ai-test-scout
        ///
        /// Session: \(sessionId)
        /// Goal: \(goal)
        /// Generated: \(Date())
        ///
        /// Stats:
        /// - Total Steps: \(steps.count)
        /// - Successful: \(successRate.successful)
        /// - Failed: \(successRate.failed)
        /// - Unique Elements: \(visitedElements.count)

        class \(className): XCTestCase {
            var app: XCUIApplication!

            override func setUp() {
                super.setUp()
                continueAfterFailure = false
                app = XCUIApplication()
            }


        """

        // Add failure tests first (these document bugs)
        if !failedSteps.isEmpty {
            suite += "    // MARK: - Failure Tests (Document Known Issues)\n\n"
            for failure in failedSteps {
                suite += generateFailureTest(for: failure, className: className)
                suite += "\n"
            }
        }

        // Add successful flow tests (these are regression tests)
        if !successfulSteps.isEmpty {
            suite += "    // MARK: - Success Tests (Regression Protection)\n\n"

            // Generate tests for key successful flows
            // Use the last successful step in each "screen" as a test
            let keySteps = identifyKeySuccessfulSteps()
            for (index, step) in keySteps.enumerated() {
                suite += generateSuccessTest(upToStep: step, testName: "Flow\(index + 1)")
                suite += "\n"
            }
        }

        suite += "}\n"
        return suite
    }

    // MARK: - Test Suite Export

    /// Save the test suite to a Swift file
    public func saveTestSuite(to url: URL, className: String = "GeneratedUITests") throws {
        let suite = generateComprehensiveTestSuite(className: className)
        try suite.write(to: url, atomically: true, encoding: .utf8)
        print("✅ Test suite saved to: \(url.path)")
        print("   - Failures: \(failedSteps.count)")
        print("   - Success tests: \(identifyKeySuccessfulSteps().count)")
    }

    /// Generate a failure report in Markdown
    public func generateFailureReport() -> String {
        var report = """
        # UI Exploration Test Report

        **Session:** `\(sessionId.uuidString.prefix(8))...`
        **Goal:** \(goal)
        **Started:** \(startTime)

        ## Summary

        | Metric | Value |
        |--------|-------|
        | Total Steps | \(steps.count) |
        | Successful | \(successRate.successful) (\(successPercentage)%) |
        | Failed | \(successRate.failed) (\(failurePercentage)%) |
        | Unique Elements | \(visitedElements.count) |

        """

        if failedSteps.isEmpty {
            report += "\n✅ **Perfect Exploration!** All \(steps.count) interactions completed successfully.\n"
        } else {
            report += """

            ## Failed Interactions

            The following interactions failed during exploration. Each has a generated test case to reproduce the issue:

            """

            for (index, failure) in failedSteps.enumerated() {
                report += """

                ### \(index + 1). \(failure.targetElement ?? "Unknown Element")

                - **Action:** `\(failure.action)`
                - **Issue:** \(failure.reasoning)
                - **Screen:** \(failure.screenDescription)
                - **Reproduction Steps:** \(reproductionPath(for: failure).count) steps required

                """
            }
        }

        report += """


        ## Generated Tests

        A complete test suite has been generated with:
        - **\(failedSteps.count)** failure tests (documenting known issues)
        - **\(identifyKeySuccessfulSteps().count)** success tests (regression protection)

        Run these tests to:
        1. Verify failures are fixed when bugs are resolved
        2. Ensure working flows don't break in future changes
        3. Track UI reliability over time

        """

        return report
    }

    /// Save the failure report to a markdown file
    public func saveFailureReport(to url: URL) throws {
        let report = generateFailureReport()
        try report.write(to: url, atomically: true, encoding: .utf8)
        print("📝 Report saved to: \(url.path)")
    }

    // MARK: - Private Helpers

    /// Identify key successful steps to test (avoid testing every single step)
    /// Picks the last successful step before each screen change
    private func identifyKeySuccessfulSteps() -> [ExplorationStep] {
        var keySteps: [ExplorationStep] = []
        var lastScreenDescription = ""

        for step in successfulSteps {
            // Include step if it's on a different screen than the last one
            if step.screenDescription != lastScreenDescription {
                keySteps.append(step)
                lastScreenDescription = step.screenDescription
            }
        }

        // Also include the very last successful step
        if let lastSuccess = successfulSteps.last, !keySteps.contains(where: { $0.id == lastSuccess.id }) {
            keySteps.append(lastSuccess)
        }

        return keySteps
    }

    private var successPercentage: Int {
        guard steps.count > 0 else { return 0 }
        return Int(Double(successRate.successful) / Double(steps.count) * 100)
    }

    private var failurePercentage: Int {
        guard steps.count > 0 else { return 0 }
        return Int(Double(successRate.failed) / Double(steps.count) * 100)
    }

    private func generateStepCode(_ step: ExplorationStep, indent: String, expectFailure: Bool) -> String {
        var code = ""

        switch step.action {
        case "tap":
            if let target = step.targetElement {
                if expectFailure {
                    code += "\(indent)// Expected to fail: \(step.reasoning)\n"
                    code += "\(indent)XCTExpectFailure(\"\(step.reasoning)\") {\n"
                    code += "\(indent)    app.descendants(matching: .any).matching(identifier: \"\(target)\").firstMatch.tap()\n"
                    code += "\(indent)}\n"
                } else {
                    code += "\(indent)app.descendants(matching: .any).matching(identifier: \"\(target)\").firstMatch.tap()\n"
                    code += "\(indent)sleep(1) // Wait for navigation\n"
                }
            }

        case "type":
            if let target = step.targetElement {
                let text = step.textTyped ?? "test@example.com"
                if expectFailure {
                    code += "\(indent)// Expected to fail: \(step.reasoning)\n"
                    code += "\(indent)XCTExpectFailure(\"\(step.reasoning)\") {\n"
                    code += "\(indent)    let element = app.descendants(matching: .any).matching(identifier: \"\(target)\").firstMatch\n"
                    code += "\(indent)    element.tap()\n"
                    code += "\(indent)    element.typeText(\"\(text)\")\n"
                    code += "\(indent)}\n"
                } else {
                    code += "\(indent)let element = app.descendants(matching: .any).matching(identifier: \"\(target)\").firstMatch\n"
                    code += "\(indent)element.tap()\n"
                    code += "\(indent)element.typeText(\"\(text)\")\n"
                }
            }

        case "swipe":
            code += "\(indent)app.swipeUp()\n"
            code += "\(indent)sleep(1) // Wait for scroll animation\n"

        default:
            break
        }

        return code
    }

    private func sanitizeTestName(_ name: String) -> String {
        name.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
    }
}
