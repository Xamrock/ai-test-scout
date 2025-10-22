import Foundation
import Testing
import CoreGraphics
@testable import AITestScout

/// Tests for ElementContext and ElementQueries - Detailed element metadata for test generation
@Suite("ElementContext and ElementQueries Tests")
struct ElementContextTests {

    // MARK: - ElementQueries Tests

    @Test("ElementQueries initializes with all query strategies")
    func testElementQueriesInitialization() throws {
        let queries = ElementQueries(
            primary: "app.buttons[\"loginButton\"]",
            byLabel: "app.buttons[\"Log In\"]",
            byType: "app.buttons.element(boundBy: 0)",
            alternatives: [
                "app.descendants(matching: .button).matching(identifier: \"loginButton\").firstMatch"
            ]
        )

        #expect(queries.primary == "app.buttons[\"loginButton\"]")
        #expect(queries.byLabel == "app.buttons[\"Log In\"]")
        #expect(queries.byType == "app.buttons.element(boundBy: 0)")
        #expect(queries.alternatives.count == 1)
    }

    @Test("ElementQueries with minimal data (primary only)")
    func testElementQueriesMinimal() throws {
        let queries = ElementQueries(primary: "app.buttons.element(boundBy: 0)")

        #expect(queries.primary == "app.buttons.element(boundBy: 0)")
        #expect(queries.byLabel == nil)
        #expect(queries.byType == nil)
        #expect(queries.alternatives.isEmpty)
    }

    @Test("ElementQueries is Equatable")
    func testElementQueriesEquatable() throws {
        let queries1 = ElementQueries(
            primary: "app.buttons[\"btn\"]",
            byLabel: "app.buttons[\"Button\"]",
            byType: "app.buttons.element(boundBy: 0)",
            alternatives: ["alt1", "alt2"]
        )

        let queries2 = ElementQueries(
            primary: "app.buttons[\"btn\"]",
            byLabel: "app.buttons[\"Button\"]",
            byType: "app.buttons.element(boundBy: 0)",
            alternatives: ["alt1", "alt2"]
        )

        #expect(queries1 == queries2)
    }

