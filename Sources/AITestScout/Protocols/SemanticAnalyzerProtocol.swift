import Foundation

/// Type alias for element group (maintains compatibility with SemanticAnalyzer.ElementGroup)
public typealias ElementGroup = DefaultSemanticAnalyzer.ElementGroup

/// Protocol for analyzing UI elements using semantic analysis
public protocol SemanticAnalyzerProtocol: Sendable {
    /// Detects the semantic intent of an element based on its label and identifier
    /// - Parameters:
    ///   - label: The user-visible label
    ///   - identifier: The accessibility identifier
    /// - Returns: The detected semantic intent
    func detectIntent(label: String?, identifier: String?) -> SemanticIntent

    /// Detects the type of screen based on element composition
    /// - Parameter elements: The elements on the screen
    /// - Returns: The detected screen type
    func detectScreenType(from elements: [MinimalElement]) -> ScreenType

    /// Calculates semantic priority for an element (higher = more important)
    /// - Parameter element: The element to analyze
    /// - Returns: Priority score (typically 0-200)
    func calculateSemanticPriority(_ element: MinimalElement) -> Int

    /// Groups semantically related elements together
    /// - Parameter elements: The elements to group
    /// - Returns: Array of element groups
    func groupRelatedElements(_ elements: [MinimalElement]) -> [ElementGroup]
}
