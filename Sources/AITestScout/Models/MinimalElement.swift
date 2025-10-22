import Foundation

/// A minimal representation of a UI element optimized for AI token efficiency
public struct MinimalElement: Equatable, Codable, Sendable {
    /// The type of element
    public let type: ElementType

    /// Accessibility identifier if available
    public let id: String?

    /// User-visible label or text content
    public let label: String?

    /// Whether this element can be interacted with (tapped, typed into, etc.)
    public let interactive: Bool

    /// Current value of the element (for inputs, toggles, etc.)
    public let value: String?

    /// Semantic intent of the element
    /// Omitted from JSON if nil to save tokens
    public let intent: SemanticIntent?

    /// Semantic priority score (higher = more important for AI to consider)
    /// Omitted from JSON if nil to save tokens
    public let priority: Int?

    /// Child elements in the hierarchy (omitted from JSON if empty to save tokens)
    public let children: [MinimalElement]

    public init(
        type: ElementType,
        id: String? = nil,
        label: String? = nil,
        interactive: Bool,
        value: String? = nil,
        intent: SemanticIntent? = nil,
        priority: Int? = nil,
        children: [MinimalElement] = []
    ) {
        self.type = type
        self.id = id
        self.label = label
        self.interactive = interactive
        self.value = value
        self.intent = intent
        self.priority = priority
        self.children = children
    }

    // Custom encoding to omit empty/nil fields to save tokens
    enum CodingKeys: String, CodingKey {
        case type, id, label, interactive, value, intent, priority, children
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encode(interactive, forKey: .interactive)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(intent, forKey: .intent)
        try container.encodeIfPresent(priority, forKey: .priority)

        // Only encode children if not empty (saves tokens)
        if !children.isEmpty {
            try container.encode(children, forKey: .children)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ElementType.self, forKey: .type)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        interactive = try container.decode(Bool.self, forKey: .interactive)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        intent = try container.decodeIfPresent(SemanticIntent.self, forKey: .intent)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)

        // Default to empty array if children is not present (backward compatibility)
        children = try container.decodeIfPresent([MinimalElement].self, forKey: .children) ?? []
    }
}
