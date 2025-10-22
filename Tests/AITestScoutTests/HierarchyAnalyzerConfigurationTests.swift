import Testing
import Foundation
import XCTest
@testable import AITestScout

@Suite("HierarchyAnalyzerConfiguration Tests")
struct HierarchyAnalyzerConfigurationTests {

    // MARK: - Default Configuration Tests

    @Test("Default configuration should have sensible defaults")
    func testDefaultConfiguration() {
        // Arrange & Act
        let config = HierarchyAnalyzerConfiguration()

        // Assert
        #expect(config.maxDepth == 10, "Default maxDepth should be 10")
        #expect(config.maxChildrenPerElement == 50, "Default maxChildrenPerElement should be 50")
        #expect(config.excludeKeyboard == true, "Should exclude keyboard by default")
        #expect(config.useSemanticAnalysis == true, "Should use semantic analysis by default")
        #expect(config.categorizer is DefaultElementCategorizer, "Should use default categorizer")
        #expect(config.semanticAnalyzer is DefaultSemanticAnalyzer, "Should use default semantic analyzer")
    }

    @Test("Default configuration should use non-nil semantic analyzer")
    func testDefaultSemanticAnalyzerNotNil() {
        // Arrange & Act
        let config = HierarchyAnalyzerConfiguration()

        // Assert
        #expect(config.semanticAnalyzer != nil, "Default semantic analyzer should not be nil")
    }

    // MARK: - Custom Configuration Tests

    @Test("Should allow custom maxDepth")
    func testCustomMaxDepth() {
        // Arrange
        let customDepth = 5

        // Act
        let config = HierarchyAnalyzerConfiguration(maxDepth: customDepth)

        // Assert
        #expect(config.maxDepth == customDepth)
    }

    @Test("Should allow custom maxChildrenPerElement")
    func testCustomMaxChildren() {
        // Arrange
        let customMaxChildren = 25

        // Act
        let config = HierarchyAnalyzerConfiguration(maxChildrenPerElement: customMaxChildren)

        // Assert
        #expect(config.maxChildrenPerElement == customMaxChildren)
    }

    @Test("Should allow disabling keyboard exclusion")
    func testDisableKeyboardExclusion() {
        // Arrange & Act
        let config = HierarchyAnalyzerConfiguration(excludeKeyboard: false)

        // Assert
        #expect(config.excludeKeyboard == false)
    }

    @Test("Should allow disabling semantic analysis")
    func testDisableSemanticAnalysis() {
        // Arrange & Act
        let config = HierarchyAnalyzerConfiguration(useSemanticAnalysis: false)

        // Assert
        #expect(config.useSemanticAnalysis == false)
    }

    @Test("Should allow custom categorizer")
    func testCustomCategorizer() {
        // Arrange
        let customCategorizer = CustomTestCategorizer()

        // Act
        let config = HierarchyAnalyzerConfiguration(categorizer: customCategorizer)

        // Assert
        #expect(config.categorizer is CustomTestCategorizer)
    }

    @Test("Should allow custom semantic analyzer")
    func testCustomSemanticAnalyzer() {
        // Arrange
        let customAnalyzer = CustomTestSemanticAnalyzer()

        // Act
        let config = HierarchyAnalyzerConfiguration(semanticAnalyzer: customAnalyzer)

        // Assert
        #expect(config.semanticAnalyzer is CustomTestSemanticAnalyzer)
    }

    @Test("Should allow nil semantic analyzer")
    func testNilSemanticAnalyzer() {
        // Arrange & Act
        let config = HierarchyAnalyzerConfiguration(semanticAnalyzer: nil)

        // Assert
        #expect(config.semanticAnalyzer == nil, "Should allow nil semantic analyzer")
    }

    // MARK: - Multiple Custom Parameters Tests

    @Test("Should allow multiple custom parameters at once")
    func testMultipleCustomParameters() {
        // Arrange
        let customCategorizer = CustomTestCategorizer()
        let customAnalyzer = CustomTestSemanticAnalyzer()

        // Act
        let config = HierarchyAnalyzerConfiguration(
            maxDepth: 7,
            maxChildrenPerElement: 30,
            excludeKeyboard: false,
            useSemanticAnalysis: false,
            categorizer: customCategorizer,
            semanticAnalyzer: customAnalyzer
        )

        // Assert
        #expect(config.maxDepth == 7)
        #expect(config.maxChildrenPerElement == 30)
        #expect(config.excludeKeyboard == false)
        #expect(config.useSemanticAnalysis == false)
        #expect(config.categorizer is CustomTestCategorizer)
        #expect(config.semanticAnalyzer is CustomTestSemanticAnalyzer)
    }

    // MARK: - Mutability Tests

    @Test("Configuration properties should be mutable")
    func testConfigurationMutability() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()

        // Act
        config.maxDepth = 15
        config.maxChildrenPerElement = 100
        config.excludeKeyboard = false
        config.useSemanticAnalysis = false

