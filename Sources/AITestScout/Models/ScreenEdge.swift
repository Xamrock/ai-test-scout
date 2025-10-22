import Foundation

/// Represents a transition between two screens
public struct ScreenEdge: Codable, Hashable {
    /// Unique identifier for this edge
    public let id: UUID

    /// Source screen fingerprint
    public let from: String

    /// Destination screen fingerprint
    public let to: String

    /// The action that caused this transition
    public let action: Action

    /// Network requests made during this transition (for future use)
    public let networkRequests: [String]?

    /// How long the transition took
    public let duration: TimeInterval

    /// When this transition occurred
    public let timestamp: Date

    /// Whether the action succeeded
    public let wasSuccessful: Bool

    public init(
        id: UUID = UUID(),
        from: String,
        to: String,
        action: Action,
        networkRequests: [String]? = nil,
        duration: TimeInterval,
        timestamp: Date = Date(),
        wasSuccessful: Bool = true
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.action = action
        self.networkRequests = networkRequests
        self.duration = duration
        self.timestamp = timestamp
        self.wasSuccessful = wasSuccessful
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ScreenEdge, rhs: ScreenEdge) -> Bool {
        lhs.id == rhs.id
    }
}
