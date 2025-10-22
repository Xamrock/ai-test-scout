import Testing
import Foundation
@testable import AITestScout

@Suite("MinimalElement Tests")
struct MinimalElementTests {

    @Test("Should create a minimal element with all properties")
    func testMinimalElementCreation() {
        // Arrange & Act
        let element = MinimalElement(
            type: .button,
            id: "loginButton",
            label: "Login",
            interactive: true,
            children: []
        )

        // Assert
        #expect(element.type == .button)
        #expect(element.id == "loginButton")
        #expect(element.label == "Login")
        #expect(element.interactive == true)
        #expect(element.children.isEmpty)
    }

    @Test("Should create element with optional nil values")
    func testMinimalElementWithNilValues() {
        // Arrange & Act
        let element = MinimalElement(
            type: .container,
            id: nil,
            label: nil,
            interactive: false,
            children: []
        )

        // Assert
        #expect(element.type == .container)
        #expect(element.id == nil)
        #expect(element.label == nil)
        #expect(element.interactive == false)
    }

    @Test("Should create element hierarchy with children")
    func testElementHierarchy() {
        // Arrange
        let childButton = MinimalElement(
            type: .button,
            id: "submitBtn",
            label: "Submit",
            interactive: true,
            children: []
        )

        let childInput = MinimalElement(
            type: .input,
            id: "emailInput",
            label: "Email",
            interactive: true,
            children: []
        )

        // Act
        let parentForm = MinimalElement(
            type: .container,
            id: "loginForm",
            label: nil,
            interactive: false,
            children: [childInput, childButton]
        )

        // Assert
        #expect(parentForm.children.count == 2)
        #expect(parentForm.children[0].type == .input)
        #expect(parentForm.children[1].type == .button)
    }

    @Test("Should conform to Equatable")
    func testEquality() {
        // Arrange
        let element1 = MinimalElement(
            type: .button,
            id: "btn1",
            label: "Click",
            interactive: true,
            children: []
        )

        let element2 = MinimalElement(
            type: .button,
            id: "btn1",
            label: "Click",
            interactive: true,
            children: []
        )

        let element3 = MinimalElement(
            type: .button,
            id: "btn2",
            label: "Click",
            interactive: true,
            children: []
        )

        // Assert
        #expect(element1 == element2)
        #expect(element1 != element3)
    }

    // MARK: - Semantic Field Tests

    @Test("Should include semantic intent field when provided")
    func testSemanticIntentField() {
        // Arrange & Act
        let submitButton = MinimalElement(
            type: .button,
            id: "login",
            label: "Login",
            interactive: true,
            intent: .submit
        )

        let neutralButton = MinimalElement(
            type: .button,
            id: "generic",
            label: "Button",
            interactive: true,
            intent: nil // Neutral intent omitted
        )

        // Assert
        #expect(submitButton.intent == .submit)
        #expect(neutralButton.intent == nil)
    }

    @Test("Should include semantic priority field when provided")
    func testSemanticPriorityField() {
        // Arrange & Act
        let highPriorityElement = MinimalElement(
            type: .button,
            id: "submit",
            label: "Submit",
            interactive: true,
            priority: 150
        )

        let lowPriorityElement = MinimalElement(
            type: .button,
            id: "cancel",
            label: "Cancel",
            interactive: true,
            priority: 25
        )

        let noPriorityElement = MinimalElement(
            type: .text,
            label: "Text",
            interactive: false,
            priority: nil
        )

        // Assert
        #expect(highPriorityElement.priority == 150)
        #expect(lowPriorityElement.priority == 25)
        #expect(noPriorityElement.priority == nil)
    }

    @Test("Should encode semantic fields in JSON")
    func testSemanticFieldsEncoding() throws {
        // Arrange
        let elementWithSemantics = MinimalElement(
            type: .button,
            id: "login",
            label: "Login",
            interactive: true,
            intent: .submit,
            priority: 150
        )

        // Act
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(elementWithSemantics)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Assert
        #expect(json?["intent"] as? String == "submit")
        #expect(json?["priority"] as? Int == 150)
    }

    // MARK: - Value Field Tests

    @Test("Should handle various value types")
    func testVariousValueTypes() {
        // Arrange & Act
        let stringValue = MinimalElement(
            type: .input,
            id: "email",
            label: "Email",
            interactive: true,
            value: "test@example.com"
        )

        let numericValue = MinimalElement(
            type: .slider,
            id: "volume",
            label: "Volume",
            interactive: true,
            value: "75"
        )

        let booleanValue = MinimalElement(
            type: .toggle,
            id: "notifications",
            label: "Notifications",
            interactive: true,
            value: "1" // Boolean represented as "1" or "0"
        )

        // Assert
        #expect(stringValue.value == "test@example.com")
        #expect(numericValue.value == "75")
        #expect(booleanValue.value == "1")
    }

    @Test("Should encode value field when present")
    func testValueFieldEncoding() throws {
        // Arrange
        let elementWithValue = MinimalElement(
            type: .input,
            id: "username",
            label: "Username",
            interactive: true,
            value: "john_doe"
        )

        let elementWithoutValue = MinimalElement(
            type: .button,
            id: "submit",
            label: "Submit",
            interactive: true,
            value: nil
        )

        // Act
        let encoder = JSONEncoder()

        let jsonWithValue = try encoder.encode(elementWithValue)
        let jsonObjWithValue = try JSONSerialization.jsonObject(with: jsonWithValue) as? [String: Any]

        let jsonWithoutValue = try encoder.encode(elementWithoutValue)
        let jsonObjWithoutValue = try JSONSerialization.jsonObject(with: jsonWithoutValue) as? [String: Any]

        // Assert
        #expect(jsonObjWithValue?["value"] as? String == "john_doe")
        #expect(jsonObjWithoutValue?["value"] == nil, "Value field should be omitted when nil")
    }

    // MARK: - Token Optimization Tests

    @Test("Should omit nil optional fields for token efficiency")
    func testNilFieldOmission() throws {
        // Arrange
        let minimalElement = MinimalElement(
            type: .container,
            id: nil,
            label: nil,
            interactive: false,
            value: nil,
            intent: nil,
            priority: nil,
            children: []
        )

        // Act
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(minimalElement)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Assert - nil fields should not appear in JSON
        #expect(!jsonString.contains("\"id\""), "id should be omitted when nil")
        #expect(!jsonString.contains("\"label\""), "label should be omitted when nil")
        #expect(!jsonString.contains("\"value\""), "value should be omitted when nil")
        #expect(!jsonString.contains("\"intent\""), "intent should be omitted when nil")
        #expect(!jsonString.contains("\"priority\""), "priority should be omitted when nil")
        #expect(!jsonString.contains("\"children\""), "children should be omitted when empty")
    }

    @Test("Should include only populated fields for token efficiency")
    func testPopulatedFieldsOnly() throws {
        // Arrange
        let element = MinimalElement(
            type: .button,
            id: "submit",
            label: nil, // Omitted
            interactive: true,
            value: nil, // Omitted
            intent: .submit,
            priority: nil, // Omitted
            children: []
        )

        // Act
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(element)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Assert
        #expect(jsonString.contains("\"type\""))
        #expect(jsonString.contains("\"id\""))
        #expect(jsonString.contains("\"interactive\""))
        #expect(jsonString.contains("\"intent\""))

        #expect(!jsonString.contains("\"label\""), "label should be omitted")
        #expect(!jsonString.contains("\"value\""), "value should be omitted")
        #expect(!jsonString.contains("\"priority\""), "priority should be omitted")
        #expect(!jsonString.contains("\"children\""), "children should be omitted when empty")
    }
}