    @Test("ElementQueries is Codable")
    func testElementQueriesCodable() throws {
        let original = ElementQueries(
            primary: "app.textFields[\"email\"]",
            byLabel: "app.textFields[\"Email\"]",
            byType: "app.textFields.element(boundBy: 0)",
            alternatives: ["alt1"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ElementQueries.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - ElementContext Tests

    @Test("ElementContext initializes with all fields")
    func testElementContextInitialization() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 200, width: 335, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries,
            accessibilityTraits: ["button"],
            accessibilityHint: "Double tap to log in"
        )

        #expect(context.xcuiElementType == "XCUIElementTypeButton")
        #expect(context.frame == CGRect(x: 20, y: 200, width: 335, height: 44))
        #expect(context.isEnabled == true)
        #expect(context.isVisible == true)
        #expect(context.isHittable == true)
        #expect(context.hasFocus == false)
        #expect(context.queries == queries)
        #expect(context.accessibilityTraits == ["button"])
        #expect(context.accessibilityHint == "Double tap to log in")
    }

    @Test("ElementContext with minimal optional fields")
    func testElementContextMinimal() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 0, y: 0, width: 100, height: 50),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        #expect(context.accessibilityTraits == nil)
        #expect(context.accessibilityHint == nil)
    }

    @Test("ElementContext frame captures position and size")
    func testElementContextFrameData() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 50, y: 100, width: 200, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        #expect(context.frame.origin.x == 50)
        #expect(context.frame.origin.y == 100)
        #expect(context.frame.size.width == 200)
        #expect(context.frame.size.height == 44)
    }

    @Test("ElementContext is Equatable")
    func testElementContextEquatable() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context1 = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 200, width: 335, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let context2 = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 200, width: 335, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        #expect(context1 == context2)
    }

    @Test("ElementContext different states are not equal")
    func testElementContextInequality() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context1 = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let context2 = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: false,  // Different
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        #expect(context1 != context2)
    }

    @Test("ElementContext is Codable")
    func testElementContextCodable() throws {
        let queries = ElementQueries(
            primary: "app.textFields[\"email\"]",
            byLabel: "app.textFields[\"Email\"]"
        )

        let original = ElementContext(
            xcuiElementType: "XCUIElementTypeTextField",
            frame: CGRect(x: 10, y: 50, width: 300, height: 40),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: true,
            queries: queries,
            accessibilityTraits: ["textField"],
            accessibilityHint: "Enter email address"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ElementContext.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - State Flags

    @Test("ElementContext disabled element state")
    func testDisabledElementState() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: false,
            isVisible: true,
            isHittable: false,  // Disabled elements typically not hittable
            hasFocus: false,
            queries: queries
        )

        #expect(context.isEnabled == false)
        #expect(context.isHittable == false)
    }

    @Test("ElementContext invisible element state")
    func testInvisibleElementState() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: false,
            isHittable: false,  // Invisible elements not hittable
            hasFocus: false,
            queries: queries
        )

        #expect(context.isVisible == false)
        #expect(context.isHittable == false)
    }

    @Test("ElementContext focused element state")
    func testFocusedElementState() throws {
        let queries = ElementQueries(primary: "app.textFields[\"email\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeTextField",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: true,
            queries: queries
        )

        #expect(context.hasFocus == true)
    }

    // MARK: - Real World Scenarios

    @Test("ElementContext for login button")
    func testLoginButtonContext() throws {
        let queries = ElementQueries(
            primary: "app.buttons[\"loginButton\"]",
            byLabel: "app.buttons[\"Log In\"]",
            byType: "app.buttons.element(boundBy: 0)",
            alternatives: [
                "app.descendants(matching: .button).matching(identifier: \"loginButton\").firstMatch"
            ]
        )

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 700, width: 353, height: 50),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries,
            accessibilityTraits: ["button"],
            accessibilityHint: "Log in to your account"
        )

        #expect(context.xcuiElementType.contains("Button"))
        #expect(context.isHittable)
        #expect(context.queries.primary.contains("loginButton"))
    }

    @Test("ElementContext for text field with focus")
    func testTextFieldWithFocusContext() throws {
        let queries = ElementQueries(
            primary: "app.textFields[\"emailField\"]",
            byLabel: "app.textFields[\"Email\"]"
        )

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeTextField",
            frame: CGRect(x: 20, y: 200, width: 353, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: true,
            queries: queries,
            accessibilityTraits: ["textField"]
        )

        #expect(context.hasFocus)
        #expect(context.queries.primary.contains("textFields"))
    }

    @Test("ElementContext for disabled submit button")
    func testDisabledSubmitButtonContext() throws {
        let queries = ElementQueries(
            primary: "app.buttons[\"submitButton\"]",
            byLabel: "app.buttons[\"Submit\"]"
        )

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 700, width: 353, height: 50),
            isEnabled: false,
            isVisible: true,
            isHittable: false,
            hasFocus: false,
            queries: queries,
            accessibilityTraits: ["button", "notEnabled"]
        )

        #expect(!context.isEnabled)
        #expect(!context.isHittable)
        #expect(context.isVisible)  // Visible but not interactable
    }

    // MARK: - JSON Export

    @Test("ElementContext exports to clean JSON")
    func testElementContextJSONExport() throws {
        let queries = ElementQueries(
            primary: "app.buttons[\"btn\"]",
            byLabel: "app.buttons[\"Button\"]"
        )

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 200, width: 335, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(context)

        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString != nil)
        #expect(jsonString?.contains("xcuiElementType") == true)
        #expect(jsonString?.contains("queries") == true)
        #expect(jsonString?.contains("isHittable") == true)
    }

    // MARK: - Accessibility

    @Test("ElementContext with multiple accessibility traits")
    func testMultipleAccessibilityTraits() throws {
        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries,
            accessibilityTraits: ["button", "selected", "updatesFrequently"]
        )

        #expect(context.accessibilityTraits?.count == 3)
        #expect(context.accessibilityTraits?.contains("button") == true)
        #expect(context.accessibilityTraits?.contains("selected") == true)
    }

    @Test("ElementContext with accessibility hint")
    func testAccessibilityHint() throws {
        let queries = ElementQueries(primary: "app.buttons[\"deleteBtn\"]")

        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries,
            accessibilityHint: "Double tap to delete this item permanently"
        )

        #expect(context.accessibilityHint == "Double tap to delete this item permanently")
    }
}
