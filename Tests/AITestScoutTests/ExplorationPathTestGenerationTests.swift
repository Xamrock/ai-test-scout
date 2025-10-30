import Foundation
import Testing
@testable import AITestScout

/// Tests for ExplorationPath test generation capabilities
@Suite("ExplorationPath Test Generation Tests")
struct ExplorationPathTestGenerationTests {

    // MARK: - String Escaping Tests

    @Test("Should escape double quotes in strings")
    func testEscapeDoubleQuotes() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test")
        let input = #"Element with "quotes""#
        let escaped = path.escapeSwiftString(input)
        #expect(escaped == #"Element with \"quotes\""#)
    }

    @Test("Should escape backslashes in strings")
    func testEscapeBackslashes() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test")
        let input = #"Path\to\element"#
        let escaped = path.escapeSwiftString(input)
        #expect(escaped == #"Path\\to\\element"#)
    }

    @Test("Should escape newlines in strings")
    func testEscapeNewlines() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test")
        let input = "Line1\nLine2"
        let escaped = path.escapeSwiftString(input)
        #expect(escaped == "Line1\\nLine2")
    }

    @Test("Should escape multiple special characters")
    func testEscapeMultipleCharacters() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test")
        let input = #"Text with "quotes" and \backslash"#
        let escaped = path.escapeSwiftString(input)
        #expect(escaped.contains(#"\""#))
        #expect(escaped.contains(#"\\"#))
    }

    @Test("Should handle strings without special characters")
    func testNoEscapingNeeded() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test")
        let input = "SimpleIdentifier123"
        let escaped = path.escapeSwiftString(input)
        #expect(escaped == "SimpleIdentifier123")
    }

    // MARK: - Generated Code Quality Tests

    @Test("Generated tap code should use waitForExistence")
    func testTapUsesWaitForExistence() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test tap")
        let step = ExplorationStep(
            action: "tap",
            targetElement: "loginButton",
            textTyped: nil,
            screenDescription: "Login screen",
            interactiveElementCount: 5,
            reasoning: "Tap login button",
            confidence: 95
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "TapTest")

        #expect(generatedCode.contains("waitForExistence"))
        #expect(generatedCode.contains("XCTAssertTrue"))
        #expect(!generatedCode.contains("sleep(1)"))
    }

    @Test("Generated type code should use waitForExistence")
    func testTypeUsesWaitForExistence() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test type")
        let step = ExplorationStep(
            action: "type",
            targetElement: "emailField",
            textTyped: "test@example.com",
            screenDescription: "Login screen",
            interactiveElementCount: 5,
            reasoning: "Enter email",
            confidence: 95
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "TypeTest")

        #expect(generatedCode.contains("waitForExistence"))
        #expect(generatedCode.contains("XCTAssertTrue"))
    }

    @Test("Generated code should not have redundant app initialization")
    func testNoRedundantAppInit() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test app init")
        let step = ExplorationStep(
            action: "tap",
            targetElement: "button",
            textTyped: nil,
            screenDescription: "Screen",
            interactiveElementCount: 3,
            reasoning: "Test",
            confidence: 90
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "InitTest")

        // Should not declare new app variable inside test function
        #expect(!generatedCode.contains("let app = XCUIApplication()"))
        // Should just call launch
        #expect(generatedCode.contains("app.launch()"))
    }

    @Test("Generated failure test should not have redundant app initialization")
    func testFailureTestNoRedundantAppInit() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test failure")
        let step = ExplorationStep(
            action: "tap",
            targetElement: "brokenButton",
            textTyped: nil,
            screenDescription: "Screen",
            interactiveElementCount: 3,
            reasoning: "Element not hittable",
            confidence: 95,
            wasSuccessful: false
        )
        path.addStep(step)

        let generatedCode = path.generateFailureTest(for: step, stepIndex: 1)

        #expect(!generatedCode.contains("let app = XCUIApplication()"))
        #expect(generatedCode.contains("app.launch()"))
    }

    @Test("Unknown actions should generate warning comments")
    func testUnknownActionGeneratesWarning() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test unknown")
        let step = ExplorationStep(
            action: "unknownAction",
            targetElement: "element",
            textTyped: nil,
            screenDescription: "Screen",
            interactiveElementCount: 3,
            reasoning: "Custom action",
            confidence: 80
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "UnknownTest")

        #expect(generatedCode.contains("WARNING"))
        #expect(generatedCode.contains("Unknown action"))
        #expect(generatedCode.contains("unknownAction"))
    }

    @Test("Swipe action should use Thread.sleep instead of sleep")
    func testSwipeUsesThreadSleep() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test swipe")
        let step = ExplorationStep(
            action: "swipe",
            targetElement: nil,
            textTyped: nil,
            screenDescription: "Scrollable screen",
            interactiveElementCount: 10,
            reasoning: "Scroll to see more",
            confidence: 90
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "SwipeTest")

        #expect(generatedCode.contains("Thread.sleep"))
        #expect(generatedCode.contains("0.5"))
        #expect(!generatedCode.contains("sleep(1)"))
    }

    // MARK: - String Escaping in Generated Code

    @Test("Generated code should escape special characters in identifiers")
    func testEscapedIdentifiersInGeneratedCode() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test escaping")
        let step = ExplorationStep(
            action: "tap",
            targetElement: #"button"with"quotes"#,
            textTyped: nil,
            screenDescription: "Screen",
            interactiveElementCount: 5,
            reasoning: "Test",
            confidence: 95
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "EscapeTest")

        // Should contain escaped quotes
        #expect(generatedCode.contains(#"button\"with\"quotes"#))
        // Should not contain unescaped quotes that would break Swift
        let lines = generatedCode.split(separator: "\n")
        let identifierLines = lines.filter { $0.contains("identifier:") }
        for line in identifierLines {
            // Make sure quotes are properly escaped in identifier strings
            let identifierPart = String(line.split(separator: "identifier:").last ?? "")
            if identifierPart.contains("button") {
                #expect(identifierPart.contains(#"\""#))
            }
        }
    }

    @Test("Generated code should escape special characters in typed text")
    func testEscapedTextInGeneratedCode() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Test text escaping")
        let step = ExplorationStep(
            action: "type",
            targetElement: "textField",
            textTyped: #"Text with "quotes" and \backslash"#,
            screenDescription: "Screen",
            interactiveElementCount: 5,
            reasoning: "Test",
            confidence: 95
        )
        path.addStep(step)

        let generatedCode = path.generateSuccessTest(upToStep: step, testName: "TextEscapeTest")

        // Should contain escaped special characters
        #expect(generatedCode.contains(#"\""#))
        #expect(generatedCode.contains(#"\\"#))
    }

    // MARK: - Integration Tests

    @Test("Complete test suite should have all improvements")
    func testComprehensiveTestSuite() throws {
        guard #available(macOS 26.0, iOS 26.0, *) else { return }
        let path = ExplorationPath(goal: "Complete test")

        // Add successful tap
        let tapStep = ExplorationStep(
            action: "tap",
            targetElement: "nextButton",
            textTyped: nil,
            screenDescription: "First screen",
            interactiveElementCount: 5,
            reasoning: "Go to next screen",
            confidence: 95
        )
        path.addStep(tapStep)

        // Add successful type
        let typeStep = ExplorationStep(
            action: "type",
            targetElement: "nameField",
            textTyped: "John Doe",
            screenDescription: "Form screen",
            interactiveElementCount: 8,
            reasoning: "Enter name",
            confidence: 90
        )
        path.addStep(typeStep)

        // Add failed step
        let failedStep = ExplorationStep(
            action: "tap",
            targetElement: "submitButton",
            textTyped: nil,
            screenDescription: "Form screen",
            interactiveElementCount: 8,
            reasoning: "Element not hittable",
            confidence: 85,
            wasSuccessful: false
        )
        path.addStep(failedStep)

        let suite = path.generateComprehensiveTestSuite(className: "IntegrationTests")

        // Verify improvements are present
        #expect(suite.contains("waitForExistence"))
        #expect(suite.contains("XCTAssertTrue"))
        #expect(!suite.contains("let app = XCUIApplication()"))
        #expect(suite.contains("app.launch()"))
        #expect(!suite.contains("sleep(1)"))

        // Verify structure
        #expect(suite.contains("class IntegrationTests: XCTestCase"))
        #expect(suite.contains("override func setUp()"))
        #expect(suite.contains("var app: XCUIApplication!"))
    }
}
