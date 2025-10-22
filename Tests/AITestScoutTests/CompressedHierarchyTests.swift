import Testing
import Foundation
@testable import AITestScout

@Suite("CompressedHierarchy Tests")
struct CompressedHierarchyTests {

    @Test("Should create compressed hierarchy with elements")
    func testCompressedHierarchyCreation() {
        // Arrange
        let button = MinimalElement(
            type: .button,
            id: "loginBtn",
            label: "Login",
            interactive: true
        )

        // Act
        let hierarchy = CompressedHierarchy(
            elements: [button],
            screenshot: Data()
        )

        // Assert
        #expect(hierarchy.elements.count == 1)
        #expect(hierarchy.elements[0].type == .button)
    }

    @Test("Should serialize to JSON format without screenshot by default")
    func testJSONSerialization() throws {
        // Arrange
        let button = MinimalElement(
            type: .button,
            id: "submitBtn",
            label: "Submit",
            interactive: true
        )

        let input = MinimalElement(
            type: .input,
            id: "emailField",
            label: "Email",
            interactive: true
        )

        let hierarchy = CompressedHierarchy(
            elements: [input, button],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert
        #expect(json != nil)
        #expect(json?["elements"] != nil)
        #expect(json?["screenshot"] == nil) // Screenshot not included by default for token efficiency

        let elements = json?["elements"] as? [[String: Any]]
        #expect(elements?.count == 2)
        #expect(elements?[0]["type"] as? String == "input")
        #expect(elements?[1]["type"] as? String == "button")
    }

    @Test("Should serialize screenshot as base64 string when requested")
    func testScreenshotSerialization() throws {
        // Arrange
        let testData = "test screenshot".data(using: .utf8)!
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: testData
        )

        // Act - explicitly request screenshot inclusion
        let jsonData = try hierarchy.toJSON(includeScreenshot: true)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert
        let screenshotString = json?["screenshot"] as? String
        #expect(screenshotString != nil)

        // Decode base64 and verify it matches original
        let decodedData = Data(base64Encoded: screenshotString!)
        #expect(decodedData == testData)
    }

