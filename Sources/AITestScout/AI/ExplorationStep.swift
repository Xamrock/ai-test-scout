import Foundation

/// Represents a single step in the exploration journey
@available(macOS 26.0, iOS 26.0, *)
public struct ExplorationStep: Codable, Equatable {
    /// Unique identifier for this step
    public let id: UUID

    /// Timestamp when this step was taken
    public let timestamp: Date

    /// The action taken (tap, type, swipe, done)
    public let action: String

    /// The element that was interacted with (if applicable)
    public let targetElement: String?

    /// Text that was typed (if action was 'type')
    public let textTyped: String?

    /// A brief description of the screen at this step
    public let screenDescription: String

    /// Number of interactive elements visible on this screen
    public let interactiveElementCount: Int

    /// The AI's reasoning for taking this action
    public let reasoning: String

    /// Confidence level (0-100) for this decision
    public let confidence: Int

    /// Whether this step was successful (element found and interacted)
    public var wasSuccessful: Bool

    /// Optional verification result for this step (Phase 3)
    public let verificationResult: VerificationResult?

    /// Whether this step was a retry attempt from a failed verification
    public let wasRetry: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: String,
        targetElement: String?,
        textTyped: String?,
        screenDescription: String,
        interactiveElementCount: Int,
        reasoning: String,
        confidence: Int,
        wasSuccessful: Bool = true,
        verificationResult: VerificationResult? = nil,
        wasRetry: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.targetElement = targetElement
        self.textTyped = textTyped
        self.screenDescription = screenDescription
        self.interactiveElementCount = interactiveElementCount
        self.reasoning = reasoning
        self.confidence = confidence
        self.wasSuccessful = wasSuccessful
        self.verificationResult = verificationResult
        self.wasRetry = wasRetry
    }

    /// Creates an ExplorationStep from an ExplorationDecision
    public static func from(
        decision: ExplorationDecision,
        hierarchy: CompressedHierarchy,
        wasSuccessful: Bool = true,
        verificationResult: VerificationResult? = nil,
        wasRetry: Bool = false
    ) -> ExplorationStep {
        // Generate screen description from interactive elements
        let interactiveElements = hierarchy.elements.filter { $0.interactive }
        let elementSummary = interactiveElements.prefix(5).compactMap { element in
            if let id = element.id {
                return id
            } else if let label = element.label {
                return label
            }
            return nil
        }.joined(separator: ", ")

        let screenDesc = interactiveElements.isEmpty
            ? "Empty screen"
            : "Screen with: \(elementSummary)\(interactiveElements.count > 5 ? "..." : "")"

        return ExplorationStep(
            action: decision.action,
            targetElement: decision.targetElement,
            textTyped: decision.textToType,
            screenDescription: screenDesc,
            interactiveElementCount: interactiveElements.count,
            reasoning: decision.reasoning,
            confidence: decision.confidence,
            wasSuccessful: wasSuccessful,
            verificationResult: verificationResult,
            wasRetry: wasRetry
        )
    }

    /// Returns a compact string representation for displaying in prompts
    public func compactDescription() -> String {
        let target = targetElement ?? "none"
        let text = textTyped.map { " '\($0)'" } ?? ""
        return "\(action) \(target)\(text)"
    }
}
