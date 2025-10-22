import Foundation
import AITestScout

/// Example: End-to-end test generation from exploration data
///
/// This example demonstrates the complete workflow:
/// 1. Configure an LLM client (Claude or OpenAI)
/// 2. Create a TestGenerator
/// 3. Generate tests from exploration data
/// 4. Save generated tests to files
///
/// Usage:
/// ```swift
/// // Set your API key as an environment variable
/// export ANTHROPIC_API_KEY="your-key-here"
///
/// // Run this example
/// swift run TestGenerationExample
/// ```

// MARK: - Step 1: Configure LLM Client

func configureLLMClient() -> any LLMClient {
    // Option A: Use Claude (recommended for test generation)
    if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] {
        let config = LLMClientConfiguration(
            apiKey: apiKey,
            provider: .claude
        )
        return ClaudeClient(configuration: config)
    }

    // Option B: Use OpenAI
    if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
        let config = LLMClientConfiguration(
            apiKey: apiKey,
            provider: .openAI
        )
        return OpenAIClient(configuration: config)
    }

    fatalError("Please set ANTHROPIC_API_KEY or OPENAI_API_KEY environment variable")
}

// MARK: - Step 2: Create Test Generator

func createTestGenerator() -> TestGenerator {
    let client = configureLLMClient()
    return TestGenerator(llmClient: client)
}

// MARK: - Example 1: Generate Flow Test

func generateLoginFlowTest() async throws {
    print("📝 Generating login flow test...")

    let generator = createTestGenerator()

    // Sample exploration data (would come from AICrawler in real usage)
    let explorationData = """
    {
        "session": {
            "goal": "Test user login flow",
            "startTime": "2025-01-15T10:00:00Z",
            "totalSteps": 4
        },
        "explorationSteps": [
            {
                "stepNumber": 1,
                "action": "tap",
                "targetElement": "emailField",
                "elementQueries": {
                    "primary": "textFields[\\"emailField\\"]",
                    "byLabel": "textFields[\\"Email\\"]",
                    "byType": "textFields.element(boundBy: 0)"
                },
                "screenBefore": "login_screen",
                "screenAfter": "login_screen"
            },
            {
                "stepNumber": 2,
                "action": "type",
                "targetElement": "emailField",
                "inputValue": "user@example.com",
                "screenBefore": "login_screen",
                "screenAfter": "login_screen"
            },
            {
                "stepNumber": 3,
                "action": "tap",
                "targetElement": "passwordField",
                "elementQueries": {
                    "primary": "secureTextFields[\\"passwordField\\"]",
                    "byLabel": "secureTextFields[\\"Password\\"]",
                    "byType": "secureTextFields.element(boundBy: 0)"
                },
                "screenBefore": "login_screen",
                "screenAfter": "login_screen"
            },
            {
                "stepNumber": 4,
                "action": "tap",
                "targetElement": "loginButton",
                "elementQueries": {
                    "primary": "buttons[\\"loginButton\\"]",
                    "byLabel": "buttons[\\"Log In\\"]",
                    "byType": "buttons.element(boundBy: 0)"
                },
                "screenBefore": "login_screen",
                "screenAfter": "dashboard_screen"
            }
        ],
        "metadata": {
            "totalScreens": 2,
            "totalElements": 3,
            "duration": 12.5
        }
    }
    """

    // Generate the test
    let test = try await generator.generateFlowTest(
        explorationData: explorationData,
        testName: "testUserCanLogIn",
        screens: ["login_screen", "dashboard_screen"],
        model: "claude-3-5-sonnet-20241022" // Optional: specify model
    )

    print("✅ Generated test: \(test.testName)")
    print("📊 Metadata:")
    print("   - Screens covered: \(test.metadata.screensCovered.count)")
    print("   - Mode: Flow test")
    print("")
    print("📄 Generated code preview:")
    print(String(test.code.prefix(500)))
    print("...")

    // Save to file
    let outputURL = URL(fileURLWithPath: "GeneratedTests/\(test.suggestedFilename)")
    try? FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try test.writeToFile(url: outputURL)
    print("💾 Saved to: \(outputURL.path)")
}

// MARK: - Example 2: Generate Screen Test

