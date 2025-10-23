import Testing
import Foundation
@testable import AITestScout

@Suite("Enhanced Decision Tests")
struct EnhancedDecisionTests {

    // MARK: - SuccessProbability Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("SuccessProbability initializes with valid probability")
    func testSuccessProbabilityInit() {
        let prob = SuccessProbability(value: 0.75, reasoning: "Likely to succeed")

        #expect(prob.value == 0.75)
        #expect(prob.reasoning == "Likely to succeed")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("SuccessProbability clamps values to 0.0-1.0 range")
    func testSuccessProbabilityClamping() {
        let tooLow = SuccessProbability(value: -0.5, reasoning: "Test")
        #expect(tooLow.value == 0.0, "Should clamp negative values to 0.0")

        let tooHigh = SuccessProbability(value: 1.5, reasoning: "Test")
        #expect(tooHigh.value == 1.0, "Should clamp values > 1.0 to 1.0")

        let valid = SuccessProbability(value: 0.5, reasoning: "Test")
        #expect(valid.value == 0.5, "Should preserve valid values")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("SuccessProbability provides confidence levels")
    func testSuccessProbabilityConfidenceLevels() {
        let veryLow = SuccessProbability(value: 0.1, reasoning: "Test")
        #expect(veryLow.confidenceLevel == .veryLow)

        let low = SuccessProbability(value: 0.35, reasoning: "Test")
        #expect(low.confidenceLevel == .low)

        let medium = SuccessProbability(value: 0.55, reasoning: "Test")
        #expect(medium.confidenceLevel == .medium)

        let high = SuccessProbability(value: 0.75, reasoning: "Test")
        #expect(high.confidenceLevel == .high)

        let veryHigh = SuccessProbability(value: 0.95, reasoning: "Test")
        #expect(veryHigh.confidenceLevel == .veryHigh)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("SuccessProbability factory methods create correct instances")
    func testSuccessProbabilityFactoryMethods() {
        let certain = SuccessProbability.certain(reasoning: "Guaranteed")
        #expect(certain.value == 1.0)
        #expect(certain.reasoning == "Guaranteed")

        let unlikely = SuccessProbability.unlikely(reasoning: "Risky")
        #expect(unlikely.value == 0.2)
        #expect(unlikely.reasoning == "Risky")

        let moderate = SuccessProbability.moderate(reasoning: "50/50")
        #expect(moderate.value == 0.5)
        #expect(moderate.reasoning == "50/50")
    }

    // MARK: - ExplorationDecision Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision initializes with all properties")
    func testEnhancedDecisionInit() {
        let decision = ExplorationDecision(
            action: "tap_button",
            targetElement: "login_btn",
            reasoning: "User needs to log in",
            successProbability: SuccessProbability(value: 0.8, reasoning: "Button is visible and enabled"),
            expectedOutcome: "Login screen should appear",
            alternativeActions: ["tap_forgot_password", "tap_signup"]
        )

        #expect(decision.action == "tap_button")
        #expect(decision.targetElement == "login_btn")
        #expect(decision.reasoning == "User needs to log in")
        #expect(decision.successProbability.value == 0.8)
        #expect(decision.expectedOutcome == "Login screen should appear")
        #expect(decision.alternativeActions.count == 2)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision works without optional fields")
    func testEnhancedDecisionWithDefaults() {
        let decision = ExplorationDecision(
            action: "tap_button",
            targetElement: "submit",
            reasoning: "Submit the form",
            successProbability: SuccessProbability(value: 0.9, reasoning: "Form is complete")
        )

        #expect(decision.action == "tap_button")
        #expect(decision.targetElement == "submit")
        #expect(decision.expectedOutcome == nil)
        #expect(decision.alternativeActions.isEmpty)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision is Codable")
    func testEnhancedDecisionCodable() throws {
        let original = ExplorationDecision(
            action: "tap_button",
            targetElement: "test_btn",
            reasoning: "Test action",
            successProbability: SuccessProbability(value: 0.7, reasoning: "Likely"),
            expectedOutcome: "Button press registered",
            alternativeActions: ["swipe", "long_press"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExplorationDecision.self, from: data)

        #expect(decoded.action == original.action)
        #expect(decoded.targetElement == original.targetElement)
        #expect(decoded.reasoning == original.reasoning)
        #expect(decoded.successProbability.value == original.successProbability.value)
        #expect(decoded.expectedOutcome == original.expectedOutcome)
        #expect(decoded.alternativeActions == original.alternativeActions)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision is Sendable")
    func testEnhancedDecisionSendable() {
        let decision = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Test",
            successProbability: SuccessProbability(value: 0.5, reasoning: "Maybe")
        )

        Task {
            let _ = decision // Can be captured in async context
        }

        #expect(decision.action == "tap")
    }

    // MARK: - ConfidenceLevel Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ConfidenceLevel provides helpful descriptions")
    func testConfidenceLevelDescriptions() {
        #expect(ConfidenceLevel.veryLow.description.lowercased().contains("very low"))
        #expect(ConfidenceLevel.low.description.lowercased().contains("low"))
        #expect(ConfidenceLevel.medium.description.lowercased().contains("medium"))
        #expect(ConfidenceLevel.high.description.lowercased().contains("high"))
        #expect(ConfidenceLevel.veryHigh.description.lowercased().contains("very high"))
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ConfidenceLevel ordering is correct")
    func testConfidenceLevelOrdering() {
        #expect(ConfidenceLevel.veryLow < ConfidenceLevel.low)
        #expect(ConfidenceLevel.low < ConfidenceLevel.medium)
        #expect(ConfidenceLevel.medium < ConfidenceLevel.high)
        #expect(ConfidenceLevel.high < ConfidenceLevel.veryHigh)
    }

    // MARK: - Integration Tests

    @available(macOS 26.0, iOS 26.0, *)
    @Test("High confidence decisions should be preferred over low confidence")
    func testConfidenceComparison() {
        let highConfidence = ExplorationDecision(
            action: "tap_primary",
            targetElement: "primary_btn",
            reasoning: "Main action",
            successProbability: SuccessProbability(value: 0.9, reasoning: "Clear path")
        )

        let lowConfidence = ExplorationDecision(
            action: "tap_secondary",
            targetElement: "secondary_btn",
            reasoning: "Backup action",
            successProbability: SuccessProbability(value: 0.3, reasoning: "Uncertain")
        )

        #expect(highConfidence.successProbability.value > lowConfidence.successProbability.value)
        #expect(highConfidence.successProbability.confidenceLevel > lowConfidence.successProbability.confidenceLevel)
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("ExplorationDecision provides richer context than basic decision")
    func testEnhancedVsBasicDecision() {
        let enhanced = ExplorationDecision(
            action: "tap",
            targetElement: "btn",
            reasoning: "Test",
            successProbability: SuccessProbability(value: 0.8, reasoning: "High confidence"),
            expectedOutcome: "Action completes",
            alternativeActions: ["swipe", "long_press"]
        )

        // Enhanced decision has additional fields that basic CrawlerDecision doesn't
        #expect(enhanced.successProbability.value > 0.0, "Has success probability")
        #expect(enhanced.expectedOutcome != nil, "Has expected outcome")
        #expect(enhanced.alternativeActions.isEmpty == false, "Has alternatives")
    }

    @available(macOS 26.0, iOS 26.0, *)
    @Test("SuccessProbability reasoning guides decision making")
    func testReasoningGuidance() {
        let prob = SuccessProbability(
            value: 0.85,
            reasoning: "Element is visible, enabled, and user intent is clear"
        )

        #expect(prob.reasoning.isEmpty == false, "Reasoning should be provided")
        #expect(prob.confidenceLevel == .veryHigh, "0.85 should map to very high confidence (80-100%)")
    }
}
