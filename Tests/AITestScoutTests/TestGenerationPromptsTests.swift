import Foundation
import Testing
@testable import AITestScout

/// Tests for TestGenerationPrompts - LLM prompts for test generation
@Suite("TestGenerationPrompts Tests")
struct TestGenerationPromptsTests {

    // MARK: - Template Structure Tests

    @Test("Flow test template should have required sections")
    func testFlowTemplateStructure() throws {
        let template = TestGenerationPrompts.flowTestTemplate

        #expect(template.contains("XCUITest"))
        #expect(template.contains("exploration data"))
        #expect(template.contains("Swift"))
        #expect(template.contains("import XCTest"))
    }

    @Test("Screen test template should have required sections")
    func testScreenTemplateStructure() throws {
        let template = TestGenerationPrompts.screenTestTemplate

        #expect(template.contains("XCUITest"))
        #expect(template.contains("screen"))
        #expect(template.contains("Swift"))
    }

    @Test("Full suite template should have required sections")
    func testFullSuiteTemplateStructure() throws {
        let template = TestGenerationPrompts.fullSuiteTemplate

        #expect(template.contains("XCUITest"))
        #expect(template.contains("comprehensive"))
        #expect(template.contains("test suite"))
    }

    // MARK: - Variable Substitution Tests

    @Test("Template should support exploration data substitution")
    func testExplorationDataSubstitution() throws {
        let template = TestGenerationPrompts.flowTestTemplate
        let explorationJSON = "{\"steps\": []}"

        let prompt = template.replacingOccurrences(
            of: "{EXPLORATION_DATA}",
            with: explorationJSON
        )

        #expect(prompt.contains(explorationJSON))
        #expect(!prompt.contains("{EXPLORATION_DATA}"))
    }

    @Test("Template should support test name substitution")
    func testTestNameSubstitution() throws {
        let template = TestGenerationPrompts.flowTestTemplate
        let testName = "testLoginFlow"

        let prompt = template.replacingOccurrences(
            of: "{TEST_NAME}",
            with: testName
        )

        #expect(prompt.contains(testName))
    }

    // MARK: - Best Practices Tests

    @Test("Templates should include best practices")
    func testBestPracticesIncluded() throws {
        let template = TestGenerationPrompts.flowTestTemplate

        // Should mention waits
        #expect(template.lowercased().contains("wait") ||
                template.contains("waitForExistence"))

