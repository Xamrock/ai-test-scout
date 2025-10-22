import Foundation

/// Represents a unique screen in the app navigation graph
public struct ScreenNode: Codable, Hashable {
    /// Unique identifier for this screen (fingerprint)
    public let fingerprint: String

    /// The type of screen (login, form, list, etc.)
    public let screenType: ScreenType?

    /// The elements on this screen
    public let elements: [MinimalElement]

    /// Screenshot data (PNG)
    public let screenshot: Data

    /// When this screen was first captured
    public let timestamp: Date

    /// Number of steps from app launch
    public let depth: Int

    /// Text extracted via OCR (optional, for future use)
    public let ocrText: [String]?

    /// The fingerprint of the screen we came from
    public let parentFingerprint: String?

    /// How many times we've visited this screen
    public var visitCount: Int

    /// When we last visited this screen
    public var lastVisited: Date?

    /// User flows that include this screen
    public var userFlows: [String]

    public init(
        fingerprint: String,
        screenType: ScreenType?,
        elements: [MinimalElement],
        screenshot: Data,
        timestamp: Date = Date(),
        depth: Int,
        ocrText: [String]? = nil,
        parentFingerprint: String? = nil,
        visitCount: Int = 1,
        lastVisited: Date? = nil,
        userFlows: [String] = []
    ) {
        self.fingerprint = fingerprint
        self.screenType = screenType
        self.elements = elements
        self.screenshot = screenshot
        self.timestamp = timestamp
        self.depth = depth
        self.ocrText = ocrText
        self.parentFingerprint = parentFingerprint
        self.visitCount = visitCount
        self.lastVisited = lastVisited ?? timestamp
        self.userFlows = userFlows
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fingerprint)
    }

    public static func == (lhs: ScreenNode, rhs: ScreenNode) -> Bool {
        lhs.fingerprint == rhs.fingerprint
    }
}
