import Testing
import Foundation
@testable import AITestScout

@Suite("Versioning Tests")
struct VersioningTests {

    // MARK: - Version Field Tests

    @Test("CompressedHierarchy should have version field")
    func testHierarchyHasVersion() {
        // Arrange & Act
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        // Assert
        #expect(hierarchy.version != nil, "Hierarchy should have a version")
    }

    @Test("Version should default to current version")
    func testDefaultVersion() {
        // Arrange & Act
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        // Assert
        #expect(hierarchy.version == "1.0", "Default version should be 1.0")
    }

    @Test("Version should be settable via initializer")
    func testCustomVersionViaInit() {
        // Arrange & Act
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil,
            version: "2.0"
        )

        // Assert
        #expect(hierarchy.version == "2.0", "Should accept custom version")
    }

    @Test("Version should be included in JSON output")
    func testVersionInJSON() throws {
        // Arrange
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil,
            version: "1.0"
        )

        // Act
        let jsonData = try hierarchy.toJSON(includeScreenshot: false)
        let decoded = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Assert
        #expect(decoded["version"] as? String == "1.0", "Version should be in JSON")
    }

    @Test("Version should be omitted from JSON when nil")
    func testNilVersionOmittedFromJSON() throws {
        // Arrange
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil,
            version: nil
        )

        // Act
        let jsonData = try hierarchy.toJSON(includeScreenshot: false)
        let decoded = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Assert
        #expect(decoded["version"] == nil, "Nil version should be omitted from JSON")
    }

    // MARK: - Version Format Tests

    @Test("Version should support semantic versioning format")
    func testSemanticVersioningFormat() {
        // Arrange
        let versions = ["1.0.0", "2.1.3", "0.9.0", "10.5.2"]

        // Act & Assert
        for version in versions {
            let hierarchy = CompressedHierarchy(
                elements: [],
                screenshot: Data(),
                screenType: nil,
                version: version
            )
            #expect(hierarchy.version == version, "Should support semantic version: \(version)")
        }
    }

    @Test("Version should support simple version format")
    func testSimpleVersionFormat() {
        // Arrange
        let versions = ["1.0", "2.1", "0.9", "10.5"]

        // Act & Assert
        for version in versions {
            let hierarchy = CompressedHierarchy(
                elements: [],
                screenshot: Data(),
                screenType: nil,
                version: version
            )
            #expect(hierarchy.version == version, "Should support simple version: \(version)")
        }
    }

    @Test("Version should support arbitrary string format")
    func testArbitraryVersionFormat() {
        // Arrange
        let versions = ["v1", "beta-2", "2024.1", "next"]

        // Act & Assert
        for version in versions {
            let hierarchy = CompressedHierarchy(
                elements: [],
                screenshot: Data(),
                screenType: nil,
                version: version
            )
            #expect(hierarchy.version == version, "Should support arbitrary version: \(version)")
        }
    }

    // MARK: - Backward Compatibility Tests

    @Test("Existing hierarchies without version should decode successfully")
    func testBackwardCompatibilityDecoding() throws {
        // Arrange - JSON without version field
        let jsonWithoutVersion = """
        {
            "elements": [],
            "screenshot": ""
        }
        """

        // Act
        let jsonData = jsonWithoutVersion.data(using: .utf8)!
        let decoder = JSONDecoder()
        let hierarchy = try decoder.decode(CompressedHierarchy.self, from: jsonData)

        // Assert
        #expect(hierarchy.version == nil || hierarchy.version == "1.0",
                "Should handle missing version field gracefully")
    }

    @Test("Hierarchies with version should round-trip correctly")
    func testVersionRoundTrip() throws {
        // Arrange
        let original = CompressedHierarchy(
            elements: [
                MinimalElement(type: .button, id: "test", label: "Test", interactive: true, children: [])
            ],
            screenshot: Data(),
            screenType: .login,
            version: "1.5.0"
        )

        // Act
        let jsonData = try original.toJSON(includeScreenshot: false)

        // Decode just to check version is preserved
        let dict = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Assert
        #expect(dict["version"] as? String == "1.5.0", "Version should survive encoding")
    }

    // MARK: - Current Version Constant Tests

    @Test("Should have a current version constant")
    func testCurrentVersionConstant() {
        // Assert
        #expect(!CompressedHierarchy.currentVersion.isEmpty, "Current version should not be empty")
    }

    @Test("Default version should match current version")
    func testDefaultMatchesCurrentVersion() {
        // Arrange & Act
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        // Assert
        #expect(hierarchy.version == CompressedHierarchy.currentVersion,
                "Default version should match current version constant")
    }

    @Test("Current version should be semantic versioning format")
    func testCurrentVersionFormat() {
        // Arrange
        let version = CompressedHierarchy.currentVersion

        // Assert - Should match X.Y or X.Y.Z format
        let pattern = #"^\d+\.\d+(\.\d+)?$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.firstMatch(
            in: version,
            range: NSRange(version.startIndex..., in: version)
        )

        #expect(matches != nil, "Current version '\(version)' should follow semantic versioning")
    }

    // MARK: - JSON Encoding Tests

    @Test("Version should be present in JSON output")
    func testVersionPresentInJSON() throws {
        // Arrange
        let hierarchy = CompressedHierarchy(
            elements: [MinimalElement(type: .button, interactive: true, children: [])],
            screenshot: Data(),
            screenType: nil,
            version: "1.0"
        )

        // Act
        let jsonData = try hierarchy.toJSON(includeScreenshot: false)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Assert - Version should be present in JSON
        #expect(jsonString.contains("\"version\""), "Version should be in JSON output")
        #expect(jsonString.contains("\"1.0\""), "Version value should be in JSON output")
    }

    @Test("Multiple hierarchies can have different versions")
    func testMultipleVersions() {
        // Arrange & Act
        let hierarchy1 = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil,
            version: "1.0"
        )

        let hierarchy2 = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil,
            version: "2.0"
        )

        // Assert
        #expect(hierarchy1.version == "1.0")
        #expect(hierarchy2.version == "2.0")
        #expect(hierarchy1.version != hierarchy2.version)
    }

    // MARK: - Integration Tests

    @Test("Version should be preserved through full capture workflow")
    func testVersionInCaptureWorkflow() {
        // Arrange
        let elements = [
            MinimalElement(type: .button, id: "btn1", label: "Click", interactive: true),
            MinimalElement(type: .text, label: "Welcome", interactive: false)
        ]

        // Act
        let hierarchy = CompressedHierarchy(
            elements: elements,
            screenshot: Data([0x01, 0x02, 0x03]),
            screenType: .login,
            version: "1.0"
        )

        // Assert
        #expect(hierarchy.version == "1.0")
        #expect(hierarchy.elements.count == 2)
        #expect(hierarchy.screenType == .login)
    }

    @Test("Version should work with all other hierarchy features")
    func testVersionWithAllFeatures() throws {
        // Arrange
        let elements = [
            MinimalElement(
                type: .button,
                id: "submit",
                label: "Submit",
                interactive: true,
                value: nil,
                intent: .submit,
                priority: 150,
                children: []
            )
        ]

        let hierarchy = CompressedHierarchy(
            elements: elements,
            screenshot: Data(),
            screenType: .form,
            version: "1.2.0"
        )

        // Act
        let jsonData = try hierarchy.toJSON(includeScreenshot: false)
        let dict = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Assert
        #expect(dict["version"] as? String == "1.2.0")
        #expect(dict["screenType"] as? String == "form")
        let elementsArray = dict["elements"] as! [[String: Any]]
        #expect(elementsArray.count == 1)
        #expect(elementsArray[0]["intent"] as? String == "submit")
        #expect(elementsArray[0]["priority"] as? Int == 150)
    }
}
