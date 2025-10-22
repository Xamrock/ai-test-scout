import Foundation

/// Represents a generated XCUITest file with metadata
public struct GeneratedTest: Codable, Sendable {
    /// The name of the test method (e.g., "testLoginFlow")
    public let testName: String

    /// The complete Swift test code
    public let code: String

    /// The generation mode used
    public let mode: GenerationMode

    /// Metadata about the test
    public var metadata: TestMetadata

    public init(
        testName: String,
        code: String,
        mode: GenerationMode,
        metadata: TestMetadata
    ) {
        self.testName = testName
        self.code = code
        self.mode = mode
        self.metadata = metadata
    }

    /// Suggested filename based on test name
    /// E.g., "testLoginFlow" → "LoginFlowTests.swift"
    public var suggestedFilename: String {
        // Remove "test" prefix
        let name = testName.hasPrefix("test") ?
            String(testName.dropFirst(4)) : testName

        // Convert camelCase to PascalCase if needed
        let pascalName = name.prefix(1).uppercased() + name.dropFirst()

        return "\(pascalName)Tests.swift"
    }

    /// Write the test code to a file
    /// - Parameter url: The file URL to write to
    /// - Throws: File writing errors
    public func writeToFile(url: URL) throws {
        try code.write(to: url, atomically: true, encoding: .utf8)
    }
}

/// Metadata about a generated test
public struct TestMetadata: Codable, Sendable {
    /// Screen fingerprints covered by this test
    public var screensCovered: [String]

    /// Number of elements tested
    public var elementsTested: Int

    /// Estimated runtime in seconds
    public var estimatedRuntime: Double

    /// Number of assertions in the test
    public var assertionCount: Int

    /// Number of user interactions (taps, types, swipes)
    public var interactionCount: Int

    public init(
        screensCovered: [String] = [],
        elementsTested: Int = 0,
        estimatedRuntime: Double = 0,
        assertionCount: Int = 0,
        interactionCount: Int = 0
    ) {
        self.screensCovered = screensCovered
        self.elementsTested = elementsTested
        self.estimatedRuntime = estimatedRuntime
        self.assertionCount = assertionCount
        self.interactionCount = interactionCount
    }

    /// Empty metadata
    public static let empty = TestMetadata()
}

/// Mode used for test generation
public enum GenerationMode: Codable, Sendable {
    /// Generate test for a specific user flow
    case flow(screens: [String])

    /// Generate test for a single screen
    case screen(fingerprint: String)

    /// Generate comprehensive test suite
    case full

    /// Whether this is flow mode
    public var isFlow: Bool {
        if case .flow = self { return true }
        return false
    }

    /// Whether this is screen mode
    public var isScreen: Bool {
        if case .screen = self { return true }
        return false
    }

    /// Whether this is full mode
    public var isFull: Bool {
        if case .full = self { return true }
        return false
    }
}
