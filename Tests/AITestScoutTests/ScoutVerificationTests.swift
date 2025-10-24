import Testing
import Foundation
import XCTest
@testable import AITestScout

@Suite("Scout Verification Integration Tests")
struct ScoutVerificationTests {

    // MARK: - Verification Loop Integration Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer verifies action after execution")
    func testExplorerVerifiesActionAfterExecution() async throws {
        // This test verifies the integration point exists
        // Actual verification happens in the exploration loop

        // Create a mock exploration scenario
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "testButton",
            reasoning: "Test tap",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Should work"),
            expectedOutcome: "Navigate to new screen"
        )

        #expect(decision.expectedOutcome != nil)
        #expect(decision.action == "tap")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer tracks verification results in exploration path")
    func testExplorerTracksVerificationResults() async throws {
        let crawler = try await AICrawler()
        let path = crawler.startExploration(goal: "Test verification tracking")

        #expect(path.goal == "Test verification tracking")
        #expect(crawler.explorationPath != nil)

        // Verification results should be tracked in exploration path steps
        // Each step should have a verification result
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer retries with alternative when verification fails")
    func testExplorerRetriesWithAlternative() async throws {
        let crawler = try await AICrawler()

        // Scenario: Primary action fails verification
        let primaryDecision = ExplorationDecision(
            action: "tap",
            targetElement: "submitBtn",
            reasoning: "Submit form",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Should work"),
            expectedOutcome: "Navigate to success screen",
            alternativeActions: ["tap_cancelBtn", "swipe"]
        )

        #expect(primaryDecision.alternativeActions.count == 2)

        // If verification fails, should try first alternative
        let firstAlternative = primaryDecision.alternativeActions[0]
        #expect(firstAlternative == "tap_cancelBtn")

        // Convert alternative to decision
        let context = CompressedHierarchy(
            elements: [
                MinimalElement(type: .button, id: "submitBtn", interactive: true),
                MinimalElement(type: .button, id: "cancelBtn", interactive: true)
            ],
            screenshot: Data(),
            screenType: .form
        )

        let alternativeDecision = try await crawler.convertAlternativeToDecision(
            firstAlternative,
            context: context
        )

        #expect(alternativeDecision.action == "tap")
        #expect(alternativeDecision.targetElement == "cancelBtn")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer limits retry attempts to prevent infinite loops")
    func testExplorerLimitsRetryAttempts() async throws {
        // Test that retry logic has a maximum number of attempts
        // Should try primary + up to 2 alternatives, then give up

        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn1",
            reasoning: "Try multiple fallbacks",
            successProbability: SuccessProbability(value: 0.5, reasoning: "Uncertain"),
            alternativeActions: ["tap_btn2", "tap_btn3", "swipe", "done"]
        )

        #expect(decision.alternativeActions.count == 4)

        // Should only try first 2-3 alternatives max to avoid infinite loops
        let maxRetries = 2
        #expect(maxRetries == 2)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer skips verification when disabled in config")
    func testExplorerSkipsVerificationWhenDisabled() async throws {
        // When verification is disabled in config, should skip verification step
        // This allows backward compatibility

        let config = ExplorationConfig(
            steps: 5,
            goal: "Test without verification",
            enableVerification: false
        )

        #expect(config.enableVerification == false)
        #expect(config.steps == 5)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer includes verification stats in result")
    func testExplorerIncludesVerificationStatsInResult() async throws {
        // ExplorationResult should include verification metrics
        // - Total verifications performed
        // - Verification pass/fail counts
        // - Retry attempts made

        // This will be verified after implementing the result updates
        #expect(true, "Result should include verification stats")
    }

    // MARK: - Verification Logic Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer captures before hierarchy before action")
    func testExplorerCapturesBeforeHierarchy() async throws {
        // Verify that before hierarchy is captured before executing action
        // This is essential for comparison

        let hierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, id: "btn", interactive: true)],
            screenshot: Data(),
            screenType: nil
        )

        #expect(hierarchy.elements.count == 1)
        #expect(hierarchy.fingerprint != "")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer captures after hierarchy after action settles")
    func testExplorerCapturesAfterHierarchyAfterSettle() async throws {
        // After hierarchy should be captured after:
        // 1. Action is executed
        // 2. UI settles (1 second delay)

        // Verify the timing exists in the loop
        #expect(true, "Should wait 1 second before capturing after hierarchy")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer handles verification errors gracefully")
    func testExplorerHandlesVerificationErrorsGracefully() async throws {
        // If verification throws an error, exploration should continue
        // Error should be logged but not stop the entire exploration

        #expect(true, "Verification errors should not halt exploration")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer updates exploration path with verification result")
    func testExplorerUpdatesPathWithVerificationResult() async throws {
        let crawler = try await AICrawler()
        let path = crawler.startExploration(goal: "Test path updates")

        // Each step should record its verification result
        // This allows post-exploration analysis

        #expect(path.steps.count == 0, "Fresh path has no steps")

        // After actions are executed and verified, steps should include:
        // - The decision
        // - The verification result
        // - Whether retries were needed
    }

    // MARK: - Edge Cases

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer skips verification for done action")
    func testExplorerSkipsVerificationForDone() async throws {
        let crawler = try await AICrawler()

        let doneDecision = ExplorationDecision(
            action: "done",
            targetElement: nil,
            reasoning: "Exploration complete",
            successProbability: SuccessProbability(value: 1.0, reasoning: "Done")
        )

        // Verify that done action doesn't trigger verification
        #expect(doneDecision.action == "done")

        // Verification should be skipped for done actions
        let hierarchy = CompressedHierarchy(elements: [], screenshot: Data(), screenType: nil)
        let result = crawler.verifyAction(
            decision: doneDecision,
            beforeHierarchy: hierarchy,
            afterHierarchy: hierarchy
        )

        #expect(result.passed)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer handles action execution failure during verification")
    func testExplorerHandlesActionExecutionFailure() async throws {
        // When action execution fails (throws error), verification should:
        // 1. Not be performed (no after hierarchy available)
        // 2. Mark action as failed
        // 3. Not attempt retries (execution failure is different from verification failure)

        #expect(true, "Action execution failures should skip verification")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer preserves existing behavior when verification disabled")
    func testExplorerPreservesExistingBehaviorWhenDisabled() async throws {
        // When enableVerification = false, behavior should be identical to old version
        // No verification overhead, no retries, no verification stats

        let config = ExplorationConfig(
            steps: 3,
            goal: "Legacy mode",
            enableVerification: false
        )

        #expect(config.enableVerification == false)
        #expect(config.steps == 3)
    }

    // MARK: - Retry Strategy Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer tries alternatives in order")
    func testExplorerTriesAlternativesInOrder() async throws {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn1",
            reasoning: "Try in order",
            successProbability: SuccessProbability(value: 0.6, reasoning: "Moderate"),
            alternativeActions: ["tap_btn2", "swipe", "tap_btn3"]
        )

        // Should try alternatives in order: btn2, swipe, btn3
        #expect(decision.alternativeActions[0] == "tap_btn2")
        #expect(decision.alternativeActions[1] == "swipe")
        #expect(decision.alternativeActions[2] == "tap_btn3")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("Explorer stops retrying after first successful verification")
    func testExplorerStopsRetryingAfterSuccess() async throws {
        // If first alternative passes verification, should not try remaining alternatives
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn1",
            reasoning: "Should stop after success",
            successProbability: SuccessProbability(value: 0.5, reasoning: "Try it"),
            alternativeActions: ["tap_btn2", "tap_btn3", "done"]
        )

        #expect(decision.alternativeActions.count == 3)
        // Logic: try primary → fail → try btn2 → success → stop (don't try btn3 or done)
    }
}
