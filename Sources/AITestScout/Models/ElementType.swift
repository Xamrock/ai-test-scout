import Foundation

/// Represents the type of a UI element
public enum ElementType: String, Codable, Equatable, Sendable {
    case button = "button"
    case input = "input"
    case text = "text"
    case image = "image"
    case toggle = "toggle"
    case link = "link"
    case tab = "tab"
    case scrollable = "scrollable"
    case container = "container"
    case picker = "picker"
    case slider = "slider"
}
