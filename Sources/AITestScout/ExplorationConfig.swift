import Foundation

/// Configuration for app exploration
@available(macOS 26.0, iOS 26.0, *)
public struct ExplorationConfig: Sendable {
    /// Maximum number of exploration steps to take
    public var steps: Int

    /// The exploration goal for AI guidance
    public var goal: String

    /// Optional output directory for generated tests and reports
    /// If nil, uses smart defaults (Desktop or project directory)
    public var outputDirectory: URL?

    /// Whether to generate test files automatically
    public var generateTests: Bool

    /// Whether to fail the test if critical issues are found
    public var failOnCriticalIssues: Bool

    /// Whether to show verbose console output
    public var verboseOutput: Bool

    /// Initialize with default configuration
    public init(
        steps: Int = 20,
        goal: String = "Explore the app systematically",
        outputDirectory: URL? = nil,
        generateTests: Bool = true,
        failOnCriticalIssues: Bool = false,
        verboseOutput: Bool = true
    ) {
        self.steps = steps
        self.goal = goal
        self.outputDirectory = outputDirectory
        self.generateTests = generateTests
        self.failOnCriticalIssues = failOnCriticalIssues
        self.verboseOutput = verboseOutput
    }
}
