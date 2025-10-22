import Foundation

/// Types of screens detected by semantic analysis
public enum ScreenType: String, Codable, Equatable, Sendable {
    case login = "login"                    // Login/authentication screen
    case form = "form"                      // Data entry form
    case list = "list"                      // List/table view
    case settings = "settings"              // Settings/preferences
    case tabNavigation = "tabNavigation"    // Tab-based navigation
    case error = "error"                    // Error state
    case loading = "loading"                // Loading state
    case content = "content"                // Generic content screen
}
