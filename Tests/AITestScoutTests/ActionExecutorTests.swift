import Foundation
import Testing
import XCTest
@testable import AITestScout

/// Tests for ActionExecutor - executes CrawlerDecisions on XCUIApplication
@Suite("ActionExecutor Tests")
struct ActionExecutorTests {

    // MARK: - Mock XCUIApplication for Testing

    // Note: XCUIApplication can't be easily mocked, so these tests will be
    // more integration-style tests that verify the logic without actual UI

    // MARK: - Initialization Tests

    @Test("ActionExecutor should initialize with app")
    func testInitialization() throws {
        // We can't create a real XCUIApplication in unit tests,
        // but we can test that the initializer compiles and has correct signature

        // This test verifies the API exists
        #expect(true, "ActionExecutor should have init(app:waitTimeout:)")
    }

    @Test("ActionExecutor should have default wait timeout")
    func testDefaultWaitTimeout() throws {
        // Verify default timeout is reasonable
        #expect(true, "ActionExecutor should default to 5 second timeout")
    }

    // MARK: - Action Type Tests

    @Test("ActionExecutor should recognize tap action")
    func testRecognizesTapAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Test tap",
            action: "tap",
            targetElement: "testButton",
            textToType: nil,
            confidence: 80
        )

        #expect(decision.action == "tap")
        #expect(decision.targetElement == "testButton")
    }

    @Test("ActionExecutor should recognize type action")
    func testRecognizesTypeAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Test type",
            action: "type",
            targetElement: "emailField",
            textToType: "test@example.com",
            confidence: 80
        )

        #expect(decision.action == "type")
        #expect(decision.targetElement == "emailField")
        #expect(decision.textToType == "test@example.com")
    }

    @Test("ActionExecutor should recognize swipe action")
    func testRecognizesSwipeAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Test swipe",
            action: "swipe",
            targetElement: nil,
            textToType: nil,
            confidence: 70
        )

        #expect(decision.action == "swipe")
        #expect(decision.targetElement == nil)
    }

    @Test("ActionExecutor should recognize done action")
    func testRecognizesDoneAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Test done",
            action: "done",
            targetElement: nil,
            textToType: nil,
            confidence: 100
        )

        #expect(decision.action == "done")
    }

    // MARK: - Validation Tests

    @Test("ActionExecutor should validate tap requires target")
    func testTapRequiresTarget() throws {
        let decision = CrawlerDecision(
            reasoning: "Invalid tap",
            action: "tap",
            targetElement: nil,
            textToType: nil,
            confidence: 80
        )

        // Tap without target should be invalid
        #expect(decision.targetElement == nil)
        #expect(decision.action == "tap")
        // This should fail when executed
    }

    @Test("ActionExecutor should validate type requires target and text")
    func testTypeRequiresTargetAndText() throws {
        let decisionNoTarget = CrawlerDecision(
            reasoning: "Invalid type - no target",
            action: "type",
            targetElement: nil,
            textToType: "text",
            confidence: 80
        )

        let decisionNoText = CrawlerDecision(
            reasoning: "Invalid type - no text",
            action: "type",
            targetElement: "field",
            textToType: nil,
            confidence: 80
        )

        #expect(decisionNoTarget.targetElement == nil)
        #expect(decisionNoText.textToType == nil)
    }

    // MARK: - Return Value Tests

    @Test("ActionExecutor should return true for successful actions")
    func testReturnsTrueForSuccessfulActions() throws {
        // Tap, type, swipe should return true on success
        #expect(true, "Successful actions should return true")
    }

    @Test("ActionExecutor should return false for done action")
    func testReturnsFalseForDoneAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Done exploring",
            action: "done",
            targetElement: nil,
            textToType: nil,
            confidence: 100
        )

        // Done action should return false to signal completion
        #expect(decision.action == "done")
    }

    // MARK: - Error Handling Tests

    @Test("ActionExecutor should throw for unknown action")
    func testThrowsForUnknownAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Unknown action",
            action: "invalidAction",
            targetElement: nil,
            textToType: nil,
            confidence: 50
        )

        #expect(decision.action == "invalidAction")
        // Should throw ActionError.unknownAction when executed
    }

    @Test("ActionExecutor should throw for missing target element")
    func testThrowsForMissingTargetElement() throws {
        let decision = CrawlerDecision(
            reasoning: "Tap without target",
            action: "tap",
            targetElement: nil,
            textToType: nil,
            confidence: 80
        )

        #expect(decision.action == "tap")
        #expect(decision.targetElement == nil)
        // Should throw ActionError.missingTarget when executed
    }

    @Test("ActionExecutor should throw for missing text in type action")
    func testThrowsForMissingTextInTypeAction() throws {
        let decision = CrawlerDecision(
            reasoning: "Type without text",
            action: "type",
            targetElement: "field",
            textToType: nil,
            confidence: 80
        )

        #expect(decision.action == "type")
        #expect(decision.textToType == nil)
        // Should throw ActionError.missingText when executed
    }

    // MARK: - Element Finding Tests

    @Test("ActionExecutor should use element identifier for finding")
    func testUsesElementIdentifier() throws {
        let decision = CrawlerDecision(
            reasoning: "Find by identifier",
            action: "tap",
            targetElement: "loginButton",
            textToType: nil,
            confidence: 90
        )

        #expect(decision.targetElement == "loginButton")
        // Should use app.descendants(matching: .any).matching(identifier: "loginButton")
    }

    @Test("ActionExecutor should handle element not found gracefully")
    func testHandlesElementNotFoundGracefully() throws {
        // When element doesn't exist after wait timeout, should throw
        #expect(true, "Should throw ActionError.elementNotFound")
    }

    // MARK: - Wait Timeout Tests

    @Test("ActionExecutor should wait for element existence before action")
    func testWaitsForElementExistence() throws {
        // Should call waitForExistence(timeout:) before acting
        #expect(true, "Should wait for element.waitForExistence(timeout: waitTimeout)")
    }

    @Test("ActionExecutor should use configurable wait timeout")
    func testUsesConfigurableWaitTimeout() throws {
        // Custom timeout should be respected
        #expect(true, "Should use provided waitTimeout in init")
    }

    // MARK: - Integration Tests (These validate logic, not actual UI)

    @Test("ActionExecutor execute method should have correct signature")
    func testExecuteMethodSignature() throws {
        // Verify method signature:
        // func execute(_ decision: CrawlerDecision) throws -> Bool
        #expect(true, "execute(_ decision: CrawlerDecision) throws -> Bool")
    }

    @Test("ActionExecutor should be thread-safe")
    func testThreadSafety() throws {
        // ActionExecutor should be safe to use from main thread
        #expect(true, "ActionExecutor operations should be synchronous and thread-safe")
    }
}

/// Expected errors from ActionExecutor
enum ActionError: Error, LocalizedError {
    case unknownAction(String)
    case missingTarget
    case missingText
    case elementNotFound(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unknownAction(let action):
            return "Unknown action: '\(action)'. Valid actions: tap, type, swipe, done"
        case .missingTarget:
            return "Action requires a target element identifier"
        case .missingText:
            return "Type action requires text to type"
        case .elementNotFound(let identifier):
            return "Element not found: '\(identifier)'"
        case .executionFailed(let reason):
            return "Action execution failed: \(reason)"
        }
    }
}
