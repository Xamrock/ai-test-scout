import Foundation
import XCTest

/// Delegate protocol for customizing HierarchyAnalyzer behavior at key extension points
///
/// All methods are optional. Implement only the methods you need to customize specific behavior.
///
/// Example:
/// ```swift
/// class MyDelegate: HierarchyAnalyzerDelegate {
///     func shouldInclude(_ element: MinimalElement) -> Bool {
///         // Only include elements with IDs
///         return element.id != nil
///     }
///
///     func priorityForElement(_ element: MinimalElement) -> Int? {
///         // Custom priority for search fields
///         if element.type == "input" && element.id?.contains("search") == true {
///             return 999
///         }
///         return nil // Use default priority
///     }
///  }
/// ```
public protocol HierarchyAnalyzerDelegate: AnyObject {

    // MARK: - Lifecycle Methods

    /// Called when hierarchy capture is about to begin
    func willBeginCapture()

    /// Called before compression with full access to all captured elements
    /// - Parameters:
    ///   - app: The XCUIApplication being analyzed (for custom queries)
    ///   - allElements: All elements captured before filtering/prioritization
    /// - Note: This is called BEFORE the 50-element limit is applied. Use this hook to run
    ///   comprehensive tools that need access to the complete hierarchy (accessibility scanners,
    ///   visual analyzers, etc.). This data is NOT sent to the AI, so it doesn't affect token usage.
    func willCompressHierarchy(app: XCUIApplication, allElements: [MinimalElement])

    /// Called when hierarchy capture has completed successfully
    /// - Parameter hierarchy: The captured and compressed hierarchy (top 50 elements for AI)
    func didCompleteCapture(_ hierarchy: CompressedHierarchy)

    /// Called when an error is encountered during capture
    /// - Parameter error: The error that occurred
    func didEncounterError(_ error: Error)

    // MARK: - Element Filtering Methods

    /// Determines whether an element should be included in the hierarchy
    /// - Parameter element: The element to evaluate
    /// - Returns: `true` to include the element, `false` to exclude it
    /// - Note: This is called in addition to the default filtering logic. Returning `false` will exclude the element even if it would normally be included.
    func shouldInclude(_ element: MinimalElement) -> Bool

    /// Determines whether children of an element should be processed
    /// - Parameter element: The parent element
    /// - Returns: `true` to process children, `false` to skip them
    func shouldProcessChildren(of element: MinimalElement) -> Bool

    // MARK: - Element Customization Methods

    /// Provides a custom priority for an element
    /// - Parameter element: The element to prioritize
    /// - Returns: Custom priority value, or `nil` to use default priority calculation
    /// - Note: If non-nil, this overrides both structural and semantic priority
    func priorityForElement(_ element: MinimalElement) -> Int?

    /// Transforms an element before it's added to the hierarchy
    /// - Parameter element: The original element
    /// - Returns: The transformed element, or `nil` to exclude it
    /// - Note: This is called after `shouldInclude`. Return `nil` to exclude the element.
    func transformElement(_ element: MinimalElement) -> MinimalElement?

    // MARK: - Element Context (Enhanced Export)

    /// Called when detailed context is captured for an element
    /// - Parameters:
    ///   - element: The minimal element
    ///   - context: Rich context with queries, frame, state, etc.
    /// - Note: This is called for elements that will be included in the hierarchy.
    ///   Use this to collect additional data for LLM test generation exports.
    func didCaptureElementContext(_ element: MinimalElement, context: ElementContext)
}

// MARK: - Default Implementations (All Optional)

public extension HierarchyAnalyzerDelegate {
    func willBeginCapture() { }

    func willCompressHierarchy(app: XCUIApplication, allElements: [MinimalElement]) { }

    func didCompleteCapture(_ hierarchy: CompressedHierarchy) { }

    func didEncounterError(_ error: Error) { }

    func shouldInclude(_ element: MinimalElement) -> Bool {
        return true // Include by default
    }

    func shouldProcessChildren(of element: MinimalElement) -> Bool {
        return true // Process children by default
    }

    func priorityForElement(_ element: MinimalElement) -> Int? {
        return nil // Use default priority
    }

    func transformElement(_ element: MinimalElement) -> MinimalElement? {
        return element // No transformation by default
    }

    func didCaptureElementContext(_ element: MinimalElement, context: ElementContext) { }
}
