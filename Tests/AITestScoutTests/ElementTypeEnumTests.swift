import Testing
import Foundation
@testable import AITestScout

@Suite("ElementType Enum Tests")
struct ElementTypeEnumTests {

    // MARK: - ElementType Enum Tests

    @Test("ElementType should have common UI element cases")
    func testCommonElementTypes() {
        // Assert - Verify common element types exist
        let types: [ElementType] = [
            .button,
            .input,
            .text,
            .image,
            .toggle,
            .link,
            .tab,
            .scrollable,
            .container,
            .picker,
            .slider
        ]

        #expect(types.count == 11, "Should have all common element types")
    }

    @Test("ElementType should have string raw values")
    func testElementTypeRawValues() {
        // Assert
        #expect(ElementType.button.rawValue == "button")
        #expect(ElementType.input.rawValue == "input")
        #expect(ElementType.text.rawValue == "text")
        #expect(ElementType.image.rawValue == "image")
        #expect(ElementType.toggle.rawValue == "toggle")
        #expect(ElementType.link.rawValue == "link")
        #expect(ElementType.tab.rawValue == "tab")
        #expect(ElementType.scrollable.rawValue == "scrollable")
        #expect(ElementType.container.rawValue == "container")
        #expect(ElementType.picker.rawValue == "picker")
        #expect(ElementType.slider.rawValue == "slider")
    }

    @Test("ElementType should be constructible from string")
    func testElementTypeFromString() {
        // Act & Assert
        #expect(ElementType(rawValue: "button") == .button)
        #expect(ElementType(rawValue: "input") == .input)
        #expect(ElementType(rawValue: "text") == .text)
        #expect(ElementType(rawValue: "unknown") == nil)
    }

    @Test("ElementType should be Codable")
    func testElementTypeCodable() throws {
        // Arrange
        let type = ElementType.button

        // Act
        let encoded = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(ElementType.self, from: encoded)

        // Assert
        #expect(decoded == .button)
    }

    @Test("MinimalElement should use ElementType enum")
    func testMinimalElementWithEnum() {
        // Act
        let element = MinimalElement(
            type: .button,
            id: "btn",
            label: "Click",
            interactive: true
        )

        // Assert
        #expect(element.type == .button)
    }

    @Test("MinimalElement should encode type as string in JSON")
    func testMinimalElementEncodesTypeAsString() throws {
        // Arrange
        let element = MinimalElement(type: .button, id: "btn", interactive: true, children: [])

        // Act
        let encoded = try JSONEncoder().encode(element)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

        // Assert
        #expect(json["type"] as? String == "button", "Type should encode as string")
    }

    // MARK: - ScreenType Enum Tests

    @Test("ScreenType should have common screen cases")
    func testCommonScreenTypes() {
        // Assert
        let types: [ScreenType] = [
            .login,
            .form,
            .list,
            .settings,
            .tabNavigation,
            .error,
            .loading,
            .content
        ]

        #expect(types.count == 8, "Should have all screen types")
    }

    @Test("ScreenType should have string raw values")
    func testScreenTypeRawValues() {
        // Assert
        #expect(ScreenType.login.rawValue == "login")
        #expect(ScreenType.form.rawValue == "form")
        #expect(ScreenType.list.rawValue == "list")
        #expect(ScreenType.settings.rawValue == "settings")
        #expect(ScreenType.tabNavigation.rawValue == "tabNavigation")
        #expect(ScreenType.error.rawValue == "error")
        #expect(ScreenType.loading.rawValue == "loading")
        #expect(ScreenType.content.rawValue == "content")
    }

    @Test("ScreenType should be Codable")
    func testScreenTypeCodable() throws {
        // Arrange
        let type = ScreenType.login

        // Act
        let encoded = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(ScreenType.self, from: encoded)

        // Assert
        #expect(decoded == .login)
    }

    // MARK: - SemanticIntent Enum Tests

    @Test("SemanticIntent should have all intent cases")
    func testSemanticIntentCases() {
        // Assert
        let intents: [SemanticIntent] = [
            .submit,
            .cancel,
            .destructive,
            .navigation,
            .neutral
        ]

        #expect(intents.count == 5, "Should have all intent types")
    }

    @Test("SemanticIntent should have string raw values")
    func testSemanticIntentRawValues() {
        // Assert
        #expect(SemanticIntent.submit.rawValue == "submit")
        #expect(SemanticIntent.cancel.rawValue == "cancel")
        #expect(SemanticIntent.destructive.rawValue == "destructive")
        #expect(SemanticIntent.navigation.rawValue == "navigation")
        #expect(SemanticIntent.neutral.rawValue == "neutral")
    }

    @Test("MinimalElement should use optional SemanticIntent")
    func testMinimalElementWithIntent() {
        // Act
        let element = MinimalElement(
            type: .button,
            id: "submit",
            label: "Submit",
            interactive: true,
            value: nil,
            intent: .submit
        )

        // Assert
        #expect(element.intent == .submit)
    }

    @Test("MinimalElement should allow nil intent")
    func testMinimalElementWithNilIntent() {
        // Act
        let element = MinimalElement(
            type: .button,
            id: "btn",
            interactive: true,
            intent: nil
        )

        // Assert
        #expect(element.intent == nil)
    }

    // MARK: - Backward Compatibility Tests

    @Test("Should decode old string-based type as enum")
    func testBackwardCompatibilityStringToEnum() throws {
        // Arrange - Old JSON with string type
        let json = """
        {
            "type": "button",
            "interactive": true,
            "children": []
        }
        """

        // Act
        let data = json.data(using: .utf8)!
        let element = try JSONDecoder().decode(MinimalElement.self, from: data)

        // Assert
        #expect(element.type == .button)
    }

    @Test("Should encode enum as string for compatibility")
    func testEnumEncodesAsString() throws {
        // Arrange
        let element = MinimalElement(type: .input, id: "email", interactive: true, children: [])

        // Act
        let data = try JSONEncoder().encode(element)
        let json = String(data: data, encoding: .utf8)!

        // Assert
        #expect(json.contains("\"input\""), "Should encode as string")
    }

    // MARK: - CompressedHierarchy Integration Tests

    @Test("CompressedHierarchy should use ScreenType enum")
    func testCompressedHierarchyWithScreenType() {
        // Act
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: .login
        )

        // Assert
        #expect(hierarchy.screenType == .login)
    }

    @Test("CompressedHierarchy should allow nil screenType")
    func testCompressedHierarchyWithNilScreenType() {
        // Act
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: nil
        )

        // Assert
        #expect(hierarchy.screenType == nil)
    }

    @Test("CompressedHierarchy should encode screenType as string")
    func testCompressedHierarchyEncodesScreenTypeAsString() throws {
        // Arrange
        let hierarchy = CompressedHierarchy(
            elements: [],
            screenshot: Data(),
            screenType: .form
        )

        // Act
        let json = try hierarchy.toJSON(includeScreenshot: false)
        let dict = try JSONSerialization.jsonObject(with: json) as! [String: Any]

        // Assert
        #expect(dict["screenType"] as? String == "form")
    }
}