func generateHomeScreenTest() async throws {
    print("\n📝 Generating home screen test...")

    let generator = createTestGenerator()

    // Sample screen data
    let screenData = """
    {
        "fingerprint": "home_screen_v1",
        "elements": [
            {
                "identifier": "profileButton",
                "label": "Profile",
                "type": "button",
                "frame": {"x": 20, "y": 44, "width": 50, "height": 50},
                "isInteractive": true,
                "queries": {
                    "primary": "buttons[\\"profileButton\\"]",
                    "byLabel": "buttons[\\"Profile\\"]"
                }
            },
            {
                "identifier": "searchField",
                "label": "Search",
                "type": "textField",
                "frame": {"x": 80, "y": 44, "width": 200, "height": 44},
                "isInteractive": true,
                "queries": {
                    "primary": "textFields[\\"searchField\\"]"
                }
            },
            {
                "identifier": "feedTable",
                "type": "table",
                "frame": {"x": 0, "y": 100, "width": 375, "height": 667},
                "isInteractive": true,
                "queries": {
                    "primary": "tables[\\"feedTable\\"]"
                }
            }
        ],
        "screenType": "list",
        "layout": "vertical"
    }
    """

    let test = try await generator.generateScreenTest(
        screenData: screenData,
        testName: "testHomeScreenElements",
        fingerprint: "home_screen_v1"
    )

    print("✅ Generated test: \(test.testName)")
    print("📊 Screen: \(test.metadata.screensCovered.first ?? "unknown")")

    // Save to file
    let outputURL = URL(fileURLWithPath: "GeneratedTests/\(test.suggestedFilename)")
    try test.writeToFile(url: outputURL)
    print("💾 Saved to: \(outputURL.path)")
}

// MARK: - Example 3: Generate Full Test Suite

func generateComprehensiveSuite() async throws {
    print("\n📝 Generating comprehensive test suite...")

    let generator = createTestGenerator()

    // Complete exploration data with multiple flows
    let explorationData = """
    {
        "session": {
            "goal": "Comprehensive app exploration",
            "totalScreens": 5,
            "totalSteps": 15
        },
        "flows": [
            {
                "name": "Login Flow",
                "screens": ["login", "dashboard"],
                "steps": 4
            },
            {
                "name": "Profile Flow",
                "screens": ["dashboard", "profile", "settings"],
                "steps": 6
            },
            {
                "name": "Content Creation Flow",
                "screens": ["dashboard", "create", "preview", "published"],
                "steps": 5
            }
        ],
        "explorationSteps": [
            // ... full exploration data
        ]
    }
    """

    let test = try await generator.generateFullSuite(
        explorationData: explorationData,
        suiteName: "ComprehensiveAppTests"
    )

    print("✅ Generated suite: \(test.testName)")
    print("📊 Full suite with multiple test methods")

    // Save to file
    let outputURL = URL(fileURLWithPath: "GeneratedTests/\(test.suggestedFilename)")
    try test.writeToFile(url: outputURL)
    print("💾 Saved to: \(outputURL.path)")
}

// MARK: - Example 4: Batch Generation

func generateMultipleFlowTests() async throws {
    print("\n📝 Generating multiple flow tests in parallel...")

    let generator = createTestGenerator()

    let explorationData = """
    {
        "session": {"goal": "Multi-flow exploration"},
        "explorationSteps": []
    }
    """

    // Define multiple flows to generate
    let flows: [(testName: String, screens: [String])] = [
        ("testOnboardingFlow", ["welcome", "signup", "tutorial", "home"]),
        ("testCheckoutFlow", ["cart", "shipping", "payment", "confirmation"]),
        ("testSearchFlow", ["home", "search", "results", "detail"])
    ]

    // Generate all tests concurrently
    let tests = try await generator.generateFlowTests(
        flows: flows,
        explorationData: explorationData,
        model: "claude-3-5-sonnet-20241022"
    )

    print("✅ Generated \(tests.count) tests in parallel:")
    for test in tests {
        print("   - \(test.testName)")

        // Save each test
        let outputURL = URL(fileURLWithPath: "GeneratedTests/\(test.suggestedFilename)")
        try test.writeToFile(url: outputURL)
    }
}

// MARK: - Example 5: Integration with AICrawler

