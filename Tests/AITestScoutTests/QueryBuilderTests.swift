import Foundation
import Testing
import XCTest
@testable import AITestScout

/// Tests for QueryBuilder - XCUITest query string generation
@Suite("QueryBuilder Tests")
struct QueryBuilderTests {

    // MARK: - Primary Query Generation

    @Test("Primary query uses identifier when available")
    func testPrimaryQueryWithIdentifier() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: "loginButton",
            label: "Log In",
            index: 0
        )

        #expect(queries.primary == "app.buttons[\"loginButton\"]")
    }

    @Test("Primary query uses label when no identifier")
    func testPrimaryQueryWithLabelOnly() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .textField,
            id: nil,
            label: "Email",
            index: 2
        )

        #expect(queries.primary == "app.textFields[\"Email\"]")
    }

    @Test("Primary query uses index when no identifier or label")
    func testPrimaryQueryWithIndexOnly() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .staticText,
            id: nil,
            label: nil,
            index: 5
        )

        #expect(queries.primary == "app.staticTexts.element(boundBy: 5)")
    }

    // MARK: - Alternative Queries

    @Test("By-label query provided when both ID and label exist")
    func testByLabelQuery() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: "submitBtn",
            label: "Submit",
            index: 0
        )

        #expect(queries.byLabel == "app.buttons[\"Submit\"]")
    }

    @Test("By-label query is nil when only label exists (used as primary)")
    func testByLabelQueryNilWhenNoId() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: nil,
            label: "Submit",
            index: 0
        )

        #expect(queries.byLabel == nil)
    }

    @Test("By-type query always provided with index")
    func testByTypeQuery() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .switch,
            id: "darkModeSwitch",
            label: "Dark Mode",
            index: 3
        )

        #expect(queries.byType == "app.switches.element(boundBy: 3)")
    }

    // MARK: - Alternative Strategies

    @Test("Alternative queries include descendants matching by identifier")
    func testAlternativeQueriesWithIdentifier() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: "loginButton",
            label: "Log In",
            index: 0
        )

        let expected = "app.descendants(matching: .button).matching(identifier: \"loginButton\").firstMatch"
        #expect(queries.alternatives.contains(expected))
    }

    @Test("Alternative queries include predicate-based label matching")
    func testAlternativeQueriesWithLabel() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .textField,
            id: "emailField",
            label: "Email Address",
            index: 0
        )

        let expected = "app.descendants(matching: .textField).matching(NSPredicate(format: \"label == %@\", \"Email Address\")).firstMatch"
        #expect(queries.alternatives.contains(expected))
    }

    // MARK: - Element Type Mapping

    @Test("Element type mapping for common interactive types")
    func testElementTypeMappingInteractive() throws {
        let buttonQueries = QueryBuilder.buildQueries(elementType: .button, id: "btn", label: nil, index: 0)
        #expect(buttonQueries.primary.contains("buttons"))

        let textFieldQueries = QueryBuilder.buildQueries(elementType: .textField, id: "field", label: nil, index: 0)
        #expect(textFieldQueries.primary.contains("textFields"))

        let switchQueries = QueryBuilder.buildQueries(elementType: .switch, id: "toggle", label: nil, index: 0)
        #expect(switchQueries.primary.contains("switches"))

        let sliderQueries = QueryBuilder.buildQueries(elementType: .slider, id: "volume", label: nil, index: 0)
        #expect(sliderQueries.primary.contains("sliders"))
    }

    @Test("Element type mapping for container types")
    func testElementTypeMappingContainers() throws {
        let scrollViewQueries = QueryBuilder.buildQueries(elementType: .scrollView, id: "scroll", label: nil, index: 0)
        #expect(scrollViewQueries.primary.contains("scrollViews"))

        let tableQueries = QueryBuilder.buildQueries(elementType: .table, id: "list", label: nil, index: 0)
        #expect(tableQueries.primary.contains("tables"))

        let collectionQueries = QueryBuilder.buildQueries(elementType: .collectionView, id: "grid", label: nil, index: 0)
        #expect(collectionQueries.primary.contains("collectionViews"))
    }

    @Test("Element type mapping for navigation types")
    func testElementTypeMappingNavigation() throws {
        let tabBarQueries = QueryBuilder.buildQueries(elementType: .tabBar, id: "tabs", label: nil, index: 0)
        #expect(tabBarQueries.primary.contains("tabBars"))

        let navBarQueries = QueryBuilder.buildQueries(elementType: .navigationBar, id: "nav", label: nil, index: 0)
        #expect(navBarQueries.primary.contains("navigationBars"))

        let segmentQueries = QueryBuilder.buildQueries(elementType: .segmentedControl, id: "segment", label: nil, index: 0)
        #expect(segmentQueries.primary.contains("segmentedControls"))
    }

    // MARK: - String Escaping

    @Test("Special characters are properly escaped in queries")
    func testStringEscaping() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: "test\"button\\with\nspecial\rchars\ttab",
            label: nil,
            index: 0
        )

        // Verify escaped string is in the query
        #expect(queries.primary.contains("\\\""))
        #expect(queries.primary.contains("\\\\"))
        #expect(queries.primary.contains("\\n"))
        #expect(queries.primary.contains("\\r"))
        #expect(queries.primary.contains("\\t"))
    }

    @Test("Quotes in labels are escaped")
    func testQuoteEscaping() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .staticText,
            id: nil,
            label: "User's \"Profile\" Settings",
            index: 0
        )

        #expect(queries.primary.contains("\\\"Profile\\\""))
    }

    // MARK: - Empty/Nil Values

    @Test("Empty string identifier treated as nil")
    func testEmptyIdentifier() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: "",
            label: "Button",
            index: 0
        )

        // Should use label as primary
        #expect(queries.primary == "app.buttons[\"Button\"]")
    }

    @Test("Empty string label treated as nil")
    func testEmptyLabel() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: nil,
            label: "",
            index: 3
        )

        // Should use index as primary
        #expect(queries.primary == "app.buttons.element(boundBy: 3)")
    }

    // MARK: - Edge Cases

    @Test("Zero index is valid")
    func testZeroIndex() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: nil,
            label: nil,
            index: 0
        )

        #expect(queries.primary == "app.buttons.element(boundBy: 0)")
        #expect(queries.byType == "app.buttons.element(boundBy: 0)")
    }

    @Test("Large index values are handled")
    func testLargeIndex() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .cell,
            id: nil,
            label: nil,
            index: 999
        )

        #expect(queries.primary == "app.cells.element(boundBy: 999)")
    }

    // MARK: - Real World Examples

    @Test("Login button query generation")
    func testLoginButtonQueries() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .button,
            id: "loginButton",
            label: "Log In",
            index: 0
        )

        #expect(queries.primary == "app.buttons[\"loginButton\"]")
        #expect(queries.byLabel == "app.buttons[\"Log In\"]")
        #expect(queries.byType == "app.buttons.element(boundBy: 0)")
        #expect(queries.alternatives.count >= 2)
    }

    @Test("Email field query generation")
    func testEmailFieldQueries() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .textField,
            id: "emailField",
            label: "Email",
            index: 0
        )

        #expect(queries.primary == "app.textFields[\"emailField\"]")
        #expect(queries.byLabel == "app.textFields[\"Email\"]")
        #expect(queries.alternatives.count >= 2)
    }

    @Test("Password field query generation")
    func testPasswordFieldQueries() throws {
        let queries = QueryBuilder.buildQueries(
            elementType: .secureTextField,
            id: "passwordField",
            label: "Password",
            index: 1
        )

        #expect(queries.primary == "app.secureTextFields[\"passwordField\"]")
        #expect(queries.byLabel == "app.secureTextFields[\"Password\"]")
        #expect(queries.byType == "app.secureTextFields.element(boundBy: 1)")
    }
}
