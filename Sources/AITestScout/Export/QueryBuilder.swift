import Foundation
import XCTest

/// Generates XCUITest query strings for locating elements in test code
///
/// This utility converts element metadata into valid Swift code that can be used
/// by LLMs to generate working XCUITests. It provides multiple query strategies
/// to maximize test reliability.
///
/// Example:
/// ```swift
/// let queries = QueryBuilder.buildQueries(
///     elementType: .textField,
///     id: "emailField",
///     label: "Email",
///     index: 0
/// )
/// // queries.primary = "app.textFields[\"emailField\"]"
/// // queries.byLabel = "app.textFields[\"Email\"]"
/// // queries.byType = "app.textFields.element(boundBy: 0)"
/// ```
public enum QueryBuilder {

    /// Builds comprehensive query strategies for an element
    /// - Parameters:
    ///   - elementType: The XCUIElement.ElementType
    ///   - id: The accessibility identifier (if any)
    ///   - label: The accessibility label (if any)
    ///   - index: The element's index among siblings of the same type
    /// - Returns: ElementQueries with multiple query strategies
    public static func buildQueries(
        elementType: XCUIElement.ElementType,
        id: String?,
        label: String?,
        index: Int = 0
    ) -> ElementQueries {
        let typeString = elementTypeQueryString(elementType)
        var alternatives: [String] = []

        // Primary: by identifier (most reliable if available)
        let primary: String
        if let id = id, !id.isEmpty {
            primary = "app.\(typeString)[\"\(escapeString(id))\"]"
        } else if let label = label, !label.isEmpty {
            primary = "app.\(typeString)[\"\(escapeString(label))\"]"
        } else {
            primary = "app.\(typeString).element(boundBy: \(index))"
        }

        // By label (alternative if primary used ID)
        let byLabel: String?
        if let label = label, !label.isEmpty, id != nil {
            byLabel = "app.\(typeString)[\"\(escapeString(label))\"]"
        } else {
            byLabel = nil
        }

        // By type and index
        let byType = "app.\(typeString).element(boundBy: \(index))"

        // Alternative: using descendants with predicate (most flexible)
        if let id = id, !id.isEmpty {
            alternatives.append(
                "app.descendants(matching: .\(elementTypeShortString(elementType))).matching(identifier: \"\(escapeString(id))\").firstMatch"
            )
        }

        if let label = label, !label.isEmpty {
            alternatives.append(
                "app.descendants(matching: .\(elementTypeShortString(elementType))).matching(NSPredicate(format: \"label == %@\", \"\(escapeString(label))\")).firstMatch"
            )
        }

        return ElementQueries(
            primary: primary,
            byLabel: byLabel,
            byType: byType,
            alternatives: alternatives
        )
    }

    /// Converts XCUIElement.ElementType to query string (e.g., .button → "buttons")
    private static func elementTypeQueryString(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .button: return "buttons"
        case .textField: return "textFields"
        case .secureTextField: return "secureTextFields"
        case .staticText: return "staticTexts"
        case .image: return "images"
        case .icon: return "icons"
        case .searchField: return "searchFields"
        case .scrollView: return "scrollViews"
        case .table: return "tables"
        case .cell: return "cells"
        case .switch: return "switches"
        case .toggle: return "toggles"
        case .link: return "links"
        case .slider: return "sliders"
        case .stepper: return "steppers"
        case .picker: return "pickers"
        case .pickerWheel: return "pickerWheels"
        case .tab: return "tabs"
        case .tabBar: return "tabBars"
        case .tabGroup: return "tabGroups"
        case .segmentedControl: return "segmentedControls"
        case .pageIndicator: return "pageIndicators"
        case .navigationBar: return "navigationBars"
        case .toolbar: return "toolbars"
        case .collectionView: return "collectionViews"
        case .webView: return "webViews"
        case .alert: return "alerts"
        case .dialog: return "dialogs"
        case .sheet: return "sheets"
        case .activityIndicator: return "activityIndicators"
        case .progressIndicator: return "progressIndicators"
        case .map: return "maps"
        case .menuItem: return "menuItems"
        case .menu: return "menus"
        case .menuBar: return "menuBars"
        case .window: return "windows"
        case .keyboard: return "keyboards"
        default: return "otherElements"
        }
    }

    /// Converts XCUIElement.ElementType to short enum string (e.g., .button → "button")
    private static func elementTypeShortString(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .button: return "button"
        case .textField: return "textField"
        case .secureTextField: return "secureTextField"
        case .staticText: return "staticText"
        case .image: return "image"
        case .icon: return "icon"
        case .searchField: return "searchField"
        case .scrollView: return "scrollView"
        case .table: return "table"
        case .cell: return "cell"
        case .switch: return "switch"
        case .toggle: return "toggle"
        case .link: return "link"
        case .slider: return "slider"
        case .stepper: return "stepper"
        case .picker: return "picker"
        case .pickerWheel: return "pickerWheel"
        case .tab: return "tab"
        case .tabBar: return "tabBar"
        case .tabGroup: return "tabGroup"
        case .segmentedControl: return "segmentedControl"
        case .pageIndicator: return "pageIndicator"
        case .navigationBar: return "navigationBar"
        case .toolbar: return "toolbar"
        case .collectionView: return "collectionView"
        case .webView: return "webView"
        case .alert: return "alert"
        case .dialog: return "dialog"
        case .sheet: return "sheet"
        case .activityIndicator: return "activityIndicator"
        case .progressIndicator: return "progressIndicator"
        case .map: return "map"
        case .menuItem: return "menuItem"
        case .menu: return "menu"
        case .menuBar: return "menuBar"
        case .window: return "window"
        case .keyboard: return "keyboard"
        default: return "any"
        }
    }

    /// Escapes special characters in strings for Swift string literals
    private static func escapeString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