        // Should mention assertions
        #expect(template.lowercased().contains("assert") ||
                template.contains("XCTAssert"))

        // Should mention element queries
        #expect(template.lowercased().contains("query") ||
                template.lowercased().contains("identifier"))
    }

    @Test("Templates should encourage multiple query strategies")
    func testMultipleQueryStrategies() throws {
        let template = TestGenerationPrompts.flowTestTemplate

        // Should mention using ElementQueries alternatives
        #expect(template.lowercased().contains("alternative") ||
                template.lowercased().contains("fallback") ||
                template.lowercased().contains("multiple"))
    }

    // MARK: - Examples Tests

    @Test("Templates should include code examples")
    func testCodeExamplesIncluded() throws {
        let template = TestGenerationPrompts.flowTestTemplate

        // Should have example code blocks
        #expect(template.contains("```") || template.contains("example"))
    }

    // MARK: - Prompt Builder Tests

    @Test("PromptBuilder should build flow test prompt")
    func testBuildFlowPrompt() throws {
        let exportJSON = """
        {
            "session": {"goal": "Test login"},
            "explorationSteps": []
        }
        """

        let prompt = TestGenerationPrompts.buildFlowTestPrompt(
            explorationData: exportJSON,
            testName: "testLoginFlow",
            screens: ["login", "dashboard"]
        )

        #expect(prompt.contains("testLoginFlow"))
        #expect(prompt.contains("login"))
        #expect(prompt.contains("dashboard"))
        #expect(prompt.contains(exportJSON))
    }

    @Test("PromptBuilder should build screen test prompt")
    func testBuildScreenPrompt() throws {
        let screenData = """
        {
            "fingerprint": "screen123",
            "elements": []
        }
        """

        let prompt = TestGenerationPrompts.buildScreenTestPrompt(
            screenData: screenData,
            testName: "testHomeScreen",
            fingerprint: "screen123"
        )

        #expect(prompt.contains("testHomeScreen"))
        #expect(prompt.contains("screen123"))
        #expect(prompt.contains(screenData))
    }

    @Test("PromptBuilder should build full suite prompt")
    func testBuildFullSuitePrompt() throws {
        let exportJSON = "{}"

        let prompt = TestGenerationPrompts.buildFullSuitePrompt(
            explorationData: exportJSON,
            suiteName: "ComprehensiveTests"
        )

        #expect(prompt.contains("ComprehensiveTests"))
        #expect(prompt.contains(exportJSON))
    }

    // MARK: - Token Efficiency Tests

    @Test("Templates should be reasonably sized")
    func testTemplateSize() throws {
        // Templates shouldn't be excessively long (waste tokens)
        #expect(TestGenerationPrompts.flowTestTemplate.count < 10000)
        #expect(TestGenerationPrompts.screenTestTemplate.count < 10000)
        #expect(TestGenerationPrompts.fullSuiteTemplate.count < 15000)
    }

    // MARK: - XCUITest Patterns Tests

    @Test("Templates should reference XCUITest patterns")
    func testXCUITestPatterns() throws {
        let template = TestGenerationPrompts.flowTestTemplate

        // Should mention key XCUITest concepts
        #expect(template.contains("XCUIApplication") ||
                template.lowercased().contains("xcuiapplication"))

        #expect(template.contains("XCTAssert") ||
                template.lowercased().contains("assertion"))
    }

    @Test("Templates should mention element query methods")
    func testElementQueryMethods() throws {
        let template = TestGenerationPrompts.flowTestTemplate

        // Should reference element query patterns
        let hasQueryMethods = template.contains("buttons[") ||
                              template.contains("textFields[") ||
                              template.contains("descendants(matching:") ||
                              template.lowercased().contains("query")

        #expect(hasQueryMethods)
    }

    // MARK: - Formatting Tests

    @Test("Built prompts should have clean formatting")
    func testPromptFormatting() throws {
        let prompt = TestGenerationPrompts.buildFlowTestPrompt(
            explorationData: "{}",
            testName: "test",
            screens: ["s1"]
        )

        // Should not have excessive whitespace
        #expect(!prompt.contains("    \n    \n    \n"))

        // Should have reasonable line breaks
        #expect(prompt.contains("\n"))
    }

    // MARK: - System Prompts Tests

    @Test("System prompt should set expectations")
    func testSystemPrompt() throws {
        let systemPrompt = TestGenerationPrompts.systemPrompt

        #expect(systemPrompt.contains("XCUITest"))
        #expect(systemPrompt.lowercased().contains("expert") ||
                systemPrompt.lowercased().contains("generate"))
    }

    @Test("System prompt should specify output format")
    func testSystemPromptFormat() throws {
        let systemPrompt = TestGenerationPrompts.systemPrompt

        #expect(systemPrompt.lowercased().contains("swift") ||
                systemPrompt.lowercased().contains("code"))
    }

    // MARK: - Helper Methods Tests

    @Test("Should escape JSON for prompts")
    func testJSONEscaping() throws {
        let json = """
        {"key": "value with \"quotes\""}
        """

        let escaped = TestGenerationPrompts.escapeJSON(json)

        // Should handle quotes properly
        #expect(escaped.contains("\\\"") || !escaped.contains("\"quotes\""))
    }

    @Test("Should format screen list for prompts")
    func testScreenListFormatting() throws {
        let screens = ["login", "dashboard", "settings"]

        let formatted = TestGenerationPrompts.formatScreenList(screens)

        #expect(formatted.contains("login"))
        #expect(formatted.contains("dashboard"))
        #expect(formatted.contains("settings"))

        // Should be readable
        #expect(formatted.contains("→") || formatted.contains("->") ||
                formatted.contains(",") || formatted.contains("\n"))
    }

    // MARK: - Real World Scenarios

    @Test("Complete flow prompt should be valid")
    func testCompleteFlowPrompt() throws {
        let exportData = """
        {
            "session": {
                "goal": "Test login flow",
                "totalSteps": 3
            },
            "explorationSteps": [
                {
                    "action": "tap",
                    "targetElement": "emailField"
                }
            ]
        }
        """

        let prompt = TestGenerationPrompts.buildFlowTestPrompt(
            explorationData: exportData,
            testName: "testUserCanLogin",
            screens: ["login", "dashboard"]
        )

        // Should be a complete, valid prompt
        #expect(prompt.count > 100)
        #expect(prompt.contains("testUserCanLogin"))
        #expect(prompt.contains("emailField"))
    }
}
