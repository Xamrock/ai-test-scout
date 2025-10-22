import Foundation

/// Types of actions that can be performed on UI elements
public enum ActionType: String, Codable, Hashable {
    case tap
    case type
    case swipe
    case back
    case done
}
