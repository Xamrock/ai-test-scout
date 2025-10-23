import Foundation
import XCTest

/// High-level facade for AI-powered app exploration
///
/// XamrockExplorer provides a simple, one-line API for exploring iOS apps
/// with AI. It orchestrates all the underlying components (HierarchyAnalyzer,
/// AICrawler, ActionExecutor) and provides a clean interface.
///
/// **Simple Usage:**
/// ```swift
/// func testExploration() throws {
///     let result = try XamrockExplorer.explore(app, steps: 10)
///     print("Discovered \(result.screensDiscovered) screens")
/// }
/// ```
///
/// **Detailed Usage:**
/// ```swift
/// func testExploration() throws {
///     let result = try XamrockExplorer.explore(
///         app,
///         steps: 20,
///         goal: "Test the checkout flow"
///     )
///
///     try result.assertDiscovered(minScreens: 3)
///     try result.assertTransitions(min: 5)
/// }
/// ```
@available(macOS 26.0, iOS 26.0, *)
@MainActor
public class XamrockExplorer: XCTestCase, @unchecked Sendable {
    /// The most recent exploration result
    nonisolated(unsafe) private static var _lastResult: ExplorationResult?

    /// Access the last exploration result
    nonisolated public static var lastResult: ExplorationResult? {
        return _lastResult
    }

    /// Explore an app with AI guidance
    ///
    /// This method orchestrates the entire exploration process:
    /// 1. Initializes HierarchyAnalyzer and AICrawler
    /// 2. Runs the exploration loop for N steps
    /// 3. Executes AI-recommended actions
    /// 4. Tracks discovered screens and transitions
    /// 5. Returns comprehensive results
    ///
    /// - Parameters:
    ///   - app: The XCUIApplication to explore
    ///   - steps: Maximum number of exploration steps (default: 20)
    ///   - goal: The exploration goal for AI guidance (default: systematic exploration)
    ///   - outputDirectory: Optional directory for generated files (default: Desktop/XamrockExplorations)
    /// - Returns: ExplorationResult with discovered screens, transitions, and navigation graph
    /// - Throws: Errors from component initialization or action execution
    ///
    /// **Example:**
    /// ```swift
    /// // Simple one-liner
    /// try XamrockExplorer.explore(app, steps: 10)
    ///
    /// // With custom output directory
    /// let result = try XamrockExplorer.explore(
    ///     app,
    ///     steps: 15,
    ///     outputDirectory: URL(fileURLWithPath: "./UITests/Generated")
    /// )
    /// ```
    nonisolated public static func explore(
        _ app: XCUIApplication,
        steps: Int = 20,
        goal: String = "Explore the app systematically",
        outputDirectory: URL? = nil
    ) throws -> ExplorationResult {
        return try explore(app, config: ExplorationConfig(
            steps: steps,
            goal: goal,
            outputDirectory: outputDirectory
        ))
    }

