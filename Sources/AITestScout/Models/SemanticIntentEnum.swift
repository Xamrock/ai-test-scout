import Foundation

/// The semantic intent of a UI element
public enum SemanticIntent: String, Codable, Equatable, Sendable {
    case submit = "submit"            // Positive actions: Submit, Login, Save, Send, Continue
    case cancel = "cancel"            // Dismissive actions: Cancel, Close, Back, Skip
    case destructive = "destructive"  // Dangerous actions: Delete, Remove, Logout
    case navigation = "navigation"    // Navigation: Settings, Profile, Home, Menu
    case neutral = "neutral"          // No specific intent
}
