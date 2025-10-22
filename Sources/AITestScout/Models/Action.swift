import Foundation

/// Represents an action that causes a screen transition
public struct Action: Codable, Hashable {
    /// The type of action performed
    public let type: ActionType

    /// The element that was interacted with (if applicable)
    public let targetElement: String?

    /// Text that was typed (for type actions)
    public let textTyped: String?

    /// AI reasoning for why this action was taken
    public let reasoning: String

    /// Confidence level (0-100)
    public let confidence: Int

    public init(
        type: ActionType,
        targetElement: String? = nil,
        textTyped: String? = nil,
        reasoning: String,
        confidence: Int = 100
    ) {
        self.type = type
        self.targetElement = targetElement
        self.textTyped = textTyped
        self.reasoning = reasoning
        self.confidence = min(100, max(0, confidence))
    }
}
