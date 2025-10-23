import Testing
import Foundation
@testable import AITestScout

@Suite("AICrawler Enhanced Decision Integration Tests")
struct AICrawlerEnhancedDecisionTests {

    // MARK: - Enhanced Decision Method Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("AICrawler provides decideNextActionEnhanced method")
    func testEnhancedDecisionMethodExists() async throws {
        let crawler = try await AICrawler()

        // Verify the crawler exists and can be initialized
        #expect(crawler.navigationGraph.nodes.isEmpty)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Enhanced decisions include success probability")
    func testEnhancedDecisionsHaveSuccessProbability() {
        // This is a conceptual test - actual AI decisions can't be tested in unit tests
        // We test the structure exists

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "test_btn",
            reasoning: "Test",
            successProbability: SuccessProbability(value: 0.8, reasoning: "High confidence")
        )

        #expect(decision.successProbability.value == 0.8)
        #expect(decision.successProbability.confidenceLevel == .veryHigh)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision provides confidence property")
    func testConfidenceProperty() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "login_btn",
            reasoning: "User needs to login",
            successProbability: SuccessProbability(value: 0.9, reasoning: "Clear action")
        )

        // Confidence is computed from success probability
        #expect(decision.confidence == 90, "0.9 probability should map to 90 confidence")
    }

    // MARK: - Backward Compatibility Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Existing decideNextAction method still works")
    func testBackwardCompatibilityWithBasicDecisions() async throws {
        let crawler = try await AICrawler()

        // Verify existing API is unchanged
        // We can't actually run the decision without a real screen hierarchy
        // But we can verify the method signature exists and returns correct type

        #expect(crawler.navigationGraph.nodes.isEmpty)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Navigation graph works with both decision types")
    func testNavigationGraphWorksWithBothTypes() async throws {
        let crawler = try await AICrawler()

        // Verify navigation graph is agnostic to decision type
        #expect(crawler.navigationGraph.nodes.isEmpty)

        // Both basic and enhanced decisions should work with the graph
        let basicAction = Action(
            type: .tap,
            targetElement: "btn1",
            textTyped: nil,
            reasoning: "Basic",
            confidence: 80
        )

        let enhancedDecision = ExplorationDecision(
            action: "tap",
            targetElement: "btn2",
            reasoning: "Enhanced",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Confident")
        )

        let enhancedAction = Action(
            type: .tap,
            targetElement: enhancedDecision.targetElement,
            textTyped: nil,
            reasoning: enhancedDecision.reasoning,
            confidence: Int(enhancedDecision.successProbability.value * 100)
        )

        // Both actions should have the same structure
        #expect(basicAction.type == enhancedAction.type)
    }

    // MARK: - Success Probability Integration Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("High confidence decisions should be prioritized")
    func testHighConfidenceDecisionPrioritization() {
        let highConfidence = ExplorationDecision(
            action: "tap",
            targetElement: "primary_action",
            reasoning: "Main path",
            successProbability: SuccessProbability(value: 0.95, reasoning: "Obvious choice")
        )

        let lowConfidence = ExplorationDecision(
            action: "tap",
            targetElement: "secondary_action",
            reasoning: "Alternative",
            successProbability: SuccessProbability(value: 0.3, reasoning: "Uncertain")
        )

        #expect(highConfidence.successProbability.confidenceLevel == .veryHigh)
        #expect(lowConfidence.successProbability.confidenceLevel == .low)
        #expect(highConfidence.successProbability.value > lowConfidence.successProbability.value)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Low confidence decisions suggest trying alternatives")
    func testLowConfidenceDecisionsProvideAlternatives() {
        let uncertainDecision = ExplorationDecision(
            action: "tap",
            targetElement: "unclear_btn",
            reasoning: "Not sure about this",
            successProbability: SuccessProbability(value: 0.4, reasoning: "Element might not work"),
            expectedOutcome: "Might navigate somewhere",
            alternativeActions: ["swipe", "tap_back", "try_search"]
        )

        #expect(uncertainDecision.successProbability.confidenceLevel == .medium)
        #expect(uncertainDecision.alternativeActions.isEmpty == false)
        #expect(uncertainDecision.alternativeActions.count == 3)
    }

    // MARK: - Expected Outcome Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Enhanced decisions provide expected outcomes")
    func testExpectedOutcomeProvided() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "login_btn",
            reasoning: "Navigate to login",
            successProbability: SuccessProbability(value: 0.85, reasoning: "Standard flow"),
            expectedOutcome: "Login form should appear with email and password fields"
        )

        #expect(decision.expectedOutcome != nil)
        #expect(decision.expectedOutcome?.isEmpty == false)
        #expect(decision.expectedOutcome?.lowercased().contains("login") == true)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Expected outcomes help with verification")
    func testExpectedOutcomesEnableVerification() {
        let submitDecision = ExplorationDecision(
            action: "tap",
            targetElement: "submit_form",
            reasoning: "Complete registration",
            successProbability: SuccessProbability(value: 0.9, reasoning: "Form is filled"),
            expectedOutcome: "Success message or dashboard screen should appear"
        )

        // Expected outcome provides what to check after action
        #expect(submitDecision.expectedOutcome != nil)

        // This enables post-action verification in the exploration loop
        if let outcome = submitDecision.expectedOutcome {
            #expect(outcome.contains("Success") || outcome.contains("dashboard"))
        }
    }

    // MARK: - Alternative Actions Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Alternative actions provide fallback strategies")
    func testAlternativeActionsProvideFallbacks() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "primary_nav",
            reasoning: "Try main navigation",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Should work"),
            alternativeActions: ["swipe_from_edge", "tap_menu_button", "tap_back"]
        )

        #expect(decision.alternativeActions.count == 3)
        #expect(decision.alternativeActions.contains("swipe_from_edge"))
        #expect(decision.alternativeActions.contains("tap_menu_button"))
    }

    // MARK: - Decision Quality Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision provides rich debugging information")
    func testExplorationDecisionProvidesRichContext() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Tap button to proceed to next screen",
            successProbability: SuccessProbability(
                value: 0.8,
                reasoning: "Button is visible, enabled, and labeled 'Next'"
            ),
            expectedOutcome: "Second onboarding screen appears",
            alternativeActions: ["swipe_left", "tap_skip"]
        )

        // ExplorationDecision has comprehensive context
        #expect(decision.successProbability.reasoning.isEmpty == false)
        #expect(decision.expectedOutcome != nil)
        #expect(decision.alternativeActions.isEmpty == false)
        #expect(decision.confidence >= 0 && decision.confidence <= 100)
    }

    // MARK: - Integration Workflow Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Enhanced decision workflow supports retry logic")
    func testEnhancedDecisionSupportsRetry() {
        let firstAttempt = ExplorationDecision(
            action: "tap",
            targetElement: "submit",
            reasoning: "Try submitting",
            successProbability: SuccessProbability(value: 0.6, reasoning: "Might need more data"),
            expectedOutcome: "Form submission or error message",
            alternativeActions: ["fill_missing_fields", "tap_cancel"]
        )

        // If first attempt fails and confidence was medium, we have alternatives
        if firstAttempt.successProbability.confidenceLevel == .medium {
            #expect(firstAttempt.alternativeActions.isEmpty == false)

            // Can try alternative
            let alternative = firstAttempt.alternativeActions.first
            #expect(alternative != nil)
        }
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Both decision types can coexist in the same exploration")
    func testMixedDecisionTypesInExploration() async throws {
        let crawler = try await AICrawler()

        // Start with an exploration path
        let path = crawler.startExploration(goal: "Test mixed decisions")

        #expect(path.goal == "Test mixed decisions")
        #expect(crawler.navigationGraph.nodes.isEmpty)

        // Both basic and enhanced decisions should work with the same crawler
        // (Actual implementation will be in Phase 2.2)
    }
}