    /// Explore an app with detailed configuration
    ///
    /// - Parameters:
    ///   - app: The XCUIApplication to explore
    ///   - config: Exploration configuration
    /// - Returns: ExplorationResult with discovered screens, transitions, and navigation graph
    /// - Throws: Errors from component initialization or action execution
    nonisolated public static func explore(
        _ app: XCUIApplication,
        config: ExplorationConfig
    ) throws -> ExplorationResult {
        // Create a temporary test case instance for xcAwait
        let testCase = XamrockExplorer()

        // REUSES: HierarchyAnalyzer (existing component)
        let analyzer = HierarchyAnalyzer()

        // REUSES: AICrawler (existing component) via xcAwait helper
        let crawler = try testCase.xcAwait {
            try await AICrawler()
        }

        // REUSES: ActionExecutor (new wrapper around XCUIApplication)
        let executor = ActionExecutor(app: app)

        // REUSES: ExplorationPath (existing component)
        _ = crawler.startExploration(goal: config.goal)

        // Track timing
        let startTime = Date()

        // Exploration loop - run on MainActor for UI operations
        let (duration, stats, verificationStats) = try testCase.xcAwait {
            try await Task { @MainActor in
                var localDuration: TimeInterval = 0
                var localStats: CoverageStats?
                var verificationsPerformed = 0
                var verificationsPassed = 0
                var verificationsFailed = 0
                var retryAttempts = 0

                do {
                    for stepNumber in 1...config.steps {
                        // 1. REUSES: analyzer.capture() (existing, MainActor-isolated)
                        let beforeHierarchy = analyzer.capture(from: app)

                        // 2. REUSES: crawler.decideNextActionWithChoices() (existing)
                        let decision = try await crawler.decideNextActionWithChoices(
                            hierarchy: beforeHierarchy,
                            goal: config.goal
                        )

                        // 3. Check if done
                        if decision.action == "done" {
                            print("✅ Exploration complete at step \(stepNumber)")
                            break
                        }

                        // 4. Execute action with verification and retry logic (Phase 3)
                        var currentDecision = decision
                        var actionSuccessful = false
                        var verificationResult: VerificationResult? = nil
                        var attemptNumber = 0
                        let maxAttempts = config.enableVerification ? 1 + config.maxRetries : 1

                        while attemptNumber < maxAttempts {
                            // 4a. Execute the action
                            do {
                                actionSuccessful = try executor.execute(currentDecision)
                            } catch {
                                // Catch all errors (ActionError and XCUIElement runtime errors)
                                let errorMessage = (error as? ActionError)?.localizedDescription ?? error.localizedDescription
                                print("⚠️  Action failed: \(errorMessage)")
                                crawler.markLastStepFailed(reason: errorMessage)
                                actionSuccessful = false
                                // Action execution failure - don't verify, break retry loop
                                break
                            }

                            // 4b. If action executed successfully, wait for UI to settle
                            if actionSuccessful {
                                try await Task.sleep(nanoseconds: 1_000_000_000)
                            }

                            // 4c. Verify action outcome (Phase 3)
                            if config.enableVerification && actionSuccessful {
                                let afterHierarchy = analyzer.capture(from: app)

                                verificationResult = crawler.verifyAction(
                                    decision: currentDecision,
                                    beforeHierarchy: beforeHierarchy,
                                    afterHierarchy: afterHierarchy
                                )

                                verificationsPerformed += 1

                                if verificationResult!.passed {
                                    verificationsPassed += 1
                                    // Success! Break the retry loop
                                    break
                                } else {
                                    verificationsFailed += 1

                                    if config.verboseOutput {
                                        print("⚠️  Verification failed: \(verificationResult!.reason)")
                                    }

                                    // Try next alternative if available
                                    attemptNumber += 1
                                    if attemptNumber < maxAttempts,
                                       attemptNumber - 1 < currentDecision.alternativeActions.count {
                                        retryAttempts += 1
                                        let alternativeAction = currentDecision.alternativeActions[attemptNumber - 1]

                                        if config.verboseOutput {
                                            print("🔄 Retrying with alternative: \(alternativeAction)")
                                        }

                                        // Convert alternative to decision
                                        currentDecision = try await crawler.convertAlternativeToDecision(
                                            alternativeAction,
                                            context: afterHierarchy
                                        )
                                    } else {
                                        // No more alternatives, accept the failure
                                        break
                                    }
                                }
                            } else {
                                // Verification disabled or action failed - exit retry loop
                                break
                            }
                        }

                        // 5. Record step with verification result
                        let step = ExplorationStep.from(
                            decision: currentDecision,
                            hierarchy: beforeHierarchy,
                            wasSuccessful: actionSuccessful && (verificationResult?.passed ?? true),
                            verificationResult: verificationResult,
                            wasRetry: attemptNumber > 0
                        )
                        crawler.explorationPath?.addStep(step)
                    }

                    // Calculate duration and get stats
                    localDuration = Date().timeIntervalSince(startTime)
                    localStats = crawler.getCoverageStats()
                } catch {
                    // If exploration fails, still return partial results
                    localDuration = Date().timeIntervalSince(startTime)
                    localStats = crawler.getCoverageStats()
                    throw error
                }

                return (
                    localDuration,
                    localStats!,
                    (verificationsPerformed, verificationsPassed, verificationsFailed, retryAttempts)
                )
            }.value
        }

        // Get action statistics from exploration path
        let (successfulActions, failedActions) = crawler.explorationPath?.successRate ?? (0, 0)

        // Generate test files if configured and there were failures
        var testFileURL: URL?
        var reportFileURL: URL?

        if config.generateTests, let explorationPath = crawler.explorationPath, failedActions > 0 {
            do {
                // Determine output directory using smart defaults
                let outputDir = try determineOutputDirectory(
                    configured: config.outputDirectory,
                    sessionId: explorationPath.sessionId
                )

                try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

                // Save test suite
                testFileURL = outputDir.appendingPathComponent("GeneratedTests.swift")
                try explorationPath.saveTestSuite(to: testFileURL!, className: "GeneratedUITests")

                // Save failure report
                reportFileURL = outputDir.appendingPathComponent("FailureReport.md")
                try explorationPath.saveFailureReport(to: reportFileURL!)

                if config.verboseOutput {
                    print("\n📁 Generated test artifacts:")
                    print("   Tests: \(testFileURL!.path)")
                    print("   Report: \(reportFileURL!.path)")
                }
            } catch {
                print("⚠️  Failed to save test artifacts: \(error)")
            }
        }

        // Create result
        let result = ExplorationResult(
            screensDiscovered: stats.totalScreens,
            transitions: stats.totalEdges,
            duration: duration,
            navigationGraph: crawler.navigationGraph,
            successfulActions: successfulActions,
            failedActions: failedActions,
            generatedTestFile: testFileURL,
            generatedReportFile: reportFileURL,
            verificationsPerformed: verificationStats.0,
            verificationsPassed: verificationStats.1,
            verificationsFailed: verificationStats.2,
            retryAttempts: verificationStats.3
        )

        // Show summary output if verbose
        if config.verboseOutput {
            printExplorationSummary(result: result, config: config)
        }

        // Store for later access
        _lastResult = result

        return result
    }

