import Foundation
import XCTest

/// Represents a categorized element with type and interactivity information
public struct ElementCategory: Equatable {
    public let type: String
    public let interactive: Bool

    public init(type: String, interactive: Bool) {
        self.type = type
        self.interactive = interactive
    }
}

/// Protocol for categorizing XCUIElement types into simplified representations
public protocol ElementCategorizerProtocol: Sendable {
    /// Categorizes an XCUIElement type into a simplified representation
    /// - Parameter elementType: The XCUIElement.ElementType to categorize
    /// - Returns: An ElementCategory with simplified type name and interactivity flag
    func categorize(_ elementType: XCUIElement.ElementType) -> ElementCategory

    /// Determines if an element type should be skipped during hierarchy capture
    /// - Parameter elementType: The XCUIElement.ElementType to check
    /// - Returns: True if the element should be skipped (system UI, keyboard)
    func shouldSkip(_ elementType: XCUIElement.ElementType) -> Bool
}

/// Default implementation of ElementCategorizerProtocol with standard UI element mappings
public final class DefaultElementCategorizer: ElementCategorizerProtocol, @unchecked Sendable {

    public init() {}

    public func categorize(_ elementType: XCUIElement.ElementType) -> ElementCategory {
        switch elementType {
        // Interactive input elements
        case .textField, .secureTextField, .searchField:
            return ElementCategory(type: "input", interactive: true)

        // Buttons and clickable elements
        case .button, .radioButton, .checkBox, .menuButton, .toolbarButton, .popUpButton:
            return ElementCategory(type: "button", interactive: true)

        // Toggle elements
        case .switch, .toggle:
            return ElementCategory(type: "toggle", interactive: true)

        // Links
        case .link:
            return ElementCategory(type: "link", interactive: true)

        // Scrollable containers
        case .scrollView, .table, .collectionView, .outline:
            return ElementCategory(type: "scrollable", interactive: true)

        // Static text
        case .staticText:
            return ElementCategory(type: "text", interactive: false)

        // Images
        case .image, .icon:
            return ElementCategory(type: "image", interactive: false)

        // Pickers
        case .picker, .pickerWheel, .datePicker:
            return ElementCategory(type: "picker", interactive: true)

        // Sliders and steppers
        case .slider, .stepper:
            return ElementCategory(type: "slider", interactive: true)

        // Segmented controls and tab bars
        case .segmentedControl, .tab, .tabBar, .tabGroup:
            return ElementCategory(type: "tab", interactive: true)

        // Containers and layout elements (non-interactive)
        case .group, .other, .layoutArea, .layoutItem, .splitGroup, .cell:
            return ElementCategory(type: "container", interactive: false)

        // System UI (usually skipped, but categorized just in case)
        case .application, .window, .menuBar, .menuBarItem, .menu, .menuItem,
             .statusBar, .statusItem, .touchBar, .toolbar, .navigationBar:
            return ElementCategory(type: "system", interactive: false)

        // Everything else as container
        default:
            return ElementCategory(type: "container", interactive: false)
        }
    }

    public func shouldSkip(_ elementType: XCUIElement.ElementType) -> Bool {
        switch elementType {
        // System UI elements
        case .menuBar, .menuBarItem, .menu, .menuItem,
             .statusBar, .statusItem, .touchBar, .toolbar:
            return true

        // Keyboard elements - skip to prevent AI from analyzing keyboard keys
        case .keyboard, .key:
            return true

        default:
            return false
        }
    }
}
