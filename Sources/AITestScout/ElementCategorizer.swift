import Foundation
import XCTest

/// Categorizes XCUIElement types into simplified string types for AI consumption
/// - Note: This enum delegates to DefaultElementCategorizer for backward compatibility
public enum ElementCategorizer {

    /// A categorized element with type and interactivity information
    /// - Note: Deprecated. Use ElementCategory instead.
    public struct Category {
        public let type: String
        public let interactive: Bool

        public init(type: String, interactive: Bool) {
            self.type = type
            self.interactive = interactive
        }
    }

    /// Default categorizer instance for backward compatibility
    private static let defaultCategorizer = DefaultElementCategorizer()

    /// Categorizes an XCUIElement type into a simplified representation
    /// - Parameter elementType: The XCUIElement.ElementType to categorize
    /// - Returns: A Category with simplified type name and interactivity flag
    /// - Note: Delegates to DefaultElementCategorizer for consistent behavior
    public static func categorize(_ elementType: XCUIElement.ElementType) -> Category {
        let category = defaultCategorizer.categorize(elementType)
        return Category(type: category.type, interactive: category.interactive)
    }

    /// Determines if an element type should be skipped during hierarchy capture
    /// - Parameter elementType: The XCUIElement.ElementType to check
    /// - Returns: True if the element should be skipped (system UI, keyboard)
    /// - Note: Delegates to DefaultElementCategorizer for consistent behavior
    public static func shouldSkip(_ elementType: XCUIElement.ElementType) -> Bool {
        return defaultCategorizer.shouldSkip(elementType)
    }
}
