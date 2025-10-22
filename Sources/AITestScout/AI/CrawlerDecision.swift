import Foundation
import FoundationModels

/// Represents an AI's decision about what action to take next in the UI
@available(macOS 26.0, iOS 26.0, *)
@Generable
public struct CrawlerDecision: Codable, Sendable {
    /// Analysis of the current screen and reasoning for the decision
    @Guide(description: "Your step-by-step thinking about the current screen and what action makes sense")
    public let reasoning: String

    /// The action to take: 'tap', 'type', 'swipe', or 'done'
    @Guide(description: "Choose action type: 'tap' to tap element, 'type' to enter text, 'swipe' to scroll, or 'done' if exploration complete")
    public let action: String

    /// Element identifier or label to interact with (required for tap/type actions)
    @Guide(description: "CRITICAL: For action='tap' or action='type', you MUST provide the element id or label from the JSON (e.g. 'emailField', 'loginButton'). NEVER null for tap/type. Only null when action='done' or action='swipe'")
    public let targetElement: String?

    /// Text to type into an input field (only needed when action is 'type')
    @Guide(description: "Text to type into the field. Only provide when action is 'type', otherwise null")
    public let textToType: String?

    /// Confidence level 0-100 representing certainty in this decision
    @Guide(description: "Your confidence in this decision from 0 (uncertain) to 100 (very confident)")
    public let confidence: Int

    public init(
        reasoning: String,
        action: String,
        targetElement: String?,
        textToType: String?,
        confidence: Int
    ) {
        self.reasoning = reasoning
        self.action = action
        self.targetElement = targetElement
        self.textToType = textToType
        self.confidence = confidence
    }
}

/// Possible actions the crawler can take
public enum CrawlerAction: String, Codable {
    case tap
    case type
    case swipe
    case done
}
