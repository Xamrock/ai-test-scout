import Foundation

/// Metadata enriching an exploration session with context for LLM test generation
///
/// This structure bundles all the additional information (beyond basic exploration steps)
/// that an LLM needs to generate high-quality, reproducible tests.
///
/// **Design Note**: This is optional metadata that can be attached to an ExplorationPath
/// without modifying the core ExplorationPath structure. This maintains backward compatibility.
///
/// Example:
/// ```swift
/// let metadata = ExplorationMetadata(
///     environment: EnvironmentCapture.capture(),
///     elementContexts: contextMap,
///     appContext: AppContext(
///         bundleId: "com.example.app",
///         appVersion: "1.0.0",
///         buildNumber: "100"
///     )
/// )
/// explorationPath.attachMetadata(metadata)
/// ```
public struct ExplorationMetadata: Codable, Equatable {
    /// Environment information (OS, device, screen size, etc.)
    public let environment: EnvironmentInfo

    /// Element contexts mapped by element key (type|id|label)
    /// Contains detailed state and query information for each element
    public let elementContexts: [String: ElementContext]

    /// Application context (bundle ID, version, build)
    public let appContext: AppContext

    public init(
        environment: EnvironmentInfo,
        elementContexts: [String: ElementContext],
        appContext: AppContext
    ) {
        self.environment = environment
        self.elementContexts = elementContexts
        self.appContext = appContext
    }
}

/// Information about the application under test
public struct AppContext: Codable, Equatable {
    /// Bundle identifier (e.g., "com.example.app")
    public let bundleId: String

    /// App version (e.g., "2.5.0")
    public let appVersion: String

    /// Build number (e.g., "145")
    public let buildNumber: String

    /// Launch arguments passed to the app during testing
    public let launchArguments: [String]

    /// Launch environment variables
    public let launchEnvironment: [String: String]

    public init(
        bundleId: String,
        appVersion: String,
        buildNumber: String,
        launchArguments: [String] = [],
        launchEnvironment: [String: String] = [:]
    ) {
        self.bundleId = bundleId
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.launchArguments = launchArguments
        self.launchEnvironment = launchEnvironment
    }
}