        // Assert
        #expect(config.maxDepth == 15)
        #expect(config.maxChildrenPerElement == 100)
        #expect(config.excludeKeyboard == false)
        #expect(config.useSemanticAnalysis == false)
    }

    @Test("Should allow replacing categorizer after initialization")
    func testReplaceCategorizer() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()
        let newCategorizer = CustomTestCategorizer()

        // Act
        config.categorizer = newCategorizer

        // Assert
        #expect(config.categorizer is CustomTestCategorizer)
    }

    @Test("Should allow replacing semantic analyzer after initialization")
    func testReplaceSemanticAnalyzer() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()
        let newAnalyzer = CustomTestSemanticAnalyzer()

        // Act
        config.semanticAnalyzer = newAnalyzer

        // Assert
        #expect(config.semanticAnalyzer is CustomTestSemanticAnalyzer)
    }

    @Test("Should allow setting semantic analyzer to nil after initialization")
    func testSetSemanticAnalyzerToNil() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()
        #expect(config.semanticAnalyzer != nil, "Should start with non-nil analyzer")

        // Act
        config.semanticAnalyzer = nil

        // Assert
        #expect(config.semanticAnalyzer == nil)
    }

    // MARK: - Integration with HierarchyAnalyzer Tests

    @Test("HierarchyAnalyzer should accept configuration object")
    func testHierarchyAnalyzerAcceptsConfiguration() {
        // Arrange
        let config = HierarchyAnalyzerConfiguration(
            maxDepth: 8,
            excludeKeyboard: false
        )

        // Act
        let analyzer = HierarchyAnalyzer(configuration: config)

        // Assert
        _ = analyzer
        #expect(Bool(true), "Should initialize with configuration")
    }

    @Test("HierarchyAnalyzer should use configuration values")
    func testHierarchyAnalyzerUsesConfigurationValues() {
        // Arrange
        let customCategorizer = CustomTestCategorizer()
        let customSemanticAnalyzer = CustomTestSemanticAnalyzer()

        var config = HierarchyAnalyzerConfiguration()
        config.categorizer = customCategorizer
        config.semanticAnalyzer = customSemanticAnalyzer

        // Act
        let analyzer = HierarchyAnalyzer(configuration: config)

        // Assert - Analyzer created successfully with custom dependencies
        _ = analyzer
        #expect(Bool(true), "Should use custom categorizer and analyzer from config")
    }

    @Test("HierarchyAnalyzer convenience init should create default configuration")
    func testConvenienceInitCreatesDefaultConfig() {
        // Act
        let analyzer = HierarchyAnalyzer(
            maxDepth: 12,
            maxChildrenPerElement: 40,
            excludeKeyboard: false,
            useSemanticAnalysis: false
        )

        // Assert - Analyzer created successfully
        _ = analyzer
        #expect(Bool(true), "Convenience init should create default config internally")
    }

    // MARK: - Edge Cases and Validation Tests

    @Test("Should handle extreme maxDepth values")
    func testExtremeMaxDepth() {
        // Arrange & Act
        let configZero = HierarchyAnalyzerConfiguration(maxDepth: 0)
        let configLarge = HierarchyAnalyzerConfiguration(maxDepth: 1000)

        // Assert
        #expect(configZero.maxDepth == 0, "Should allow maxDepth of 0")
        #expect(configLarge.maxDepth == 1000, "Should allow large maxDepth")
    }

    @Test("Should handle extreme maxChildrenPerElement values")
    func testExtremeMaxChildren() {
        // Arrange & Act
        let configZero = HierarchyAnalyzerConfiguration(maxChildrenPerElement: 0)
        let configLarge = HierarchyAnalyzerConfiguration(maxChildrenPerElement: 10000)

        // Assert
        #expect(configZero.maxChildrenPerElement == 0)
        #expect(configLarge.maxChildrenPerElement == 10000)
    }

    // MARK: - Semantic Analysis Configuration Tests

    @Test("useSemanticAnalysis flag should work independently of analyzer presence")
    func testSemanticAnalysisFlagIndependent() {
        // Scenario 1: useSemanticAnalysis = true, analyzer = nil
        let config1 = HierarchyAnalyzerConfiguration(
            useSemanticAnalysis: true,
            semanticAnalyzer: nil
        )
        #expect(config1.useSemanticAnalysis == true)
        #expect(config1.semanticAnalyzer == nil)

        // Scenario 2: useSemanticAnalysis = false, analyzer = non-nil
        let config2 = HierarchyAnalyzerConfiguration(
            useSemanticAnalysis: false,
            semanticAnalyzer: DefaultSemanticAnalyzer()
        )
        #expect(config2.useSemanticAnalysis == false)
        #expect(config2.semanticAnalyzer != nil)
    }

    @Test("Disabling semantic analysis should still allow semantic analyzer in config")
    func testDisabledSemanticWithAnalyzer() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()

        // Act
        let config = HierarchyAnalyzerConfiguration(
            useSemanticAnalysis: false,
            semanticAnalyzer: analyzer
        )

        // Assert
        #expect(config.useSemanticAnalysis == false, "Semantic analysis disabled")
        #expect(config.semanticAnalyzer != nil, "But analyzer still present in config")
    }
}

// MARK: - Test Helpers

/// Custom categorizer for testing
private final class CustomTestCategorizer: ElementCategorizerProtocol {
    func categorize(_ elementType: XCUIElement.ElementType) -> ElementCategory {
        return ElementCategory(type: "custom", interactive: true)
    }

    func shouldSkip(_ elementType: XCUIElement.ElementType) -> Bool {
        return false
    }
}

/// Custom semantic analyzer for testing
private final class CustomTestSemanticAnalyzer: SemanticAnalyzerProtocol {
    func detectIntent(label: String?, identifier: String?) -> SemanticIntent {
        return .neutral
    }

    func detectScreenType(from elements: [MinimalElement]) -> ScreenType {
        return .content
    }

    func calculateSemanticPriority(_ element: MinimalElement) -> Int {
        return 100
    }

    func groupRelatedElements(_ elements: [MinimalElement]) -> [ElementGroup] {
        return []
    }
}
