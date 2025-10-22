import Foundation

/// XCUITest query strategies for locating an element in test code
///
/// Provides multiple approaches to find the same element, allowing LLMs to generate
/// robust tests that can adapt if one query method fails.
///
/// Example:
/// ```swift
/// let queries = ElementQueries(
///     primary: "app.textFields[\"emailField\"]",
///     byLabel: "app.textFields[\"Email\"]",
///     byType: "app.textFields.element(boundBy: 0)",
///     alternatives: [
///         "app.descendants(matching: .textField).matching(identifier: \"emailField\").firstMatch"
///     ]
/// )
/// ```
public struct ElementQueries: Codable, Equatable {
    /// Primary query strategy (most reliable, usually by identifier)
    public let primary: String

    /// Alternative query using the element's label
    public let byLabel: String?

    /// Alternative query using element type and index
    public let byType: String?

    /// Additional fallback query strategies
    public let alternatives: [String]

    public init(
        primary: String,
        byLabel: String? = nil,
        byType: String? = nil,
        alternatives: [String] = []
    ) {
        self.primary = primary
        self.byLabel = byLabel
        self.byType = byType
        self.alternatives = alternatives
    }
}
