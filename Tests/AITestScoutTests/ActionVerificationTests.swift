import Testing
import Foundation
@testable import AITestScout

@Suite("Action Verification Tests")
struct ActionVerificationTests {

    // MARK: - Basic Verification Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification passes when screen changes after tap")
    func testVerificationPassesOnScreenChange() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "loginButton",
            reasoning: "Tap login to proceed",
            successProbability: SuccessProbability(value: 0.8, reasoning: "High confidence"),
            expectedOutcome: "Navigate to dashboard"
        )

        let beforeHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "loginButton", interactive: true)],
            screenshot: Data(),
            screenType: .login
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "dashboardTitle", interactive: false)],
            screenshot: Data(),
            screenType: .content
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: beforeHierarchy,
            afterHierarchy: afterHierarchy
        )

        #expect(result.passed)
        #expect(result.screenChanged)
        #expect(result.reason.contains("expected") || result.reason.contains("outcome"))
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification fails when screen doesn't change")
    func testVerificationFailsOnNoScreenChange() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "submitButton",
            reasoning: "Submit form",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Should work"),
            expectedOutcome: "Navigate to next screen"
        )

        let hierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "submitButton", interactive: true)],
            screenshot: Data(),
            screenType: .form
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy // Same screen!
        )

        #expect(!result.passed)
        #expect(!result.screenChanged)
        #expect(result.reason.contains("screen did not change"))
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification passes for type action when field has value")
    func testVerificationPassesForTypeAction() {
        let decision = ExplorationDecision(
            action: "type",
            targetElement: "emailField",
            reasoning: "Enter email",
            successProbability: SuccessProbability(value: 0.9, reasoning: "Clear field"),
            textToType: "test@example.com",
            expectedOutcome: "Field should contain 'test@example.com'"
        )

        let beforeHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .input, id: "emailField", interactive: true, value: nil)],
            screenshot: Data(),
            screenType: .form
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .input, id: "emailField", interactive: true, value: "test@example.com")],
            screenshot: Data(),
            screenType: .form
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: beforeHierarchy,
            afterHierarchy: afterHierarchy
        )

        #expect(result.passed)
        #expect(result.reason.contains("text was entered"))
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification handles nil expectedOutcome gracefully")
    func testVerificationWithNilExpectedOutcome() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "button1",
            reasoning: "Tap button",
            successProbability: SuccessProbability(value: 0.5, reasoning: "Uncertain"),
            expectedOutcome: nil // No expected outcome
        )

        let before = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "button1", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let after = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "button2", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: before,
            afterHierarchy: after
        )

        // Should pass if screen changed (basic heuristic)
        #expect(result.passed)
        #expect(result.screenChanged)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification skips for done action")
    func testVerificationSkipsForDoneAction() {
        let decision = ExplorationDecision(
            action: "done",
            targetElement: nil,
            reasoning: "Exploration complete",
            successProbability: SuccessProbability(value: 1.0, reasoning: "Done")
        )

        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy
        )

        // Done action always "passes" verification
        #expect(result.passed)
        #expect(result.reason.contains("done action"))
    }

    // MARK: - Expected Outcome Parsing Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Parse expected outcome for element appearance")
    func testParseExpectedOutcomeForElement() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "loginBtn",
            reasoning: "Login",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Should work"),
            expectedOutcome: "Dashboard screen should appear with welcomeMessage element"
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [
                MinimalElement(type: .text, id: "welcomeMessage", interactive: false),
                MinimalElement(type: .text, id: "dashboardTitle", interactive: false)
            ],
            screenshot: Data(),
            screenType: .content
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: CompressedHierarchy(elements: [], screenshot: Data(), screenType: .login),
            afterHierarchy: afterHierarchy
        )

        #expect(result.passed)
        #expect(result.expectedElementFound == true)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification fails when expected element missing")
    func testVerificationFailsWhenElementMissing() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "submitBtn",
            reasoning: "Submit",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Should show success"),
            expectedOutcome: "Success message should appear"
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "errorMessage", interactive: false)],
            screenshot: Data(),
            screenType: .content
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: CompressedHierarchy(elements: [], screenshot: Data(), screenType: .form),
            afterHierarchy: afterHierarchy
        )

        // Screen changed but expected element not found
        #expect(!result.passed)
        #expect(result.screenChanged)
        #expect(result.expectedElementFound == false)
    }

    // MARK: - Swipe Action Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification for swipe only checks screen change")
    func testSwipeVerificationOnlyChecksScreenChange() {
        let decision = ExplorationDecision(
            action: "swipe",
            targetElement: nil,
            reasoning: "Scroll for more content",
            successProbability: SuccessProbability(value: 0.6, reasoning: "May reveal content"),
            expectedOutcome: "More content should become visible"
        )

        let beforeHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "item1", interactive: false)],
            screenshot: Data(),
            screenType: .list
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [
                MinimalElement(type: .text, id: "item1", interactive: false),
                MinimalElement(type: .text, id: "item2", interactive: false)
            ],
            screenshot: Data(),
            screenType: .list
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: beforeHierarchy,
            afterHierarchy: afterHierarchy
        )

        // Screen changed (different elements) = swipe succeeded
        #expect(result.passed)
        #expect(result.screenChanged)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Swipe verification fails if hierarchy identical")
    func testSwipeVerificationFailsIfNoChange() {
        let decision = ExplorationDecision(
            action: "swipe",
            targetElement: nil,
            reasoning: "Try to scroll",
            successProbability: SuccessProbability(value: 0.5, reasoning: "Might be at bottom"),
            expectedOutcome: "Content should scroll"
        )

        let hierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "item1", interactive: false)],
            screenshot: Data(),
            screenType: .list
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy
        )

        #expect(!result.passed)
        #expect(!result.screenChanged)
    }

    // MARK: - Edge Cases

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification handles empty hierarchies")
    func testVerificationWithEmptyHierarchies() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Tap",
            successProbability: SuccessProbability(value: 0.5, reasoning: "Try it")
        )

        let empty = CompressedHierarchy(elements: [], screenshot: Data(), screenType: nil)

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: empty,
            afterHierarchy: empty
        )

        // Empty hierarchies = no change
        #expect(!result.passed)
        #expect(!result.screenChanged)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification is case-insensitive for element matching")
    func testVerificationCaseInsensitiveElementMatching() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Tap",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Should work"),
            expectedOutcome: "SuccessMessage should appear"
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "successmessage", interactive: false)],
            screenshot: Data(),
            screenType: .content
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: CompressedHierarchy(elements: [], screenshot: Data(), screenType: nil),
            afterHierarchy: afterHierarchy
        )

        #expect(result.passed)
        #expect(result.expectedElementFound == true)
    }

    // MARK: - Verification Result Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("VerificationResult provides detailed reason")
    func testVerificationResultReason() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Tap",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Try it")
        )

        let before = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let after = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "newScreen", interactive: false)],
            screenshot: Data(),
            screenType: nil
        )

        let verifier = ActionVerifier()
        let result = verifier.verify(
            decision: decision,
            beforeHierarchy: before,
            afterHierarchy: after
        )

        #expect(!result.reason.isEmpty)
        #expect(result.reason.count > 10)
    }
}