    // MARK: - Private Helpers

    /// Determine the output directory for generated files
    /// Uses smart defaults: Temp directory with clear naming
    nonisolated private static func determineOutputDirectory(configured: URL?, sessionId: UUID) throws -> URL {
        // Use configured directory if provided
        if let configured = configured {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let sessionFolder = "\(timestamp)_\(sessionId.uuidString.prefix(8))"
            return configured.appendingPathComponent(sessionFolder)
        }

        // Use temp directory with clear naming (accessible for EMs)
        // iOS doesn't support Desktop, so use temp with descriptive path
        let tempBase = FileManager.default.temporaryDirectory
            .appendingPathComponent("AITestScoutExplorations")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let sessionFolder = "\(timestamp)_\(sessionId.uuidString.prefix(8))"

        return tempBase.appendingPathComponent(sessionFolder)
    }

    /// Print a formatted exploration summary for EMs
    nonisolated private static func printExplorationSummary(result: ExplorationResult, config: ExplorationConfig) {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 EXPLORATION SUMMARY")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        print("✅ Coverage: \(result.screensDiscovered) screens, \(result.transitions) transitions")
        print("⏱️ Duration: \(Int(result.duration))s")
        print("🎯 Success Rate: \(result.successRatePercent)% (\(result.successfulActions)/\(result.totalActions) actions)")

        // Show verification metrics (Phase 3)
        if config.enableVerification && result.verificationsPerformed > 0 {
            print()
            print("🔍 Verification: \(result.verificationSuccessRate)% pass rate (\(result.verificationsPassed)/\(result.verificationsPerformed))")
            if result.retryAttempts > 0 {
                print("🔄 Retries: \(result.retryAttempts) alternative actions attempted")
            }
        }

        if result.hasCriticalFailures {
            print()
            print("⚠️  ISSUES FOUND: \(result.failedActions)")
            print()
            print("  Check the generated test file for reproduction steps")
        } else {
            print()
            print("🎉 Perfect Exploration! All interactions succeeded.")
        }

        if let testFile = result.generatedTestFile, let reportFile = result.generatedReportFile {
            print()
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 GENERATED FILES")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print()
            print("Tests:  file://\(testFile.path)")
            print("Report: file://\(reportFile.path)")
            print()
            print("💡 NEXT STEPS")
            print()
            print("1. Review the failure report for details")
            print("2. Add GeneratedTests.swift to your test target")
            print("3. Run tests to verify the issues")
            print("4. Track success rate over time")
        }

        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        print("🚀 Powered by Xamrock AITestScout")
        print("   Explore enterprise testing tools: xamrock.com")
        print()
    }
}
