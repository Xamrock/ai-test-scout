import Foundation
import CryptoKit

/// Represents a compressed view hierarchy optimized for AI consumption
public struct CompressedHierarchy: Codable, Sendable {
    /// Current schema version for this hierarchy format
    public static let currentVersion = "1.0"

    /// The minimal elements in the hierarchy
    public let elements: [MinimalElement]

    /// Screenshot data for visual context
    public let screenshot: Data

    /// Detected screen type (login, form, list, settings, etc.)
    /// Helps AI understand context and make better decisions
    public let screenType: ScreenType?

    /// Schema version for this hierarchy (enables backward compatibility)
    public let version: String?

    /// Unique fingerprint for this screen (SHA-256 hash)
    /// Combines structural data (elements) with visual data (screenshot)
    /// Cached at initialization for performance
    public let fingerprint: String

    public init(
        elements: [MinimalElement],
        screenshot: Data,
        screenType: ScreenType? = nil,
        version: String? = CompressedHierarchy.currentVersion
    ) {
        self.elements = elements
        self.screenshot = screenshot
        self.screenType = screenType
        self.version = version
        // Compute fingerprint once at initialization
        self.fingerprint = Self.generateFingerprint(elements: elements, screenshot: screenshot)
    }

    // Custom coding keys to exclude fingerprint from encoding
    private enum CodingKeys: String, CodingKey {
        case elements
        case screenshot
        case screenType
        case version
    }

    /// Custom decoder to recompute fingerprint after decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.elements = try container.decode([MinimalElement].self, forKey: .elements)
        self.screenshot = try container.decode(Data.self, forKey: .screenshot)
        self.screenType = try container.decodeIfPresent(ScreenType.self, forKey: .screenType)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        // Recompute fingerprint from decoded data
        self.fingerprint = Self.generateFingerprint(elements: elements, screenshot: screenshot)
    }

    /// Generate a unique fingerprint for this screen
    /// Uses only structural elements (type, id, label) to ensure stable fingerprints
    /// across identical screens with minor visual differences (animations, timestamps, etc.)
    private static func generateFingerprint(elements: [MinimalElement], screenshot: Data) -> String {
        // Create structural signature from elements
        let structuralSignature = elements.map { element in
            "\(element.type.rawValue):\(element.id ?? ""):\(element.label ?? "")"
        }.joined(separator: "|")

        // Hash the structural signature
        let structuralData = Data(structuralSignature.utf8)
        let structuralHash = SHA256.hash(data: structuralData)

        // Convert to hex string (using only structural hash for stability)
        return structuralHash.map { String(format: "%02x", $0) }.joined()
    }

    /// Converts the hierarchy to compact JSON format for AI consumption
    /// - Parameters:
    ///   - includeScreenshot: Whether to include the base64-encoded screenshot (default: false)
    ///   - interactiveOnly: Whether to include only interactive elements (default: false)
    /// - Returns: JSON data optimized for AI token efficiency
    /// - Throws: Encoding errors if serialization fails
    public func toJSON(includeScreenshot: Bool = false, interactiveOnly: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // Compact output (no pretty printing)

        // Filter elements if requested
        let elementsToEncode = interactiveOnly ? filterInteractiveElements(elements) : elements

        if includeScreenshot {
            // Include screenshot for human consumption or debugging
            let jsonOutput = JSONOutputWithScreenshot(
                version: version,
                elements: elementsToEncode,
                screenshot: screenshot.base64EncodedString(),
                screenType: screenType
            )
            return try encoder.encode(jsonOutput)
        } else {
            // Optimized for AI - no screenshot (Foundation Models can't process images)
            let jsonOutput = JSONOutput(
                version: version,
                elements: elementsToEncode,
                screenType: screenType
            )
            return try encoder.encode(jsonOutput)
        }
    }

    /// Recursively filters to keep only interactive elements and important non-interactive ones
    private func filterInteractiveElements(_ elements: [MinimalElement]) -> [MinimalElement] {
        elements.compactMap { element in
            // Keep interactive elements
            if element.interactive {
                // If it has children, filter them too
                if !element.children.isEmpty {
                    let filteredChildren = filterInteractiveElements(element.children)
                    return MinimalElement(
                        type: element.type,
                        id: element.id,
                        label: element.label,
                        interactive: element.interactive,
                        value: element.value,
                        intent: element.intent,
                        priority: element.priority,
                        children: filteredChildren
                    )
                }
                return element
            }

            // Keep non-interactive elements with IDs (developer marked as important)
            if element.id != nil {
                let filteredChildren = element.children.isEmpty ? [] : filterInteractiveElements(element.children)
                return MinimalElement(
                    type: element.type,
                    id: element.id,
                    label: element.label,
                    interactive: element.interactive,
                    value: element.value,
                    intent: element.intent,
                    priority: element.priority,
                    children: filteredChildren
                )
            }

            // Skip other non-interactive elements (text, images without IDs)
            return nil
        }
    }

    /// Optimized structure for AI consumption (no screenshot)
    private struct JSONOutput: Codable {
        let version: String?
        let elements: [MinimalElement]
        let screenType: ScreenType?
    }

    /// Full structure with screenshot for debugging/human consumption
    private struct JSONOutputWithScreenshot: Codable {
        let version: String?
        let elements: [MinimalElement]
        let screenshot: String
        let screenType: ScreenType?
    }
}