func integrateWithAICrawler() async throws {
    print("\n📝 Example: Integration with AICrawler...")

    // In real usage, you would:
    // 1. Use AICrawler to explore your app
    // 2. Use ExplorationExporter to export the exploration data
    // 3. Use TestGenerator to generate tests from that data

    print("""

    Complete Integration Example:

    ```swift
    import XCTest
    import AITestScout

    class AppExplorationTests: XCTestCase {
        func testGenerateTestsFromExploration() async throws {
            let app = XCUIApplication()

            // Step 1: Explore the app with AICrawler
            let crawler = AICrawler(
                app: app,
                goal: "Test the login and dashboard flows"
            )

            let explorationResult = try await crawler.explore()

            // Step 2: Export exploration data
            let exporter = ExplorationExporter()
            let exportData = try exporter.export(explorationResult)
            let jsonData = try JSONEncoder().encode(exportData)
            let jsonString = String(data: jsonData, encoding: .utf8)!

            // Step 3: Generate tests using TestGenerator
            let config = LLMClientConfiguration(
                apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]!,
                provider: .claude
            )
            let generator = TestGenerator(llmClient: ClaudeClient(configuration: config))

            let generatedTest = try await generator.generateFlowTest(
                explorationData: jsonString,
                testName: "testGeneratedLoginFlow",
                screens: explorationResult.visitedScreens
            )

            // Step 4: Save the generated test
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(generatedTest.suggestedFilename)
            try generatedTest.writeToFile(url: outputURL)

            print("✅ Generated test saved to: \\(outputURL.path)")
            print("📊 Test covers \\(generatedTest.metadata.screensCovered.count) screens")
            print("💻 Code preview:")
            print(generatedTest.code)
        }
    }
    ```
    """)
}

// MARK: - Example 6: Error Handling

func handleLLMErrors() async {
    print("\n📝 Example: Error handling...")

    do {
        let config = LLMClientConfiguration(
            apiKey: "invalid-key",
            provider: .claude
        )
        let generator = TestGenerator(llmClient: ClaudeClient(configuration: config))

        _ = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: []
        )
    } catch let error as LLMError {
        print("❌ LLM Error:")
        switch error {
        case .invalidAPIKey:
            print("   - Invalid API key. Please check your configuration.")
        case .apiError(let message):
            print("   - API error: \(message)")
        case .rateLimitExceeded:
            print("   - Rate limit exceeded. Please wait and retry.")
        case .invalidResponse(let message):
            print("   - Invalid response: \(message)")
        case .networkError(let error):
            print("   - Network error: \(error.localizedDescription)")
        }
    } catch {
        print("❌ Unexpected error: \(error)")
    }
}

// MARK: - Main Example Runner

func runExamples() async {
    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║            AITestScout Test Generation Example            ║
    ║                                                           ║
    ║  This example demonstrates the complete workflow for      ║
    ║  generating XCUITests from exploration data using LLMs    ║
    ╚═══════════════════════════════════════════════════════════╝

    """)

    // Check for API key
    guard ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] != nil ||
          ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil else {
        print("""
        ⚠️  No API key found!

        Please set one of these environment variables:
        - ANTHROPIC_API_KEY (recommended)
        - OPENAI_API_KEY

        Example:
        export ANTHROPIC_API_KEY="your-key-here"
        """)
        return
    }

    do {
        // Run examples
        try await generateLoginFlowTest()
        try await generateHomeScreenTest()
        try await generateComprehensiveSuite()
        try await generateMultipleFlowTests()
        try await integrateWithAICrawler()
        await handleLLMErrors()

        print("""

        ✅ All examples completed successfully!

        📚 Next Steps:
        1. Check the GeneratedTests/ directory for output files
        2. Review the generated test code
        3. Integrate with your existing test suite
        4. Customize prompts in TestGenerationPrompts.swift if needed
        5. Add test healing capabilities (coming soon!)

        """)
    } catch {
        print("❌ Error running examples: \(error)")
    }
}

// MARK: - Entry Point

// Uncomment to run:
// Task {
//     await runExamples()
// }

/*
 Quick Reference:

 1. LLM Client Configuration:
    - ClaudeClient (recommended for test generation)
    - OpenAIClient (also supported)

 2. TestGenerator Methods:
    - generateFlowTest() - Single user flow
    - generateScreenTest() - Single screen validation
    - generateFullSuite() - Comprehensive test suite
    - generateFlowTests() - Batch generation (concurrent)

 3. GeneratedTest Properties:
    - testName - Name of the test method
    - code - Complete Swift test code
    - mode - Generation mode (flow/screen/full)
    - metadata - Coverage and metrics
    - suggestedFilename - Auto-generated filename

 4. Saving Tests:
    - Use writeToFile(url:) method
    - Suggested filename from suggestedFilename property
    - Create directories as needed

 5. Integration Points:
    - AICrawler → explores app
    - ExplorationExporter → exports data
    - TestGenerator → generates tests
    - Generated files → add to test target
*/
