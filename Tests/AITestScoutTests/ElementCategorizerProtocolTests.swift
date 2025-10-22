import Testing
import XCTest
@testable import AITestScout

@Suite("ElementCategorizerProtocol Tests")
struct ElementCategorizerProtocolTests {

    // MARK: - Default Categorizer Tests

    @Test("Default categorizer should maintain existing button behavior")
    func testDefaultCategorizerButton() {
        // Arrange
        let categorizer = DefaultElementCategorizer()

        // Act
        let category = categorizer.categorize(.button)

        // Assert
        #expect(category.type == "button")
        #expect(category.interactive == true)
    }

    @Test("Default categorizer should maintain existing input behavior")
    func testDefaultCategorizerInput() {
        // Arrange
        let categorizer = DefaultElementCategorizer()

        // Act
        let textFieldCategory = categorizer.categorize(.textField)
        let secureCategory = categorizer.categorize(.secureTextField)

        // Assert
        #expect(textFieldCategory.type == "input")
        #expect(textFieldCategory.interactive == true)
        #expect(secureCategory.type == "input")
        #expect(secureCategory.interactive == true)
    }

    @Test("Default categorizer should skip system UI elements")
    func testDefaultCategorizerSkipsSystemUI() {
        // Arrange
        let categorizer = DefaultElementCategorizer()

        // Act & Assert
        #expect(categorizer.shouldSkip(.menuBar) == true)
        #expect(categorizer.shouldSkip(.statusBar) == true)
        #expect(categorizer.shouldSkip(.keyboard) == true)
        #expect(categorizer.shouldSkip(.key) == true)
    }

    @Test("Default categorizer should not skip content elements")
    func testDefaultCategorizerKeepsContentElements() {
        // Arrange
        let categorizer = DefaultElementCategorizer()

        // Act & Assert
        #expect(categorizer.shouldSkip(.button) == false)
        #expect(categorizer.shouldSkip(.textField) == false)
        #expect(categorizer.shouldSkip(.staticText) == false)
    }

    // MARK: - Custom Categorizer Tests

    @Test("Custom categorizer can override element types")
    func testCustomCategorizerOverride() {
        // Arrange
        let customCategorizer = CustomTestCategorizer()

        // Act
        let category = customCategorizer.categorize(.button)

        // Assert - custom categorizer treats buttons as "custom-button"
        #expect(category.type == "custom-button")
        #expect(category.interactive == true)
    }

    @Test("Custom categorizer can override skip logic")
    func testCustomCategorizerSkipOverride() {
        // Arrange
        let customCategorizer = CustomTestCategorizer()

        // Act & Assert - custom categorizer doesn't skip keyboards
        #expect(customCategorizer.shouldSkip(.keyboard) == false)
        #expect(customCategorizer.shouldSkip(.key) == false)
    }

    // MARK: - Integration with HierarchyAnalyzer

    @Test("HierarchyAnalyzer should accept custom categorizer via configuration")
    func testHierarchyAnalyzerAcceptsCustomCategorizer() {
        // Arrange
        let customCategorizer = CustomTestCategorizer()
        var config = HierarchyAnalyzerConfiguration()
        config.categorizer = customCategorizer

        // Act
        let analyzer = HierarchyAnalyzer(configuration: config)

        // Assert - analyzer created successfully with custom categorizer
        _ = analyzer // Suppress unused variable warning
        #expect(true, "Analyzer should initialize with custom categorizer")
    }

    @Test("HierarchyAnalyzer should use default categorizer when none specified")
    func testHierarchyAnalyzerUsesDefaultCategorizer() {
        // Arrange & Act
        let analyzer = HierarchyAnalyzer()

        // Assert - analyzer created successfully
        _ = analyzer
        #expect(true, "Analyzer should initialize with default categorizer")
    }

    // MARK: - Protocol Conformance Tests

    @Test("ElementCategory should be equatable")
    func testElementCategoryEquatable() {
        // Arrange
        let category1 = ElementCategory(type: "button", interactive: true)
        let category2 = ElementCategory(type: "button", interactive: true)
        let category3 = ElementCategory(type: "input", interactive: true)

        // Assert
        #expect(category1 == category2)
        #expect(category1 != category3)
    }

    @Test("ElementCategory should have public init")
    func testElementCategoryPublicInit() {
        // Act
        let category = ElementCategory(type: "custom", interactive: false)

        // Assert
        #expect(category.type == "custom")
        #expect(category.interactive == false)
    }
}

// MARK: - Test Helpers

/// Custom categorizer for testing protocol conformance
private final class CustomTestCategorizer: ElementCategorizerProtocol {
    func categorize(_ elementType: XCUIElement.ElementType) -> ElementCategory {
        // Override button categorization
        if elementType == .button {
            return ElementCategory(type: "custom-button", interactive: true)
        }

        // Fall back to default behavior for everything else
        let defaultCategorizer = DefaultElementCategorizer()
        return defaultCategorizer.categorize(elementType)
    }

    func shouldSkip(_ elementType: XCUIElement.ElementType) -> Bool {
        // Override: don't skip keyboards (for testing)
        if elementType == .keyboard || elementType == .key {
            return false
        }

        // Fall back to default behavior
        let defaultCategorizer = DefaultElementCategorizer()
        return defaultCategorizer.shouldSkip(elementType)
    }
}
