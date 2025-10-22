import Foundation

/// Orchestrates LLM-based test generation from exploration data
public final class TestGenerator: Sendable {
    /// The LLM client used for code generation
    public let llmClient: any LLMClient

    /// Initialize with an LLM client
    /// - Parameter llmClient: The LLM client to use for generation
    public init(llmClient: any LLMClient) {
        self.llmClient = llmClient
    }

    // MARK: - Flow Test Generation

    /// Generate a test for a specific user flow
    /// - Parameters:
    ///   - explorationData: JSON string of exploration export
    ///   - testName: Name of the test method
    ///   - screens: List of screen fingerprints in the flow
    ///   - model: Optional model to use (defaults to LLM provider's default)
    /// - Returns: Generated test with code and metadata
    public func generateFlowTest(
        explorationData: String,
        testName: String,
        screens: [String],
        model: String? = nil
    ) async throws -> GeneratedTest {
        // Build prompt using template
        let prompt = TestGenerationPrompts.buildFlowTestPrompt(
            explorationData: explorationData,
            testName: testName,
            screens: screens
        )

        // Generate code via LLM
        let response = try await llmClient.generateCompletion(
            prompt: prompt,
            model: model
        )

        // Create metadata
        let metadata = TestMetadata(
            screensCovered: screens,
            elementsTested: 0, // Could be parsed from exploration data
            estimatedRuntime: 0,
            assertionCount: 0,
            interactionCount: 0
        )

        // Return generated test
        return GeneratedTest(
            testName: testName,
            code: response.content,
            mode: .flow(screens: screens),
            metadata: metadata
        )
    }

    // MARK: - Screen Test Generation

    /// Generate a test for a specific screen
    /// - Parameters:
    ///   - screenData: JSON string of screen data
    ///   - testName: Name of the test method
    ///   - fingerprint: Screen fingerprint
    ///   - model: Optional model to use
    /// - Returns: Generated test with code and metadata
    public func generateScreenTest(
        screenData: String,
        testName: String,
        fingerprint: String,
        model: String? = nil
    ) async throws -> GeneratedTest {
        // Build prompt using template
        let prompt = TestGenerationPrompts.buildScreenTestPrompt(
            screenData: screenData,
            testName: testName,
            fingerprint: fingerprint
        )

        // Generate code via LLM
        let response = try await llmClient.generateCompletion(
            prompt: prompt,
            model: model
        )

        // Create metadata
        let metadata = TestMetadata(
            screensCovered: [fingerprint],
            elementsTested: 0,
            estimatedRuntime: 0,
            assertionCount: 0,
            interactionCount: 0
        )

        // Return generated test
        return GeneratedTest(
            testName: testName,
            code: response.content,
            mode: .screen(fingerprint: fingerprint),
            metadata: metadata
        )
    }

    // MARK: - Full Suite Generation

    /// Generate a comprehensive test suite
    /// - Parameters:
    ///   - explorationData: JSON string of complete exploration export
    ///   - suiteName: Name of the test suite class
    ///   - model: Optional model to use
    /// - Returns: Generated test suite with code and metadata
    public func generateFullSuite(
        explorationData: String,
        suiteName: String,
        model: String? = nil
    ) async throws -> GeneratedTest {
        // Build prompt using template
        let prompt = TestGenerationPrompts.buildFullSuitePrompt(
            explorationData: explorationData,
            suiteName: suiteName
        )

        // Generate code via LLM
        let response = try await llmClient.generateCompletion(
            prompt: prompt,
            model: model
        )

        // Create metadata
        let metadata = TestMetadata(
            screensCovered: [],
            elementsTested: 0,
            estimatedRuntime: 0,
            assertionCount: 0,
            interactionCount: 0
        )

        // Return generated test
        return GeneratedTest(
            testName: suiteName,
            code: response.content,
            mode: .full,
            metadata: metadata
        )
    }

    // MARK: - Batch Generation

    /// Generate multiple flow tests concurrently
    /// - Parameters:
    ///   - flows: Array of flow configurations
    ///   - explorationData: The exploration data to use for all tests
    ///   - model: Optional model to use
    /// - Returns: Array of generated tests
    public func generateFlowTests(
        flows: [(testName: String, screens: [String])],
        explorationData: String,
        model: String? = nil
    ) async throws -> [GeneratedTest] {
        try await withThrowingTaskGroup(of: GeneratedTest.self) { group in
            for flow in flows {
                group.addTask {
                    try await self.generateFlowTest(
                        explorationData: explorationData,
                        testName: flow.testName,
                        screens: flow.screens,
                        model: model
                    )
                }
            }

            var results: [GeneratedTest] = []
            for try await test in group {
                results.append(test)
            }
            return results
        }
    }
}
