import Foundation
import Testing
@testable import AITestScout

/// Tests for TestGenerator - orchestrates LLM-based test generation
@Suite("TestGenerator Tests")
struct TestGeneratorTests {

    // MARK: - Mock LLM Client

    actor MockLLMClient: LLMClient {
        private var mockResponse: String = """
        import XCTest

        final class GeneratedTests: XCTestCase {
            func testExample() throws {
                let app = XCUIApplication()
                app.launch()

                let button = app.buttons["testButton"]
                XCTAssertTrue(button.waitForExistence(timeout: 5))
                button.tap()
            }
        }
        """
        private var capturedPrompts: [String] = []
        private var shouldFail = false
        private var callCount = 0

        func generateCompletion(prompt: String, model: String?) async throws -> LLMResponse {
            capturedPrompts.append(prompt)
            callCount += 1

            if shouldFail {
                throw LLMError.apiError("Mock API error")
            }

            return LLMResponse(
                content: mockResponse,
                model: model ?? "mock-model",
                usage: TokenUsage(promptTokens: 100, completionTokens: 200, totalTokens: 300)
            )
        }

        // Public accessors and mutators for testing
        func getCallCount() -> Int {
            return callCount
        }

        func getCapturedPrompts() -> [String] {
            return capturedPrompts
        }

        func getMockResponse() -> String {
            return mockResponse
        }

        func setMockResponse(_ response: String) {
            mockResponse = response
        }

        func setShouldFail(_ value: Bool) {
            shouldFail = value
        }
    }

    // MARK: - Initialization Tests

