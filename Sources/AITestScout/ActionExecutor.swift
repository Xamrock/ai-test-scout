import Foundation
import XCTest

/// Executes ExplorationDecisions on XCUIApplication
/// Wraps XCUIApplication element finding and interaction logic
@available(macOS 26.0, iOS 26.0, *)
@MainActor
public class ActionExecutor: @unchecked Sendable {
    private let app: XCUIApplication
    private let waitTimeout: TimeInterval

    /// Initialize action executor
    /// - Parameters:
    ///   - app: The XCUIApplication to execute actions on
    ///   - waitTimeout: How long to wait for elements (default: 5 seconds)
    nonisolated public init(app: XCUIApplication, waitTimeout: TimeInterval = 5) {
        self.app = app
        self.waitTimeout = waitTimeout
    }

    /// Execute an exploration decision
    /// - Parameter decision: The decision to execute
    /// - Returns: true if action was executed, false if "done"
    /// - Throws: ActionError if execution fails
    public func execute(_ decision: ExplorationDecision) throws -> Bool {
        switch decision.action {
        case "tap":
            try executeTap(decision)
            return true

        case "type":
            try executeType(decision)
            return true

        case "swipe":
            try executeSwipe()
            return true

        case "done":
            return false

        default:
            throw ActionError.unknownAction(decision.action)
        }
    }

    // MARK: - Private Execution Methods

    private func executeTap(_ decision: ExplorationDecision) throws {
        guard let target = decision.targetElement, !target.isEmpty else {
            throw ActionError.missingTarget
        }

        let element = findElement(target)

        guard element.waitForExistence(timeout: waitTimeout) else {
            throw ActionError.elementNotFound(target)
        }

        guard element.isHittable else {
            throw ActionError.executionFailed("Element '\(target)' exists but is not hittable")
        }

        element.tap()
    }

    private func executeType(_ decision: ExplorationDecision) throws {
        guard let target = decision.targetElement, !target.isEmpty else {
            throw ActionError.missingTarget
        }

        guard let text = decision.textToType, !text.isEmpty else {
            throw ActionError.missingText
        }

        let element = findElement(target)

        guard element.waitForExistence(timeout: waitTimeout) else {
            throw ActionError.elementNotFound(target)
        }

        // Check if this element type typically has keyboard focus issues
        // SwiftUI SearchFields have known XCUITest limitations
        let elementType = element.elementType
        if elementType == .searchField {
            // Known issue: SwiftUI SearchFields don't reliably accept keyboard focus in XCUITest
            throw ActionError.executionFailed("SwiftUI SearchField elements have known keyboard focus limitations in XCUITest. Element '\(target)' cannot reliably receive text input.")
        }

        // Try multiple approaches to focus and type into the field
        var lastError: Error?
        let approaches: [(String, () throws -> Void)] = [
            ("tap + typeText", {
                element.tap()
                Thread.sleep(forTimeInterval: 0.3)
                element.typeText(text)
            }),
            ("doubleTap + typeText", {
                element.doubleTap()
                Thread.sleep(forTimeInterval: 0.3)
                element.typeText(text)
            }),
            ("tap coordinate + typeText", {
                let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                coordinate.tap()
                Thread.sleep(forTimeInterval: 0.3)
                element.typeText(text)
            })
        ]

        // Try each approach until one works
        for (approachName, approach) in approaches {
            do {
                try approach()
                return // Success!
            } catch {
                lastError = error
                print("⚠️  Approach '\(approachName)' failed: \(error.localizedDescription)")
                continue
            }
        }

        // All approaches failed
        if let error = lastError {
            throw error
        } else {
            throw ActionError.executionFailed("All typing approaches failed for element '\(target)'")
        }
    }

    private func executeSwipe() throws {
        // Swipe up by default (most common for scrolling)
        app.swipeUp()
    }

    // MARK: - Element Finding

    /// Find an element by identifier
    /// Reuses XCUIApplication's descendants matching pattern
    /// - Parameter identifier: Element identifier or label
    /// - Returns: The found element (may not exist yet)
    private func findElement(_ identifier: String) -> XCUIElement {
        // This matches the existing pattern from the feedback
        return app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}

/// Errors that can occur during action execution
public enum ActionError: Error, LocalizedError {
    case unknownAction(String)
    case missingTarget
    case missingText
    case elementNotFound(String)
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unknownAction(let action):
            return "Unknown action: '\(action)'. Valid actions: tap, type, swipe, done"
        case .missingTarget:
            return "Action requires a target element identifier"
        case .missingText:
            return "Type action requires text to type"
        case .elementNotFound(let identifier):
            return "Element not found: '\(identifier)' (waited \(5) seconds)"
        case .executionFailed(let reason):
            return "Action execution failed: \(reason)"
        }
    }
}
