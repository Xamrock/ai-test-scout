import Foundation
import XCTest

/// Helper utility for handling keyboard interactions in iOS UI tests
/// Particularly useful for iOS 26+ where keyboard UI changed to icon-based buttons
public class KeyboardHelper {

    /// Dismisses the keyboard if currently visible
    /// - Parameter app: The XCUIApplication instance
    /// - Returns: True if keyboard was dismissed successfully, false otherwise
    @MainActor
    @discardableResult
    public static func dismissKeyboard(in app: XCUIApplication) -> Bool {
        // Check if keyboard is visible first
        guard app.keyboards.firstMatch.exists else {
            return true // No keyboard showing, already "dismissed"
        }

        let keyboard = app.keyboards.firstMatch

        // Strategy 1: Find return/action button in keyboard
        // iOS 26+ uses icon-based return keys without text labels
        if let actionButton = findKeyboardActionButton(in: keyboard) {
            actionButton.tap()
            usleep(200_000) // 0.2 seconds for animation

            if !app.keyboards.firstMatch.exists {
                return true
            }
        }

        // Strategy 2: Tap outside keyboard area (top of screen)
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        coordinate.tap()
        usleep(200_000)

        if !app.keyboards.firstMatch.exists {
            return true
        }

        // Strategy 3: Swipe down on keyboard
        keyboard.swipeDown()
        usleep(300_000) // 0.3 seconds

        // Final check
        return !app.keyboards.firstMatch.exists
    }

    /// Finds a keyboard action button (Return, Done, Go, Search, Send, etc.)
    /// - Parameter keyboard: The keyboard XCUIElement
    /// - Returns: The action button if found, nil otherwise
    @MainActor
    private static func findKeyboardActionButton(in keyboard: XCUIElement) -> XCUIElement? {
        // First try: Look for button with "Return" identifier (most common)
        let returnButton = keyboard.buttons.matching(identifier: "Return").firstMatch
        if returnButton.exists {
            return returnButton
        }

        // Second try: Search through keyboard buttons for action keywords
        let actionTerms = ["return", "done", "go", "search", "send", "next", "join"]
        let buttons = keyboard.buttons
        let buttonCount = min(buttons.count, 15) // Limit search to avoid performance issues

        for i in 0..<buttonCount {
            let button = buttons.element(boundBy: i)

            guard button.exists else { continue }

            let label = button.label.lowercased()
            let identifier = button.identifier.lowercased()

            // Check if this button matches any action term
            for term in actionTerms {
                if label.contains(term) || identifier.contains(term) {
                    return button
                }
            }
        }

        return nil
    }

    /// Checks if the keyboard is currently visible
    /// - Parameter app: The XCUIApplication instance
    /// - Returns: True if keyboard is visible
    @MainActor
    public static func isKeyboardVisible(in app: XCUIApplication) -> Bool {
        return app.keyboards.firstMatch.exists
    }
}