    @Test("Should handle nested element hierarchy in JSON")
    func testNestedHierarchySerialization() throws {
        // Arrange
        let child = MinimalElement(
            type: .button,
            id: "childBtn",
            label: "Click",
            interactive: true
        )

        let parent = MinimalElement(
            type: .container,
            id: "parentContainer",
            label: nil,
            interactive: false,
            children: [child]
        )

        let hierarchy = CompressedHierarchy(
            elements: [parent],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert
        let elements = json?["elements"] as? [[String: Any]]
        #expect(elements?.count == 1)

        let parentElement = elements?[0]
        let children = parentElement?["children"] as? [[String: Any]]
        #expect(children?.count == 1)
        #expect(children?[0]["type"] as? String == "button")
        #expect(children?[0]["label"] as? String == "Click")
    }

    @Test("Should produce compact JSON output")
    func testCompactJSONOutput() throws {
        // Arrange
        let element = MinimalElement(
            type: .button,
            id: "btn",
            label: "Test",
            interactive: true
        )

        let hierarchy = CompressedHierarchy(
            elements: [element],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Assert - should not have pretty formatting (no excessive whitespace)
        #expect(!jsonString.contains("\n"))
        #expect(jsonString.contains("\"type\":\"button\""))
    }

    @Test("Should filter to interactive elements only when requested")
    func testInteractiveOnlyFilter() throws {
        // Arrange
        let button = MinimalElement(
            type: .button,
            id: "btn",
            label: "Click",
            interactive: true
        )

        let text = MinimalElement(
            type: .text,
            label: "Description text",
            interactive: false
        )

        let labelWithId = MinimalElement(
            type: .text,
            id: "titleLabel",
            label: "Important Title",
            interactive: false
        )

        let hierarchy = CompressedHierarchy(
            elements: [button, text, labelWithId],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON(interactiveOnly: true)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let elements = json?["elements"] as? [[String: Any]]

        // Assert - should include button and labelWithId (has ID), but not plain text
        #expect(elements?.count == 2)
        #expect(elements?[0]["type"] as? String == "button")
        #expect(elements?[1]["type"] as? String == "text")
        #expect(elements?[1]["id"] as? String == "titleLabel")
    }

    @Test("Should omit empty children arrays to save tokens")
    func testEmptyChildrenOmission() throws {
        // Arrange
        let elementWithoutChildren = MinimalElement(
            type: .button,
            id: "btn",
            label: "Click",
            interactive: true
        )

        let hierarchy = CompressedHierarchy(
            elements: [elementWithoutChildren],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Assert - should not contain "children" key for elements without children
        #expect(!jsonString.contains("\"children\""))
    }

    @Test("Should include value field when present")
    func testValueFieldInclusion() throws {
        // Arrange
        let inputWithValue = MinimalElement(
            type: .input,
            id: "emailField",
            label: "Email",
            interactive: true,
            value: "test@example.com"
        )

        let hierarchy = CompressedHierarchy(
            elements: [inputWithValue],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let elements = json?["elements"] as? [[String: Any]]

        // Assert
        #expect(elements?[0]["value"] as? String == "test@example.com")
    }

    // MARK: - Screen Type Field Tests

    @Test("Should include screenType field when detected")
    func testScreenTypeFieldInclusion() throws {
        // Arrange
        let elements = [
            MinimalElement(type: .input, id: "email", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "password", label: "Password", interactive: true),
            MinimalElement(type: .button, id: "login", label: "Login", interactive: true)
        ]

        let hierarchy = CompressedHierarchy(
            elements: elements,
            screenshot: Data(),
            screenType: .login
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert
        #expect(json?["screenType"] as? String == "login")
    }

    @Test("Should omit screenType when nil")
    func testScreenTypeOmissionWhenNil() throws {
        // Arrange
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Assert
        #expect(!jsonString.contains("screenType"), "screenType should be omitted when nil")
    }

    @Test("Should serialize various screen types correctly")
    func testVariousScreenTypes() throws {
        // Test different screen type values
        let screenTypes: [(ScreenType, String)] = [
            (.login, "login"),
            (.form, "form"),
            (.list, "list"),
            (.settings, "settings"),
            (.tabNavigation, "tabNavigation"),
            (.error, "error"),
            (.loading, "loading")
        ]

        for (screenType, expectedString) in screenTypes {
            let hierarchy = CompressedHierarchy(
                elements: [],
                screenshot: Data(),
                screenType: screenType
            )

            let jsonData = try hierarchy.toJSON()
            let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

            #expect(
                json?["screenType"] as? String == expectedString,
                "Should serialize '\(expectedString)' screen type correctly"
            )
        }
    }

    // MARK: - Nested Filtering Tests

    @Test("Should filter nested children when interactiveOnly is true")
    func testNestedInteractiveOnlyFiltering() throws {
        // Arrange - Create nested hierarchy with mixed interactive/non-interactive
        let deepChild = MinimalElement(
            type: .button,
            id: "deepButton",
            label: "Deep Button",
            interactive: true
        )

        let nonInteractiveChild = MinimalElement(
            type: .text,
            id: nil,
            label: "Some text",
            interactive: false
        )

        let middleContainer = MinimalElement(
            type: .container,
            id: "middleContainer",
            label: nil,
            interactive: false,
            children: [deepChild, nonInteractiveChild]
        )

        let topLevel = MinimalElement(
            type: .container,
            id: "topContainer",
            label: nil,
            interactive: false,
            children: [middleContainer]
        )

        let hierarchy = CompressedHierarchy(
            elements: [topLevel],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON(interactiveOnly: true)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let elements = json?["elements"] as? [[String: Any]]

        // Assert - Should include containers with IDs and filter down to interactive children
        #expect(elements?.count == 1, "Should include top container (has ID)")

        let topElement = elements?[0]
        #expect(topElement?["id"] as? String == "topContainer")

        let children = topElement?["children"] as? [[String: Any]]
        #expect(children?.count == 1, "Middle container should be included (has ID)")

        let middleElement = children?[0]
        #expect(middleElement?["id"] as? String == "middleContainer")

        let deepChildren = middleElement?["children"] as? [[String: Any]]
        #expect(deepChildren?.count == 1, "Should only include interactive deep button")
        #expect(deepChildren?[0]["id"] as? String == "deepButton")
    }

    @Test("Should preserve hierarchy structure with interactiveOnly filtering")
    func testHierarchyPreservationWithFiltering() throws {
        // Arrange
        let interactiveButton = MinimalElement(
            type: .button,
            id: "btn",
            label: "Click",
            interactive: true
        )

        let containerWithId = MinimalElement(
            type: .container,
            id: "importantContainer",
            label: nil,
            interactive: false,
            children: [interactiveButton]
        )

        let hierarchy = CompressedHierarchy(
            elements: [containerWithId],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON(interactiveOnly: true)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert - Container with ID should be preserved with its interactive children
        let elements = json?["elements"] as? [[String: Any]]
        #expect(elements?.count == 1)
        #expect(elements?[0]["id"] as? String == "importantContainer")

        let children = elements?[0]["children"] as? [[String: Any]]
        #expect(children?.count == 1)
        #expect(children?[0]["interactive"] as? Bool == true)
    }

    // MARK: - Edge Case Tests

    @Test("Should handle very large element arrays")
    func testLargeElementArrays() throws {
        // Arrange - Create array with many elements
        var largeElementArray: [MinimalElement] = []

        for i in 0..<100 {
            largeElementArray.append(
                MinimalElement(
                    type: .button,
                    id: "button\(i)",
                    label: "Button \(i)",
                    interactive: true
                )
            )
        }

        let hierarchy = CompressedHierarchy(
            elements: largeElementArray,
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let elements = json?["elements"] as? [[String: Any]]

        // Assert
        #expect(elements?.count == 100, "Should serialize all 100 elements")
        #expect(elements?[0]["id"] as? String == "button0")
        #expect(elements?[99]["id"] as? String == "button99")
    }

    @Test("Should handle deeply nested hierarchies")
    func testDeeplyNestedHierarchies() throws {
        // Arrange - Create 10 levels deep hierarchy
        var currentElement = MinimalElement(
            type: .button,
            id: "deepest",
            label: "Deepest Button",
            interactive: true
        )

        for level in (0..<9).reversed() {
            currentElement = MinimalElement(
                type: .container,
                id: "level\(level)",
                label: nil,
                interactive: false,
                children: [currentElement]
            )
        }

        let hierarchy = CompressedHierarchy(
            elements: [currentElement],
            screenshot: Data()
        )

        // Act
        let jsonData = try hierarchy.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert - Verify structure is preserved
        var current = json?["elements"] as? [[String: Any]]
        #expect(current?[0]["id"] as? String == "level0")

        // Navigate down to verify depth
        for level in 0..<9 {
            current = current?[0]["children"] as? [[String: Any]]
            if level < 8 {
                #expect(current?[0]["id"] as? String == "level\(level + 1)")
            } else {
                #expect(current?[0]["id"] as? String == "deepest")
            }
        }
    }

    @Test("Should handle empty screenshot data gracefully")
    func testEmptyScreenshotData() throws {
        // Arrange
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data() // Empty screenshot
        )

        // Act
        let jsonData = try hierarchy.toJSON(includeScreenshot: true)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert - Should include empty base64 string
        let screenshot = json?["screenshot"] as? String
        #expect(screenshot != nil, "Screenshot field should be present")
        #expect(screenshot?.isEmpty == true, "Empty data should produce empty base64 string")
    }
}
