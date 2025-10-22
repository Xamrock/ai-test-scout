import Foundation

/// Templates for generating XCUITest code from exploration data
public enum TestGenerationPrompts {

    // MARK: - System Prompt

    /// System prompt that sets context for the LLM
    public static let systemPrompt = """
    You are an expert iOS test automation engineer specializing in XCUITest.
    Your task is to generate high-quality, production-ready Swift test code.

    Generate clean, idiomatic Swift code that follows XCUITest best practices:
    - Use proper waits (waitForExistence) instead of sleep
    - Include meaningful assertions
    - Use multiple query strategies (identifier, label, type+index)
    - Handle edge cases gracefully
    - Add clear, descriptive comments
    - Follow Swift naming conventions

    Output ONLY the Swift code, no explanations or markdown formatting.
    """

    // MARK: - Flow Test Template

    /// Template for generating flow-based tests
    public static let flowTestTemplate = """
    Generate a complete XCUITest that validates the following user flow:

    **Test Name:** {TEST_NAME}

    **Flow Path:**
    {SCREEN_LIST}

    **Exploration Data:**
    ```json
    {EXPLORATION_DATA}
    ```

    **Requirements:**
    1. Create a complete Swift test class
    2. Include imports (XCTest)
    3. Use element queries from the exploration data (primary, byLabel, byType)
    4. Add waitForExistence(timeout: 5) before interacting with elements
    5. Include assertions to verify each screen appears
    6. Use the actual element identifiers and labels from the data
    7. Follow the exploration steps in order
    8. Add XCTAssert statements to verify success
    9. Use fallback queries if primary query might fail

    **Example structure:**
    ```swift
    import XCTest

    final class GeneratedTests: XCTestCase {
        func {TEST_NAME}() throws {
            let app = XCUIApplication()
            app.launch()

            // Step 1: Find and interact with element
            let element = app.buttons["identifier"]
            XCTAssertTrue(element.waitForExistence(timeout: 5))
            element.tap()

            // Step 2: Verify next screen
            // ... continue for each step
        }
    }
    ```

    Generate the complete test code now:
    """

    // MARK: - Screen Test Template

    /// Template for generating screen-specific tests
    public static let screenTestTemplate = """
    Generate Swift XCUITest code to test a single screen.

    **Test Name:** {TEST_NAME}

    **Screen Fingerprint:** {SCREEN_FINGERPRINT}

    **Screen Data:**
    ```json
    {SCREEN_DATA}
    ```

    **Requirements:**
    1. Test all interactive elements on the screen
    2. Verify elements are visible and hittable
    3. Test element states (enabled, selected, etc.)
    4. Include accessibility checks
    5. Use proper element queries from the data
    6. Add assertions for element existence

    Generate the complete Swift test code now:
    """

    // MARK: - Full Suite Template

    /// Template for generating comprehensive test suite
    public static let fullSuiteTemplate = """
    Generate a comprehensive XCUITest suite based on complete app exploration.

    **Suite Name:** {SUITE_NAME}

    **Exploration Data:**
    ```json
    {EXPLORATION_DATA}
    ```

    **Requirements:**
    1. Create multiple test methods, one per major user flow
    2. Include setup/teardown methods
    3. Test critical paths first
    4. Include edge cases
    5. Use Page Object pattern where appropriate
    6. Add helper methods for common operations
    7. Ensure tests are independent and can run in any order

    Generate the complete test suite now:
    """

    // MARK: - Prompt Builders

    /// Build a prompt for flow-based test generation
    /// - Parameters:
    ///   - explorationData: JSON string of exploration export
    ///   - testName: Name of the test method
    ///   - screens: List of screen fingerprints in the flow
    /// - Returns: Complete prompt ready for LLM
    public static func buildFlowTestPrompt(
        explorationData: String,
        testName: String,
        screens: [String]
    ) -> String {
        let screenList = formatScreenList(screens)

        return flowTestTemplate
            .replacingOccurrences(of: "{TEST_NAME}", with: testName)
            .replacingOccurrences(of: "{SCREEN_LIST}", with: screenList)
            .replacingOccurrences(of: "{EXPLORATION_DATA}", with: explorationData)
    }

    /// Build a prompt for screen-specific test generation
    /// - Parameters:
    ///   - screenData: JSON string of screen data
    ///   - testName: Name of the test method
    ///   - fingerprint: Screen fingerprint
    /// - Returns: Complete prompt ready for LLM
    public static func buildScreenTestPrompt(
        screenData: String,
        testName: String,
        fingerprint: String
    ) -> String {
        return screenTestTemplate
            .replacingOccurrences(of: "{TEST_NAME}", with: testName)
            .replacingOccurrences(of: "{SCREEN_FINGERPRINT}", with: fingerprint)
            .replacingOccurrences(of: "{SCREEN_DATA}", with: screenData)
    }

    /// Build a prompt for full test suite generation
    /// - Parameters:
    ///   - explorationData: JSON string of complete exploration export
    ///   - suiteName: Name of the test suite class
    /// - Returns: Complete prompt ready for LLM
    public static func buildFullSuitePrompt(
        explorationData: String,
        suiteName: String
    ) -> String {
        return fullSuiteTemplate
            .replacingOccurrences(of: "{SUITE_NAME}", with: suiteName)
            .replacingOccurrences(of: "{EXPLORATION_DATA}", with: explorationData)
    }

    // MARK: - Helper Methods

    /// Format a list of screens as a readable flow
    /// - Parameter screens: Array of screen fingerprints
    /// - Returns: Formatted string showing the flow
    public static func formatScreenList(_ screens: [String]) -> String {
        if screens.isEmpty {
            return "No specific flow (explore all screens)"
        }

        return screens.enumerated().map { index, screen in
            "\(index + 1). \(screen)"
        }.joined(separator: "\n")
    }

    /// Escape JSON for inclusion in prompts
    /// - Parameter json: JSON string
    /// - Returns: Escaped JSON safe for prompt inclusion
    public static func escapeJSON(_ json: String) -> String {
        // Escape quotes and backslashes for safe inclusion in prompts
        return json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
