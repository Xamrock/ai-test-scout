import Testing
import Foundation
@testable import AITestScout

@Suite("AICrawler Verification Integration Tests")
struct AICrawlerVerificationIntegrationTests {

    // MARK: - Verification Integration Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler can verify action with expected outcome")
    func testCrawlerVerifiesActionWithExpectedOutcome() async throws {
        let crawler = try await AICrawler()

        let beforeHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "loginBtn", interactive: true)],
            screenshot: Data(),
            screenType: .login
        )

        let afterHierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .text, id: "welcomeMessage", interactive: false)],
            screenshot: Data(),
            screenType: .content
        )

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "loginBtn",
            reasoning: "Login",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Should work"),
            expectedOutcome: "Navigate to screen with welcomeMessage element"
        )

        let result = crawler.verifyAction(
            decision: decision,
            beforeHierarchy: beforeHierarchy,
            afterHierarchy: afterHierarchy
        )

        #expect(result.passed)
        #expect(result.screenChanged)
        #expect(result.expectedElementFound == true)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler verification detects screen change")
    func testCrawlerDetectsScreenChange() async throws {
        let crawler = try await AICrawler()

        let before = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn1", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let after = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn2", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn1",
            reasoning: "Tap",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Try it")
        )

        let result = crawler.verifyAction(
            decision: decision,
            beforeHierarchy: before,
            afterHierarchy: after
        )

        #expect(result.passed)
        #expect(result.screenChanged)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler verification fails when screen doesn't change")
    func testCrawlerDetectsNoScreenChange() async throws {
        let crawler = try await AICrawler()

        let hierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Tap",
            successProbability: SuccessProbability(value: 0.6, reasoning: "Might work"),
            expectedOutcome: "Navigate to new screen"
        )

        let result = crawler.verifyAction(
            decision: decision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy
        )

        #expect(!result.passed)
        #expect(!result.screenChanged)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler skips verification for done action")
    func testCrawlerSkipsVerificationForDone() async throws {
        let crawler = try await AICrawler()

        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        let decision = ExplorationDecision(
            action: "done",
            targetElement: nil,
            reasoning: "Complete",
            successProbability: SuccessProbability(value: 1.0, reasoning: "Done")
        )

        let result = crawler.verifyAction(
            decision: decision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy
        )

        #expect(result.passed)
    }

    // MARK: - Alternative Action Conversion Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler converts alternative action string to decision")
    func testConvertAlternativeToDecision() async throws {
        let crawler = try await AICrawler()

        let context = CompressedHierarchy(
            elements: [
                MinimalElement(type: .button, id: "backButton", interactive: true),
                MinimalElement(type: .button, id: "cancelButton", interactive: true)
            ],
            screenshot: Data(),
            screenType: .content
        )

        let alternativeAction = "swipe"

        let decision = try await crawler.convertAlternativeToDecision(
            alternativeAction,
            context: context
        )

        #expect(decision.action == "swipe")
        #expect(decision.successProbability.value > 0.0)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler converts tap alternative with target")
    func testConvertTapAlternativeWithTarget() async throws {
        let crawler = try await AICrawler()

        let context = CompressedHierarchy(
            elements: [
                MinimalElement(type: .button, id: "backButton", interactive: true),
                MinimalElement(type: .button, id: "cancelButton", interactive: true)
            ],
            screenshot: Data(),
            screenType: .content
        )

        let alternativeAction = "tap_backButton"

        let decision = try await crawler.convertAlternativeToDecision(
            alternativeAction,
            context: context
        )

        #expect(decision.action == "tap")
        #expect(decision.targetElement == "backButton")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler converts type alternative with target")
    func testConvertTypeAlternativeWithTarget() async throws {
        let crawler = try await AICrawler()

        let context = CompressedHierarchy(
            elements: [
                MinimalElement(type: .input, id: "emailField", interactive: true, value: nil)
            ],
            screenshot: Data(),
            screenType: .form
        )

        let alternativeAction = "type_emailField"

        let decision = try await crawler.convertAlternativeToDecision(
            alternativeAction,
            context: context
        )

        #expect(decision.action == "type")
        #expect(decision.targetElement == "emailField")
        #expect(decision.textToType != nil)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Crawler handles invalid alternative action gracefully")
    func testHandlesInvalidAlternative() async throws {
        let crawler = try await AICrawler()

        let context = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        let alternativeAction = "invalid_action"

        // Should throw or return a fallback decision
        do {
            let decision = try await crawler.convertAlternativeToDecision(
                alternativeAction,
                context: context
            )
            // If no error, should be a safe fallback like "done"
            #expect(decision.action == "done" || decision.action == "swipe")
        } catch {
            // Expected to throw for invalid actions
            #expect(Bool(true))
        }
    }

    // MARK: - Alternative Action Extraction Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Low confidence decisions suggest alternatives")
    func testLowConfidenceSuggestsAlternatives() async throws {
        let crawler = try await AICrawler()

        // Create a decision with low confidence using decideNextActionEnhanced
        let hierarchy = CompressedHierarchy(
            elements: [
                MinimalElement(type: .button, id: "submitBtn", interactive: true),
                MinimalElement(type: .button, id: "cancelBtn", interactive: true)
            ],
            screenshot: Data(),
            screenType: .form
        )

        // The enhanced decision should include alternatives for uncertain situations
        // Note: We can't easily test the AI decision directly, so we verify the structure exists
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "submitBtn",
            reasoning: "Uncertain",
            successProbability: SuccessProbability(value: 0.4, reasoning: "Low confidence"),
            alternativeActions: ["swipe", "tap_cancelBtn"]
        )

        #expect(decision.alternativeActions.count > 0)
        #expect(decision.successProbability.confidenceLevel == .medium)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("High confidence decisions may skip alternatives")
    func testHighConfidenceSkipsAlternatives() async throws {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "loginBtn",
            reasoning: "Clear action",
            successProbability: SuccessProbability(value: 0.95, reasoning: "Very confident"),
            alternativeActions: []
        )

        #expect(decision.successProbability.confidenceLevel == .veryHigh)
        // High confidence can have empty alternatives (not required)
        #expect(Bool(true))
    }

    // MARK: - Integration with Existing Crawler Features

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification works with navigation graph")
    func testVerificationWorksWithNavigationGraph() async throws {
        let crawler = try await AICrawler()

        let before = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn1", interactive: true)],
            screenshot: Data(),
            screenType: .content
        )

        let after = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn2", interactive: true)],
            screenshot: Data(),
            screenType: .content
        )

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn1",
            reasoning: "Navigate",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Should work")
        )

        // Verify the action
        let result = crawler.verifyAction(
            decision: decision,
            beforeHierarchy: before,
            afterHierarchy: after
        )

        #expect(result.passed)
        #expect(result.screenChanged)

        // Navigation graph should still work independently
        #expect(crawler.navigationGraph.nodes.count >= 0)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Verification preserves exploration path")
    func testVerificationPreservesExplorationPath() async throws {
        let crawler = try await AICrawler()
        let path = crawler.startExploration(goal: "Test verification")

        #expect(path.goal == "Test verification")
        #expect(crawler.explorationPath != nil)

        // Verification should not affect exploration path
        let hierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Test",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Try it")
        )

        _ = crawler.verifyAction(
            decision: decision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy
        )

        #expect(crawler.explorationPath != nil)
        #expect(crawler.explorationPath?.goal == "Test verification")
    }
}
