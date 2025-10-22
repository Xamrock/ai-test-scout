import Foundation
import CoreGraphics

/// Additional context about an element for LLM test generation
///
/// This structure captures detailed state and positioning information that enables
/// LLMs to generate accurate XCUITest code, including proper waits, assertions,
/// and element queries.
///
/// **Design Note**: This is a separate struct (not part of MinimalElement) to maintain
/// backward compatibility. Existing code using MinimalElement continues to work unchanged.
///
/// Example:
/// ```swift
/// let context = ElementContext(
///     xcuiElementType: "XCUIElementTypeTextField",
///     frame: CGRect(x: 20, y: 200, width: 335, height: 44),
///     isEnabled: true,
///     isVisible: true,
///     isHittable: true,
///     hasFocus: false,
///     queries: ElementQueries(primary: "app.textFields[\"emailField\"]")
/// )
/// ```
public struct ElementContext: Codable, Equatable {
    /// The raw XCUIElement.ElementType name (e.g., "XCUIElementTypeButton")
    /// Needed for generating proper element type queries in test code
    public let xcuiElementType: String

    /// The element's frame in screen coordinates
    /// Useful for visual assertions and debugging positioning issues
    public let frame: CGRect

    /// Whether the element is enabled for interaction
    public let isEnabled: Bool

    /// Whether the element is visible on screen (not hidden, alpha > 0)
    public let isVisible: Bool

    /// Whether the element can be tapped (visible, enabled, not obscured)
    /// This is the most important state for generating reliable tests
    public let isHittable: Bool

    /// Whether the element currently has keyboard/input focus
    /// Important for text input scenarios
    public let hasFocus: Bool

    /// XCUITest query strategies for finding this element
    public let queries: ElementQueries

    /// Optional accessibility traits (e.g., ["button"], ["textField", "updatesFrequently"])
    public let accessibilityTraits: [String]?

    /// Optional accessibility hint for additional context
    public let accessibilityHint: String?

    public init(
        xcuiElementType: String,
        frame: CGRect,
        isEnabled: Bool,
        isVisible: Bool,
        isHittable: Bool,
        hasFocus: Bool,
        queries: ElementQueries,
        accessibilityTraits: [String]? = nil,
        accessibilityHint: String? = nil
    ) {
        self.xcuiElementType = xcuiElementType
        self.frame = frame
        self.isEnabled = isEnabled
        self.isVisible = isVisible
        self.isHittable = isHittable
        self.hasFocus = hasFocus
        self.queries = queries
        self.accessibilityTraits = accessibilityTraits
        self.accessibilityHint = accessibilityHint
    }
}