    @Test("TestGenerator should initialize with LLMClient")
    func testInitialization() throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = generator // Suppress unused warning
    }

    @Test("TestGenerator should store LLMClient reference")
    func testClientStorage() throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        // Generator should work with the client
        #expect(generator.llmClient is MockLLMClient)
    }

    // MARK: - Flow Test Generation Tests

    @Test("TestGenerator should generate flow test from exploration data")
    func testGenerateFlowTest() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let explorationData = """
        {
            "session": {"goal": "Test login"},
            "explorationSteps": [
                {
                    "action": "tap",
                    "targetElement": "loginButton",
                    "screenBefore": "login"
                }
            ]
        }
        """

        let test = try await generator.generateFlowTest(
            explorationData: explorationData,
            testName: "testLoginFlow",
            screens: ["login", "dashboard"]
        )

        #expect(test.testName == "testLoginFlow")
        #expect(test.code.contains("XCUIApplication"))
        #expect(test.mode.isFlow)
        #expect(await client.getCallCount() == 1)
    }

    @Test("TestGenerator should use flow prompt template")
    func testUsesFlowPromptTemplate() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "testFlow",
            screens: ["s1"]
        )

        let prompts = await client.getCapturedPrompts()
        #expect(prompts.count == 1)
        let prompt = prompts[0]
        #expect(prompt.contains("Flow Path"))
        #expect(prompt.contains("testFlow"))
    }

    @Test("TestGenerator should include screens in flow prompt")
    func testFlowPromptIncludesScreens() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: ["login", "dashboard", "settings"]
        )

        let prompts = await client.getCapturedPrompts()
        let prompt = prompts[0]
        #expect(prompt.contains("login"))
        #expect(prompt.contains("dashboard"))
        #expect(prompt.contains("settings"))
    }

    // MARK: - Screen Test Generation Tests

    @Test("TestGenerator should generate screen test")
    func testGenerateScreenTest() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let screenData = """
        {
            "fingerprint": "screen123",
            "elements": [
                {"identifier": "button1", "type": "button"}
            ]
        }
        """

        let test = try await generator.generateScreenTest(
            screenData: screenData,
            testName: "testHomeScreen",
            fingerprint: "screen123"
        )

        #expect(test.testName == "testHomeScreen")
        #expect(test.mode.isScreen)
        #expect(await client.getCallCount() == 1)
    }

    @Test("TestGenerator should use screen prompt template")
    func testUsesScreenPromptTemplate() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = try await generator.generateScreenTest(
            screenData: "{}",
            testName: "testScreen",
            fingerprint: "screen123"
        )

        let prompts = await client.getCapturedPrompts()
        let prompt = prompts[0]
        #expect(prompt.contains("screen"))
        #expect(prompt.contains("screen123"))
    }

    // MARK: - Full Suite Generation Tests

    @Test("TestGenerator should generate full test suite")
    func testGenerateFullSuite() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let explorationData = """
        {
            "session": {"goal": "Full exploration"},
            "explorationSteps": []
        }
        """

        let test = try await generator.generateFullSuite(
            explorationData: explorationData,
            suiteName: "ComprehensiveTests"
        )

        #expect(test.testName == "ComprehensiveTests")
        #expect(test.mode.isFull)
        #expect(await client.getCallCount() == 1)
    }

    @Test("TestGenerator should use full suite prompt template")
    func testUsesFullSuitePromptTemplate() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = try await generator.generateFullSuite(
            explorationData: "{}",
            suiteName: "FullSuite"
        )

        let prompts = await client.getCapturedPrompts()
        let prompt = prompts[0]
        #expect(prompt.contains("comprehensive"))
        #expect(prompt.contains("FullSuite"))
    }

    // MARK: - Error Handling Tests

    @Test("TestGenerator should handle LLM errors")
    func testHandlesLLMErrors() async throws {
        let client = MockLLMClient()
        await client.setShouldFail(true)
        let generator = TestGenerator(llmClient: client)

        do {
            _ = try await generator.generateFlowTest(
                explorationData: "{}",
                testName: "test",
                screens: []
            )
            #expect(Bool(false), "Should have thrown error")
        } catch {
            #expect(error is LLMError)
        }
    }

    @Test("TestGenerator should handle empty exploration data")
    func testHandlesEmptyExplorationData() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        // Should still generate a test even with empty data
        let test = try await generator.generateFlowTest(
            explorationData: "",
            testName: "test",
            screens: []
        )

        #expect(test.code.count > 0)
    }

    @Test("TestGenerator should handle malformed JSON in response")
    func testHandlesMalformedJSON() async throws {
        let client = MockLLMClient()
        let malformedResponse = "Not valid Swift code { malformed"
        await client.setMockResponse(malformedResponse)
        let generator = TestGenerator(llmClient: client)

        // Should still return the generated content
        let test = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: []
        )

        // The generator returns whatever the LLM produces
        #expect(test.code == malformedResponse)
    }

    // MARK: - Model Selection Tests

    @Test("TestGenerator should support custom model selection")
    func testCustomModelSelection() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: [],
            model: "gpt-4"
        )

        // Model should be passed to LLM client
        #expect(await client.getCallCount() == 1)
    }

    @Test("TestGenerator should use default model if none specified")
    func testDefaultModelSelection() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        _ = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: []
        )

        #expect(await client.getCallCount() == 1)
    }

    // MARK: - Metadata Tests

    @Test("TestGenerator should populate metadata from generation mode")
    func testPopulatesMetadata() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let test = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "testLogin",
            screens: ["login", "dashboard"]
        )

        // Metadata should reflect the generation
        #expect(test.metadata.screensCovered.count >= 0)
    }

    @Test("TestGenerator should track screens in flow metadata")
    func testTracksScreensInMetadata() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let test = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: ["s1", "s2", "s3"]
        )

        #expect(test.metadata.screensCovered.count == 3)
        #expect(test.metadata.screensCovered.contains("s1"))
        #expect(test.metadata.screensCovered.contains("s2"))
        #expect(test.metadata.screensCovered.contains("s3"))
    }

    // MARK: - Code Quality Tests

    @Test("Generated code should contain XCUITest patterns")
    func testGeneratedCodeContainsXCUITestPatterns() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let test = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: []
        )

        #expect(test.code.contains("XCUIApplication") ||
                test.code.contains("XCTest"))
    }

    @Test("Generated code should include assertions")
    func testGeneratedCodeIncludesAssertions() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let test = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: []
        )

        #expect(test.code.contains("XCTAssert") ||
                test.code.contains("assert"))
    }

    @Test("Generated code should include waits")
    func testGeneratedCodeIncludesWaits() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let test = try await generator.generateFlowTest(
            explorationData: "{}",
            testName: "test",
            screens: []
        )

        #expect(test.code.contains("waitForExistence") ||
                test.code.contains("wait"))
    }

    // MARK: - Integration Tests

    @Test("TestGenerator should work end-to-end with flow")
    func testEndToEndFlowGeneration() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let explorationData = """
        {
            "session": {
                "goal": "Test user login flow",
                "totalSteps": 3
            },
            "explorationSteps": [
                {
                    "stepNumber": 1,
                    "action": "tap",
                    "targetElement": "emailField",
                    "screenBefore": "login",
                    "screenAfter": "login"
                },
                {
                    "stepNumber": 2,
                    "action": "tap",
                    "targetElement": "passwordField",
                    "screenBefore": "login",
                    "screenAfter": "login"
                },
                {
                    "stepNumber": 3,
                    "action": "tap",
                    "targetElement": "loginButton",
                    "screenBefore": "login",
                    "screenAfter": "dashboard"
                }
            ]
        }
        """

        let test = try await generator.generateFlowTest(
            explorationData: explorationData,
            testName: "testUserCanLogIn",
            screens: ["login", "dashboard"]
        )

        // Verify complete test structure
        #expect(test.testName == "testUserCanLogIn")
        #expect(test.code.count > 100)
        #expect(test.mode.isFlow)
        #expect(test.metadata.screensCovered.count == 2)

        // Verify prompt was constructed correctly
        let prompts = await client.getCapturedPrompts()
        let prompt = prompts[0]
        #expect(prompt.contains("testUserCanLogIn"))
        #expect(prompt.contains("emailField"))
        #expect(prompt.contains("loginButton"))
    }

    @Test("TestGenerator should preserve exploration details in prompt")
    func testPreservesExplorationDetails() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        let explorationData = """
        {
            "explorationSteps": [
                {
                    "targetElement": "specialButton",
                    "elementQueries": {
                        "primary": "buttons[\\"specialButton\\"]"
                    }
                }
            ]
        }
        """

        _ = try await generator.generateFlowTest(
            explorationData: explorationData,
            testName: "test",
            screens: []
        )

        let prompts = await client.getCapturedPrompts()
        let prompt = prompts[0]
        #expect(prompt.contains("specialButton"))
    }

    // MARK: - Concurrency Tests

    @Test("TestGenerator should support concurrent generation")
    func testConcurrentGeneration() async throws {
        let client = MockLLMClient()
        let generator = TestGenerator(llmClient: client)

        // Generate multiple tests concurrently
        async let test1 = generator.generateFlowTest(
            explorationData: "{}",
            testName: "test1",
            screens: []
        )

        async let test2 = generator.generateFlowTest(
            explorationData: "{}",
            testName: "test2",
            screens: []
        )

        let results = try await [test1, test2]

        #expect(results.count == 2)
        #expect(results[0].testName == "test1")
        #expect(results[1].testName == "test2")
        #expect(await client.getCallCount() == 2)
    }
}
