import Foundation
import XCTest

/// Extensions for XCUIApplication to simplify element finding and interaction
extension XCUIApplication {

    /// Find an element by identifier using the standard descendants pattern
    /// - Parameter identifier: Element identifier or accessibility identifier
    /// - Returns: XCUIElement (may not exist yet - call waitForExistence)
    public func findElement(_ identifier: String) -> XCUIElement {
        // Reuses existing XCUIApplication API
        // This is the standard pattern from feedback: app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        return descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Tap an element by identifier with automatic wait
    /// - Parameter identifier: Element identifier
    /// - Throws: ActionError if element not found or not hittable
    public func tapElement(_ identifier: String) throws {
        let element = findElement(identifier)

        guard element.waitForExistence(timeout: 5) else {
            throw ActionError.elementNotFound(identifier)
        }

        guard element.isHittable else {
            throw ActionError.executionFailed("Element '\(identifier)' exists but is not hittable")
        }

        element.tap()
    }

    /// Type text into an element by identifier with automatic wait and focus
    /// - Parameters:
    ///   - identifier: Element identifier
    ///   - text: Text to type
    /// - Throws: ActionError if element not found
    public func typeInElement(_ identifier: String, text: String) throws {
        let element = findElement(identifier)

        guard element.waitForExistence(timeout: 5) else {
            throw ActionError.elementNotFound(identifier)
        }

        // Tap to focus the field
        element.tap()

        // Type the text
        element.typeText(text)
    }
}
